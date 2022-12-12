global with sharing class IntegrationINPhotos {

    
    global static Map<String, List<TemplateDataINtegrationFields.Response>> upsertPhotos (List<TemplateDataINtegrationFields.FotosINData> request){

        Map<String, Id> lookups = new Map<String, Id>();
        Set<String> technicalLookup = new Set<String>();
        Map<String,TemplateDataINtegrationFields.FotosINData> fotosMap = new Map<String,TemplateDataINtegrationFields.FotosINData>(); 

        for(TemplateDataIntegrationFields.FotosINData photos : request){
            fotosMap.put(photos.ExternalId, photos);
            technicalLookup.add(photos.Rtr);
        }
        for (TechnicalReport__c visit : [SELECT Id, ExternalId__c FROM TechnicalReport__c WHERE ExternalId__c IN: technicalLookup ]) {
            lookups.put('Technical' + visit.ExternalId__c, visit.Id);
        }

        Map<String, List<TemplateDataINtegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();

        List<Fotos__c> photosListToUpsert = new List<Fotos__c>();
    
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.FotosINData report : request){
            parentMapKeys.put(report.Rtr, lookups.containsKey('Technical'+report.Rtr) ? String.valueOf(lookups.get('Technical'+report.Rtr)) : report.Rtr);
        }


        FactoryDataIntegration.convertSObjectChild(
            new Fotos__c(),
            'IN',
            request,
            responseMap,
            photosListToUpsert,
            lookups,
            parentMapKeys
        );
     	FotosHelper.disableTrigger();
        List<Database.UpsertResult> upsResults = Database.upsert(photosListToUpsert, Fotos__c.ExternalId__c, false);

        System.debug('upsResults' + upsResults);
        IntegrationUtils.upsertChildRecords(upsResults, responseMap, photosListToUpsert, Fotos__c.ExternalId__c);
        FotosHelper.enableTrigger();
        Map<String, ContentVersion> contentVersionMap = new Map<String, ContentVersion>();
        Map<String, ContentVersion> contentVersionUpdatedMap = new Map<String, ContentVersion>();
        List<String> contentVersionList = new List<String>();
        List<String> photoIdList = new List<String>();
        for(Fotos__c photo : photosListToUpsert){
            photoIdList.add(photo.Id);
            TemplateDataINtegrationFields.FotosINData requestFotos = fotosMap.get(photo.ExternalId__c);
            if(requestFotos.Photo != null && requestFotos.Photo != ''){
                ContentVersion cv = new ContentVersion();
                cv.VersionData = EncodingUtil.base64Decode(requestFotos.Photo);
                cv.Title = 'Foto.png';
                cv.PathOnClient = 'Foto.png';
                contentVersionMap.put(photo.ExternalId__c,cv);
            }
        }
        List<String> contendToRemoveListId = new List<String>();
        List<ContentDocumentLink> contendLinkToRemoveList = new List<ContentDocumentLink>([SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted, SystemModstamp, ShareType, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN: photoIdList]);
        if (!contendLinkToRemoveList.isEmpty()) {
            Database.delete(contendLinkToRemoveList, false);
        }
        try {
            insert contentVersionMap.values();
        } catch(DMLException e) {
            System.debug('Error: ' +e);
        }
        for(ContentVersion content :contentVersionMap.values()){
            contentVersionList.add(content.Id);
        }
        for (ContentVersion content : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN: contentVersionList ]) {
            contentVersionUpdatedMap.put(content.Id,content);
        }
        List<ContentDocumentLink> contentDocumentLinkToInsert = new List<ContentDocumentLink>();
        for(Fotos__c photo : photosListToUpsert){
            TemplateDataINtegrationFields.FotosINData requestFotos = fotosMap.get(photo.ExternalId__c);
            if(requestFotos.Photo != null && requestFotos.Photo != ''){
                ContentVersion content = contentVersionMap.get(photo.ExternalId__c);
                ContentVersion contentDocument = contentVersionUpdatedMap.get(content.Id);
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocument.ContentDocumentId;
                cdl.LinkedEntityId = photo.Id;
                cdl.ShareType = 'V';
                contentDocumentLinkToInsert.add(cdl);
            }
        }
        if (!contentDocumentLinkToInsert.isEmpty()) {
            insert contentDocumentLinkToInsert;
        }
        return responseMap;
    }
}