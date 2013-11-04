public with sharing class AuditTrailUtils {

	public static Map<String,String> getConfig() {
		Map<String,String> configMap = new Map<String,String>();
		configMap.put('username'		,'');
		configMap.put('password'		,'');
		configMap.put('token'			,'');
		configMap.put('jobId'			,'');
		configMap.put('batchId'			,'');
		configMap.put('postToChatter'	,'');
		configMap.put('chatterGroupId'	,'');

		
		List<Setup_Audit_Trail_Config__c> configList = new List<Setup_Audit_Trail_Config__c>();
		configList = [SELECT username__c, password__c, token__c, Bulk_Job_ID__c, Bulk_Batch_ID__c, Post_to_Chatter__c, Chatter_Group_Id__c 
					  FROM Setup_Audit_Trail_Config__c
					  ORDER BY LastModifiedDate DESC LIMIT 1];
		 		
		if (!configList.isEmpty()) {
			String sPostToChatter = 'false';
			if (configList[0].Post_to_Chatter__c) {
				sPostToChatter = 'true';	
			}  
			configMap.put('username'		,configList[0].username__c);
			configMap.put('password'		,configList[0].password__c);
			configMap.put('token'			,configList[0].token__c);
			configMap.put('jobId'			,configList[0].Bulk_Job_ID__c);
			configMap.put('batchId'			,configList[0].Bulk_Batch_ID__c);			
			configMap.put('postToChatter'	,sPostToChatter);
			configMap.put('chatterGroupId'	,configList[0].Chatter_Group_Id__c);
		}
		
		return configMap;
	}
	
	public static void updateConfig(String jobId, String batchId) {
		List<Setup_Audit_Trail_Config__c> configList = new List<Setup_Audit_Trail_Config__c>();
		configList = [SELECT Bulk_Job_ID__c, Bulk_Batch_ID__c 
					  FROM Setup_Audit_Trail_Config__c
					  ORDER BY LastModifiedDate DESC LIMIT 1];
		 		
		if (!configList.isEmpty()) {
			configList[0].Bulk_Job_ID__c = jobId;	
			configList[0].Bulk_Batch_ID__c = batchId;
			update configList;
		}
	}

	public static String getSessionId() {
		Map<String,String> configMap = getConfig();

		String xmlReq =
		'<?xml version="1.0" encoding="utf-8" ?>'+
		'<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">'+
		'<env:Body>'+
		'<n1:login xmlns:n1="urn:partner.soap.sforce.com">'+
		'<n1:username>'+configMap.get('username')+'</n1:username>'+
		'<n1:password>'+configMap.get('password')+configMap.get('token')+'</n1:password>'+
		'</n1:login>'+
		'</env:Body>'+
		'</env:Envelope>';
		DOM.Document doc = new DOM.Document();
		doc.load(xmlReq);
		
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/Soap/u/28.0');
		req.setMethod('POST');
		req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
		req.setHeader('SOAPAction', 'login');		
		req.setBodyDocument(doc);
		
		HTTPResponse res = new HTTPResponse(); 
				
		String xmlRes;
		if (Test.isRunningTest()) {
			xmlRes = getDummySessionIdResponse();
		} else {
			res = http.send(req);
			xmlRes = res.getBody();			
		}
		
		String sessionId;
		try {
			sessionId = xmlRes.split('<sessionId>',2)[1].split('</sessionId>',2)[0];
		} catch(Exception e) {			
		}

		return sessionId;
	}



	public static String getDummySessionIdResponse() {
		return
		'<?xml version="1.0" encoding="UTF-8"?>'+
		'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:partner.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
		'<soapenv:Body>'+
		'<loginResponse>'+
		'<result>'+
		'<metadataServerUrl>https://na15.salesforce.com/services/Soap/m/28.0/00Di0000000fnjR</metadataServerUrl>'+
		'<passwordExpired>false</passwordExpired>'+
		'<sandbox>false</sandbox>'+
		'<serverUrl>https://na15.salesforce.com/services/Soap/u/28.0/00Di0000000fnjR</serverUrl>'+
		'<sessionId>00Di0000000fnjR!ARAAQHLABD_pDEsAVmS6vPUORiIThiH9B4GE7cJHE5htToV9UOshfxPUIfVcBYRxKzincGp_6uIPoiHqhTzPRSULo0h7mv1l</sessionId>'+
		'<userId>005i0000001fqC0AAI</userId>'+
		'<userInfo>'+
		'<accessibilityMode>false</accessibilityMode>'+
		'<currencySymbol>$</currencySymbol>'+
		'<orgAttachmentFileSizeLimit>5242880</orgAttachmentFileSizeLimit>'+
		'<orgDefaultCurrencyIsoCode>USD</orgDefaultCurrencyIsoCode>'+
		'<orgDisallowHtmlAttachments>false</orgDisallowHtmlAttachments>'+
		'<orgHasPersonAccounts>false</orgHasPersonAccounts>'+
		'<organizationId>00Di0000000fnjREAQ</organizationId>'+
		'<organizationMultiCurrency>false</organizationMultiCurrency>'+
		'<organizationName>danpeter</organizationName>'+
		'<profileId>00ei00000016tSrAAI</profileId>'+
		'<roleId xsi:nil="true"/>'+
		'<sessionSecondsValid>7200</sessionSecondsValid>'+
		'<userDefaultCurrencyIsoCode xsi:nil="true"/>'+
		'<userEmail>dan@danpeter.com</userEmail>'+
		'<userFullName>Daniel Peter</userFullName>'+
		'<userId>005i0000001fqC0AAI</userId>'+
		'<userLanguage>en_US</userLanguage>'+
		'<userLocale>en_US</userLocale>'+
		'<userName>usergroup@danpeter.com</userName>'+
		'<userTimeZone>America/Los_Angeles</userTimeZone>'+
		'<userType>Standard</userType>'+
		'<userUiSkin>Theme3</userUiSkin>'+
		'</userInfo></result></loginResponse>'+
		'</soapenv:Body>'+
		'</soapenv:Envelope>';
	}


}