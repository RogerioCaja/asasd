global with sharing class IntegrationINPhotos {

    
    global static Map<String, List<TemplateDataINtegrationFields.Response>> upsertPhotos (List<TemplateDataINtegrationFields.FotosINData> request){

        Map<String, Id> lookups = new Map<String, Id>();
        Set<String> technicalLookup = new Set<String>();
        for(TemplateDataIntegrationFields.FotosINData photos : request){

            technicalLookup.add(photos.Rtr);
        }
        for (TechnicalReport__c visit : [SELECT Id, ExternalId__c FROM TechnicalReport__c WHERE ExternalId__c IN: technicalLookup ]) {
            lookups.put('Technical' + visit.ExternalId__c, visit.Id);
        }

        Map<String, List<TemplateDataINtegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();

        List<Fotos__c> photosListToUpsert = new List<Fotos__c>();
    
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.FotosINData report : request){
            parentMapKeys.put(report.Rtr, lookups.containsKey('Visit'+report.Rtr) ? String.valueOf(lookups.get('Visit'+report.Rtr)) : report.Rtr);
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

        List<Database.UpsertResult> upsResults = Database.upsert(photosListToUpsert, Fotos__c.ExternalId__c, false);
        System.debug('upsResults' + upsResults);
        IntegrationUtils.upsertChildRecords(upsResults, responseMap, photosListToUpsert, Fotos__c.ExternalId__c);

        return responseMap;
    }
}
