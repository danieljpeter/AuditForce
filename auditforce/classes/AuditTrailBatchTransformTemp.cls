global class AuditTrailBatchTransformTemp implements Database.Batchable<sObject> {


	global Database.querylocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT Id, Date_String__c, Date__c, Username__c, User__c, Action__c, Action_Short__c FROM TEMP_Setup_Audit_Trail__c');
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
		List<TEMP_Setup_Audit_Trail__c> tempAuditList = new List<TEMP_Setup_Audit_Trail__c>();

		//get all the usernames in the batch
		Set<String> usernameSet = new Set<String>(); 
		for(sObject s : scope){
			TEMP_Setup_Audit_Trail__c t = (TEMP_Setup_Audit_Trail__c)s;
            usernameSet.add(t.Username__c);
		}
		
		//build a map of username to User.Id where exists
		Map<String, Id> usernameToIdMap = new Map<String, Id>();
		for (User u: [SELECT Id, Username FROM User WHERE Username IN: usernameSet]) {
			usernameToIdMap.put(u.Username, u.id);	
		}
		
		for(sObject s : scope){
			TEMP_Setup_Audit_Trail__c t = (TEMP_Setup_Audit_Trail__c)s;
            
            //convert the text version of the time to a datetime version
            t.Date__c = convertDate(t.Date_String__c); 
			
			//add in the lookup field to the user if exists
			if (usernameToIdMap.containsKey(t.Username__c)) {
				t.User__c = usernameToIdMap.get(t.Username__c);
			} 			            	
            
            //some actions are > 255.  We want to have a <=255 as well for easier reporting.
            if (t.Action__c != null) {
            	if (t.Action__c.length() > 255) {
            		t.Action_Short__c = t.Action__c.left(255);
            	} else {
            		t.Action_Short__c = t.Action__c;	
            	}
            }
            
            
            tempAuditList.add(t);
		}
		
		update tempAuditList;
	}	
	
	global void finish(Database.BatchableContext BC) {
		/*
			After finishing this transform job, we are going to optionally run the batch delete job.
			if there is nothing to delete (this is a first time insert), just skip it and run the batch insert job.
		*/
		
		//get the datetime stamp of the most recent record in the DB
		Datetime maxDatetime;
		List<Setup_Audit_Trail__c> sList = new List<Setup_Audit_Trail__c>();
		sList = [SELECT Date__c FROM Setup_Audit_Trail__c WHERE Date__c != null ORDER BY Date__c DESC LIMIT 1];
		if (!sList.isEmpty()) {
			maxDatetime	= sList[0].Date__c;
		}				

		//if maxDatetime is null, it means we don't need to run this delete batch, since we are going to insert everything to the live table
		if (maxDatetime != null) {
			AuditTrailBatchDeleteExistingTemp batchDel = new AuditTrailBatchDeleteExistingTemp();
			batchDel.maxDatetime = maxDatetime;
			ID batchprocessid = Database.executeBatch(batchDel, 2000);		
		} else {
			AuditTrailBatchInsertToFinal batchInsert = new AuditTrailBatchInsertToFinal();
			ID batchprocessid = Database.executeBatch(batchInsert, 2000);				
		}

		
	}	
	
	public static Datetime convertDate(String sDate) {
		//parse this into a datetime: 10/5/2013 9:37:31 AM PDT

		Datetime d;
		
		Integer year;
		Integer month;
		Integer day;
		Integer hour;
		Integer minute;
		Integer second;		
		
		try {
			List<String> dateTimePartList = sDate.split(' ');			
			List<String> datePartList = dateTimePartList[0].split('/');
			List<String> timePartList = dateTimePartList[1].split(':');
			String amPm = dateTimePartList[2];
			
			year = Integer.valueOf(datePartList[2]);
			month = Integer.valueOf(datePartList[0]);
			day = Integer.valueOf(datePartList[1]);		
			
			hour = Integer.valueOf(timePartList[0]);
			minute = Integer.valueOf(timePartList[1]);
			second = Integer.valueOf(timePartList[2]);
			
			if (amPm == 'PM') {
				hour += 12;
				if (hour == 24) {
					hour = 0;
				}	
			}
			
			d = Datetime.newInstance(year, month, day, hour, minute, second);
		} catch (Exception e) {		
		}
		
		return d;
	}
	
	
	
}