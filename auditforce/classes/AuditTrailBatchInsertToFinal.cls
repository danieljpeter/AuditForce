global class AuditTrailBatchInsertToFinal implements Database.Batchable<sObject> {

	global Database.querylocator start(Database.BatchableContext BC) {
		String query =
		'SELECT Id, Date__c, Username__c, User__c, Action_Short__c, Action__c, Section__c, Delegate_User__c '+ 
		'FROM TEMP_Setup_Audit_Trail__c ORDER BY Date__c';
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
		List<Setup_Audit_Trail__c> auditList = new List<Setup_Audit_Trail__c>();

		for(sObject s : scope){
			TEMP_Setup_Audit_Trail__c t = (TEMP_Setup_Audit_Trail__c)s;
			
			Setup_Audit_Trail__c a = new Setup_Audit_Trail__c(
			Date__c 			= t.Date__c, 
			Username__c			= t.Username__c, 
			User__c 			= t.User__c, 
			Action_Short__c 	= t.Action_Short__c,
			Action__c 			= t.Action__c, 
			Section__c			= t.Section__c, 
			Delegate_User__c 	= t.Delegate_User__c);

            auditList.add(a);
		}
		
		insert auditList;
	}	
	
	global void finish(Database.BatchableContext BC) {
		//TODO: nofify?	
	}	

}