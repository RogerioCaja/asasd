@RestResource(urlMapping='/upsertOrderAppdigital/*')
global without sharing class IntegrationINOrderAppdigital {
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
        List<TemplateDataINtegrationFields.ShippingDivisonINData> shippingDivisonListToUpsert = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
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
            pricebookLookups.add(order.pricebook2Id);
            shippingAccountLookups.add(order.ShippingAccount);
            orderReferenceLookups.add(order.orderReference);
            activitySectorLookups.add(order.ActivitySector);
            distributionChannelLookups.add(order.DistributionChannel);
            salesConditionLookups.add(order.condicaoVenda);
            order.company = order.PaymentAccount + order.CentroFornecedor + order.salesOrg + order.activitySector + order.distributionChannel + order.EscritorioVendas + order.EquipeVendas;
            companyLookups.add(order.company);
            System.debug('companyLookups ' + companyLookups);
            if(order.orderItems != null) {
                // Adiciona todos os External Id e o catalogo de preço de order nos orderItem
                //Putting the Order's ExternalId parameter in the OrderItem
                for (TemplateDataIntegrationFields.OrderItemINData orderItem : order.orderItems){
                    orderItem.orderExternalId = order.numeroPedidoApp;
                    orderItem.orderItemCode = orderItem.orderItemCode.replaceFirst('^0+','');
                }
                // Adiciona os orderItem na lista para upsert
                //Getting list of order items
                orderItemListToUpsert.addAll(order.orderItems);
                System.debug('orderItemListToUpsert' + orderItemListToUpsert); 
            }
            for(TemplateDataIntegrationFields.ShippingDivisonINData shippingDivison : order.shippingDivison){
                shippingDivison.orderExternalId = order.numeroPedidoApp;
                shippingDivison.orderItemCode = shippingDivison.orderItemCode.replaceFirst('^0+','');
            }
            shippingDivisonListToUpsert.addAll(order.shippingDivison);
            System.debug('shippingDivisonListToUpsert' + shippingDivisonListToUpsert);
            
            }

            
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
       
        for (CondicaoPagamento__c paymentCondition : [SELECT Id, Name, Code__c  from CondicaoPagamento__c WHERE Code__c IN: paymentConditionLookups]){//
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

        for(SalesCondition__c salesCondition : [SELECT Id, ExternalId__c FROM SalesCondition__c WHERE ExternalId__c IN : salesConditionLookups]){
            lookups.put('SalesCondition__c' + salesCondition.ExternalId__c, salesCondition.Id);

        }
        //Converting template to object list and validating required fields
        // Valida e adiciona objeto na lista para upsert
        FactoryDataIntegration.convertSObject(new Order(), 'IN', request, responseList, orderListToUpsert, lookups);
          
        //Upserting records (Order)
		IntegrationUtils.upsertRecords(
            Database.upsert(orderListToUpsert, Order.NumeroPedidoApp__c, false), 
            responseList, 
            orderListToUpsert, 
            Order.NumeroPedidoApp__c
        );
        Map<String, String> orderUpMap = new Map<String, String>();
        for(Order ordUp :orderListToUpsert){
            orderUpMap.put(ordUp.NumeroPedidoApp__c, ordUp.Id);
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
       
         //Confirmar com o Helder
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
        if(!orderListToUpsert.isEmpty()){
            IntegrationINOrderAppdigital.approvalDiscountOrder(orderListToUpsert[0]);
        }
        //Associating child object's response with object response
        // Pega todas as respostas dos OrderItem
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            response.items = new List<TemplateDataIntegrationFields.Response>();
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
    System.debug('Teste Entrada');
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
	System.debug('orderItemList ' + orderItemList);
    System.debug('orderDiscount.Company__c ' + orderDiscount.Company__c);    
            if (orderDiscount.Company__c != null) {
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
                List<String> productGroupId = new List<String>();
                for(OrderItem ordItems : orderItemList){   
                    productGroupId.add(ordItems.Product2.ProductGroup__c);
                    System.debug('Product2.ProductGroup__c' + ordItems.Product2Id);
                    System.debug('ordItems.Product2.ProductGroup__c' + ordItems.Product2.ProductGroup__c);
                    currentDiscount = ordItems.DiscountPercent__c;
                    if(currentDiscount > biggerDiscount){
                        biggerDiscount = ordItems.DiscountPercent__c;

                    }
                   
                }
	
                System.debug('productGroupId' + productGroupId);
                System.debug('biggerDiscount' + biggerDiscount);
                
                Order orders = [SELECT Id, Company__r.ClientGroup__c FROM Order WHERE Id =: orderDiscount.Id];
                System.debug('orders' + orders);
                Discount__c orderDisc = new Discount__c();
                for (Discount__c discount : [
                    SELECT Id,
                           Approver__c
                      FROM Discount__c
                     WHERE Status__c = 'Aprovado'
                       AND ClientGroup__c =: orders.Company__r.ClientGroup__c
                       AND ProductGroup__c =: productGroupId //Vamos rever esse daqui
                       AND InitialDate__c <=: System.today()
                       AND EndDate__c >=: System.today()
                       AND MinPercentage__c <=: biggerDiscount
                       AND MaxPercentage__c >=: biggerDiscount
                  ORDER BY MinPercentage__c, MaxPercentage__c
                ]) {
                    orderDisc = discount;
                }
    			System.debug('orderDisc' + orderDisc);
                Map<String, Integer> approvalLevels = new Map<String, Integer>{
                    'GerenteFilial' => 1,
                    'GerenteRegional' => 2,
                    'Diretor' => 3
                };
    
                Integer counter = 0;
                Integer approvalNumber = approvalLevels.get(orderDisc.Approver__c);
                System.debug('approvalNumber ' + approvalNumber);
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
                orderDiscount.Description += '1n73gr4ção N3sc4r4 5F x 4PP';
            update orderDiscount;
        }
        }
}