global with sharing class IntegrationINOrder {
    public IntegrationINOrder() {

    }

    global static ResponseModel upsertOrder(List<TemplateDataIntegrationFields.OrderINData> request) {
        // Guarda a relação da conta com o pedido
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> accountLookups = new Set<String>();
        Set<String> orderLookups = new Set<String>();
        //Set<String> addressLookups = new Set<String>();
        Set<String> shippingAccountLookups = new Set<String>();
        Set<String> cropLookups = new Set<String>();
        Set<String> cultureLookups = new Set<String>();
        Set<String> salesOrgLookups = new Set<String>();
        Set<String> salesCTVLookups = new Set<String>();
        Set<String> conditionLookups = new Set<String>();
        

        Set<String> pricebook2Lookups = new Set<String>();

        // Guarda uma lista de respostas
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        // Guarda uma lista de orderItem para fazer o upsert
        List<TemplateDataIntegrationFields.OrderItemINData> orderItemListToUpsert = new List<TemplateDataIntegrationFields.OrderItemINData>();
        // Guarda uma lista de pedidos para fazer o upsert
        List<Order> orderListToUpsert = new List<Order>();

        //Application of business rules
        for (TemplateDataIntegrationFields.OrderINData order : request){
            // Pega a relação da conta com o pedido
            //Getting account parameters to search
            //accountLookups.add(order.clienteCode);
            //addressLookups.add(order.addressCode);
            conditionLookups.add(order.paymentCondition);
            pricebook2Lookups.add(order.pricebook2Id);
            
            if(order.orderItems != null) {
                // Adiciona todos os External Id e o catalogo de preço de order nos orderItem
                //Putting the Order's ExternalId parameter in the OrderItem
                for (TemplateDataIntegrationFields.OrderItemINData orderItem : order.orderItems){
                    orderItem.orderExternalId = order.orderNumber;
                }
                // Adiciona os orderItem na lista para upsert
                //Getting list of order items
                orderItemListToUpsert.addAll(order.orderItems);
            }
        }
        // Pega o Id da conta com base no CNPJ da conta
        //Account search based on CNPJ field sent
        for (Account account : [SELECT Id, CNPJ__c FROM Account WHERE CNPJ__c IN : accountLookups]) {
            //Map structure for the model -> object name + parameter to record id
            //Example
            lookups.put('Account' + account.CNPJ__c, account.Id);
        }

        for (AccountAddress__c accountAddress : [SELECT Id, Name, Bairro__c, CEP__c, City__c, Account__c, Code__c, Account__r.CNPJ__c FROM AccountAddress__c WHERE Account__r.CNPJ__c IN : accountLookups]){
            lookups.put('Address' + accountAddress.Code__c, accountAddress.Id);
            
        }
       

        for (PaymentCondition__c conditionCode : [SELECT Id, Name, Code__c FROM PaymentCondition__c]){
            lookups.put('Condition' + conditionCode.Code__c, conditionCode.Id);
        }

        for (DistribuitionCenter__c distributionCenter : [SELECT Id, Name, 	Code__c from DistribuitionCenter__c]){
            lookups.put('Distribution' + distributionCenter.Code__c, distributionCenter.Id);
        }
        
        //Converting template to object list and validating required fields
        // Valida e adiciona objeto na lista para upsert
        FactoryDataIntegration.convertSObject(new Order(), 'IN', request, responseList, orderListToUpsert, lookups);
          
        //Upserting records (Order)
		IntegrationUtils.upsertRecords(
            Database.upsert(orderListToUpsert, Order.EXTERNALID__c, false), 
            responseList, 
            orderListToUpsert, 
            Order.EXTERNALID__c
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
