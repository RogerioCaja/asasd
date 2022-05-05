@RestResource(urlMapping='/upsertOrderAppdigital/*')
global with sharing class IntegrationINOrderAppdigital {
    public IntegrationINOrderAppdigital() {

    }
    @HttpPost
    global static ResponseModel upsertOrder(List<TemplateDataIntegrationFields.OrderINData> request) {
        // Guarda a relação da conta com o pedido
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> accountLookups = new Set<String>();
        Set<String> salesOrgLookups = new Set<String>();
        Set<String> cropLookups = new Set<String>();
        Set<String> cultureLookups = new Set<String>();
        Set<String> orderLookups = new Set<String>();
        Set<String> salesSectionLookups = new Set<String>();
        Set<String> salesCTVLookups = new Set<String>();
        Set<String> pricebookLookups = new Set<String>();
        Set<String> paymentConditionLookups = new Set<String>();

        //Set<String> pricebookLookups = new Set<String>();
        // Guarda uma lista de respostas
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        // Guarda uma lista de orderItem para fazer o upsert
        List<TemplateDataIntegrationFields.OrderItemINData> orderItemListToUpsert = new List<TemplateDataIntegrationFields.OrderItemINData>();
        // Guarda uma lista de pedidos para fazer o upsert
        List<TemplateDataINtegrationFields.ShippingDivisonINData> shippingDivisonListToUpsert = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
        List<Order> orderListToUpsert = new List<Order>();

        //Application of business rules
        for (TemplateDataIntegrationFields.OrderINData order : request){
            // Pega a relação da conta com o pedido
            //Getting account parameters to search
            accountLookups.add(order.clienteCode);
            salesOrgLookups.add(order.SalesOrg);
            cropLookups.add(order.Crop);
            cultureLookups.add(order.Culture);
            salesSectionLookups.add(order.ActivitySector);
            salesCTVLookups.add(order.SalesCTV);
            paymentConditionLookups.add(order.PaymentCondition);
           
            if(order.orderItems != null) {
                // Adiciona todos os External Id e o catalogo de preço de order nos orderItem
                //Putting the Order's ExternalId parameter in the OrderItem
                for (TemplateDataIntegrationFields.OrderItemINData orderItem : order.orderItems){
                    orderItem.orderExternalId = order.CodigoSap;
                }
                // Adiciona os orderItem na lista para upsert
                //Getting list of order items
                orderItemListToUpsert.addAll(order.orderItems);
                System.debug('orderItemListToUpsert' + orderItemListToUpsert); 
            }
            for(TemplateDataIntegrationFields.ShippingDivisonINData shippingDivision : order.shippingDivison){
                shippingDivision.orderExternalId = order.CodigoSap;
            }
            shippingDivisonListToUpsert.addAll(order.shippingDivison);
            System.debug('shippingDivisonListToUpsert' + shippingDivisonListToUpsert);
            
            }

            
        // Pega o Id da conta com base no CNPJ da conta
        //Account search based on CNPJ field sent
        for (Account account : [SELECT Id, CNPJ__c FROM Account WHERE CNPJ__c IN : accountLookups]) {
            //Map structure for the model -> object name + parameter to record id
            //Example
            lookups.put('Account' + account.CNPJ__c, account.Id);
        }

        for (Safra__c crop : [SELECT Id, Name, 	Code__c FROM Safra__c WHERE Code__c IN : cropLookups]){
            lookups.put('Safra__c' + crop.Code__c, crop.Id);
            
        }
       

        for (Cultura__c culture : [SELECT Id, Name, Codigo__c FROM Cultura__c WHERE Codigo__c IN : cultureLookups]){
            lookups.put('Cultura__c' + culture.Codigo__c, culture.Id);
        }

        for (SalesOrg__c salesOrg : [SELECT Id, Name, SalesOrganizationCode__c from SalesOrg__c WHERE SalesOrganizationCode__c IN: salesOrgLookups]){
            lookups.put('SalesOrg__c' + salesOrg.SalesOrganizationCode__c, salesOrg.Id);
        }

        //for (SalesCTV__c salesCTV : [SELECT Id, Name, 	Code__c from SalesCTV__c]){
        //    lookups.put('SalesCTV' + distributionCenter.Code__c, distributionCenter.Id);
       // }

        for (CondicaoPagamento__c paymentCondition : [SELECT Id, Name from CondicaoPagamento__c WHERE Name IN: paymentConditionLookups]){
            lookups.put('CondicaoPagamento__c' + paymentCondition.Code__c, paymentCondition.Id);
        }
        for (Pricebook2 pricebook2Id : [SELECT Id, ExternalId__c FROM Pricebook2 WHERE ExternalId__c IN : pricebookLookups ]){
            lookups.put('Pricebook2Id' + pricebook2Id.ExternalId__c, pricebook2Id.Id);
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
                IntegrationINOrderItemAppdigital.upsertOrderItem(orderItemListToUpsert)
            );
        }

        Map<String, List<TemplateDataIntegrationFields.Response>> shippingDivisonResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(shippingDivisonListToUpsert.size() != 0){
            shippingDivisonResponse.putAll(
                IntegrationINShippingDivisonAppdigital.upsertShippingDivison(shippingDivisonListToUpsert)
            );
        }

        //Associating child object's response with object response
        // Pega todas as respostas dos OrderItem
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            response.items = new List<TemplateDataIntegrationFields.Response>();

            
            System.debug('shippingDivisonResponse=>'+shippingDivisonResponse);
            System.debug('orderItemResponse=>'+orderItemsResponse);
            System.debug('responseList=>'+responseList);
            
            if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.idSalesforce)){
                response.items.addAll(orderItemsResponse.get(response.idSalesforce));
                for(TemplatedataIntegrationFields.Response orderItem : orderItemsResponse.get(response.idSalesforce)){
                    response.items.addAll(shippingDivisonResponse.get(orderItem.idSalesforce)); 
                }
            } 
            else if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.externalCode)){
                response.items.addAll(orderItemsResponse.get(response.externalCode));
                for(TemplatedataIntegrationFields.Response orderItem : orderItemsResponse.get(response.externalCode)){
                    response.items.addAll(shippingDivisonResponse.get(orderItem.externalCode)); 
                }
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
        IntegrationLog.createLog('Order', 'Inbound', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
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

