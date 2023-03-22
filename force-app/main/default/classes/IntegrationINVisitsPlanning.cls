@RestResource(urlMapping='/upsertVisitsPlanning/*')
global without sharing class IntegrationINVisitsPlanning {

    @HttpPost
    global static ResponseModel upsertVisitsPlanning(List<TemplateDataIntegrationFields.VisitPlanningINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();
        Map<String, String> visitPlattingMap = new Map<String, String>();
        Set<String> accountLookups = new Set<String>();
        Set<String> cropLookups = new Set<String>();
        Set<String> cultureLookups = new Set<String>();
        Set<String> userLookups = new Set<String>();
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        List<TemplateDataIntegrationFields.TechnicalReportINData> technicalReportList = new List<TemplateDataIntegrationFields.TechnicalReportINData>();
        List<TemplateDataIntegrationFields.VisitPlanningINData> visitPlanningUpdatesList = new List<TemplateDataIntegrationFields.VisitPlanningINData>();
        List<TemplateDataIntegrationFields.VisitPlanningINData> visitPlanningInsertList = new List<TemplateDataIntegrationFields.VisitPlanningINData>();
        List<TemplateDataIntegrationFields.FotosINData> photosList = new List<TemplateDataIntegrationFields.FotosINData>();
        List<VisitPlanning__c> visitsListToUpsert = new List<VisitPlanning__c>();
        for (TemplateDataIntegrationFields.VisitPlanningINData visit : request){
            if(visit.ExternalId != null){
                visitPlanningUpdatesList.add(visit);
            }else{
                visitPlanningInsertList.add(visit);
            }
        }
        //caso receba deles e tenha o externalId preenchido vai ter que fazer outro insert
        for (TemplateDataIntegrationFields.VisitPlanningINData visit : request){
            accountLookups.add(visit.BpCode);
            accountLookups.add(visit.BpPropertyCode);
            cropLookups.add(visit.Crop);
            cultureLookups.add(visit.Culture);
            userLookups.add(visit.CtvVisit);
            String keyForExternal = visit.ExternalIdApp;
            //tera que arrumar usando map
            for (TemplateDataIntegrationFields.TechnicalReportINData report : visit.TechnicalReports){
                report.ExternalIdVisit = keyForExternal;
                report.ExternalId = keyForExternal;
            }
            technicalReportList.addALL(visit.TechnicalReports);
        }

        for (Account accoun : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : accountLookups]) {
            lookups.put('Account' + accoun.ExternalId__c, accoun.Id);
        }
        for (Safra__c safra : [SELECT Id, Code__c FROM Safra__c WHERE Code__c IN : cropLookups]) {
            lookups.put('Safra' + safra.Code__c, safra.Id);
        }
        for (Cultura__c culture : [SELECT Id, Codigo__c FROM Cultura__c WHERE Codigo__c IN : cultureLookups]) {
            lookups.put('Culture' + culture.Codigo__c, culture.Id);
        }
        for (User user : [SELECT Id, CodigoSap__c FROM User WHERE CodigoSap__c IN : userLookups]) {
            lookups.put('User' + user.CodigoSap__c, user.Id);
        }

        
        
       
        FactoryDataIntegration.convertSObject(new VisitPlanning__c(), 'IN', request, responseList, visitsListToUpsert, lookups);
        System.debug('visitListToUpsert ' + visitsListToUpsert);
        System.debug('visitPlanningUpdatesList ' + visitPlanningUpdatesList);  
        System.debug('visitPlanningInsertList ' + visitPlanningInsertList);
        if(!visitPlanningInsertList.isEmpty()){
            CalendarHelper.disableTriggerForIntegration();
            IntegrationUtils.upsertRecords(
                Database.upsert(visitsListToUpsert, VisitPlanning__c.ExternalIdApp__c, false), 
                responseList, 
                visitsListToUpsert, 
                VisitPlanning__c.ExternalIdApp__c
            );
            CalendarHelper.enableTriggerForIntegration();
        }
        if(!visitPlanningUpdatesList.isEmpty()){
            CalendarHelper.disableTriggerForIntegration();
            IntegrationUtils.upsertRecords(
                Database.upsert(visitsListToUpsert, VisitPlanning__c.ExternalId__c, false), 
                responseList, 
                visitsListToUpsert, 
                VisitPlanning__c.ExternalId__c
            );
            CalendarHelper.enableTriggerForIntegration();
        }
        List<String> visitListId = new List<String>();
        for(VisitPlanning__c visit : visitsListToUpsert){
            visitListId.add(visit.Id);
        }
        List<VisitPlanning__c> visitListExternalId = new List<VisitPlanning__c>([SELECT Id, ExternalId__c, ExternalIdApp__c FROM VisitPlanning__c WHERE Id IN : visitListId]);
        for(VisitPlanning__c visit : visitListExternalId){
            visitPlattingMap.put(visit.ExternalIdApp__c, visit.ExternalId__c);
        }
        if(technicalReportList.size() != 0){
            for(TemplateDataIntegrationFields.TechnicalReportINData technical : technicalReportList){
                String externalVisit = visitPlattingMap.get(technical.ExternalIdVisit);
                technical.ExternalIdVisit = externalVisit;
                technical.ExternalId = externalVisit;
            }
        }

        Map<String, List<TemplateDataIntegrationFields.Response>> visitsTechnicalResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        Map<String, List<TemplateDataIntegrationFields.Response>> photosResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(technicalReportList.size() != 0){
            for(TemplateDataIntegrationFields.TechnicalReportINData technical : technicalReportList){
                for(TemplateDataIntegrationFields.FotosINData photos : technical.Photos){
                    photos.Rtr = technical.ExternalId + technical.RtrLine; 
                    photos.ExternalId = photos.Rtr + photos.FileLine;
                }
                photosList.addALL(technical.Photos);
            }
            visitsTechnicalResponse.putAll(
                IntegrationINTechnicalReport.upsertTechnicalReport(technicalReportList)
            );
        }
        if(photosList.size() != 0){
            photosResponse.putAll(
                IntegrationINPhotos.upsertPhotos(photosList)
            );
        }
        //Associating child object's response with object response
        // Pega todas as respostas dos OrderItem
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            response.items = new List<TemplateDataIntegrationFields.Response>();

            
            System.debug('visitsTechnicalResponse=>'+visitsTechnicalResponse);
            System.debug('photosResponse=>'+photosResponse);
            
            if(visitsTechnicalResponse.size() != 0 && visitsTechnicalResponse.containsKey(response.idSalesforce)){
                response.items.addAll(visitsTechnicalResponse.get(response.idSalesforce));
                
            }
            if(photosResponse.size() != 0 && photosResponse.containsKey(response.idSalesforce)){
                response.items.addAll(photosResponse.get(response.idSalesforce));
                
            }
        }
        //Checking integration errors to log
        // Verifica erros de integração para o log
        Boolean hasError = false;

        for(TemplateDataIntegrationFields.ResponseParent responseOrder : responseList){
            if(responseOrder.status == false){
                hasError = true;
                break;
            } else {
                for(TemplateDataIntegrationFields.Response response : responseOrder.items){
                    if(response.status == false){
                        hasError = true;
                        break;
                    }
                }
            }
        }
		
        //Creating integration log
        IntegrationLog.createLog('Visit Planning - App', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
        //Returning response
         // Retorna a resposta Outbound
        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }
    // Classe que cria a resposta
    global class ResponseModel {

        List<TemplateDataIntegrationFields.ResponseParent> response;

        public ResponseModel(List<TemplateDataIntegrationFields.ResponseParent> response) {

            this.response = response;
            
        }
        public ResponseModel() {   
            this.response = new List<TemplateDataIntegrationFields.ResponseParent>();         
        }
    }
}