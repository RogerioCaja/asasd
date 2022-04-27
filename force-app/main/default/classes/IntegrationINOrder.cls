@RestResource(urlMapping='/upsertINOrder/*')
global with sharing class IntegrationINOrder {
    public IntegrationINOrder() {

    }
    global static ResponseModel upsertOrder(List<TemplateDataIntegrationFields.IntegrationOrderINData> request) {
        // Guarda a relação da conta com o pedido
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> accountLookups = new Set<String>();
        Set<String> orderLookups = new Set<String>();
        Set<String> shippingAccountLookups = new Set<String>();
        Set<String> cropLookups = new Set<String>();
        Set<String> cultureLookups = new Set<String>();
        Set<String> salesOrgLookups = new Set<String>();
        Set<String> salesCTVLookups = new Set<String>();
        Set<String> pricebook2IdLookups = new Set<String>();
        Set<String> paymentConditionLookups = new Set<String>(); 

        // Guarda uma lista de respostas
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        // Guarda uma lista de orderItem para fazer o upsert
        List<TemplateDataIntegrationFields.IntegrationOrderINData> orderItemListToUpsert = new List<TemplateDataIntegrationFields.IntegrationOrderINData>();
        // Guarda uma lista de pedidos para fazer o upsert
        List<Order> orderListToUpsert = new List<Order>();

        //Application of business rules
        for (TemplateDataIntegrationFields.IntegrationOrderINData order : request){
            // Pega a relação da conta com o pedido
            //Getting account parameters to search
            accountLookups.add(order.paymentAccount);
            shippingAccountLookups.add(order.shippingAccount);
            cropLookups.add(order.crop);
            cultureLookups.add(order.culture);
            salesOrgLookups.add(order.salesOrg);
            salesCTVLookups.add(order.salesCTV);
            pricebook2IdLookups.add(order.pricebook2Id);
            paymentConditionLookups.add(order.paymentCondition);
            
            if(order != null) {
                // Adiciona todos os External Id e o catalogo de preço de order nos orderItem
                //Putting the Order's ExternalId parameter in the OrderItem
                //for (TemplateDataIntegrationFields.IntegrationOrderINData order : order){
                 //   orderItem.orderExternalId = order.orderNumber;
                }
                // Adiciona os orderItem na lista para upsert
                //Getting list of order items
                //orderItemListToUpsert.addAll(order.orderItems);
            //}
        }

        for (Pricebook2 pricebook2Id : [SELECT Id, ExternalId__c FROM Pricebook2 WHERE ExternalId__c IN : pricebook2IdLookups ]){
            lookups.put('Pricebook' + pricebook2Id.ExternalId__c, pricebook2Id.Id);
        }

        for (Order order : [SELECT Id, CodigoSap__c FROM Order WHERE CodigoSap__c IN : orderLookups]) {
            lookups.put('Order' + order.CodigoSap__c, order.Id);
        }

        for (Account account : [SELECT Id, Name FROM Account WHERE Name IN : shippingAccountLookups]) {
            lookups.put('Account' + account.Name, account.Id);
        }

        for (Account account : [SELECT Id, Name FROM Account WHERE Name IN : accountLookups]) {
            lookups.put('Account' + account.Name, account.Id);
        }

        for (Safra__c crop : [SELECT Id, Code__c FROM Safra__c WHERE Code__c IN : cropLookups]) {
            lookups.put('Safra' + crop.Code__c, crop.Id);
        }

        for (Cultura__c culture : [SELECT Id, Codigo__c FROM Cultura__c WHERE Codigo__c IN : cultureLookups]) {
            lookups.put('Cultura' + culture.Codigo__c, culture.Id);
        }

        for (SalesOrg__c salesOrg : [SELECT Id, SalesOrganizationCode__c FROM SalesOrg__c WHERE SalesOrganizationCode__c IN : salesOrgLookups]) {
            lookups.put('SalesOrg' + salesOrg.SalesOrganizationCode__c, salesOrg.Id);
        }

        for (User salesCTV : [SELECT Id, CodigoSap__c FROM User WHERE CodigoSap__c IN : salesCTVLookups]) {
            lookups.put('User' + salesCTV.CodigoSap__c, salesCTV.Id);
        }

        for (CondicaoPagamento__c paymentCondition : [SELECT Id, Code__c FROM CondicaoPagamento__c WHERE Code__c IN : paymentConditionLookups]) {
            lookups.put('CondicaoPagamento' + paymentCondition.Code__c, paymentCondition.Id);
        }


        //Converting template to object list and validating required fields
        // Valida e adiciona objeto na lista para upsert
        FactoryDataIntegration.convertSObject(new Order(), 'IN', request, responseList, orderListToUpsert, lookups);
          
        //Upserting records (Order)
		IntegrationUtils.upsertRecords(
            Database.upsert(orderListToUpsert, Order.CodigoSap__c, false), 
            responseList, 
            orderListToUpsert, 
            Order.CodigoSap__c
        );
        
        //Upserting records (OrderItem)
        // Upsert OrderItem
        Map<String, List<TemplateDataIntegrationFields.Response>> orderItemsResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(orderItemListToUpsert.size() != 0){
            orderItemsResponse.putAll(
                IntegrationInboundOrderItem.upsertOrderItem(orderItemListToUpsert)
            );
        }

        //Associating child object's response with object response
        // Pega todas as respostas dos OrderItem
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            response.items = new List<TemplateDataIntegrationFields.Response>();
            if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.idSalesforce)){
                response.items.addAll(orderItemsResponse.get(response.idSalesforce));
            } 
            else if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.externalCode)){
                response.items.addAll(orderItemsResponse.get(response.externalCode));
            }
        }

        //Checking integration errors to log
        // Verifica erros de integração para o log
        Boolean hasError = false;

        for(TemplateDataIntegrationFields.ResponseParent responseOrder : responseList){
            if(responseOrder.status == false){
                hasError = true;
                break;
            } else {
                for(TemplateDataIntegrationFields.Response response : responseOrder.items){
                    if(response.status == false){
                        hasError = true;
                        break;
                    }
                }
            }
        }
		
        //Creating integration log
        TemplateIntegrationLogs.createLog('Order', 'Inbound', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
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
