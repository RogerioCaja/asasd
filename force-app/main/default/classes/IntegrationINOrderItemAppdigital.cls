global with sharing class IntegrationINOrderItemAppdigital {
    public IntegrationINOrderItemAppdigital() {

    }
    // Integração do OrderItem Upsert
    //@HttpPost 
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertOrderItem(List<TemplateDataIntegrationFields.OrderItemINData> request) {
        // Guarda as relações de order e product de preço com OrderItem
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> orderLookups = new Set<String>();
        Set<String> productLookups = new Set<String>();
        // Guarda um mapa com uma lista de respostas
        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // Guarda uma lista com os OrderItem para fazer o upsert
        List<OrderItem> orderItemListToUpsert = new List<OrderItem>();

        //Application of business rules
        for(TemplateDataIntegrationFields.OrderItemINData OrderItemINData : request){

            // Pega a relação do OrderItem com Order
            //Getting order parameters to search
            orderLookups.add(OrderItemINData.orderExternalId);

            // Pega a relação do Product com o OrderItem
            //Getting product parameters to search
            productLookups.add(OrderItemINData.material);
        }
        // Pega o produto com base no ExternalID recebido
        //Product2 search based on ExternalId__c field sent
        for (Product2 product : [SELECT Id,ProductCode FROM Product2 WHERE ProductCode IN: productLookups ]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Product2' + product.ProductCode, product.Id);
        }
        // Pega o pedido com base no ExternalId recebido
        //Order search based on ExternalId__c field sent
        for (Order order : [SELECT Id, NumeroPedidoApp__c FROM Order WHERE NumeroPedidoApp__c IN : orderLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Order' + order.NumeroPedidoApp__c, order.Id);
        }
       
        for (PricebookEntry pricebookEntry : [SELECT Id, Product2Id, ProductCode, Pricebook2.isStandard FROM PricebookEntry ]){
            lookups.put('Product2' + pricebookEntry.ProductCode, pricebookEntry.Product2Id);
            lookups.put('PricebookEntry' + pricebookEntry.ProductCode, pricebookEntry.Id); //Arrumar, puxar o productCode
        }
        
        // Associa as respostas do OrderItem com Order
        //OrderItem ExternalId Map to Order ExternalId for association of responses
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.OrderItemINData orderItem : request) {
            // como estava = parentMapKeys.put(ORDEREXTERNALID + '|' + ORDERITEMEXTERNALID, lookups.containsKey('Order'+ORDEREXTERNALID) ? lookups.get('Order'+ORDEREXTERNALID) : ORDEREXTERNALID);
            parentMapKeys.put(orderItem.orderExternalId + '|' + orderItem.orderItemCode, lookups.containsKey('Order'+orderItem.orderExternalId) ? String.valueOf(lookups.get('Order'+orderItem.orderExternalId)) : orderItem.orderExternalId);
        }
        // Valida e adiciona os OrderItem na lista para o upsert
        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObjectChild(
            new OrderItem(), 
            'IN', 
            request, 
            responseMap, 
            orderItemListToUpsert, 
            lookups, 
            parentMapKeys
        );

        //Upserting records
        List<Database.UpsertResult> upsResults = Database.upsert(orderItemListToUpsert, OrderItem.ExternalId__c, false);

        IntegrationUtils.upsertChildRecords(upsResults, responseMap, orderItemListToUpsert, OrderItem.ExternalId__c); 
        System.debug('upsResults' + upsResults);
        System.debug('orderItemListToUpsert' + orderItemListToUpsert);
        System.debug(' OrderItem.ExternalId__c' +  OrderItem.ExternalId__c);
        //Returning response
        return responseMap;
    }
}
