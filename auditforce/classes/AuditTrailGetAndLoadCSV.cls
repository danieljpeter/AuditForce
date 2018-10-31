public class AuditTrailGetAndLoadCSV {
 /*
 Don't forget!!
 Add your org as it's own endpoint so it can call itself!
 Setup->Security->Remote site settings
 EX: https://na15.salesforce.com
  
 */
	public static List<String> allLines {get; set;}
	private static Integer inputCharacterMax { get { return 100000; } set; } // this is a somewhat arbitrary character limit
	public static String sessionId = UserInfo.getSessionId();
  	public static void getTrail() {  
		
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
		//System.debug('viewAuditPage:'+viewAuditPage);
		//parse out just the URL we want from the full HTML source
		List<String> auditPageList = viewAuditPage.split('href="/servlet/servlet.SetupAuditTrail', 2);
        
		String csvURL = '/servlet/servlet.SetupAuditTrail' + auditPageList[1].split('"', 2)[0];
		csvURL = csvURL.replace('&amp;', '&');
		
		
		System.debug('csvURL:'+csvURL);
        System.debug('URL:'+URL.getSalesforceBaseUrl().toExternalForm()+csvURL);
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
		csvContent = csvContent.removeStart('Date,User,Source Namespace Prefix,Action,Section,Delegate User\n');
		csvContent = 'Date_String__c,Username__c,SourceName__c,Action__c,Section__c,Delegate_User__c\n' + csvContent; 
        List<String> lines = new List<String>();
        try {
            allLines = new List<String>();
            divideString(csvContent);
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        String jobid = createBulkLoadJob();
		breakCSVinBatchesAndSubmit(jobid);	
        closeBulkJob(jobId);
        scheduleFuture();
    }
    public static void breakCSVinBatchesAndSubmit(String jobid){
        Integer count = 0;
        Integer maxBatchSize = 9999;
        List<String> csvBatch = new List<String>();
        System.debug('headers: '+allLines[0]);
        csvBatch.add(allLines[0]);
        for(integer i=1;i<=allLines.size()-1;i++){
            count++;
            if(count <= allLines.size()){
                if(String.isBlank(allLines[i].trim())) continue;
                if(allLines[i].trim().equals('"')) continue;
                csvBatch.add(allLines[i]);
                if(count == maxBatchSize){
                    count = 0;
                    String batchCSVFile = string.join(csvBatch,'"\n');
                    System.debug(batchCSVFile);
                    batchCSVFile.removeEnd('\n');
                    batchCSVFile += '"';
                    addBatchtoJob(Blob.valueOf(batchCSVFile),jobId);
                    csvBatch = new List<String>();
                    csvBatch.add(allLines[0]);
                }
                
            }
        }
        if(count > 0){
            String batchCSVFile = string.join(csvBatch,'"\n');
			batchCSVFile.removeEnd('\n');
            batchCSVFile += '"';
            System.debug(batchCSVFile);
            addBatchtoJob(Blob.valueOf(batchCSVFile),jobId);
        }
    }
    public static String createBulkLoadJob(){
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
		
			
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/async/40.0/job');
		req.setMethod('GET');
		req.setHeader('X-SFDC-Session', sessionId); 
		req.setHeader('Content-Type', 'application/xml; charset=UTF-8');
		req.setBodyDocument(doc);
		
		String xmlRes;
        HTTPResponse res = new HTTPResponse();
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
		return jobId;
    }
		
    public static void addBatchtoJob(Blob csvBlob, String jobId){
        System.debug('adding to batch');
		//===================================================================
		//Step 4: add a batch to the job.  We will have just 1 batch, the csv file			
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/async/40.0/job/'+jobId+'/batch');
		req.setMethod('GET');
		req.setHeader('X-SFDC-Session', sessionId);		 
		req.setHeader('Content-Type', 'text/csv; charset=UTF-8');						
		req.setBodyAsBlob(csvBlob);
		String xmlRes;
        HTTPResponse res = new HTTPResponse();
		if (Test.isRunningTest()) {
			xmlRes = getDummyAddBatchResponse();
		} else {
			res = http.send(req);
			xmlRes = res.getBody();
		}		
		
		String batchId; //get the Bulk Load Batch Id
		DOM.Document doc = new DOM.Document();		
		doc.load(xmlRes);
		for(Dom.XMLNode childNode: doc.getRootElement().getChildren()) {
			if (childNode.getName() == 'id') {
				batchId = childNode.getText();
				break;	
			}
		}	
    }
    public static void closeBulkJob(String jobId){
		//===================================================================		
		//Step 5: close the job
		String closeDef =
		'<?xml version="1.0" encoding="UTF-8"?>'+
		'<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'+
		'<state>Closed</state>'+
		'</jobInfo>';
		DOM.Document doc = new DOM.Document();
		doc.load(closeDef);
		
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/async/40.0/job/'+jobId);
		req.setMethod('GET');
		req.setHeader('X-SFDC-Session', sessionId);
		req.setHeader('Content-Type', 'application/xml; charset=UTF-8');
		req.setBodyDocument(doc);
		HTTPResponse res = new HTTPResponse();
        String xmlRes;
		if (!Test.isRunningTest()) {
			res = http.send(req);
			xmlRes = res.getBody();
		}			
    }
		
    public static void scheduleFuture(){
		
		//===================================================================		
		//Step 6: the bulk CSV load job is all queued up and finalized
		//from testing it seems to finish in a matter of seconds.
		//even still we are going to schedule a future job which will check if it is finished
		//and re-schedule itself until it is finished as a failsafe in case the load job
		//takes a long time to run.  such as in orgs with a lot of bulk jobs running for other reasons.
		
		Integer minuteDelay = 5;
		
		
		Datetime d = Datetime.now().addMinutes(minuteDelay);
		String sch = d.second()+' '+d.minute()+' '+d.hour()+' '+d.day()+' '+d.month()+' ? '+d.year();	

		
		
		AuditTrailCheckBulkCompleteSchedule check = new AuditTrailCheckBulkCompleteSchedule();
		System.Schedule('Audit Trail Check Bulk Completion '+d.format(), sch, check);
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
    
    public static void divideString(String input) {
        
        Integer pivot = input.indexOf( '"\n', Integer.valueOf(Math.floor(input.length() / 2) ) );
        
        String left = input.substring(0,pivot);
        String right = input.substring(pivot);
        
        if ( pivot < inputCharacterMax ) {
            // split left and right chunks, add to allLines
            List<String> leftLines = left.split('"\n');
            List<String> rightLines = right.split('"\n');
            allLines.addAll(leftLines);
            allLines.addAll(rightLines);
        }else {
            // divide and conquer!
            divideString(left);
            divideString(right);
        }
    }
    
    
}