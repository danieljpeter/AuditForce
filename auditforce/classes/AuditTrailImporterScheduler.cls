global class AuditTrailImporterScheduler implements Schedulable {

/*

//Inputting this into the anon execute block window will schedule the Setup Audit Trail csv import batch job series

AuditTrailImporterScheduler a = new AuditTrailImporterScheduler ();

String seconds = '0'; //Execute at Zero Seconds
String minutes = '30'; //on the half hour
String hours = '15'; // Execute 5pm PST (make note of running user's timezone)
String dayOfMonth = '*'; // Execute Every Day of the Month
String month = '*'; //Execute all months
String dayOfWeek = '?'; //execute every day

String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;


system.schedule('Setup Audit Trail CSV Import Main Job', sch, a);

*/	

	global void execute(SchedulableContext sc) {
		AuditTrailClearTempGetCSV clearTempGetCSV = new AuditTrailClearTempGetCSV();
		ID batchprocessid = Database.executeBatch(clearTempGetCSV, 2000);	
	}
 	
}