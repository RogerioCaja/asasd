global without sharing class IntegrationINCommodityAppdigital {
    public IntegrationINCommodityAppdigital() {

    }

    global static Map<String, List<TemplateDataINtegrationFields.Response>> upsertCommodity (List<TemplateDataINtegrationFields.OrderCommodityINData> request){

        Map<String, Id> lookups = new Map<String, Id>();
        Map<String, String> lookupsName = new Map<String, String>();

        Set<String> orderLookups = new Set<String>();

        Set<String> productLookupsForName = new Set<String>();
        Set<String> productLookups = new Set<String>();
        

        Map<String, List<TemplateDataINtegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();

        List<OrderCommodity__c> orderCommodityListToUpsert = new List<OrderCommodity__c>();
        List<String> idsCommodity = new List<String>();

        for(TemplateDataIntegrationFields.OrderCommodityINData OrderCommodityINData : request){

            productLookups.add(OrderCommodityINData.material);
            productLookupsForName.add(OrderCommodityINData.material);
            idsCommodity.add(OrderCommodityINData.orderExternalId + '|' + OrderCommodityINData.material);
            System.debug('idsCommodity ' + idsCommodity);
        }

        Map<String, OrderCommodity__c> commodityIdsMap = new Map<String, OrderCommodity__c>();
        List<OrderCommodity__c> commoditySelectList = new List<OrderCommodity__c>([SELECT Id, Name, Product__c, CommodityPrice__c, BagQuantity__c, BagMargin__c, Order__c, StartDate__c, EndDate__c, DeliveryAddress__c, ExternalId__c, Product__r.ProductCode__c, Product__r.Name FROM OrderCommodity__c WHERE ExternalId__c IN: idsCommodity]);
        System.debug('commoditySelectList ' + commoditySelectList);
        for(OrderCommodity__c ordCommodity : commoditySelectList){
            commodityIdsMap.put(ordCommodity.ExternalId__c, ordCommodity);
        }
        System.debug('commodityIdsMap ' + commodityIdsMap);

        for (TemplateDataIntegrationFields.OrderCommodityINData orderCommodity : request){
            System.debug('orderCommodityECalendariazacao ' + orderCommodity.orderCommodityECalendariazacao);
            if(orderCommodity.orderCommodityECalendariazacao == true){
                OrderCommodity__c ordCommodity = commodityIdsMap.get(orderCommodity.orderExternalId + '|' + orderCommodity.material);
                System.debug('ordCommodity ' + commodityIdsMap.get(orderCommodity.orderExternalId + '|' + orderCommodity.material));
                if(orderCommodity.orderExternalId == null){
                        
                    if(ordCommodity.Order__c != null){
                            orderCommodity.orderExternalId = ordCommodity.Order__c; 
                            lookups.put('Order' + ordCommodity.Order__r.CodigoSap__c, ordCommodity.Order__c);
                    }
                    }
            
            
            if(orderCommodity.material == null || orderCommodity.orderCommodityECalendariazacao == true){
                if(ordCommodity.Product__c != null){
                    orderCommodity.material = ordCommodity.Product__r.ProductCode__c;
                    lookups.put('Product2' + ordCommodity.Product__r.ProductCode__c, ordCommodity.Product__c);
                } 
            }
                System.debug('orderCommodity.material ' + orderCommodity.material);
            if(orderCommodity.material == null || orderCommodity.orderCommodityECalendariazacao == true){
                if(ordCommodity.Product__c != null){
                    orderCommodity.material = ordCommodity.Product__r.ProductCode__c;
                    lookupsName.put('Product2Name' + ordCommodity.Product__r.ProductCode__c, ordCommodity.Name);
                }
            }
            if(orderCommodity.bagQuantity == null || orderCommodity.orderCommodityECalendariazacao == true){
                orderCommodity.bagQuantity = ordCommodity.BagQuantity__c;
            }
            if(orderCommodity.bagMargin == null || orderCommodity.orderCommodityECalendariazacao == true){
                orderCommodity.bagMargin = ordCommodity.BagMargin__c;
            }
            if(orderCommodity.startDate == null || orderCommodity.orderCommodityECalendariazacao == true){
                orderCommodity.startDate = ordCommodity.StartDate__c;
            }
            if(orderCommodity.endDate == null || orderCommodity.orderCommodityECalendariazacao == true){
                orderCommodity.endDate = ordCommodity.EndDate__c;
            }
            if(orderCommodity.deliveryAddress == null || orderCommodity.orderCommodityECalendariazacao == true){
                orderCommodity.deliveryAddress = ordCommodity.DeliveryAddress__c;
            }
            if(orderCommodity.commodityPrice == null || orderCommodity.orderCommodityECalendariazacao == true){
                orderCommodity.commodityPrice = ordCommodity.CommodityPrice__c;
            }
        }
    }


        for (Product2 product : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: productLookups ]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Product2' + product.ProductCode, product.Id);
        }

        for (Product2 productName : [SELECT Id,ProductCode,Name FROM Product2 WHERE ProductCode IN: productLookupsForName ]) {
            //Map structure for the model -> object name + parameter to record id
            lookupsName.put('Product2Name' + productName.ProductCode, productName.Name);
        }

        for(Order order : [SELECT Id FROM Order WHERE Id IN : orderLookups]){
            //looups.put('Order' + order.orderExternalId, order.Id);
        }

        for(TemplateDataIntegrationFields.OrderCommodityINData OrderCommodityINData : request){
            OrderCommodityINData.Name = lookupsName.containsKey('Product2Name'+OrderCommodityINData.material) ? lookupsName.get('Product2Name'+OrderCommodityINData.material) : null;
        }

        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.OrderCommodityINData orderCommodities : request){
            parentMapKeys.put(orderCommodities.orderExternalId + '|' + orderCommodities.material, lookups.containsKey('Order'+orderCommodities.orderExternalId) ? String.valueOf(lookups.get('Order' + orderCommodities.orderExternalId)) : orderCommodities.orderExternalId);
            //parentMapKeys.put(shippingDivison.orderExternalId + '|' + shippingDivison.orderCommodityCode, lookups.containsKey('Order'+shippingDivison.orderExternalId) ? String.valueOf(lookups.get('Order'+shippingDivison.orderExternalId)) : shippingDivison.orderExternalId);
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
