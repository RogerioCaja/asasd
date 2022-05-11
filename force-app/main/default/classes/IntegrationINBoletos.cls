global with sharing class IntegrationINBoletos {
    public IntegrationINBoletos() {

    }
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertBoletos(List<TemplateDataIntegrationFields.BoletosINData> request) {
        // Guarda as relações de order e product de preço com OrderItem
        Map<String, Id> lookups = new Map<String, Id>();
        Set<String> salesOrgLookups = new Set<String>();
        Set<String> accountCodeLookups = new Set<String>();
        // Guarda um mapa com uma lista de respostas
        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // Guarda uma lista com os OrderItem para fazer o upsert
        List<Boletos__c> boletosListToUpsert = new List<Boletos__c>();

        //Application of business rules
        for(TemplateDataIntegrationFields.BoletosINData BoletosINData : request){

            // Pega a relação do OrderItem com Order
            //Getting order parameters to search
            salesOrgLookups.add(BoletosINData.Empresa);
            accountCodeLookups.add(BoletosINData.CodigoParceiro);

            // Pega a relação do Product com o OrderItem
            //Getting product parameters to search
        }
        // Pega o produto com base no ExternalID recebido
        //Product2 search based on ExternalId__c field sent
        // Pega o pedido com base no ExternalId recebido
        //Order search based on ExternalId__c field sent
        for (SalesOrg__c salesOrg : [SELECT Id, Name, SalesOrganizationCode__c from SalesOrg__c WHERE SalesOrganizationCode__c IN: salesOrgLookups]){
            lookups.put('SalesOrg__c' + salesOrg.SalesOrganizationCode__c, salesOrg.Id);
        }
        for (Account account : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : accountCodeLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('AccountCode__c' + account.ExternalId__c, account.Id);
        }
       
        FactoryDataIntegration.convertSObject(
            new Boletos__c(), 
            'IN', 
            request, 
            responseMap, 
            boletosListToUpsert, 
            lookups
        );

        //Upserting records
        List<Database.UpsertResult> upsResults = Database.upsert(boletosListToUpsert, Boletos__c, false);

        IntegrationUtils.upsertRecords(upsResults, responseMap, boletosListToUpsert, Boletos__c.); 
        
        //Returning response
        return responseMap;
    }
}