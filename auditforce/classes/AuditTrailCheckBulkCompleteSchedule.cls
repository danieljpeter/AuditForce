global class AuditTrailCheckBulkCompleteSchedule implements Schedulable{

	global void execute(SchedulableContext sc) {
		AuditTrailCheckBulkCompleteBatchWrapper batchWrapper = new AuditTrailCheckBulkCompleteBatchWrapper();
		ID batchprocessid = Database.executeBatch(batchWrapper, 2000);	
	}
 
}