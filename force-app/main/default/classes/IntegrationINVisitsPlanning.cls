@RestResource(urlMapping='/upsertVisitsPlanning/*')
global without sharing class IntegrationINVisitsPlanning {

    @HttpPost
    global static ResponseModel upsertVisitsPlanning(List<TemplateDataIntegrationFields.VisitPlanningINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();
        Set<String> accountLookups = new Set<String>();
        Set<String> cropLookups = new Set<String>();
        Set<String> cultureLookups = new Set<String>();
        Set<String> userLookups = new Set<String>();
        Set<String> visitLookups = new Set<String>();
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        List<TemplateDataIntegrationFields.TechnicalReportINData> technicalReportList = new List<TemplateDataIntegrationFields.TechnicalReportINData>();
        List<TemplateDataIntegrationFields.FotosINData> photosList = new List<TemplateDataIntegrationFields.FotosINData>();
        List<VisitPlanning__c> visitsListToUpsert = new List<VisitPlanning__c>();
        
  
        for (TemplateDataIntegrationFields.VisitPlanningINData visit : request){
            accountLookups.add(visit.BpCode);
            accountLookups.add(visit.BpPropertyCode);
            cropLookups.add(visit.Crop);
            cultureLookups.add(visit.Culture);
            userLookups.add(visit.CtvVisit);
            visitLookups.add(visit.ExternalId);
            visit.ExternalId = visit.BpCode + visit.BpPropertyCode + visit.PlanStartDate + visit.PlanEndDate + visit.CtvVisit;
            for (TemplateDataIntegrationFields.TechnicalReportINData report : visit.TechnicalReports){
                report.ExternalIdVisit = visit.ExternalId;
                report.ExternalId = visit.ExternalId;
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
        System.debug('visitListToUpsert First' + visitsListToUpsert);  
        CalendarHelper.disableTriggerForIntegration();
		IntegrationUtils.upsertRecords(
            Database.upsert(visitsListToUpsert, VisitPlanning__c.ExternalId__c, false), 
            responseList, 
            visitsListToUpsert, 
            VisitPlanning__c.ExternalId__c
        );
        CalendarHelper.enableTriggerForIntegration();
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
