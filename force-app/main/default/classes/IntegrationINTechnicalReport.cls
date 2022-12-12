global with sharing class IntegrationINTechnicalReport {

    
    global static Map<String, List<TemplateDataINtegrationFields.Response>> upsertTechnicalReport (List<TemplateDataINtegrationFields.TechnicalReportINData> request){

        Map<String, Id> lookups = new Map<String, Id>();
        Set<String> visitsLookup = new Set<String>();
        for(TemplateDataIntegrationFields.TechnicalReportINData report : request){

            visitsLookup.add(report.ExternalIdVisit);
        }
        for (VisitPlanning__c visit : [SELECT Id, ExternalId__c FROM VisitPlanning__c WHERE ExternalId__c IN: visitsLookup ]) {
            lookups.put('Visit' + visit.ExternalId__c, visit.Id);
        }

        Map<String, List<TemplateDataINtegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();

        List<TechnicalReport__c> technicalReportListToUpsert = new List<TechnicalReport__c>();
	
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.TechnicalReportINData report : request){
            parentMapKeys.put(report.ExternalIdVisit, lookups.containsKey('Visit'+report.ExternalIdVisit) ? String.valueOf(lookups.get('Visit'+report.ExternalIdVisit)) : report.ExternalIdVisit);
        }


        FactoryDataIntegration.convertSObjectChild(
            new TechnicalReport__c(),
            'IN',
            request,
            responseMap,
            technicalReportListToUpsert,
            lookups,
            parentMapKeys
        );
        TechnicalReportHelper.disableTrigger();
        List<Database.UpsertResult> upsResults = Database.upsert(technicalReportListToUpsert, TechnicalReport__c.ExternalId__c, false);
        System.debug('upsResults' + upsResults);
        IntegrationUtils.upsertChildRecords(upsResults, responseMap, technicalReportListToUpsert, TechnicalReport__c.ExternalId__c);
        TechnicalReportHelper.enableTrigger();
        return responseMap;
    }
}