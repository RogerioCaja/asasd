public with sharing class IntegrationLog {

    public static Id createLog(String integrationName, String recordTypeName, String payloadIN, String payloadOUT, Boolean hasAnyErrors){
        System.debug('ON WS LOG: '+integrationName);

        Boolean shouldUseAttachmentIN  = (payloadIN.length() > 100000);
        Boolean shouldUseAttachmentOUT = (payloadOUT.length() > 100000);

        Datetime tNow = System.now();
        
        IntegrationLog__c log = new IntegrationLog__c(
            Flow__c      = recordTypeName,
            Integration__c    = integrationName,
            hasAttachment__c = (shouldUseAttachmentIN || shouldUseAttachmentOUT),
            PayloadIN__c     = (shouldUseAttachmentIN  ? '' : payloadIN),
            PayloadOUT__c    = (shouldUseAttachmentOUT ? '' : payloadOUT),
            ExecutionDate__c =  tNow,
            Status__c         = (hasAnyErrors ? 'ERRO' : 'OK')
        );

        try{
            insert log;

            // Maximum Size for a String
            if (shouldUseAttachmentIN){
            	createAttachment(log.Id, integrationName, 'IN', log.Name, String.valueOf(tNow), payloadIN);
            }

            if (shouldUseAttachmentOUT){
            	createAttachment(log.Id, integrationName, 'OUT', log.Name, String.valueOf(tNow), payloadOUT);
            }

            System.debug('NEW LOG CREATED: '+log.Id);
        }catch(Exception e){
            System.debug('EXCEPTION ON LOG - Please review parameters - '+e.getMessage()+' - '+e.getStackTraceString());
        }

        return log.Id;
    }

    @TestVisible
    private static void createAttachment(String recordId, String integrationName, String inOrOut, String logName, String timeAsString, String payload){
    	Attachment att = new Attachment();
    	att.Name = 'LOG-'+integrationName+'-'+inOrOut+'-'+timeAsString+'.txt';
    	att.Body = Blob.valueOf(payload);
    	att.ParentId = recordId;
    	insert att;
    }
}
