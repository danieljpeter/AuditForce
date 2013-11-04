global class AuditTrailCheckBulkCompleteBatchWrapper implements Database.Batchable<sObject>, Database.AllowsCallouts {
	//this is just a batch wrapper workaround to avoid "Callout from scheduled Apex not supported" limitation

	global Database.querylocator start(Database.BatchableContext BC) {
		//just a dummy query to avoid "First error: Start did not return a valid iterable object." error
		String query =
		'SELECT Id FROM TEMP_Setup_Audit_Trail__c LIMIT 1';
		return Database.getQueryLocator(query);		
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
	}	
	
	global void finish(Database.BatchableContext BC) {
		AuditTrailCheckBulkComplete.checkCompletion();	
	}	
	
}