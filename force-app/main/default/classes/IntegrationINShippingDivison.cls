global with sharing class IntegrationINShippingDivison {
    public IntegrationINShippingDivison() {

    }
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertShippingDivison(List<TemplateDataIntegrationFields.ShippingDivisonINData> request) {
        // Guarda as relações de order e product de preço com OrderItem
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> orderLookups = new Set<String>();
        Set<String> orderItemLookups = new Set<String>();
        List<TemplateDataIntegrationFields.ShippingDivisonINData> newRequest = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
        // Guarda um mapa com uma lista de respostas
        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // Guarda uma lista com os OrderItem para fazer o upsert
        List<ShippingDivison__c> ShippingDivisonListToUpsert = new List<ShippingDivison__c>();

        //Application of business rules
        for(TemplateDataIntegrationFields.ShippingDivisonINData ShippingDivisonData : request){

            // Pega a relação do OrderItem com Order
            //Getting order parameters to search
            orderLookups.add(ShippingDivisonData.orderExternalId);
            orderItemLookups.add(ShippingDivisonData.orderExternalId+'|'+ ShippingDivisonData.OrderItemCode);

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

        for (OrderItem OrderItem : [SELECT Id, ExternalId__c, Product2.ProductCode FROM OrderItem WHERE ExternalId__c IN : orderItemLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('OrderItem__c' + orderItem.ExternalId__c, orderItem.Id);
        }

        System.debug('lookups=>'+lookups);
        
        
        // Associa as respostas do OrderItem com Order
        //OrderItem ExternalId Map to Order ExternalId for association of responses
        Map<String, Decimal> sumQuantity = new  Map <String, Decimal>();
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.ShippingDivisonINData shippingDivison : request) {
            // como estava = parentMapKeys.put(ORDEREXTERNALID + '|' + ORDERITEMEXTERNALID, lookups.containsKey('Order'+ORDEREXTERNALID) ? lookups.get('Order'+ORDEREXTERNALID) : ORDEREXTERNALID);
           parentMapKeys.put(shippingDivison.orderExternalId + '|' + shippingDivison.OrderItemCode, lookups.containsKey('Order'+shippingDivison.orderExternalId) ? String.valueOf(lookups.get('Order'+shippingDivison.orderExternalId)) : shippingDivison.orderExternalId);
           string External = shippingDivison.orderExternalId + '|' + shippingDivison.OrderItemCode + '|' + shippingDivison.DivisaoRemessa;
           if(sumQuantity.containsKey(External)){
               Decimal value = sumQuantity.get(External);
               System.debug('sumQuantity' + sumQuantity);
               System.debug('value' + value);
               System.debug('Quantidade' + shippingDivison.Quantidade);
               sumQuantity.put(External, shippingDivison.Quantidade + value);
           } else {
               sumQuantity.put(External, shippingDivison.Quantidade);
            }
            System.debug('sumQuantity' + sumQuantity);
            System.debug('Quantidade' + shippingDivison.Quantidade);
        }
        Map<String, Decimal> requestFix = new Map<String, Decimal>();
        for(TemplateDataIntegrationFields.ShippingDivisonINData shippingDivison : request) {
            string External = shippingDivison.orderExternalId + '|' + shippingDivison.OrderItemCode + '|' + shippingDivison.DivisaoRemessa;
            Decimal value = sumQuantity.get(External);
            shippingDivison.Quantidade = value;
            if(requestFix.containsKey(External)){
                System.debug('já contém/passou! ');
            } else {
                requestFix.put(External, shippingDivison.Quantidade);
                System.debug('shippingDivison' +  shippingDivison);
                newRequest.add(shippingDivison);
            }
        }

        // Valida e adiciona os OrderItem na lista para o upsert
        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObjectChild(
            new ShippingDivison__c(), 
            'IN', 
            newRequest, 
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
