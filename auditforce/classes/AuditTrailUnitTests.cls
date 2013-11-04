@isTest 
public class AuditTrailUnitTests {
    
    static testMethod void testAuditTrailGetAndLoadCSV() {
		//TODO: add system.assert checks.  but at least this checks for runtime errors..
		AuditTrailGetAndLoadCSV.getTrail();
    }
  
	static testMethod void testAuditTrailBatchDeleteExistingTemp() {
		insertTempObjects();
		
		Test.StartTest();
		AuditTrailBatchDeleteExistingTemp a = new AuditTrailBatchDeleteExistingTemp();
		a.maxDatetime = Datetime.now();
		Id batchProcessId = Database.executeBatch(a);
	 	System.AssertEquals(database.countquery('SELECT COUNT()FROM TEMP_Setup_Audit_Trail__c WHERE Section__c=\'Test Apex Class\''), 10);
	 	Test.StopTest();
	}

	static testMethod void testAuditTrailBatchInsertToFinal() {
		insertTempObjects();
		
		Test.StartTest();
		AuditTrailBatchInsertToFinal a = new AuditTrailBatchInsertToFinal();
		Id batchProcessId = Database.executeBatch(a);
	 	Test.StopTest();
	 	
		System.AssertEquals(database.countquery('SELECT COUNT()FROM Setup_Audit_Trail__c WHERE Section__c=\'Test Apex Class\''), 10);  	 	
	} 


	static testMethod void testAuditTrailBatchTransformTemp() {
		insertTempObjects();
		
		Test.StartTest();
		AuditTrailBatchTransformTemp a = new AuditTrailBatchTransformTemp();
		Id batchProcessId = Database.executeBatch(a);
	 	Test.StopTest();
	 	
		System.AssertEquals(database.countquery('SELECT COUNT()FROM Setup_Audit_Trail__c WHERE Section__c=\'Test Apex Class\''), 10);  	 	
	} 

	static testMethod void testAuditTrailCheckBulkComplete() {
		AuditTrailCheckBulkComplete.checkCompletion();
	} 

	static testMethod void testAuditTrailCheckBulkCompleteBatchWrapper() {
		AuditTrailCheckBulkCompleteBatchWrapper a = new AuditTrailCheckBulkCompleteBatchWrapper();
		Id batchProcessId = Database.executeBatch(a);
	} 

	static testMethod void testAuditTrailCheckBulkCompleteSchedule() {
		Test.StartTest();			
		Datetime d = Datetime.now().addMinutes(1);
		String sch = d.second()+' '+d.minute()+' '+d.hour()+' '+d.day()+' '+d.month()+' ? '+d.year();	
		AuditTrailCheckBulkCompleteSchedule check = new AuditTrailCheckBulkCompleteSchedule();
		System.Schedule('Audit Trail Check Bulk Completion TEST', sch, check);	
		Test.StopTest();			
	} 

	static testMethod void testAuditTrailClearTempGetCSV() {
		insertTempObjects();
		
		Test.StartTest();
		AuditTrailBatchDeleteExistingTemp a = new AuditTrailBatchDeleteExistingTemp();
		a.maxDatetime = Datetime.now();
		Id batchProcessId = Database.executeBatch(a);
	 	Test.StopTest();
	 	
		System.AssertEquals(database.countquery('SELECT COUNT()FROM TEMP_Setup_Audit_Trail__c WHERE Section__c=\'Test Apex Class\''), 0);  	 	
	}
	
	
	static testMethod void testAuditTrailImporterScheduler() {
		Test.StartTest();			
		Datetime d = Datetime.now().addMinutes(1);
		String sch = d.second()+' '+d.minute()+' '+d.hour()+' '+d.day()+' '+d.month()+' ? '+d.year();	
		AuditTrailImporterScheduler a = new AuditTrailImporterScheduler();
		System.Schedule('Audit Trail Check Bulk Completion TEST', sch, a);	
		Test.StopTest();			
	} 	


	static testMethod void testAuditTrailUtils_getConfig_updateConfig() {
		Test.StartTest();
		Setup_Audit_Trail_Config__c c = new Setup_Audit_Trail_Config__c(name='name',
																	  username__c = 'usergroup@danpeter.com',
																	  password__c = 'password',
																	  token__c = 'token',							  
																	  Bulk_Job_ID__c = 'jobId',							  
																	  Bulk_Batch_ID__c = 'batchId');
		insert c;
		Test.StopTest();
			
		Map<String,String> configMap = AuditTrailUtils.getConfig();
		System.AssertEquals(configMap.get('username'), 'usergroup@danpeter.com');
		System.AssertEquals(configMap.get('password'), 'password');
		System.AssertEquals(configMap.get('token'), 'token');
		System.AssertEquals(configMap.get('jobId'), 'jobId');
		System.AssertEquals(configMap.get('batchId'), 'batchId');
		
		AuditTrailUtils.updateConfig('jobId2', 'batchId2');		
		configMap = AuditTrailUtils.getConfig();
		System.AssertEquals(configMap.get('jobId'), 'jobId2');
		System.AssertEquals(configMap.get('batchId'), 'batchId2');		
	}

	static testMethod void testAuditTrailUtils_getSessionId() {
		System.AssertEquals(AuditTrailUtils.getSessionId(), '00Di0000000fnjR!ARAAQHLABD_pDEsAVmS6vPUORiIThiH9B4GE7cJHE5htToV9UOshfxPUIfVcBYRxKzincGp_6uIPoiHqhTzPRSULo0h7mv1l');
	}


	static testMethod void testSetupAuditTrailPostToChatterTrigger() {
		Test.StartTest();			
		Setup_Audit_Trail_Config__c c = new Setup_Audit_Trail_Config__c(name='name',
																	  Post_to_Chatter__c = true,
																	  Chatter_Group_Id__c = null);
		insert c;
		Test.StopTest();
		
		List<Setup_Audit_Trail__c> sList = new List<Setup_Audit_Trail__c>(); 
		
		for(Integer i = 0; i < 100; i++){
			Setup_Audit_Trail__c s = new Setup_Audit_Trail__c(
			Date__c 			= Datetime.now().addSeconds(-1*i), 
			Username__c			= 'usergroup@danpeter.com', 
			Action_Short__c 	= 'Action (Short)',
			Action__c 			= 'Action', 
			Section__c			= 'Apex', 
			Delegate_User__c 	= '');
			sList.add(s);
		}
		insert sList;
	} 	


	static void insertTempObjects() {
		//insert some test TEMP objects
		List <TEMP_Setup_Audit_Trail__c> tList = new List<TEMP_Setup_Audit_Trail__c>(); 
		for (Integer i = 0; i<10; i++){
		tList.add(new TEMP_Setup_Audit_Trail__c(Username__c = 'usergroup@danpeter.com',
												Section__c = 'Test Apex Class',
												Date_String__c = '10/28/2013 2:24:51 PM PDT',
												Date__c = Datetime.now().addDays(-10),
												Action__c = 'Changed Class code'));
			
		} 
		insert tList;
	}

 

}