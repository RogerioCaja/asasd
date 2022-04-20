global with sharing class IntegrationINOrderItem {

    //OrderItem upsert integration
    // global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertOrderItem(List<TemplateDataIntegrationFields.OrderItemINData> request) {
        
        // Map<String, Id> lookups = new Map<String, Id>();
        // Map<String, List<String>> lookupMap = new Map<String, List<String>>();
        // lookupMap = prepareData();

        // Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // List<TemplateDataIntegrationFields.ScheduleParameters> scheduleListToOrderItem = new List<TemplateDataIntegrationFields.ScheduleParameters>();
        // List<ShippingDivison__c> scheduleListToUpsert = new List<ShippingDivison__c>();
        // List<OrderItem> orderItemListToUpsert = new List<OrderItem>();

        // //Application of business rules
        // for(TemplateDataIntegrationFields.OrderItemINData orderItemINData : request){

        //     lookupMap.get('productLookups').add(orderItemINData.material);

        //     if(orderItemINData.schedules != null){
        //         for(TemplateDataIntegrationFields.ScheduleParameters schedule : orderItemINData.schedules){
        //             scheduleListToOrderItem.add(new TemplateDataIntegrationFields.ScheduleParameters(schedule.deliveryDate, schedule.codSchedule, schedule.quantity, schedule.confirmedQuantity, orderItemINData.itemCode));
        //         }
        //     }
        // }

    
        // IntegrationUtils.setLookup(new Product2(),new Set<String>{'Id', 'ProductCode'}, 'ProductCode', lookupMap.get('productLookups'), lookups);
        // IntegrationUtils.setLookup(new PricebookEntry(),new Set<String>{'Id', 'ProductCode'}, 'ProductCode', lookupMap.get('productLookups'), lookups);
        // IntegrationUtils.setLookup(new Order(),new Set<String>{'Id', 'CodigoSap__c'}, 'CodigoSap__c', lookupMap.get('productLookups'), lookups);

        // //OrderItem ExternalId Map to Order ExternalId for association of responses
        // Map<String, String> parentMapKeys = new Map<String, String>();
        // for(TemplateDataIntegrationFields.OrderItemINData orderItem : request) {
        //     parentMapKeys.put(orderItem.codExternalOrder + '|' + orderItem.itemCode, lookups.containsKey('Order'+ orderItem.codExternalOrder) ? lookups.get('Order'+ orderItem.codExternalOrder) : orderItem.codExternalOrder);
        // }

        // //Converting template to object list and validating required fields
        // // FactoryDataIntegration.convertSObjectChild(
        // //     new OrderItem(), 
        // //     'IN', 
        // //     request, 
        // //     responseMap, 
        // //     orderItemListToUpsert, 
        // //     lookups, 
        // //     parentMapKeys
        // // );

        // // //Upserting records
        // // List<Database.UpsertResult> upsResults = Database.upsert(orderItemListToUpsert, OrderItem.ExternalId__c, false);

        // // Set<Id> orderItemIds = new Set<Id>();
        // // for(Database.UpsertResult result : upsResults){
        // //     if(result.isSuccess()){
        // //         orderItemIds.add(result.getId());
        // //     }
        // // }

        // // for(OrderItem orderItem : [SELECT Id, ExternalId__c FROM OrderItem WHERE Id IN: orderItemIds]){
        // //     for(TemplateDataIntegrationFields.ScheduleParameters schedule : scheduleListToOrderItem){
        // //         scheduleListToUpsert.add(schedule.serialize(schedule, orderItem.Id));
        // //     }
        // // }

        // // List<Database.UpsertResult> upsResultsSchedule = Database.upsert(scheduleListToUpsert, ShippingDivison__c.ExternalId__c, false);

        // // IntegrationUtils.upsertChildRecords(upsResults, responseMap, orderItemListToUpsert, OrderItem.ExternalId__c); 
        
        // //Returning response
        // return responseMap;
    // }

    global static Map<String, List<String>> prepareData(){
        List<String> productLookups = new List<String>();
        List<String> orderLookups = new List<String>();

        Map<String, List<String>> response = new Map<String, List<String>>();
        response.put('productLookups', productLookups);
        response.put('orderLookups', orderLookups);
        return response;
    }
}