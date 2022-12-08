public without sharing class PhotosToReportController {
    public PhotosToReportController() {}

    @AuraEnabled
    public static String createPhoto(String base64, String filename, String rtrId, String observation){
        String externalIdRtr = [SELECT ExternalId__c FROM TechnicalReport__c WHERE Id =: rtrId LIMIT 1].ExternalId__c;
        Integer numberPhotos = [SELECT COUNT() FROM Fotos__c WHERE RTR__c =: rtrId];
        Fotos__c photo = new Fotos__c(
            ExternalId__c = externalIdRtr + '_' + (++numberPhotos),
            Observation__c = observation,
            RTR__c = rtrId
        );

        INSERT photo;

        String response = uploadFile(base64, filename, photo.Id);
        return response;
        
    }

    private static String uploadFile(String base64, String filename, String recordId) {
        ContentVersion cv = createContentVersion(base64, filename);
        ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
        if (cv == null || cdl == null) { return null; }
        return cdl.Id;
    }

    private static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        try {
            insert cv;
            return cv;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }

    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id =: contentVersionId
        ].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        
        try {
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }
}

