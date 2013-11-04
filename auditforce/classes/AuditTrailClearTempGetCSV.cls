global class AuditTrailClearTempGetCSV implements Database.Batchable<sObject>, Database.AllowsCallouts {

	global Database.querylocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT Id FROM TEMP_Setup_Audit_Trail__c');
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
      delete scope;
      DataBase.emptyRecycleBin(scope);
	}	
	
	global void finish(Database.BatchableContext BC) {
		//kick off the batch job that gets the CSV and fires the Bulk Data Load Job
		AuditTrailGetAndLoadCSV.getTrail();
	}	
	
}