public class AuditTrailGetAndLoadCSV {
 /*
 Don't forget!!
 Add your org as it's own endpoint so it can call itself!
 Setup->Security->Remote site settings
 EX: https://na15.salesforce.com
  
 */
 
  	public static void getTrail() {
		//get a session Id for all the API requests
		String sessionId = AuditTrailUtils.getSessionId();  
		
		//===================================================================
		//Step 1: get the URL for the Setup Audit Trail .CSV file.  This is just because we need the CONFIRMATIONTOKEN (screen scrape!)
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/setup/org/orgsetupaudit.jsp');
		req.setMethod('GET');	
		 
		req.setHeader('Cookie','sid='+sessionId);
		HTTPResponse res = new HTTPResponse(); 
		
		String viewAuditPage;
		if (Test.isRunningTest()) {
			viewAuditPage = getDummyPage();
		} else {			
			res = http.send(req);
			viewAuditPage = res.getBody();
		}
		
		//parse out just the URL we want from the full HTML source
		List<String> auditPageList = viewAuditPage.split('href="/servlet/servlet.SetupAuditTrail', 2);
		String csvURL = '/servlet/servlet.SetupAuditTrail' + auditPageList[1].split('"', 2)[0];
		csvURL = csvURL.replace('&amp;', '&');
		
		
		
		//===================================================================
		//Step 2: get the csv file		
		http = new Http();
		req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+csvURL);
		req.setMethod('GET');
		req.setHeader('Cookie','sid='+sessionId); 

		String csvContent; 
		
		if (Test.isRunningTest()) {
			csvContent = getDummyCSV();
		} else {
			res = http.send(req);
			csvContent = res.getBody();
		}
		
		//trim off the existing header row, and replace it with one that has the correct fieldnames.		
		csvContent = csvContent.removeStart('Date,User,Action,Section,Delegate User\n');
		csvContent = 'Date_String__c,Username__c,Action__c,Section__c,Delegate_User__c\n' + csvContent; 
		
		Blob csvBlob = Blob.valueOf(csvContent);
		
		
		//===================================================================		
		//Step 3: create a Bulk Load Job
		String loadDef =
		'<?xml version="1.0" encoding="UTF-8"?>'+
		'<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'+
		'<operation>insert</operation>'+
		'<object>TEMP_Setup_Audit_Trail__c</object>'+
		'<contentType>CSV</contentType>'+
		'</jobInfo>';
		DOM.Document doc = new DOM.Document();
		doc.load(loadDef);		
		
			
		http = new Http();
		req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/async/27.0/job');
		req.setMethod('GET');
		req.setHeader('X-SFDC-Session', sessionId); 
		req.setHeader('Content-Type', 'application/xml; charset=UTF-8');
		req.setBodyDocument(doc);
		
		String xmlRes;			
		if (Test.isRunningTest()) {
			xmlRes = getDummyCreateJobResponse();
		} else {
			res = http.send(req);
			xmlRes = res.getBody();
		}
		
		
		String jobId; //get the Bulk Load Job's Job ID
		doc = new DOM.Document();		
		doc.load(xmlRes);
		for(Dom.XMLNode childNode: doc.getRootElement().getChildren()) {
			if (childNode.getName() == 'id') {
				jobId = childNode.getText();
				break;	
			}
		}

		
		
		//===================================================================
		//Step 4: add a batch to the job.  We will have just 1 batch, the csv file			
		http = new Http();
		req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/async/27.0/job/'+jobId+'/batch');
		req.setMethod('GET');
		req.setHeader('X-SFDC-Session', sessionId);		 
		req.setHeader('Content-Type', 'text/csv; charset=UTF-8');						
		req.setBodyAsBlob(csvBlob);
		
		if (Test.isRunningTest()) {
			xmlRes = getDummyAddBatchResponse();
		} else {
			res = http.send(req);
			xmlRes = res.getBody();
		}		
		
		String batchId; //get the Bulk Load Batch Id
		doc = new DOM.Document();		
		doc.load(xmlRes);
		for(Dom.XMLNode childNode: doc.getRootElement().getChildren()) {
			if (childNode.getName() == 'id') {
				batchId = childNode.getText();
				break;	
			}
		}
		
		
		//===================================================================		
		//Step 5: close the job
		String closeDef =
		'<?xml version="1.0" encoding="UTF-8"?>'+
		'<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'+
		'<state>Closed</state>'+
		'</jobInfo>';
		doc = new DOM.Document();
		doc.load(closeDef);
		
		http = new Http();
		req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/async/27.0/job/'+jobId);
		req.setMethod('GET');
		req.setHeader('X-SFDC-Session', sessionId);
		req.setHeader('Content-Type', 'application/xml; charset=UTF-8');
		req.setBodyDocument(doc);

		if (!Test.isRunningTest()) {
			res = http.send(req);
			xmlRes = res.getBody();
		}			

		//update our config custom object with the jobId and the batchId since we can't just pass them to the
		//future, scheduled jobs.
		AuditTrailUtils.updateConfig(jobId, batchId);

		
		//===================================================================		
		//Step 6: the bulk CSV load job is all queued up and finalized
		//from testing it seems to finish in a matter of seconds.
		//even still we are going to schedule a future job which will check if it is finished
		//and re-schedule itself until it is finished as a failsafe in case the load job
		//takes a long time to run.  such as in orgs with a lot of bulk jobs running for other reasons.
		
		Integer minuteDelay = 1;
		
		
		Datetime d = Datetime.now().addMinutes(minuteDelay);
		String sch = d.second()+' '+d.minute()+' '+d.hour()+' '+d.day()+' '+d.month()+' ? '+d.year();	

		
		
		AuditTrailCheckBulkCompleteSchedule check = new AuditTrailCheckBulkCompleteSchedule();
		System.Schedule('Audit Trail Check Bulk Completion '+d.format(), sch, check);

		/*
		AuditTrailCheckBulkCompleteBatchWrapper batchWrapper = new AuditTrailCheckBulkCompleteBatchWrapper();
		String cronID = System.scheduleBatch(batchWrapper, 'Audit Trail Check Bulk Completion '+d.format(), 1, 2000);
		*/	
	}
	
		
	//===================================================================
	//dummy http responses for testing
	public static String getDummyPage() {
		return
		'<a href="/servlet/servlet.SetupAuditTrail?id=00Di00000001111&amp;_CONFIRMATIONTOKEN=28907nr89nd2589.2895724758d8937nd9wfushffsdfjk.skjfhsjkfhskdfh8937nxtr389nu.248907n528947n589347n5c9">';		
	}	

	public static String getDummyCSV() {
		return
		'Date,User,Action,Section,Delegate User\n'+
		'"10/5/2013 10:11:56 AM PDT","usergroup@danpeter.com","Changed AuditTrailImporter Apex Class code","Apex Class",""\n'+
		'"10/5/2013 10:11:26 AM PDT","usergroup@danpeter.com","Changed AuditTrailImporter Apex Class code","Apex Class",""\n';
	}

	public static String getDummyCreateJobResponse() {
		return
		'<?xml version="1.0" encoding="UTF-8"?>'+
		'<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'+
		'<id>750x0000000005LAAQ</id>'+
		'<operation>insert</operation>'+
		'<object>TEMP_Setup_Audit_Trail__c</object>'+
		'<createdById>005x0000000wPWdAAM</createdById>'+
		'<createdDate>2009-09-01T16:42:46.000Z</createdDate>'+
		'<systemModstamp>2009-09-01T16:42:46.000Z</systemModstamp>'+
		'<state>Open</state>'+
		'<concurrencyMode>Parallel</concurrencyMode>'+
		'<contentType>CSV</contentType>'+
		'<numberBatchesQueued>0</numberBatchesQueued>'+
		'<numberBatchesInProgress>0</numberBatchesInProgress>'+
		'<numberBatchesCompleted>0</numberBatchesCompleted>'+
		'<numberBatchesFailed>0</numberBatchesFailed>'+
		'<numberBatchesTotal>0</numberBatchesTotal>'+
		'<numberRecordsProcessed>0</numberRecordsProcessed>'+
		'<numberRetries>0</numberRetries>'+
		'<apiVersion>27.0</apiVersion>'+
		'</jobInfo>';
	} 

	public static String getDummyAddBatchResponse() {
		return
		'<?xml version="1.0" encoding="UTF-8"?>'+
		'<batchInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'+
		'<id>751x00000000079AAA</id>'+
		'<jobId>750x0000000005LAAQ</jobId>'+
		'<state>Queued</state>'+
		'<createdDate>2009-09-01T17:44:45.000Z</createdDate>'+
		'<systemModstamp>2009-09-01T17:44:45.000Z</systemModstamp>'+
		'<numberRecordsProcessed>0</numberRecordsProcessed>'+
		'</batchInfo>';
	}



}