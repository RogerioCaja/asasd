global with sharing class IntegrationINOrgVProduct {

    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertOrgVProduct(List<TemplateDataIntegrationFields.OrgVProductINData> request) {
        // Guarda as relações de order e product de preço com OrderItem
        Map<String, Id> lookups = new Map<String, Id>();

        //Set<String> orderLookups = new Set<String>();
        Set<String> productLookups = new Set<String>();
        Set<String> orgLookups = new Set<String>();
        // Guarda um mapa com uma lista de respostas
        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // Guarda uma lista com os OrderItem para fazer o upsert
        List<OrgVProduct__c> orgVProductListToUpsert = new List<OrgVProduct__c>();

        //Application of business rules
        for(TemplateDataIntegrationFields.OrgVProductINData orgVProduct : request){

            // Pega a relação do OrderItem com Order
            //Getting order parameters to search
            //orderLookups.add(OrderItemINData.orderExternalId);

            // Pega a relação do Product com o OrderItem
            //Getting product parameters to search
            productLookups.add(orgVProduct.OrgProduct);
            orgLookups.add(orgVProduct.OrganizacaoVendas);
        }

        // Pega o produto com base no ExternalID recebido
        //Product2 search based on ExternalId__c field sent
        for (Product2 product : [SELECT Id,ProductCode FROM Product2 WHERE ProductCode IN: productLookups ]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Product2' + product.ProductCode, product.Id);
        }
        for (SalesOrg__c salesOrg : [SELECT Id, SalesOrganizationCode__c FROM SalesOrg__c WHERE SalesOrganizationCode__c IN: orgLookups]){
          lookups.put('SalesOrg__c' + salesOrg.SalesOrganizationCode__c, salesOrg.Id);
        }
         System.debug('lookups' +  lookups);
        // Pega o pedido com base no ExternalId recebido
        //Order search based on ExternalId__c field sent

        // Associa as respostas do OrderItem com Order
        //OrderItem ExternalId Map to Order ExternalId for association of responses
        Map<String, String> parentMapKeys = new Map<String, String>();
        
        for(TemplateDataIntegrationFields.OrgVProductINData orgV : request) {
            // como estava = parentMapKeys.put(ORDEREXTERNALID + '|' + ORDERITEMEXTERNALID, lookups.containsKey('Order'+ORDEREXTERNALID) ? lookups.get('Order'+ORDEREXTERNALID) : ORDEREXTERNALID);
            parentMapKeys.put(orgV.productExternalId + '|' + (orgV.OrganizacaoVendas + '|' + orgV.OrgProduct + '|' + orgV.centroFilial), lookups.containsKey('Product2'+orgV.OrgProduct) ? String.valueOf(lookups.get('Product2'+orgV.OrgProduct)) : orgV.OrgProduct);
            System.debug('Parent Map ' + parentMapKeys);
        }
        
        // Valida e adiciona os OrderItem na lista para o upsert
        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObjectChild(
            new OrgVProduct__c(), 
            'IN', 
            request, 
            responseMap, 
            orgVProductListToUpsert, 
            lookups, 
            parentMapKeys
        );

        //Upserting records
        List<Database.UpsertResult> upsResults = Database.upsert(orgVProductListToUpsert, OrgVProduct__c.OrgVExternal__c, false);

        IntegrationUtils.upsertChildRecords(upsResults, responseMap, orgVProductListToUpsert, OrgVProduct__c.OrgVExternal__c); 
        //Returning response
        return responseMap;
    }
}
