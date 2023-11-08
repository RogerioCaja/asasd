@RestResource(urlMapping='/upsertOrderAppdigital/*')
global without sharing class IntegrationINOrderAppdigital {
    
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
        Set<String> shippingAccountLookups = new Set<String>();
        Set<String> orderReferenceLookups = new Set<String>();
        Set<String> activitySectorLookups = new Set<String>();
        Set<String> distributionChannelLookups = new Set<String>();
        Set<String> salesConditionLookups = new Set<String>();
        Set<String> companyLookups = new Set<String>();
        //Set<String> pricebookLookups = new Set<String>();
        // Guarda uma lista de respostas
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        // Guarda uma lista de orderItem para fazer o upsert
        List<TemplateDataIntegrationFields.OrderItemINData> orderItemListToUpsert = new List<TemplateDataIntegrationFields.OrderItemINData>();
        // Guarda uma lista de pedidos para fazer o upsert
        Set<Id> orderItemIds = new Set<Id>();
        List<TemplateDataINtegrationFields.ShippingDivisonINData> shippingDivisonListToUpsert = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();

        List<TemplateDataIntegrationFields.OrderCommodityINData> orderCommodityListToUpsert = new List<TemplateDataINtegrationFields.OrderCommodityINData>();

        List<Order> orderListToUpsert = new List<Order>();

        List<String> idOrders = new List<String>();
        
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
            pricebookLookups.add(order.pricebook2Id);
            shippingAccountLookups.add(order.ShippingAccount);
            orderReferenceLookups.add(order.orderReference);
            activitySectorLookups.add(order.ActivitySector);
            distributionChannelLookups.add(order.DistributionChannel);
            salesConditionLookups.add(order.condicaoVenda);
            order.company = order.PaymentAccount + order.CentroFornecedor + order.salesOrg + order.activitySector + order.distributionChannel + order.EscritorioVendas + order.EquipeVendas;
            order.companyReceiver = order.shippingAccount + order.CentroFornecedor + order.salesOrg + order.activitySector + order.distributionChannel + order.EscritorioVendas + order.EquipeVendas;
            companyLookups.add(order.company);
            companyLookups.add(order.companyReceiver);

            idOrders.add(order.CodigoSap);

            if(order.orderItems != null) {
                // Adiciona todos os External Id e o catalogo de preço de order nos orderItem
                //Putting the Order's ExternalId parameter in the OrderItem
                for (TemplateDataIntegrationFields.OrderItemINData orderItem : order.orderItems){
                    orderItem.orderItemCode = orderItem.orderItemCode.replaceFirst('^0+','');
                    orderItem.currencyOrder = order.CurrencyOrder;
                    System.debug('Curreny ' + orderItem.currencyOrder);
                    if(order.numeroPedidoApp != null && order.numeroPedidoApp != ''){
                        System.debug('orderItem.orderExternalId ' + orderItem.orderExternalId );
                        orderItem.orderExternalId = order.numeroPedidoApp;
                        orderItem.orderItemECalendariazacao = order.eCalendarizacao;
                        System.debug('orderItem.orderExternalId App' + orderItem.orderExternalId );
                    }
                    else{
                        System.debug('orderItem.orderExternalId ' + orderItem.orderExternalId );
                        orderItem.orderExternalId = order.CodigoSap;
                        orderItem.orderItemECalendariazacao = order.eCalendarizacao;
                        System.debug('orderItem.orderExternalId SAP' + orderItem.orderExternalId );
                    }
                }
                // Adiciona os orderItem na lista para upsert
                //Getting list of order items
                orderItemListToUpsert.addAll(order.orderItems);
                System.debug('orderItemListToUpsert' + orderItemListToUpsert); 
            }
            if(order.pedidoMae ==  false){
            for(TemplateDataIntegrationFields.ShippingDivisonINData shippingDivison : order.shippingDivison){
                shippingDivison.orderItemCode = shippingDivison.orderItemCode.replaceFirst('^0+','');
                    if(order.numeroPedidoApp != null && order.numeroPedidoApp != ''){
                        shippingDivison.orderExternalId = order.numeroPedidoApp;
                    }
                    else{
                        shippingDivison.orderExternalId = order.codigoSap;
                    }
                }
              
            }
            if(order.pedidoMae == false){
                shippingDivisonListToUpsert.addAll(order.shippingDivison);
            }
             
            System.debug('shippingDivisonListToUpsert' + shippingDivisonListToUpsert);
            
            if(order.commodity != null){
                for(TemplateDataIntegrationFields.OrderCommodityINData orderCommodity : order.commodity){
                    //orderCommodity.orderItemCode = orderCommodity.orderItemCode.replaceFirst('^0+','');
                    orderCommodity.orderCommodityECalendariazacao = order.eCalendarizacao;
                    System.debug('orderCommodityECalendariazacao ' + orderCommodity.orderCommodityECalendariazacao);
                        if(order.numeroPedidoApp != null && order.numeroPedidoApp != ''){
                            orderCommodity.orderExternalId = order.numeroPedidoApp;
                        }
                        else{
                            orderCommodity.orderExternalId = order.codigoSap;
                        }
                    }
                    orderCommodityListToUpsert.addAll(order.commodity);
    
                }
            }
            
           
        Map<String, Order> ordersIdsMap = new Map<String, Order>();
        List<Order> orderSelectList = new List<Order>([SELECT Id, NumeroPedidoApp__c,PaymentDate__c,ShippingDate__c,Type,CustomerOrderNumber__c, ACMContract__c,
        Currency__c,Description,DescriptionBillingSale__c,FinalTotalValue__c,Hectare__c,OrderMargin__c,OrderType__c,SalesCondition__c,IsOrderMother__c, RecordTypeId, OwnerId,
        CodigoSap__c, Pricebook2Id, Pricebook2.Name,EffectiveDate,Status,StatusRecusa__c,Incoterms__c,Incoterms2__c,PaymentForm__c, Crop__r.Code__c, Crop__c, Culture__c, Culture__r.Codigo__c, SalesOrg__r.SalesOrganizationCode__c, SalesOrg__c, SalesCondition__r.ExternalId__c,ActivitySector__r.Codigo__c,
        SalesCTV__r.CodigoSap__c, SalesCTV__c, PaymentCondition__r.Code__c, PaymentCondition__c,OrderReference__r.CodigoSap__c, OrderReference__c, Account.ExternalId__c, AccountId, ShippingAccount__r.ExternalId__c, ShippingAccount__c,Company__r.ExternalID__c,Company__c,DistributionChannel__r.Codigo__c,DistributionChannel__c,MTO__c
        FROM Order WHERE CodigoSap__c  IN : idOrders]);

        for (Order ord : orderSelectList){
            ordersIdsMap.put(ord.CodigoSap__c, ord);
        }
        for (TemplateDataIntegrationFields.OrderINData order : request){
            if(order.eCalendarizacao == true){
            Order ord = ordersIdsMap.get(order.CodigoSap);

            if(order.contratoACM == null || order.contratoACM == ''){
                order.contratoACM = ord.ACMContract__c;
            }
                
            if(order.numeroPedidoApp == null || order.eCalendarizacao == true){
                order.numeroPedidoApp = ord.NumeroPedidoApp__c;

            }
            if (order.paymentDate == null || order.eCalendarizacao == true){
                order.paymentDate = ord.PaymentDate__c;
            }
            if (order.effectiveDate == null || order.eCalendarizacao == true){
                order.effectiveDate = ord.EffectiveDate;
            }
            if(order.ShippingDate == null || order.eCalendarizacao == true){
                order.ShippingDate = ord.ShippingDate__c;
            }
            if(order.status == null || order.eCalendarizacao == true){
                order.status = ord.Status;
            }
          
            if(order.type == null || order.eCalendarizacao == true){
                order.type = ord.Type;
            }
            if(order.customerOrderNumber == null || order.eCalendarizacao == true){
                order.customerOrderNumber = ord.CustomerOrderNumber__c;
            }
            if(order.paymentForm == null || order.eCalendarizacao == true){
                order.paymentForm = ord.PaymentForm__c;
            }
            if(order.CurrencyOrder == null || order.eCalendarizacao == true){
                order.CurrencyOrder = ord.Currency__c;
            }
            if(order.incoterms == null || order.eCalendarizacao == true){
                order.incoterms = ord.Incoterms__c;
            }
            if(order.incoterms2 == null || order.eCalendarizacao == true){
                order.incoterms2 = ord.Incoterms2__c;
            }
            if(order.description == null || order.eCalendarizacao == true){
                order.description = ord.Description;
            }
            if(order.descriptionBillingSale == null || order.eCalendarizacao == true){
                order.descriptionBillingSale = ord.DescriptionBillingSale__c;
            }
            if(order.valorFinalTotal == null || order.eCalendarizacao == true){
                order.valorFinalTotal = ord.FinalTotalValue__c;
            }
            if(order.hectare == null || order.eCalendarizacao == true){
                order.hectare = ord.Hectare__c; 
            }
            if(order.margemPedido == null || order.eCalendarizacao == true){
                order.margemPedido = ord.OrderMargin__c;
            }
            if(order.orderType == null || order.eCalendarizacao == true){
                order.orderType = ord.OrderType__c;
            }
            
            if(order.pedidoMae == null || order.eCalendarizacao == true){
                order.pedidoMae = ord.IsOrderMother__c;
            }

            if(order.salesType == null || order.eCalendarizacao == true){
                order.recordIdToUpdate = ord.RecordTypeId;
            }

            if(order.orderMTO == null || order.eCalendarizacao == true ){
                order.orderMTO = ord.MTO__c;
            }

			if(order.pricebook2Id == null || order.eCalendarizacao == true ){
                if(ord.Pricebook2Id != null){
                    order.pricebook2Id = ord.Pricebook2.Name;
                    lookups.put('Pricebook2Id' + ord.Pricebook2.Name, ord.Pricebook2Id);
                }
            }

            if(order.shippingAccount == null || order.eCalendarizacao == true){
                if(ord.ShippingAccount__c != null){
                    order.shippingAccount = ord.ShippingAccount__r.ExternalId__c;
                    lookups.put('Account' + ord.ShippingAccount__r.ExternalId__c, ord.ShippingAccount__c);
                }
            }
            if(order.eCalendarizacao == true){
                if(ord.AccountId != null){
                    order.PaymentAccount = ord.Account.ExternalId__c;
                    lookups.put('Account' + ord.Account.ExternalId__c, ord.AccountId);
                    System.debug('ord.Account.ExternalId__c ' + ord.Account.ExternalId__c);
                }
            }
            if(order.orderReference == null || order.eCalendarizacao == true){
                if(ord.OrderReference__c != null){
                    order.orderReference = ord.OrderReference__r.CodigoSap__c;
                    lookups.put('Order' + ord.OrderReference__r.CodigoSap__c, ord.OrderReference__c);
                }
            }
           
            
            if(order.crop == null || order.eCalendarizacao == true){
                if(ord.Crop__c != null){
                    order.crop = ord.Crop__r.Code__c;
                    lookups.put('Safra__c' + ord.Crop__r.Code__c, ord.Crop__c);
                }
            }

            if(order.culture == null || order.eCalendarizacao == true){
                if(ord.Culture__c != null){
                    order.culture = ord.Culture__r.Codigo__c;
                    lookups.put('Cultura__c' + ord.Culture__r.Codigo__c, ord.Culture__c);
                }
            }

            if(order.salesOrg == null || order.eCalendarizacao == true){
                if(ord.SalesOrg__c != null){
                    order.salesOrg = ord.SalesOrg__r.SalesOrganizationCode__c;
                    lookups.put('SalesOrg__c' + ord.SalesOrg__r.SalesOrganizationCode__c, ord.SalesOrg__c);
                }
            }
            
            if(order.SalesCTV == null || order.SalesCTV == '' || order.eCalendarizacao == true){
                if(ord.SalesCTV__c != null){
                    order.salesCTV = ord.SalesCTV__r.CodigoSap__c;
                    lookups.put('User' + ord.SalesCTV__r.CodigoSap__c, ord.SalesCTV__c);
                }
                
                if(ord.OwnerId != null ){
                    order.salesCTV = ord.SalesCTV__r.CodigoSap__c;
                    lookups.put('User' + ord.SalesCTV__r.CodigoSap__c, ord.SalesCTV__c);
                }
            }
            
            if(order.paymentCondition == null || order.eCalendarizacao == true){
                if(ord.PaymentCondition__c != null){
                    order.paymentCondition = ord.PaymentCondition__r.Code__c;
                    lookups.put('CondicaoPagamento__c' + ord.PaymentCondition__r.Code__c, ord.PaymentCondition__c);    
                }
            } 
            if (order.company == null || order.eCalendarizacao == true){
                if(ord.Company__c != null){
                    order.company = ord.Company__r.ExternalID__c;
                    lookups.put('Company__c' + ord.Company__r.ExternalID__c, ord.Company__c);
                }
            }
            if(order.distributionChannel == null || order.eCalendarizacao == true){
                if(ord.DistributionChannel__c != null){
                    order.distributionChannel = ord.DistributionChannel__r.Codigo__c;
                    lookups.put('DistributionChannel__c' + ord.DistributionChannel__r.Codigo__c, ord.DistributionChannel__c);
                }
            }
            
            if(order.condicaoVenda == null || order.eCalendarizacao == true){
                if(ord.SalesCondition__c != null){
                    order.condicaoVenda = ord.SalesCondition__r.ExternalId__c;
                    lookups.put('SalesCondition__c' + ord.SalesCondition__r.ExternalId__c, ord.SalesCondition__c);
                }
                
            }

            if(order.activitySector == null || order.eCalendarizacao == true){
                if(ord.ActivitySector__c != null){
                    order.activitySector = ord.ActivitySector__r.Codigo__c;
                    lookups.put('ActivitySector__c' + ord.ActivitySector__r.Codigo__c, ord.ActivitySector__c);
                }
            }
        }
        }   


        // Pega o Id da conta com base no CNPJ da conta
        //Account search based on CNPJ field sent
        for (Account account : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : accountLookups]) {
            //Map structure for the model -> object name + parameter to record id
            //Example
             lookups.put('Account' + account.ExternalId__c, account.Id);       
        }
        
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

        for (Order orderReference: [SELECT Id, NumeroPedidoApp__c, CodigoSap__c FROM Order WHERE NumeroPedidoApp__c IN : orderReferenceLookups OR CodigoSap__c IN: orderReferenceLookups]){
              lookups.put('Order' + orderReference.CodigoSap__c, orderReference.Id);
            
              lookups.put('Order' + orderReference.NumeroPedidoApp__c, orderReference.Id);      
        }

        for (Company__c companyOrd: [SELECT Id, ExternalID__c FROM Company__c WHERE ExternalID__c IN : companyLookups]){
            lookups.put('Company__c' + companyOrd.ExternalID__c, companyOrd.Id);
            System.debug('Lookup Company ' + lookups);
        }

        for(SalesCondition__c salesCondition : [SELECT Id, ExternalId__c FROM SalesCondition__c WHERE ExternalId__c IN : salesConditionLookups]){
            lookups.put('SalesCondition__c' + salesCondition.ExternalId__c, salesCondition.Id);
        }

        //Converting template to object list and validating required fields
        // Valida e adiciona objeto na lista para upsert
        
        FactoryDataIntegration.convertSObject(new Order(), 'IN', request, responseList, orderListToUpsert, lookups);
        System.debug('Order List to ' + orderListToUpsert);
        //Upserting records (Order)
        Map<String, String> orderUpMap = new Map<String, String>();
        List<Order> orderWithNbApp = new List<Order>();
        List<Order> orderWithNbSap = new List<Order>();

        for(Order ordUp :orderListToUpsert){
            //orderUpMap.put(ordUp.NumeroPedidoApp__c, ordUp.Id);
            //orderUpMap.put(ordUp.CodigoSap__c, ordUp.Id);

            if(ordUp.NumeroPedidoApp__c == null || ordUp.NumeroPedidoApp__c == ''){
                orderWithNbSap.add(ordUp);
                orderUpMap.put(ordUp.CodigoSap__c, ordUp.Id);
                
            }
            else{
                orderWithNbApp.add(ordUp);
                orderUpMap.put(ordUp.NumeroPedidoApp__c, ordUp.Id);
            }
        }
        List<Order> orderListForAppr = new List<Order>();

        if(!orderWithNbApp.isEmpty()){
            IntegrationUtils.upsertRecords(
            Database.upsert(orderWithNbApp, Order.NumeroPedidoApp__c, false), 
            responseList, 
            orderWithNbApp, 
            Order.NumeroPedidoApp__c
        );
            orderListForAppr.addAll(orderWithNbApp);  
        }
        if(!orderWithNbSap.isEmpty()){
            IntegrationUtils.upsertRecords(
                Database.upsert(orderWithNbSap, Order.CodigoSap__c, false), 
                responseList, 
                orderWithNbSap, 
                Order.CodigoSap__c
            );
            orderListForAppr.addAll(orderWithNbSap);
        }

		for(Order ordUp :orderListForAppr){
            
            if(ordUp.NumeroPedidoApp__c == null || ordUp.NumeroPedidoApp__c == ''){
                orderUpMap.put(ordUp.CodigoSap__c, ordUp.Id); 
            }
            else{
                orderUpMap.put(ordUp.NumeroPedidoApp__c, ordUp.Id);
            }
        }

        for (TemplateDataIntegrationFields.OrderItemINData orderIt : orderItemListToUpsert){
            String orderId;
                if(orderIt.orderExternalId != null){
                    orderId = orderUpMap.get(orderIt.orderExternalId);
                    
                    orderIt.orderExternalId = orderId;
                } 
        }
        
        for (TemplateDataIntegrationFields.ShippingDivisonINData shipIt : shippingDivisonListToUpsert){
            String orderId;
                if(shipIt.orderExternalId != null){
                    orderId = orderUpMap.get(shipIt.orderExternalId);
                    
                    shipIt.orderExternalId = orderId;
                } 
        }

        for (TemplateDataIntegrationFields.OrderCommodityINData ordCommodity : orderCommodityListToUpsert){
            String orderId;
            if(ordCommodity.orderExternalId != null){
                orderId = orderUpMap.get(ordCommodity.orderExternalId);

                ordCommodity.orderExternalId = orderId;
            }
        }
        
         //Confirmar com o Helder
        //Upserting records (OrderItem)
        // Upsert OrderItem
        Map<String, List<TemplateDataIntegrationFields.Response>> orderItemsResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(orderItemListToUpsert.size() != 0){
            orderItemsResponse.putAll(
                IntegrationINOrderItemAppdigital.upsertOrderItem(orderItemListToUpsert)
            );
            List <TemplateDataIntegrationFields.Response> listResponse = new list<TemplateDataIntegrationFields.Response>();

            for (String resp : orderItemsResponse.keySet()){
                listResponse.addAll(orderItemsResponse.get(resp));
               
            }
            for(TemplateDataIntegrationFields.Response respp : listResponse){
                orderItemIds.add(respp.idSalesforce);
            }

           List<ShippingDivison__c> shippingListIds = [SELECT Id, OrderItem__c,OrderItem__r.OrderId  From ShippingDivison__c Where OrderItem__c IN: orderItemIds];
           OrderHelper.disableTrigger();
           Database.delete(shippingListIds, false);
           OrderHelper.enableTrigger();
           if(!shippingListIds.isEmpty()){
                //CalloutOrderDatalake.callIntegration(shippingListIds[0].OrderItem__r.OrderId);
           }
        }

        Map<String, List<TemplateDataIntegrationFields.Response>> shippingDivisonResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        
        if(shippingDivisonListToUpsert.size() != 0){
            shippingDivisonResponse.putAll(
                IntegrationINShippingDivisonAppdigital.upsertShippingDivison(shippingDivisonListToUpsert)
            );
            System.debug('shippingDivisonResponse' + shippingDivisonResponse);
        }

        Map<String, List<TemplateDataIntegrationFields.Response>> orderCommodityResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        
        if(orderCommodityListToUpsert.size() != 0){
            orderCommodityResponse.putAll(
                IntegrationINCommodityAppdigital.upsertCommodity(orderCommodityListToUpsert)
            );
            System.debug('orderCommodityResponse' + orderCommodityResponse);
        }
        
        if(!orderListForAppr.isEmpty()){
           if(orderListForAppr[0].CodigoSap__c == null || orderListForAppr[0].CodigoSap__c == ''){
                IntegrationINOrderAppdigital.approvalDiscountOrder(orderListForAppr[0]);
        	} 
        }
        
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

            } 
            else if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.externalCode)){
                response.items.addAll(orderItemsResponse.get(response.externalCode));
                for(TemplatedataIntegrationFields.Response orderItem : orderItemsResponse.get(response.externalCode)){
                    response.items.addAll(shippingDivisonResponse.get(orderItem.externalCode)); 
                }
            }

            if(orderCommodityResponse.size() != 0 && orderCommodityResponse.containsKey(response.idSalesforce)){
                response.items.addAll(orderCommodityResponse.get(response.idSalesforce));
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
        IntegrationLog.createLog('Order - AppDigital', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
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

    public static void approvalDiscountOrder(Order orderDiscount){
        List<OrderItem> orderItemList = [SELECT Id, OrderId,
        Product2Id,
        Product2.ProductGroup__c,
        PricebookEntryId, 
        ExternalId__c, 
        Quantity,
        UnitMeasure__c,
        PercentComission__c, 
        DiscountPercent__c, 
        ComissionValue__c, 
        CommercialMargin__c, 
        DiscountValue__c, 
        FinalTotalValue__c, 
        FinancialDiscountPercent__c, 
        FinancialDiscountValue__c, 
        FinancialAdditionPercent__c,
        FinancialAdditionValue__c, 
        CommercialAdditionPercent__c,  
        CommercialAdditionValue__c, 
        Dosage__c, 
        ListCost__c, 
        NumeroSap__c, 
        PracticedCost__c, 
        PracticedPrice__c, 
        UnitPrice FROM OrderItem WHERE OrderId =: orderDiscount.Id];
        if (orderDiscount.Company__c != null && orderDiscount.OrderType__c != 'Pedido Filho') {
            Id userTerritoryId;
            for (UserTerritory2Association userAssociation : [
                SELECT Id,
                        UserId,
                        Territory2Id
                    FROM UserTerritory2Association
                    WHERE UserId =: orderDiscount.SalesCTV__c
                    LIMIT 1
            ]) {
                userTerritoryId = userAssociation.Territory2Id;
            }

            Map<Id, Territory2> territoryAndParents = new Map<Id, Territory2>();
            for(Territory2 territory : [
                SELECT Id,
                        DeveloperName,
                        ParentTerritory2Id
                    FROM Territory2
            ]){
                territoryAndParents.put(territory.Id, territory);
            }
            Decimal currentDiscount = 0;
            Decimal biggerDiscount = 0;
            
            Map<Id, Decimal> discountByProductGroups = new Map<Id, Decimal>();
            System.debug('orderItemList APROVACAO => '+ orderItemList);
            for(OrderItem ordItems : orderItemList){ 
                System.debug('ordItems.DiscountPercent__c => '+ ordItems.DiscountPercent__c);
                System.debug('Product2.ProductGroup__c' + ordItems.Product2Id);
                System.debug('ordItems.Product2.ProductGroup__c' + ordItems.Product2.ProductGroup__c);
                currentDiscount = ordItems.DiscountPercent__c;
                if(currentDiscount > biggerDiscount){
                    biggerDiscount = ordItems.DiscountPercent__c;
                    if(!discountByProductGroups.containsKey(ordItems.Product2.ProductGroup__c)){
                        discountByProductGroups.put(ordItems.Product2.ProductGroup__c, currentDiscount);
                    } else{
                        Decimal currentBiggerDiscount = discountByProductGroups.get(ordItems.Product2.ProductGroup__c);
                        discountByProductGroups.put(ordItems.Product2.ProductGroup__c, currentBiggerDiscount > currentDiscount ? currentBiggerDiscount : currentDiscount);
                    }
                    //productGroupId = ordItems.Product2.ProductGroup__c;
                }
                
            }
            Order orders = [SELECT Id, Company__r.ClientGroup__c, Company__r.SalesOrg__c FROM Order WHERE Id =: orderDiscount.Id];
            //Discount__c orderDisc = new Discount__c();
            Map<Id, Discount__c> discountByGroups = new Map<Id, Discount__c>();
            Decimal greaterDiscount = 0;
            Decimal smallerDiscount;
            for(Decimal actualDiscount : discountByProductGroups.values()){
                greaterDiscount = greaterDiscount > actualDiscount ? greaterDiscount : actualDiscount;
                smallerDiscount = smallerDiscount == null ? (smallerDiscount < actualDiscount ? smallerDiscount : actualDiscount) : smallerDiscount;
            }
            
            Map<String, Integer> approvalLevels = new Map<String, Integer>{
                'GerenteFilial' => 1,
                'GerenteRegional' => 2,
                'Diretor' => 3,
                'Diretor Torre' => 4
            };
            
            System.debug('ClientGroup__c => ' + orders.Company__r.ClientGroup__c);
            //System.debug('ProductGroup__c => ' + productGroupId);
            System.debug('biggerDiscount => ' + biggerDiscount);
            for (Discount__c discount : [
                SELECT Id,
                        Approver__c,
                        ProductGroup__c,
                        MinPercentage__c,
                        MaxPercentage__c
                    FROM Discount__c
                    WHERE Status__c = 'Aprovado'
                    AND ClientGroup__c =: orders.Company__r.ClientGroup__c
                    AND SalesOrg__c =: orders.Company__r.SalesOrg__c
                    AND ProductGroup__c =: discountByProductGroups.keySet() //Vamos rever esse daqui
                    AND InitialDate__c <=: System.today()
                    AND EndDate__c >=: System.today()
                    AND (MinPercentage__c <=: smallerDiscount OR MaxPercentage__c >=: greaterDiscount)
                ORDER BY MinPercentage__c, MaxPercentage__c
            ]) {
                System.debug('discount => ' + discount);
                //orderDisc = discount;
                Decimal groupDiscount = discountByProductGroups.get(discount.ProductGroup__c);
                if(discount.MinPercentage__c <= groupDiscount && discount.MaxPercentage__c >= groupDiscount){
                    if(!discountByGroups.containsKey(discount.ProductGroup__c)){
                        discountByGroups.put(discount.ProductGroup__c, discount); 
                    } else {
                        String discountApprover = discountByGroups.get(discount.ProductGroup__c).Approver__c;
                        if(approvalLevels.get(Discount.Approver__c) > approvalLevels.get(discountApprover)){
                            discountByGroups.put(discount.ProductGroup__c, discount);
                        }
                    } 
                }
            }
            //System.debug('orderDisc => ' + orderDisc);
            //System.debug('orderDisc.Approver__c => ' + orderDisc.Approver__c);
                
            Integer counter = 0;
            
            //Integer approvalNumber = approvalLevels.get(orderDisc.Approver__c);
            Integer approvalNumber = 0;
            for(Discount__c approverDiscount : discountByGroups.values()){
                Integer discountNumber = approvalLevels.get(discountByGroups.get(approverDiscount.ProductGroup__c).Approver__c);
                approvalNumber = approvalNumber > discountNumber ? approvalNumber : discountNumber;
            }
            Map<Integer, Id> approvalByCounter = new Map<Integer, Id>();
            while (counter < approvalNumber) {
                Territory2 territory = territoryAndParents.containsKey(userTerritoryId) ? territoryAndParents.get(userTerritoryId) : new Territory2();

                if (territory != null && territory.ParentTerritory2Id != null) {
                    userTerritoryId = territory.ParentTerritory2Id;
                    approvalByCounter.put(counter, userTerritoryId);
                }
                counter++;
            }

            Map<Id, Id> approvalsByTerritory = new Map<Id, Id>();
            for (UserTerritory2Association userAssociation : [
                SELECT Id,
                        UserId,
                        Territory2Id
                    FROM UserTerritory2Association
                    WHERE Territory2Id IN: approvalByCounter.values()
            ]) {
                approvalsByTerritory.put(userAssociation.Territory2Id, userAssociation.UserId);
            }

            orderDiscount.ApprovalBranchManager__c = null;
            orderDiscount.Manager_BranchOffice__c = false;
            orderDiscount.ApprovalRegionalManager__c = null;
            orderDiscount.Gerente_Regional__c = false;
            orderDiscount.ApprovalDirector__c = null;
            orderDiscount.Director__c = false;
            orderDiscount.ApprovalTowerDirector__c = null;
            orderDiscount.TowerDirector__c = false;

            if (approvalNumber >= 1) {
                orderDiscount.ApprovalBranchManager__c = approvalsByTerritory.get(approvalByCounter.get(0));
                orderDiscount.Manager_BranchOffice__c = true;
            }
            if (approvalNumber >= 2) {
                orderDiscount.ApprovalRegionalManager__c = approvalsByTerritory.get(approvalByCounter.get(1));
                orderDiscount.Gerente_Regional__c = true;
            }
            if (approvalNumber >= 3) {
                orderDiscount.ApprovalDirector__c = approvalsByTerritory.get(approvalByCounter.get(2));
                orderDiscount.Director__c = true;
            }
            if (approvalNumber >= 4){
                orderDiscount.ApprovalTowerDirector__c = approvalsByTerritory.get(approvalByCounter.get(3));
                orderDiscount.TowerDirector__c = true;
            }  
        }
        orderDiscount.Description += '1n73gr4ção N3sc4r4 5F x 4PP';
        Database.update(orderDiscount, Order.Id);
    }
}