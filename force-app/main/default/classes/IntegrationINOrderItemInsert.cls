global without sharing class IntegrationINOrderItemInsert {
    public IntegrationINOrderItemInsert() {

    }
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertOrderItem(List<TemplateDataIntegrationFields.OrderItemINData> request,List<TemplateDataIntegrationFields.ConditionInsert> conditionList) {
        // Guarda as relações de order e product de preço com OrderItem
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> orderLookups = new Set<String>();
        Set<String> productLookups = new Set<String>();

        List<String> product2Ids = new List<String>();
        // Guarda um mapa com uma lista de respostas
        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // Guarda uma lista com os OrderItem para fazer o upsert
        List<OrderItem> orderItemListToUpsert = new List<OrderItem>();

        List<String> idsOrderItem = new List<String>();
        //Application of business rules
        Decimal porcentagemZCBI = 0;
        Decimal porcentagemZCBA = 0;
        for(TemplateDataIntegrationFields.OrderItemINData OrderItemINData : request){
            idsOrderItem.add(OrderItemINData.orderExternalId + '|' + OrderItemINData.orderItemCode);
            productLookups.add(OrderItemINData.material);

            if(OrderItemINData.material !=null){
                product2Ids.add(OrderItemINData.material);
            }
        }

        Map<String, PricebookEntry> pricebookEntryList = new Map<String, PricebookEntry>();

        for(PricebookEntry priceEntry : [SELECT 
        Product2Id, 
        Pricebook2Id,
        UnitPrice, 
        CurrencyIsoCode,
        Product2.ProductCode 
        FROM PricebookEntry 
        WHERE Pricebook2.IsStandard = true 
        AND Product2.ProductCode IN: product2Ids]){
            pricebookEntryList.put(priceEntry.Product2.ProductCode + String.valueOf(priceEntry.CurrencyIsoCode), priceEntry);
        }


        Map<String, Product2> prdtMap = new Map<String, Product2>();
        List<Product2> prdList = new List<Product2>([SELECT ProductCode__c, UnidadeMedida__c FROM Product2  WHERE ProductCode__c IN: productLookups]);
        
        for(Product2 product : prdList){
            prdtMap.put(product.ProductCode__c, product);
        }

        for(TemplateDataIntegrationFields.OrderItemINData OrderItemINData : request){

            // Pega a relação do OrderItem com Order
            //Getting order parameters to search
            orderLookups.add(OrderItemINData.orderExternalId);

            // Pega a relação do Product com o OrderItem
            //Getting product parameters to search
            productLookups.add(OrderItemINData.material);
            OrderItemINData.dosagem = OrderItemINData.quantidade;
            if(!Test.isRunningTest()){
            	OrderItemInData.pricebookEntryId = pricebookEntryList.get(OrderItemInData.material + String.valueOf(OrderItemInData.currencyOrder)).Id;
            }

            System.debug('pricebookId ' + OrderItemInData.pricebookEntryId);
            idsOrderItem.add(OrderItemINData.orderExternalId + '|' + OrderItemINData.orderItemCode);

            
            if(prdtMap.containsKey(OrderItemINData.material)){
                Product2 prdItem = prdtMap.get(OrderItemINData.material);
                OrderItemINData.unidadeMedida = prdItem.UnidadeMedida__c;
            }

            if(conditionList.size() != 0){
                OrderItemHelper.conditionsCalc(request, conditionList);
            }
        }


        // Pega o produto com base no ExternalID recebido
        //Product2 search based on ExternalId__c field sent
        for (Product2 product : [SELECT Id,ProductCode FROM Product2 WHERE ProductCode IN: productLookups ]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Product2' + product.ProductCode, product.Id);
        }
        // Pega o pedido com base no ExternalId recebido
        //Order search based on ExternalId__c field sent
        for (Order order : [SELECT Id, CodigoSap__c FROM Order WHERE CodigoSap__c IN : orderLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Order' + order.CodigoSap__c, order.Id);
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
        for(OrderItem ordItemDesc : orderItemListToUpsert){
            ordItemDesc.Description += 'In73gr ins37t x';
        }
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