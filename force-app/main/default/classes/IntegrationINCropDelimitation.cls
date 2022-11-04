@RestResource(urlMapping='/upsertCropDelimitation/*')
global without sharing class IntegrationINCropDelimitation {

    @HttpPost
    global static ResponseModel upsertCropDelimitation(List<TemplateDataIntegrationFields.DelimitadoresINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();
        Map<String, String> lookupsName = new Map<String, String>();
        Set<String> safraLookups = new Set<String>();
        Set<String> salesOrgLookups = new Set<String>();
        Set<String> salesConditionLookups = new Set<String>();
        

    
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        List<Delimitadores__c> delimitadoresListToUpsert = new List<Delimitadores__c>();
        
  
        for (TemplateDataIntegrationFields.DelimitadoresINData delimitator : request){
            Date baseDate = delimitador.BaseDateFinancing;
            delimitator.AfterPayment = baseDate.addDays(Decimal.valueOf(delimitador.AfterPaymentDate));
            safraLookups.add(delimitator.Safra);
            salesOrgLookups.add(delimitator.SalesOrganization);
            salesConditionLookups.add(delimitator.PriceList);
        }
        

        for (Safra__c safra : [SELECT Id, Name, Code__c FROM Safra__c WHERE Code__c IN : safraLookups]) {
            lookups.put('Safra__c' + safra.Code__c, safra.Id);
            lookupsName.put('SafraName' + safra.Code__c, safra.Name);
        }
        for (SalesOrg__c salesOrg : [SELECT Id, Name, SalesOrganizationCode__c FROM SalesOrg__c WHERE SalesOrganizationCode__c IN : salesOrgLookups]) {
            lookups.put('SalesOrg__c' + salesOrg.SalesOrganizationCode__c, salesOrg.Id);
            lookupsName.put('SalesOrgName' + salesOrg.SalesOrganizationCode__c, salesOrg.Name);
        }
        for (SalesCondition__c salesCondition : [SELECT Id, Name, ExternalId__c FROM SalesCondition__c WHERE  ExternalId__c IN : salesConditionLookups]){
            lookups.put('SalesCondition__c' + salesCondition.ExternalId__c, salesCondition.Id);
            lookupsName.put('SalesConditionName' + salesCondition.ExternalId__c, salesCondition.Name);
        }
       
        for (TemplateDataIntegrationFields.DelimitadoresINData delimitator : request){
            String safraName = lookupsName.containsKey('SafraName'+delimitator.Safra) ? lookupsName.get('SafraName'+delimitator.Safra) : '';
            String SalesOrgName = lookupsName.containsKey('SalesOrgName'+delimitator.SalesOrganization) ? lookupsName.get('SalesOrgName'+delimitator.SalesOrganization) : '';
            String SalesConditionName = lookupsName.containsKey('SalesConditionName'+delimitator.PriceList) ? lookupsName.get('SalesConditionName'+delimitator.PriceList) : '';
            delimitator.Name = safraName + ' ' + SalesConditionName + ' ' +  SalesOrgName;
            delimitator.DelimitadoresExternalId = delimitator.Safra + delimitator.PriceList + delimitator.SalesOrganization;
        }
        
        FactoryDataIntegration.convertSObject(new Delimitadores__c(), 'IN', request, responseList, delimitadoresListToUpsert, lookups);
        System.debug('delimitadoresListToUpsert First' + delimitadoresListToUpsert);  

		IntegrationUtils.upsertRecords(
            Database.upsert(delimitadoresListToUpsert, Delimitadores__c.ExternalId__c, false), 
            responseList, 
            delimitadoresListToUpsert, 
            Delimitadores__c.ExternalId__c
        );
        System.debug('delimitadoresListToUpsert' + delimitadoresListToUpsert);

        //Checking integration errors to log
        // Verifica erros de integração para o log
        Boolean hasError = false;

        for(TemplateDataIntegrationFields.ResponseParent responseInvoice : responseList){
            if(responseInvoice.status == false){
                hasError = true;
                break;
            }
        }
		
        //Creating integration log
        IntegrationLog.createLog('Safra Delimitadores - DataLake', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
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
