@RestResource(urlMapping='/upsertINOrder/*')
global without sharing class IntegrationINOrder {
    public IntegrationINOrder() {
			
    }
    @HttpPost
    global static ResponseModel upsertOrderValidation(List<TemplateDataIntegrationFields.OrderINData> request){
        
		List<String> idOrders = new List<String>();

        List<TemplateDataIntegrationFields.ConditionInsert> conditionList = new List<TemplateDataIntegrationFields.ConditionInsert>();

        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();

        for (TemplateDataIntegrationFields.OrderINData order : request){
            idOrders.add(order.CodigoSap);
            
        }
        
        Map<String, Order> ordersIdsMap = new Map<String, Order>();
        List<Order> orderSelectList = new List<Order>([SELECT Id, NumeroPedidoApp__c,PaymentDate__c,ShippingDate__c,Type,CustomerOrderNumber__c,
        Currency__c,Description,DescriptionBillingSale__c,FinalTotalValue__c,Hectare__c,OrderMargin__c,OrderType__c,SalesCondition__c,IsOrderMother__c, RecordTypeId, OwnerId,
        CodigoSap__c, Pricebook2Id, Pricebook2.Name,EffectiveDate,Status,StatusRecusa__c,Incoterms__c,Incoterms2__c,PaymentForm__c, Crop__r.Code__c, Crop__c, Culture__c, Culture__r.Codigo__c, SalesOrg__r.SalesOrganizationCode__c, SalesOrg__c, SalesCondition__r.ExternalId__c,ActivitySector__r.Codigo__c,
        SalesCTV__r.CodigoSap__c, SalesCTV__c, PaymentCondition__r.Code__c, PaymentCondition__c,OrderReference__r.CodigoSap__c, OrderReference__c, Account.ExternalId__c, AccountId, ShippingAccount__r.ExternalId__c, ShippingAccount__c,Company__r.ExternalID__c,Company__c,DistributionChannel__r.Codigo__c,DistributionChannel__c
        FROM Order WHERE CodigoSap__c  IN : idOrders]);

        for (Order ord : orderSelectList){
            ordersIdsMap.put(ord.CodigoSap__c, ord);

        }
         List<TemplateDataIntegrationFields.OrderINData> integrationOrderListValidation = new List<TemplateDataIntegrationFields.OrderINData>(); //Segue o jogo dentro do inboundOrder
         List<TemplateDataIntegrationFields.OrderINData> inApporderListValidation = new List<TemplateDataIntegrationFields.OrderINData>(); //Segue o jogo dentro do inboundOrderAppDigital
         for (TemplateDataIntegrationFields.OrderINData order : request){
            idOrders.add(order.CodigoSap);
             if(ordersIdsMap.containsKey(order.CodigoSap)){
					integrationOrderListValidation.add(order);
                    System.debug('1');
             }
             else{
                 inApporderListValidation.add(order);
                 System.debug('2');
             }  
        }

        ResponseModel modelo = new ResponseModel();
        
        
        if(!integrationOrderListValidation.isEmpty()){
            responseList.addAll(IntegrationINOrder.upsertOrder(integrationOrderListValidation).response); 
            System.debug('IF 1 ');
        }
        if(!inApporderListValidation.isEmpty()){
            responseList.addAll(IntegrationINOrderInsert.upsertOrder(inApporderListValidation).response);
            System.debug('IF 2 ');
        }   
        modelo.response = responseList;
        return modelo;
    }
    
    global static ResponseModel upsertOrder(List<TemplateDataIntegrationFields.OrderINData> request) { 
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
        Set<String> activitySectorLookups = new Set<String>();

        // Guarda uma lista de respostas
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        // Guarda uma lista de orderItem para fazer o upsert
        List<TemplateDataIntegrationFields.OrderItemINData> orderItemListToUpsert = new List<TemplateDataIntegrationFields.OrderItemINData>();

        List<TemplateDataIntegrationFields.ShippingDivisonINData> shippingDivisonListToUpsert = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
        
        List<TemplateDataIntegrationFields.ConditionInsert> conditionList = new List<TemplateDataIntegrationFields.ConditionInsert>();
        
        List<String> idOrders = new List<String>();

        // Guarda uma lista de pedidos para fazer o upsert
        List<Order> orderListToUpsert = new List<Order>();

        //Application of business rules
        for (TemplateDataIntegrationFields.OrderINData order : request){
            // Pega a relação da conta com o pedido
            //Getting account parameters to search
            //accountLookups.add(order.paymentAccount);
            //shippingAccountLookups.add(order.shippingAccount);
            cropLookups.add(order.crop);
            cultureLookups.add(order.culture);
            salesOrgLookups.add(order.salesOrg);
            //salesCTVLookups.add(order.salesCTV);
            pricebook2IdLookups.add(order.pricebook2Id);
            paymentConditionLookups.add(order.paymentCondition);
            activitySectorLookups.add(order.ActivitySector);
            idOrders.add(order.CodigoSap);
            
            for (TemplateDataIntegrationFields.OrderItemINData orderItem : order.orderItems) {
                orderItem.orderExternalId = order.CodigoSap;
                orderItem.orderItemCode = orderItem.orderItemCode.replaceFirst('^0+','');
                
                System.debug('order.CodigoSap ' + order.CodigoSap);
            }

            orderItemListToUpsert.addAll(order.orderItems);
            System.debug('orderItemListToUpsert ' + orderItemListToUpsert);

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

            if(order.pedidoMae == false){
                for (TemplateDataIntegrationFields.ShippingDivisonINData shippingDivisonItem : order.shippingDivison) {
                    shippingDivisonItem.orderExternalId = order.CodigoSap;
                    shippingDivisonItem.OrderItemCode = shippingDivisonItem.OrderItemCode.replaceFirst('^0+','');
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
                
            
            System.debug('accountLookups' + accountLookups);
            
            /*
            if(order != null) {
                // Adiciona todos os External Id e o catalogo de preço de order nos orderItem
                //Putting the Order's ExternalId parameter in the OrderItem
                //for (TemplateDataIntegrationFields.OrderINData order : order){
                 //   orderItem.orderExternalId = order.orderNumber;
                }
                // Adiciona os orderItem na lista para upsert
                //Getting list of order items
                //orderItemListToUpsert.addAll(order.orderItems);
            //}
            */
        }
        
        Map<String, Order> ordersIdsMap = new Map<String, Order>();
        List<Order> orderSelectList = new List<Order>([SELECT Id, NumeroPedidoApp__c,PaymentDate__c,ShippingDate__c,Type,CustomerOrderNumber__c,
        Currency__c,Description,DescriptionBillingSale__c,FinalTotalValue__c,Hectare__c,OrderMargin__c,OrderType__c,SalesCondition__c,IsOrderMother__c, RecordTypeId, OwnerId,
        CodigoSap__c, Pricebook2Id, Pricebook2.Name,EffectiveDate,Status,StatusRecusa__c,Incoterms__c,Incoterms2__c,PaymentForm__c, Crop__r.Code__c, Crop__c, Culture__c, Culture__r.Codigo__c, SalesOrg__r.SalesOrganizationCode__c, SalesOrg__c, SalesCondition__r.ExternalId__c,ActivitySector__r.Codigo__c,
        SalesCTV__r.CodigoSap__c, SalesCTV__c, PaymentCondition__r.Code__c, PaymentCondition__c,OrderReference__r.CodigoSap__c, OrderReference__c, Account.ExternalId__c, AccountId, ShippingAccount__r.ExternalId__c, ShippingAccount__c,Company__r.ExternalID__c,Company__c,DistributionChannel__r.Codigo__c,DistributionChannel__c
        FROM Order WHERE CodigoSap__c  IN : idOrders]);

        for (Order ord : orderSelectList){
            ordersIdsMap.put(ord.CodigoSap__c, ord);

        }
        for (TemplateDataIntegrationFields.OrderINData order : request){
            Order ord = ordersIdsMap.get(order.CodigoSap);
            
            if(order.numeroPedidoApp == null){
                order.numeroPedidoApp = ord.NumeroPedidoApp__c;
            }
            if (order.paymentDate == null){
                order.paymentDate = ord.PaymentDate__c;
            }
            if (order.effectiveDate == null){
                order.effectiveDate = ord.EffectiveDate;
            }
            if(order.ShippingDate == null){
                order.ShippingDate = ord.ShippingDate__c;
            }
            if(order.status == null){
                order.status = ord.Status;
            }
          
            if(order.type == null){
                order.type = ord.Type;
            }
            if(order.customerOrderNumber == null){
                order.customerOrderNumber = ord.CustomerOrderNumber__c;
            }
            if(order.paymentForm == null){
                order.paymentForm = ord.PaymentForm__c;
            }
            if(order.CurrencyOrder == null){
                order.CurrencyOrder = ord.Currency__c;
            }
            if(order.incoterms == null){
                order.incoterms = ord.Incoterms__c;
            }
            if(order.incoterms2 == null){
                order.incoterms2 = ord.Incoterms2__c;
            }
            if(order.description == null){
                order.description = ord.Description;
            }
            if(order.descriptionBillingSale == null){
                order.descriptionBillingSale = ord.DescriptionBillingSale__c;
            }
            if(order.valorFinalTotal == null){
                order.valorFinalTotal = ord.FinalTotalValue__c;
            }
            if(order.hectare == null){
                order.hectare = ord.Hectare__c; 
            }
            if(order.margemPedido == null){
                order.margemPedido = ord.OrderMargin__c;
            }
            if(order.orderType == null){
                order.orderType = ord.OrderType__c;
            }
            
            if(order.pedidoMae == null){
                order.pedidoMae = ord.IsOrderMother__c;
            }

            

            if(order.salesType == null){
                order.recordIdToUpdate = ord.RecordTypeId;
            }
            
			if(order.pricebook2Id == null){
                if(ord.Pricebook2Id != null){
                    order.pricebook2Id = ord.Pricebook2.Name;
                    lookups.put('Pricebook2Id' + ord.Pricebook2.Name, ord.Pricebook2Id);
                }
            }


        
            if(order.shippingAccount == null){
                if(ord.ShippingAccount__c != null){
                    order.shippingAccount = ord.ShippingAccount__r.ExternalId__c;
                    lookups.put('Account' + ord.ShippingAccount__r.ExternalId__c, ord.ShippingAccount__c);
                }
            }
            if(order.PaymentAccount == null){
                if(ord.AccountId != null){
                    order.PaymentAccount = ord.AccountId;
                    lookups.put('Account' + ord.Account.ExternalId__c, ord.AccountId);
                }
            }
            if(order.orderReference == null){
                if(ord.OrderReference__c != null){
                    order.orderReference = ord.OrderReference__r.CodigoSap__c;
                    lookups.put('Order' + ord.OrderReference__r.CodigoSap__c, ord.OrderReference__c);
                }
            }
           
            
            if(order.crop == null){
                if(ord.Crop__c != null){
                    order.crop = ord.Crop__r.Code__c;
                    lookups.put('Safra__c' + ord.Crop__r.Code__c, ord.Crop__c);
                }
            }

            if(order.culture == null){
                if(ord.Culture__c != null){
                    order.culture = ord.Culture__r.Codigo__c;
                    lookups.put('Cultura__c' + ord.Culture__r.Codigo__c, ord.Culture__c);
                }
            }

            if(order.salesOrg == null){
                if(ord.SalesOrg__c != null){
                    order.salesOrg = ord.SalesOrg__r.SalesOrganizationCode__c;
                    lookups.put('SalesOrg__c' + ord.SalesOrg__r.SalesOrganizationCode__c, ord.SalesOrg__c);
                }
            }
            
            if(order.SalesCTV == null || order.SalesCTV == ''){
                if(ord.SalesCTV__c != null){
                    order.salesCTV = ord.SalesCTV__r.CodigoSap__c;
                    lookups.put('User' + ord.SalesCTV__r.CodigoSap__c, ord.SalesCTV__c);
                }
                
                if(ord.OwnerId != null){
                    order.salesCTV = ord.SalesCTV__r.CodigoSap__c;
                    lookups.put('User' + ord.SalesCTV__r.CodigoSap__c, ord.SalesCTV__c);
                }
            }
            
            if(order.paymentCondition == null){
                if(ord.PaymentCondition__c != null){
                    order.paymentCondition = ord.PaymentCondition__r.Code__c;
                    lookups.put('CondicaoPagamento__c' + ord.PaymentCondition__r.Code__c, ord.PaymentCondition__c);    
                }
            } 
            if (order.company == null){
                if(ord.Company__c != null){
                    order.company = ord.Company__r.ExternalID__c;
                    lookups.put('Company__c' + ord.Company__r.ExternalID__c, ord.Company__c);
                }
            }
            if(order.distributionChannel == null){
                if(ord.DistributionChannel__c != null){
                    order.distributionChannel = ord.DistributionChannel__r.Codigo__c;
                    lookups.put('DistributionChannel__c' + ord.DistributionChannel__r.Codigo__c, ord.DistributionChannel__c);
                }
            }
            
            if(order.condicaoVenda == null){
                if(ord.SalesCondition__c != null){
                    order.condicaoVenda = ord.SalesCondition__r.ExternalId__c;
                    lookups.put('SalesCondition__c' + ord.SalesCondition__r.ExternalId__c, ord.SalesCondition__c);
                }
                
            }

            if(order.activitySector == null){
                if(ord.ActivitySector__c != null){
                    order.activitySector = ord.ActivitySector__r.Codigo__c;
                    lookups.put('ActivitySector__c' + ord.ActivitySector__r.Codigo__c, ord.ActivitySector__c);
                }
            }
            
        }

        for (Pricebook2 pricebook2Id : [SELECT Id, ExternalId__c, Name FROM Pricebook2 WHERE Name IN : pricebook2IdLookups ]){
            lookups.put('Pricebook2Id' + pricebook2Id.Name, pricebook2Id.Id);
        }

        for (Order order : [SELECT Id, CodigoSap__c FROM Order WHERE CodigoSap__c IN : orderLookups]) {
            lookups.put('Order' + order.CodigoSap__c, order.Id);
        }

        for (Account account : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : shippingAccountLookups]) {
            lookups.put('Account' + account.ExternalId__c, account.Id);
        }

        for (Account account : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : accountLookups]) {
            lookups.put('Account' + account.ExternalId__c, account.Id);
            system.debug('account.ExternalId__c' + account.ExternalId__c);
            system.debug('lookups' + lookups);
        }

        for (Safra__c crop : [SELECT Id, Code__c FROM Safra__c WHERE Code__c IN : cropLookups]) {
            lookups.put('Safra__c' + crop.Code__c, crop.Id);
        }

        for (Cultura__c culture : [SELECT Id, Codigo__c FROM Cultura__c WHERE Codigo__c IN : cultureLookups]) {
            lookups.put('Cultura__c' + culture.Codigo__c, culture.Id);
        }

        for (SalesOrg__c salesOrg : [SELECT Id, SalesOrganizationCode__c FROM SalesOrg__c WHERE SalesOrganizationCode__c IN : salesOrgLookups]) {
            lookups.put('SalesOrg__c' + salesOrg.SalesOrganizationCode__c, salesOrg.Id);
        }

        for (User salesCTV : [SELECT Id, CodigoSap__c FROM User WHERE CodigoSap__c IN : salesCTVLookups]) {
            lookups.put('User' + salesCTV.CodigoSap__c, salesCTV.Id);
        }

        for (CondicaoPagamento__c paymentCondition : [SELECT Id, Code__c FROM CondicaoPagamento__c WHERE Code__c IN : paymentConditionLookups]) {
            lookups.put('CondicaoPagamento__c' + paymentCondition.Code__c, paymentCondition.Id);
        }

        for (ActivitySector__c activitySector :[SELECT Id, Name, Codigo__c FROM ActivitySector__c WHERE Codigo__c IN : activitySectorLookups]){
            lookups.put('ActivitySector__c' + activitySector.Codigo__c, activitySector.Id);
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

        Map<String, String> orderUpMap = new Map<String, String>();
    
        for(Order ordUp :orderListToUpsert){
            orderUpMap.put(ordUp.CodigoSap__c, ordUp.Id);
            System.debug('orderUpMap ' + orderUpMap);
            System.debug('orderListToUpsert1111 ' + orderListToUpsert);
        }
        
        Map<String, String> orderIdEx = new Map<String, String>();
        for (TemplateDataIntegrationFields.OrderItemINData orderIt : orderItemListToUpsert){
            String orderId;
               if(orderIt.orderExternalId != null){
		            orderId = ordersIdsMap.get(orderIt.orderExternalId).Id;
                    
                    orderIt.orderExternalId = orderId;

                    orderIdEx.put(orderId, orderIt.orderExternalId);
                }  
                  
        }
        for (TemplateDataIntegrationFields.ShippingDivisonINData shipIt : shippingDivisonListToUpsert){
            String orderId;
            
                if(shipIt.orderExternalId != null){
                    orderId = ordersIdsMap.get(shipIt.orderExternalId).Id;
                    
                    shipIt.orderExternalId = orderId;
                } 
            
                
        }
        //Upserting records (OrderItem)
        // Upsert OrderItem

        Map<String, List<TemplateDataIntegrationFields.Response>> orderItemsResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(orderItemListToUpsert.size() != 0){
            orderItemsResponse.putAll(
                IntegrationINOrderItem.upsertOrderItem(orderItemListToUpsert, conditionList)
            );

        }

        Map<String, List<TemplateDataIntegrationFields.Response>> shippingDivisonResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(shippingDivisonListToUpsert.size() != 0){
            shippingDivisonResponse.putAll(
                IntegrationINShippingDivison.upsertShippingDivison(shippingDivisonListToUpsert)
            );
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
                    if(shippingDivisonResponse.containsKey(orderItem.idSalesforce)){
                        response.items.addAll(shippingDivisonResponse.get(orderItem.idSalesforce)); 
                    }
                }
            } 
            else if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.externalCode)){
                response.items.addAll(orderItemsResponse.get(response.externalCode));
                for(TemplatedataIntegrationFields.Response orderItem : orderItemsResponse.get(response.externalCode)){
                    if(shippingDivisonResponse.containsKey(orderItem.externalCode)){
                        response.items.addAll(shippingDivisonResponse.get(orderItem.externalCode)); 
                    }
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
        IntegrationLog.createLog('Order - Alteração OV', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
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