public class AuditTrailCheckBulkComplete {


	public static void checkCompletion() {
		Map<String,String> configMap = AuditTrailUtils.getConfig();
		String jobId = configMap.get('jobId');
		String batchId = configMap.get('batchId'); 

		String sessionId = AuditTrailUtils.getSessionId();

		Http http = new Http();
		HttpRequest req = new HttpRequest();		
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/async/27.0/job/'+jobId+'/batch/'+batchId);		
		req.setMethod('GET');
		req.setHeader('X-SFDC-Session', sessionId);
		req.setHeader('Content-Type', 'application/xml; charset=UTF-8');
		
		HTTPResponse res = new HTTPResponse(); 
		String xmlRes;
		
		if (Test.isRunningTest()) {
			xmlRes = getDummyCheckStatusResponse();
		} else {
			res = http.send(req);
			xmlRes = res.getBody();
		}			
		
		String state;
		DOM.Document doc = new DOM.Document();		
		doc.load(xmlRes);
		for(Dom.XMLNode childNode: doc.getRootElement().getChildren()) {
			if (childNode.getName() == 'state') {
				state = childNode.getText();
				break;	
			}
		}		
		
		System.Debug('state: ' + state);

		if ((state == 'Completed') || (state == 'Failed')) { //process failed, because these are partial successes where rows > 10k.  load the first 10k
			//the bulk API job is all done, transform the temp table to the live table with batch apex
			AuditTrailBatchTransformTemp batchTransform = new AuditTrailBatchTransformTemp();
			ID batchprocessid = Database.executeBatch(batchTransform, 2000);				
		} else {
			//Queued, InProgress, etc.  Schedule this same job to run again in 1 minute.
			Integer minuteDelay = 1;
			
			Datetime d = Datetime.now().addMinutes(minuteDelay);
			String sch = d.second()+' '+d.minute()+' '+d.hour()+' '+d.day()+' '+d.month()+' ? '+d.year();	
					
			AuditTrailCheckBulkCompleteSchedule check = new AuditTrailCheckBulkCompleteSchedule();
			System.Schedule('Audit Trail Check Bulk Completion', sch, check);		
		}

		
	}
	

	public static String getDummyCheckStatusResponse() {
		return
		'<?xml version="1.0" encoding="UTF-8"?>'+
		'<batchInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'+
		'<id>751x00000000079AAA</id>'+
		'<jobId>750x0000000005LAAQ</jobId>'+
		'<state>Completed</state>'+
		'<createdDate>2009-09-01T17:44:45.000Z</createdDate>'+
		'<systemModstamp>2009-09-01T17:44:45.000Z</systemModstamp>'+
		'<numberRecordsProcessed>2</numberRecordsProcessed>'+
		'</batchInfo>';
	}

	

}