trigger SetupAuditTrailPostToChatter on Setup_Audit_Trail__c (after insert) {

	Map<String,String> configMap = AuditTrailUtils.getConfig();
	
	Id chatterGroupId;

	Boolean postToChatter = false;
	if (configMap.get('postToChatter') == 'true') {
		postToChatter = true;	
		chatterGroupId = configMap.get('chatterGroupId');
	}
	
	if (postToChatter) {
		List<FeedItem> feedList = new List<FeedItem>();
		for (Setup_Audit_Trail__c s : Trigger.new) {
			try {
				String sBody = 
				s.Username__c + ' ' + s.Action_Short__c + ' on ' + s.Section__c + ' at ' + s.Date__c.format();
				feedList.add(new FeedItem(Body=sBody, Type='TextPost', ParentId=chatterGroupId));
			} catch(Exception e) {
				System.debug('ERROR: ' + e.getMessage());					
			}
		}
		if (!feedList.isEmpty()) {
			if (feedList.size() < 500) { //don't want to spam the chatter feed too bad  
				try {
					Database.Insert(feedList, false); //allow partial successes
				} catch(Exception e) {
					System.debug('ERROR: ' + e.getMessage());
				}		
			}
		}
	}

}