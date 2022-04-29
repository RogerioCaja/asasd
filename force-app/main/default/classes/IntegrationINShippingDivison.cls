global with sharing class IntegrationINShippingDivison {
    public IntegrationINShippingDivison() {

    }
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertShippingDivison(List<TemplateDataIntegrationFields.ShippingDivisonData> request) {
        // Guarda as relações de order e product de preço com OrderItem
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> orderLookups = new Set<String>();
        // Guarda um mapa com uma lista de respostas
        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // Guarda uma lista com os OrderItem para fazer o upsert
        List<ShippingDivison__c> ShippingDivisonListToUpsert = new List<ShippingDivison__c>();

        //Application of business rules
        for(TemplateDataIntegrationFields.ShippingDivisonData ShippingDivisonData : request){

            // Pega a relação do OrderItem com Order
            //Getting order parameters to search
            orderLookups.add(ShippingDivisonData.NumeroDivisaoRemessa);

            // Pega a relação do Product com o OrderItem
            //Getting product parameters to search
        }
        // Pega o produto com base no ExternalID recebido
        //Product2 search based on ExternalId__c field sent
        // Pega o pedido com base no ExternalId recebido
        //Order search based on ExternalId__c field sent
        for (Order order : [SELECT Id, CodigoSap__c FROM Order WHERE CodigoSap__c IN : orderLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Order' + order.CodigoSap__c, order.Id);
        }
       
        
        // Associa as respostas do OrderItem com Order
        //OrderItem ExternalId Map to Order ExternalId for association of responses
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.ShippingDivisonData shippingDivison : request) {
            // como estava = parentMapKeys.put(ORDEREXTERNALID + '|' + ORDERITEMEXTERNALID, lookups.containsKey('Order'+ORDEREXTERNALID) ? lookups.get('Order'+ORDEREXTERNALID) : ORDEREXTERNALID);
           parentMapKeys.put(shippingDivison.orderExternalId + '|' + shippingDivison.NumeroDivisaoRemessa, lookups.containsKey('Order'+shippingDivison.NumeroDivisaoRemessa) ? String.valueOf(lookups.get('Order'+shippingDivison.orderExternalId)) : shippingDivison.orderExternalId);
        }
        // Valida e adiciona os OrderItem na lista para o upsert
        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObjectChild(
            new OrderItem(), 
            'IN', 
            request, 
            responseMap, 
            ShippingDivisonListToUpsert, 
            lookups, 
            parentMapKeys
        );

        //Upserting records
        List<Database.UpsertResult> upsResults = Database.upsert(ShippingDivisonListToUpsert, ShippingDivison__c.ExternalId__c, false);

        IntegrationUtils.upsertChildRecords(upsResults, responseMap, ShippingDivisonListToUpsert, ShippingDivison__c.ExternalId__c); 
        
        //Returning response
        return responseMap;
    }
}
