global without sharing class IntegrationINOrderInsert {
    public IntegrationINOrderInsert() {

    }

 
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
        Set<String> shippingAccountLookups = new Set<String>();
        Set<String> orderReferenceLookups = new Set<String>();
        Set<String> activitySectorLookups = new Set<String>();
        Set<String> distributionChannelLookups = new Set<String>();
        Set<String> companyLookups = new Set<String>();
        //Set<String> pricebookLookups = new Set<String>();
        // Guarda uma lista de respostas
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        // Guarda uma lista de orderItem para fazer o upsert
        List<TemplateDataIntegrationFields.OrderItemINData> orderItemListToUpsert = new List<TemplateDataIntegrationFields.OrderItemINData>();
        // Guarda uma lista de pedidos para fazer o upsert
        List<TemplateDataINtegrationFields.ShippingDivisonINData> shippingDivisonListToUpsert = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();

        List<TemplateDataIntegrationFields.ConditionInsert> conditionList = new List<TemplateDataIntegrationFields.ConditionInsert>();
        
        List<String> idOrders = new List<String>();

        List<Order> orderListToUpsert = new List<Order>();

        
        //Application of business rules
        for (TemplateDataIntegrationFields.OrderINData order : request){
            // Pega a relação da conta com o pedido
            //Getting account parameters to search
            accountLookups.add(order.PaymentAccount);
            salesOrgLookups.add(order.SalesOrg);
            cropLookups.add(order.Crop);
            cultureLookups.add(order.Culture);
            salesSectionLookups.add(order.ActivitySector);
            salesCTVLookups.add(order.SalesCTV);
            paymentConditionLookups.add(order.PaymentCondition);
            if(order.PriceBook2Id == null){
                order.PriceBook2Id = 'Standard Price Book';
            }
            pricebookLookups.add(order.pricebook2Id);
            shippingAccountLookups.add(order.ShippingAccount);
            orderReferenceLookups.add(order.orderReference);
            activitySectorLookups.add(order.ActivitySector);
            distributionChannelLookups.add(order.DistributionChannel);
            order.company = order.PaymentAccount + order.CentroFornecedor + order.salesOrg + order.activitySector + order.distributionChannel + order.EscritorioVendas + order.EquipeVendas;
            companyLookups.add(order.company);

            
            System.debug('order.PriceBook2Id ' + order.PriceBook2Id);
            
            System.debug('companyLookups ' + companyLookups);
            if(order.orderItems != null) {
                // Adiciona todos os External Id e o catalogo de preço de order nos orderItem
                //Putting the Order's ExternalId parameter in the OrderItem
                for (TemplateDataIntegrationFields.OrderItemINData orderItem : order.orderItems){
                    orderItem.orderExternalId = order.CodigoSap;
                    orderItem.orderItemCode = orderItem.orderItemCode.replaceFirst('^0+','');
                }
                // Adiciona os orderItem na lista para upsert
                //Getting list of order items
                orderItemListToUpsert.addAll(order.orderItems);
                System.debug('orderItemListToUpsert' + orderItemListToUpsert); 

                switch on order.salesType {
                    // ---- Pedido mãe  ----
                     when 'ZCCO' {
                         order.pedidoMae = true;
                     }
                     when 'ZCVF'{
                        order.pedidoMae = true;
                     }
                     when 'ZCVN'{
                        order.pedidoMae = true;
                     }
     
                    // --- Pedidos normais ---
                     when 'ZSER'{
                        order.pedidoMae = false;
                     }
                     when 'ZVBA'{
                         order.pedidoMae = false;
                         
                     }
                     when 'ZVEF'{
                         order.pedidoMae = false;
                         
                     }
                     when 'ZVNO' {
                         order.pedidoMae = false;
     
                     }
                     when 'ZVVO'{
                         order.pedidoMae = false;
                         
                     }
                     when 'ZRCO'{
                         order.pedidoMae = false;
     
                     }
                 }

            }
            if(order.pedidoMae ==  false){
            for(TemplateDataIntegrationFields.ShippingDivisonINData shippingDivison : order.shippingDivison){
                    shippingDivison.orderExternalId = order.CodigoSap;
                    shippingDivison.OrderItemCode = shippingDivison.OrderItemCode.replaceFirst('^0+','');
                }
                shippingDivisonListToUpsert.addAll(order.shippingDivison);
            }

            for (TemplateDataIntegrationFields.PartnerInsert partnerList : order.partners){
                
                if(partnerList.PARVW == 'AG'){ // Cliente Emissor da ordem
                    accountLookups.add(partnerList.KUNNR);
                    order.PaymentAccount = partnerList.KUNNR;
                }
                else if (partnerList.PARVW == 'RE'){ // Recebedor da Fatura
                    
                }
                else if (partnerList.PARVW == 'RG'){ // Tipo Parceiro RG - Pagador

                }
                else if (partnerList.PARVW == 'WE'){ // Recebedor da Mercadoria
                    shippingAccountLookups.add(partnerList.KUNNR);
                    order.ShippingAccount = partnerList.KUNNR;
                }
                else if (partnerList.PARVW == 'ZC'){ // CTV Consultor
                    salesCTVLookups.add(partnerList.KUNNR);
                    order.salesCTV = partnerList.KUNNR;
                }
        }

            conditionList.addAll(order.conditions);
             
            System.debug('shippingDivisonListToUpsert' + shippingDivisonListToUpsert);
            
            }

            System.debug('Chegou!?!!!!!!!!!!!!!!!!!!!! ');    
        // Pega o Id da conta com base no CNPJ da conta
        //Account search based on CNPJ field sent
        for (Account account : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : accountLookups]) {
            //Map structure for the model -> object name + parameter to record id
            //Example
            lookups.put('Account' + account.ExternalId__c, account.Id);
        }
  // Pega o WE 
        for (Account account : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : shippingAccountLookups]) {
            lookups.put('Account' + account.ExternalId__c, account.Id);
        }

        for (Safra__c crop : [SELECT Id, Name, 	Code__c FROM Safra__c WHERE Code__c IN : cropLookups]){
            lookups.put('Safra__c' + crop.Code__c, crop.Id);
            
        }
       
        for (DistributionChannel__c distributionChannel :[SELECT Id, Name, Codigo__c FROM DistributionChannel__c WHERE Codigo__c IN : distributionChannelLookups]){
            lookups.put('DistributionChannel__c' + distributionChannel.Codigo__c, distributionChannel.Id);
        }

        
        for (ActivitySector__c activitySector :[SELECT Id, Name, Codigo__c FROM ActivitySector__c WHERE Codigo__c IN : activitySectorLookups]){
            lookups.put('ActivitySector__c' + activitySector.Codigo__c, activitySector.Id);
        }
        
        
        for (Cultura__c culture : [SELECT Id, Name, Codigo__c FROM Cultura__c WHERE Codigo__c IN : cultureLookups]){
            lookups.put('Cultura__c' + culture.Codigo__c, culture.Id);
        }

        for (SalesOrg__c salesOrg : [SELECT Id, Name, SalesOrganizationCode__c from SalesOrg__c WHERE SalesOrganizationCode__c IN: salesOrgLookups]){
            lookups.put('SalesOrg__c' + salesOrg.SalesOrganizationCode__c, salesOrg.Id);
        }

        for (User salesCTV : [SELECT Id, CodigoSap__c FROM User WHERE CodigoSap__c IN: salesCTVLookups]){
            lookups.put('User' + salesCTV.CodigoSap__c, salesCTV.Id);
       }
       
        for (CondicaoPagamento__c paymentCondition : [SELECT Id, Name,Code__c  from CondicaoPagamento__c WHERE Code__c IN: paymentConditionLookups]){
            lookups.put('CondicaoPagamento__c' + paymentCondition.Code__c, paymentCondition.Id);
        }
        for (Pricebook2 pricebook2Id : [SELECT Id, ExternalId__c, Name FROM Pricebook2 WHERE Name IN : pricebookLookups ]){
            
            lookups.put('Pricebook2Id' + pricebook2Id.Name, pricebook2Id.Id);
            
        }

        for (Order orderReference: [SELECT Id, CodigoSap__c FROM Order WHERE CodigoSap__c IN : orderReferenceLookups]){
            lookups.put('Order' + orderReference.CodigoSap__c, orderReference.Id);
        }

        for (Company__c companyOrd: [SELECT Id, ExternalID__c FROM Company__c WHERE ExternalID__c IN : companyLookups]){
            lookups.put('Company__c' + companyOrd.ExternalID__c, companyOrd.Id);
            System.debug('Lookup Company ' + lookups);
        }
        //Converting template to object list and validating required fields
        // Valida e adiciona objeto na lista para upsert
        System.debug('Chegou!?010102301023010230120 ');
        FactoryDataIntegration.convertSObject(new Order(), 'IN', request, responseList, orderListToUpsert, lookups);
          
        //Upserting records (Order)
        System.debug('Chegou!? 222222');
		IntegrationUtils.upsertRecords(
            Database.upsert(orderListToUpsert, Order.CodigoSap__c, false), 
            responseList, 
            orderListToUpsert, 
            Order.CodigoSap__c
        );
        Map<String, String> orderUpMap = new Map<String, String>();
        for(Order ordUp :orderListToUpsert){
            orderUpMap.put(ordUp.CodigoSap__c, ordUp.Id);
        }
        Map<String, String> orderIdEx = new Map<String, String>();
        for (TemplateDataIntegrationFields.OrderItemINData orderIt : orderItemListToUpsert){
            String orderId;
            
                if(orderIt.orderExternalId != null){
                    orderId = orderUpMap.get(orderIt.orderExternalId);
                    
                    orderIt.orderExternalId = orderId;

                    orderIdEx.put(orderId, orderIt.orderExternalId);
                } 
        }
        
        for (TemplateDataIntegrationFields.ShippingDivisonINData shipIt : shippingDivisonListToUpsert){
            String orderId;
                if(shipIt.orderExternalId != null){
                    orderId = orderUpMap.get(shipIt.orderExternalId);
                    
                    shipIt.orderExternalId = orderId;
                } 
        }
        
      
         //Confirmar com o Helder
        //Upserting records (OrderItem)
        // Upsert OrderItem
        Map<String, List<TemplateDataIntegrationFields.Response>> orderItemsResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(orderItemListToUpsert.size() != 0){
            orderItemsResponse.putAll(
                IntegrationINOrderItemInsert.upsertOrderItem(orderItemListToUpsert, conditionList)
            );
            System.debug('orderItemsResponse' + orderItemsResponse);
        }

        Map<String, List<TemplateDataIntegrationFields.Response>> shippingDivisonResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        
        if(shippingDivisonListToUpsert.size() != 0){
            shippingDivisonResponse.putAll(
                IntegrationINShippingdivisionInsert.upsertShippingDivison(shippingDivisonListToUpsert)
            );
            System.debug('shippingDivisonResponse' + shippingDivisonResponse);
        }

            AggregateResult[] resulTotal =[SELECT SUM(FinalTotalValue__c) somatoria FROM OrderItem WHERE OrderId =: orderIdEx.keySet() AND ReasonRefuse__c  =: null AND ReasonRefuse__c  =: ''];
        	 List<OrderItem> orderItemListT = [SELECT Id,  FinalTotalValue__c FROM OrderItem WHERE OrderId =: orderIdEx.keySet()];
        	 System.debug('orderItemListT ' + orderItemListT);
             System.debug('resulTotal ' + resulTotal);
             Order order = new Order();
             order.Id = (new List<String>(orderIdEx.keySet()))[0]; //(new List<String>(posts.keySet()))[0]
             //Object avgAmount = resulTotal[0].get('somatoria');
             order.FinalTotalValue__c  = (Decimal)resulTotal[0].get('somatoria');
             System.debug('order.FinalTotalValue__c ' + order.FinalTotalValue__c);
             OrderHelper.disableTrigger();
             upsert order;
             OrderHelper.enableTrigger();
        System.debug('Chegou!? ');
        //Associating child object's response with object response
        // Pega todas as respostas dos OrderItem
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            response.items = new List<TemplateDataIntegrationFields.Response>();
            if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.idSalesforce)){
                response.items.addAll(orderItemsResponse.get(response.idSalesforce));
                
                for(TemplatedataIntegrationFields.Response orderItem : orderItemsResponse.get(response.idSalesforce)){
                    if(shippingDivisonResponse.containsKey(orderItem.idSalesforce)){
                        response.items.addAll(shippingDivisonResponse.get(orderItem.idSalesforce));
                    } 
                }
                
                System.debug('orderItemsResponse' + orderItemsResponse);
                System.debug('shippingDivisonResponse' + shippingDivisonResponse);
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
        IntegrationLog.createLog('Order - Inserção OV', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
        //Returning response
         // Retorna a resposta Outbound
        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }
    // Classe que cria a resposta
    global class ResponseModel {

        global List<TemplateDataIntegrationFields.ResponseParent> response;

        public ResponseModel(List<TemplateDataIntegrationFields.ResponseParent> response) {

            this.response = response;
            
        }
        public ResponseModel() {   
            this.response = new List<TemplateDataIntegrationFields.ResponseParent>();         
        }
    }
}