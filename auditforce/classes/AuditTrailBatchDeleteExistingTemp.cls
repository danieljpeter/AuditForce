global class AuditTrailBatchDeleteExistingTemp implements Database.Batchable<sObject> {
	
	public Datetime maxDatetime;

	global Database.querylocator start(Database.BatchableContext BC) {
		String dateString = maxDatetime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
		return Database.getQueryLocator('SELECT Id FROM TEMP_Setup_Audit_Trail__c WHERE Date__c < '+dateString);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
      delete scope;
      DataBase.emptyRecycleBin(scope);
	}	
	
	global void finish(Database.BatchableContext BC) {
		//kick off the batch job that copies the records to the live table
		AuditTrailBatchInsertToFinal batchInsert = new AuditTrailBatchInsertToFinal();
		ID batchprocessid = Database.executeBatch(batchInsert, 2000);				
	}	
	
}