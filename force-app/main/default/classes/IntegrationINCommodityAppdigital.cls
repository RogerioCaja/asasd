global with sharing class IntegrationINCommodityAppdigital {
    public IntegrationINCommodityAppdigital() {

    }

    global static Map<String, List<TemplateDataINtegrationFields.Response>> upsertCommodity (List<TemplateDataINtegrationFields.OrderCommodityINData> request){

        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> orderLookups = new Set<String>();

        Set<String> productLookups = new Set<String>();

        Map<String, List<TemplateDataINtegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();

        List<OrderCommodity__c> orderCommodityListToUpsert = new List<OrderCommodity__c>();

        for(TemplateDataIntegrationFields.OrderCommodityINData OrderCommodityINData : request){

            productLookups.add(OrderCommodityINData.material);
        }

        for (Product2 product : [SELECT Id,ProductCode FROM Product2 WHERE ProductCode IN: productLookups ]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Product2' + product.ProductCode, product.Id);
        }

        for(Order order : [SELECT Id FROM Order WHERE Id IN : orderLookups]){
            //looups.put('Order' + order.orderExternalId, order.Id);
        }

        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.OrderCommodityINData orderCommodity : request){
            parentMapKeys.put(orderCommodity.orderExternalId + '|' + orderCommodity.material, lookups.containsKey('Order'+orderCommodity.orderExternalId) ? String.valueOf(lookups.get('Order' + orderCommodity.orderExternalId)) : orderCommodity.orderExternalId);
            //parentMapKeys.put(shippingDivison.orderExternalId + '|' + shippingDivison.OrderItemCode, lookups.containsKey('Order'+shippingDivison.orderExternalId) ? String.valueOf(lookups.get('Order'+shippingDivison.orderExternalId)) : shippingDivison.orderExternalId);
        }


        FactoryDataIntegration.convertSObjectChild(
            new OrderCommodity__c(),
            'IN',
            request,
            responseMap,
            orderCommodityListToUpsert,
            lookups,
            parentMapKeys
        );

        
        List<Database.UpsertResult> upsResults = Database.upsert(orderCommodityListToUpsert, OrderCommodity__c.ExternalId__c, false);
        System.debug('upsResults' + upsResults);
        IntegrationUtils.upsertChildRecords(upsResults, responseMap, orderCommodityListToUpsert, OrderCommodity__c.ExternalId__c);

        return responseMap;
    }
}
