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
    static testMethod void AuditTrailClearTempGetCSVtest(){
        insertTempObjects();
		
		Test.StartTest();
		AuditTrailClearTempGetCSV a = new AuditTrailClearTempGetCSV();
		Id batchProcessId = Database.executeBatch(a);
	 	Test.StopTest();
    }
	
	static testMethod void testAuditTrailImporterScheduler() {
		Test.StartTest();			
		Datetime d = Datetime.now().addMinutes(1);
		String sch = d.second()+' '+d.minute()+' '+d.hour()+' '+d.day()+' '+d.month()+' ? '+d.year();	
		AuditTrailImporterScheduler a = new AuditTrailImporterScheduler();
		System.Schedule('Audit Trail Check Bulk Completion TEST', sch, a);	
		Test.StopTest();			
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