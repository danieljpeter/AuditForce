public class AuditTrailCheckBulkComplete {
	public static void checkCompletion() {
		AuditTrailBatchTransformTemp batchTransform = new AuditTrailBatchTransformTemp();
		ID batchprocessid = Database.executeBatch(batchTransform, 2000);				
	}
}