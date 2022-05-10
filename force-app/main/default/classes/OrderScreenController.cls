public without sharing class OrderScreenController {
    public static Map<Id, Integer> orderItemsPosition;

    @AuraEnabled
    public static String getOrder(String recordId, Boolean cloneOrder) {
        System.debug('recordId: ' + recordId);
        HeaderSerialize order;
        AccountSerialize account;
        List<ProductSerialize> ordItemList = new List<ProductSerialize>();
        List<DivisionSerialize> divisionList = new List<DivisionSerialize>();

        order = getOrderData(recordId, cloneOrder);
        if (order.lista_precos != null) {
            ordItemList = getOrderItemData(order.Id);
            divisionList = getShippingDivison();
        }
        account = getOrderAccountData(order.AccountId);

        return JSON.serialize(new OrderSerialize(order, ordItemList, divisionList, account));
    }

    @AuraEnabled
    public static String getAccount(String recordId) {
        OrderSerialize order;
        AccountSerialize account;
        List<ProductSerialize> ordItemList;
        
        account = getOrderAccountData(recordId);

        return JSON.serialize(new OrderSerialize(account));
    }

    public static HeaderSerialize getOrderData(Id orderId, Boolean cloneOrder){
        Order order = [SELECT Id, Description, DescriptionBillingSale__c, AccountId, Type, ShippingAccount__c , ShippingAccount__r.Phone,  ShippingAccount__r.Name, 
        ShippingAccount__r.BillingCity, ShippingAccount__r.BillingState ,ShippingAccount__r.CPF__c, ShippingAccount__r.CNPJ__c , Pricebook2Id, Pricebook2.Name, 
        Pricebook2.InitialDate__c, Pricebook2.EndDate__c, PaymentDate__c,  CustomerOrderNumber__c, Crop__c , Crop__r.Name, Culture__c , Culture__r.Name,
        PaymentForm__c, StatusSF__c, SalesOrg__c, SalesOrg__r.Name, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c, SalesCTV__r.Name,
        PaymentCondition__c, PaymentCondition__r.Name, ShippingDate__c, Incoterms__c, OrderReference__c, OrderReference__r.Name, IsOrderMother__c
        FROM Order 
        WHERE Id = :orderId LIMIT 1];
        return new HeaderSerialize(order, cloneOrder);
    }

    public static List<ProductSerialize> getOrderItemData(Id orderId) {
        List<ProductSerialize> prods = new List<ProductSerialize>();
        orderItemsPosition = new Map<Id, Integer>();
        Integer counter = 0;
        for(OrderItem item : [
            SELECT Id,
                   Product2Id,
                   Product2.Name,
                   Product2.ExternalId__c,
                   Product2.PrincipleActive__c,
                   Product2.Multiplicity__c,
                   Product2.ProductGroup__c,
                   Product2.ProductGroup__r.Name,
                   InvoicedQuantity__c,
                   OrderId,
                   PricebookEntryId,
                   ServiceDate,
                   Quantity,
                   ListPrice,
                   UnitPrice,
                   FinalTotalValue__c,
                   Dosage__c,
                   toLabel(Status__c),
                   UnitMeasure__c,
                   DiscountPercent__c,
                   DiscountValue__c,
                   CommercialAdditionPercent__c,
                   CommercialAdditionValue__c,
                   FinancialAdditionPercent__c,
                   FinancialAdditionValue__c,
                   FinancialDiscountPercent__c,
                   FinancialDiscountValue__c,
                   ComissionValue__c,
                   CommercialMargin__c,
                   AmountUsed__c
              FROM OrderItem
             WHERE OrderId =: orderId
        ]){
            prods.add(new ProductSerialize(item, counter));
            orderItemsPosition.put(item.Id, counter);
            counter++;
        }

        return prods;
    }

    public static List<DivisionSerialize> getShippingDivison() {
        List<DivisionSerialize> divisions = new List<DivisionSerialize>();
        Integer counter = 0;
        for (ShippingDivison__c shippingDivison : [
            SELECT Id,
                   OrderItem__c,
                   OrderItem__r.Product2Id,
                   OrderItem__r.Quantity,
                   OrderItem__r.UnitPrice,
                   Quantity__c,
                   DeliveryDate__c,
                   ExternalId__c,
                   ConfirmedQuantity__c
              FROM ShippingDivison__c
             WHERE OrderItem__c IN: orderItemsPosition.keySet()
        ]) {
            divisions.add(new DivisionSerialize(shippingDivison, counter, orderItemsPosition.get(shippingDivison.OrderItem__c)));
            counter++;
        }

        return divisions;
    }

    public static AccountSerialize getOrderAccountData(Id accountId) {
        Account account = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE Id =: accountId LIMIT 1];
        return new AccountSerialize(account);
    }

    @AuraEnabled
    public static string getAccountDataChild(Id accountId){
        try {
            List<AccountSerialize> accountListSerialize = new List<AccountSerialize>();
            Account accountMom = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE Id =: accountId LIMIT 1];
            List<Account> accountList = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE ParentId =: accountId];
            accountList.add(accountMom);
            for(Account account : accountList)
                accountListSerialize.add(new AccountSerialize(account));
            return JSON.serialize(new AccountSerialize(accountListSerialize));
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getOrderMothers(){
        try 
        {
            List<InformationFields> orders = new List<InformationFields>();
            Q subQuery = new Q('OrderItems')
                                .selectFields(new Set<String>{'AmountUsed__c', 'Quantity'});

            String query = new Q(Order.SObjectType)
                            .addSubquery(subQuery)
                            .selectFields(new Set<String>{'Id', 'CustomerOrderNumber__c'})
                            .add(Q.conditionGroup(
                            new List<Qcondition>{
                            Q.condition('SalesCTV__c').equalsTo(UserInfo.getUserId()), 
                            Q.condition('Crop__r.StartDateOrderInsertion__c').isLessOrEquals(System.today()), 
                            Q.condition('Crop__r.EndDateInsertionOrders__c').isGreaterThan(System.today()), 
                            Q.condition('IsOrderMother__c').equalsTo(true)})
                            .setLogicalOperatorAsAnd()).build();
            List<Order> orderList = Database.query(query);

            for (Order order : orderList) {
                Boolean isAvalaible = false;
                for (OrderItem orderItem : order.OrderItems) {
                    if (orderItem.AmountUsed__c < orderItem.Quantity) isAvalaible = true;
                }

                if (isAvalaible) orders.add(new InformationFields(order.Id, order.CustomerOrderNumber__c));
            }

            return JSON.serialize(orders);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String saveOrder(Id orderId, Boolean cloneOrder, String data) {
        Savepoint sp = Database.setSavepoint();
        try{
            Order order;
            String msg;
            Boolean newOrder = true;
            System.debug('data: ' + data);
            OrderDeserialize orderData = (OrderDeserialize) JSON.deserialize(data, OrderDeserialize.class);
            
            if (orderId != null && !cloneOrder) {
                newOrder = false;
                order = [SELECT Id, Description, DescriptionBillingSale__c, AccountId, Type, ShippingAccount__c, Pricebook2Id, PaymentDate__c, ShippingDate__c, PaymentCondition__c, CustomerOrderNumber__c,
                Crop__c, Culture__c, PaymentForm__c, StatusSF__c, SalesOrg__c, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c, EffectiveDate
                FROM Order WHERE Id =: orderId LIMIT 1];
            } else {
                order = new Order();
            }
            System.debug('order: ' + order);

            Account acc = [SELECT Id FROM Account WHERE Id =: orderData.accountData.Id LIMIT 1];
            Company__c company = new Company__c();
            for (Company__c accountCompany : [
                SELECT Id,
                       ClientGroup__c
                  FROM Company__c
                 WHERE Conta__c =: orderData.accountData.Id
            ]) {
                company = accountCompany;
            }
    
            Decimal orderTotalValue = 0;
            Decimal biggerDiscount = 0;
            Id productGroupId;
            Set<Id> setOrderItemsIds = new Set<Id>();
            Set<Id> setProductGroups = new Set<Id>();
            for (ProductDeserialize orderProduct : orderData.productData) {
                orderTotalValue += orderProduct.totalPrice;
                if (orderProduct.orderItemId != null) {
                    setOrderItemsIds.add(orderProduct.orderItemId);
                }

                if (orderProduct.productGroupId != null) {
                    setProductGroups.add(orderProduct.productGroupId);
                }

                Decimal currentDiscount = 100 - ((orderProduct.totalPrice * 100) / (orderProduct.quantity * orderProduct.listPrice));
                if (biggerDiscount < currentDiscount) {
                    biggerDiscount = currentDiscount;
                    productGroupId = orderProduct.productGroupId;
                }
            }
            
            Map<Id, OrderItem> orderItemsById = new Map<Id, OrderItem>([
                SELECT Id
                  FROM OrderItem
                 WHERE Id IN: setOrderItemsIds
            ]);
            
            User user = [SELECT Id, SellerType__c FROM User WHERE Id =: UserInfo.getUserId()];
            String sellerType = user.SellerType__c != null ? user.SellerType__c : '';

            Map<Id, Comissao__c> commissionByGroup = new Map<Id, Comissao__c>();
            if (sellerType != '') {
                for (Comissao__c commission : [
                    SELECT Id,
                           ProductGroup__c,
                           SellerType__c,
                           CommissionPercentage__c 
                    FROM Comissao__c
                    WHERE ProductGroup__c IN: setProductGroups
                    AND SellerType__c =: sellerType
                ]) {
                    if (!commissionByGroup.containsKey(commission.ProductGroup__c)) {
                        commissionByGroup.put(commission.ProductGroup__c, commission);
                    }
                }
            }

            Territory2 salesTeamTerritory;
            if (company != null) {
                Id userTerritoryId;
                for (UserTerritory2Association userAssociation : [
                    SELECT Id,
                           UserId,
                           Territory2Id
                      FROM UserTerritory2Association
                     WHERE UserId =: orderData.headerData.ctv_venda.Id
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

                Discount__c orderDiscount = new Discount__c();
                for (Discount__c discount : [
                    SELECT Id,
                           Approver__c
                      FROM Discount__c
                     WHERE Status__c = 'Aprovado'
                       AND ClientGroup__c =: company.ClientGroup__c
                       AND ProductGroup__c =: productGroupId
                       AND InitialDate__c <=: System.today()
                       AND EndDate__c >=: System.today()
                       AND MinPercentage__c <=: biggerDiscount
                       AND MaxPercentage__c >=: biggerDiscount
                  ORDER BY MinPercentage__c, MaxPercentage__c
                ]) {
                    orderDiscount = discount;
                }

                Map<String, Integer> approvalLevels = new Map<String, Integer>{
                    'GerenteFilial' => 1,
                    'GerenteRegional' => 2,
                    'Diretor' => 3
                };

                Integer counter = 0;
                Integer approvalNumber = approvalLevels.get(orderDiscount.Approver__c);
                Map<Integer, Id> approvalByCounter = new Map<Integer, Id>();
                while (counter < approvalNumber) {
                    Territory2 territory = territoryAndParents.containsKey(userTerritoryId) ? territoryAndParents.get(userTerritoryId) : new Territory2();

                    if (territory != null && territory.ParentTerritory2Id != null) {
                        userTerritoryId = territory.ParentTerritory2Id;
                        approvalByCounter.put(counter, userTerritoryId);
                    }

                    if (counter == 1) {
                        salesTeamTerritory = territory;
                    }
                    counter++;
                }

                if (salesTeamTerritory == null && territoryAndParents.get(userTerritoryId) != null && territoryAndParents.get(territoryAndParents.get(userTerritoryId).ParentTerritory2Id) != null) {
                    salesTeamTerritory = territoryAndParents.get(territoryAndParents.get(userTerritoryId).ParentTerritory2Id);
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

                if (approvalNumber >= 1) {
                    order.ApprovalBranchManager__c = approvalsByTerritory.get(approvalByCounter.get(0));
                    order.Manager_BranchOffice__c = true;
                }
                if (approvalNumber >= 2) {
                    order.ApprovalRegionalManager__c = approvalsByTerritory.get(approvalByCounter.get(1));
                    order.Gerente_Regional__c = true;
                }
                if (approvalNumber >= 3) {
                    order.ApprovalDirector__c = approvalsByTerritory.get(approvalByCounter.get(2));
                    order.Director__c = true;
                }
            }

            Id companyId;
            Id salesOrgId;
            if (salesTeamTerritory != null && salesTeamTerritory.DeveloperName != null) {
                String salesTeamDevName = salesTeamTerritory.DeveloperName.substring(1, salesTeamTerritory.DeveloperName.length());
                for (Company__c salesTeamCompany : [
                    SELECT Id,
                           SalesOrg__c
                      FROM Company__c
                     WHERE Conta__c =: orderData.accountData.Id
                       AND SalesTeam__r.ExternalId__c =: salesTeamDevName
                ]) {
                    companyId = salesTeamCompany.Id;
                    salesOrgId = salesTeamCompany.SalesOrg__c;
                }
            }

            order.AccountId = acc.Id;
            order.Status = 'Draft';
            order.PriceBook2Id = orderData.headerData.lista_precos.Id;
            order.Type = orderData.headerData.tipo_venda ;
            order.ShippingAccount__c = orderData.headerData.cliente_entrega.Id ;
            order.PaymentDate__c = Date.valueOf(orderData.headerData.data_pagamento) ;
            order.CustomerOrderNumber__c = orderData.headerData.numero_pedido_cliente ;
            order.EffectiveDate = newOrder ? Date.today() : order.EffectiveDate;
            order.Crop__c = orderData.headerData.safra.Id ;
            order.Culture__c = orderData.headerData.cultura.Id ;
            order.PaymentForm__c = orderData.headerData.forma_pagamento ;
            order.SalesOrg__c = salesOrgId;
            order.DistributionChannel__c = orderData.headerData.canal_distribuicao ;
            order.ActivitySector__c = orderData.headerData.setor_atividade ;
            order.Currency__c = orderData.headerData.moeda ;
            order.SalesCTV__c = orderData.headerData.ctv_venda.Id ;
            order.StatusSF__c = orderData.headerData.status_pedido;
            order.Incoterms__c = orderData.headerData.frete;
            order.Description = orderData.summaryData.observation;
            order.PaymentCondition__c = orderData.headerData.condicao_pagamento.Id;
            order.ShippingDate__c = Date.valueOf(orderData.headerData.data_entrega);
            order.DescriptionBillingSale__c = orderData.summaryData.billing_sale_observation;
            order.OrderReference__c = orderData.headerData.pedido_mae.Id;
            order.IsOrderMother__c = Boolean.valueOf(orderData.headerData.pedido_mae_check);
            order.FinalTotalValue__c = orderTotalValue;

            Map<Id, OrderItem> motherItems = new Map<Id, OrderItem>();
            Boolean newDivision = false;
            if (order.OrderReference__c != null) {
                for (OrderItem item : [
                    SELECT Id,
                           Quantity,
                           AmountUsed__c
                      FROM OrderItem
                     WHERE OrderId =: order.OrderReference__c
                ]) {
                    motherItems.put(item.Id, item);
                }

                newDivision = newOrder ? true : false;
            }
            System.debug('newDivision: ' + newDivision);

            Database.UpsertResult insResults = Database.upsert(order, false);
            if (insResults.isSuccess()) {
                msg = 'Pedido ' + (newOrder ? 'criado' : 'atualizado') + ' com sucesso';

                List<OrderItem> listOrderItems = new List<OrderItem>();
                Map<String, String> statusValueByLabel = new Map<String, String>{
                    'Concluído' => '5',
                    'Faturado Parcialmente' => '4',
                    'Crédito Liberado' => '3',
                    'Cancelado' => 'X'
                };
                Integer itemCounter = 1;
                for (ProductDeserialize orderProduct : orderData.productData) {
                    OrderItem orderItem;
                    if (!newOrder && orderItemsById.containsKey(orderProduct.orderItemId)) {
                        orderItem = orderItemsById.get(orderProduct.orderItemId);
                    } else {
                        orderItem = new OrderItem();
                        orderItem.NumeroSap__c = String.valueOf(itemCounter * 10);
                        orderItem.ExternalId__c = order.Id + '|' + orderItem.NumeroSap__c;
                        orderItem.OrderId = order.Id;
                        orderItem.PricebookEntryId = orderProduct.entryId;
                        orderItem.Product2Id = orderProduct.productId;
                        orderItem.ListPrice = orderProduct.listPrice;
                        orderItem.AmountUsed__c = order.IsOrderMother__c ? 0 : null;
                        orderItem.ServiceDate = System.today();
                        itemCounter++;
                    }
                    
                    if (motherItems.containsKey(orderProduct.orderItemId)) {
                        OrderItem motherItem = motherItems.get(orderProduct.orderItemId);
                        motherItem.AmountUsed__c = motherItem.AmountUsed__c != null ? motherItem.AmountUsed__c + orderProduct.quantity : 0;
                        motherItems.put(orderProduct.orderItemId, motherItem);
                    }

                    
                    orderItem.Quantity = orderProduct.quantity;
                    orderItem.UnitPrice = orderProduct.unitPrice;
                    orderItem.Dosage__c = orderProduct.dosage;
                    orderItem.Status__c = orderProduct.sapStatus != null ? statusValueByLabel.get(orderProduct.sapStatus) : null;
                    orderItem.UnitMeasure__c = orderProduct.unity;
                    orderItem.FinalTotalValue__c = orderProduct.totalPrice;
                    orderItem.DiscountPercent__c = orderProduct.commercialDiscountPercentage != '' ? stringToDecimal(orderProduct.commercialDiscountPercentage) : 0;
                    orderItem.DiscountValue__c = orderProduct.commercialDiscountValue;
                    orderItem.CommercialAdditionPercent__c = orderProduct.commercialAdditionPercentage != '' ? stringToDecimal(orderProduct.commercialAdditionPercentage) : 0;
                    orderItem.CommercialAdditionValue__c = orderProduct.commercialAdditionValue;
                    orderItem.FinancialAdditionPercent__c = orderProduct.financialAdditionPercentage != '' ? stringToDecimal(orderProduct.financialAdditionPercentage) : 0;
                    orderItem.FinancialAdditionValue__c = orderProduct.financialAdditionValue;
                    orderItem.FinancialDiscountPercent__c = orderProduct.financialDecreasePercentage != '' ? stringToDecimal(orderProduct.financialDecreasePercentage) : 0;
                    orderItem.FinancialDiscountValue__c = orderProduct.financialDecreaseValue;
                    orderItem.ComissionValue__c = orderProduct.comissionValue;
                    orderItem.CommercialMargin__c = orderProduct.commercialMarginPercentage;
                    orderItem.PercentComission__c = orderProduct.productGroupId != null ?
                                                    (commissionByGroup.get(orderProduct.productGroupId) != null ?
                                                        commissionByGroup.get(orderProduct.productGroupId).CommissionPercentage__c :
                                                        0
                                                    ) :
                                                    0;
                    orderItem.ComissionValue__c = orderItem.PercentComission__c != 0 ? (orderItem.FinalTotalValue__c * orderItem.PercentComission__c) / 100 : 0;
                    listOrderItems.add(orderItem);
                }
                update motherItems.values();

                String orderItemErrors = '';
                Set<Id> itemsIds = new Set<Id>();
                List<Database.UpsertResult> insOrderItemResults = Database.upsert(listOrderItems, false);
                for (Database.UpsertResult result : insOrderItemResults){
                    if(!result.isSuccess()){
                        for (Database.error error: insResults.getErrors()){
                            orderItemErrors += '\n' + error.getMessage();
                            msg = 'Pedido não pôde ser ' + (newOrder ? 'criado' : 'atualizado');
                            return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg + orderItemErrors));
                        }
                    } else {
                        itemsIds.add(result.getId());
                    }
                }

                Set<Id> setDivisionIds = new Set<Id>();
                if (orderData.divisionData != null) {
                    Map<String, Id> mapOrderItems = new Map<String, Id>();
                    for (OrderItem orderItem : [
                        SELECT Id,
                               Product2Id,
                               Quantity,
                               UnitPrice
                          FROM OrderItem
                         WHERE Id IN: itemsIds
                    ]) {
                        String key = orderItem.Product2Id + '-' + String.valueOf(orderItem.Quantity) + '-' + String.valueOf(orderItem.UnitPrice);
                        System.debug('key: ' + key);
                        mapOrderItems.put(key, orderItem.Id);
                    }

                    for (DivisionDeserialize division : orderData.divisionData) {
                        System.debug('division.divisionId: ' + division.divisionId);
                        if (division.divisionId != null) {
                            setDivisionIds.add(division.divisionId);
                        }
                    }

                    Map<Id, ShippingDivison__c> divisionsById = new Map<Id, ShippingDivison__c>();
                    for (ShippingDivison__c shippingDivison : [
                        SELECT Id
                          FROM ShippingDivison__c
                         WHERE Id IN: setDivisionIds
                    ]) {
                        divisionsById.put(shippingDivison.Id, shippingDivison);
                    }

                    List<ShippingDivison__c> listShippingDivision = new List<ShippingDivison__c>();
                    Map<Id, Decimal> quantityDistributedByItem = new Map<Id, Decimal>();
                    for (DivisionDeserialize division : orderData.divisionData) {
                        ShippingDivison__c shippingDivision;
                        if (!newOrder && !cloneOrder && divisionsById.containsKey(division.divisionId)) {
                            shippingDivision = divisionsById.get(division.divisionId);
                        } else {
                            shippingDivision = new ShippingDivison__c();
                        }

                        shippingDivision.DeliveryDate__c = Date.valueOf(division.deliveryDate);
                        shippingDivision.Quantity__c = division.quantity;
                        shippingDivision.ExternalId__c = division.externalId;
                        shippingDivision.ConfirmedQuantity__c = division.confirmedQuantity != null ? division.confirmedQuantity : 0;
                        shippingDivision.OrderItem__c = !cloneOrder && !newDivision && division.orderItemId != null ?
                                                        division.orderItemId : mapOrderItems.get(division.orderItemKey);
                        listShippingDivision.add(shippingDivision);

                        if (quantityDistributedByItem.containsKey(shippingDivision.OrderItem__c)) {
                            Decimal quantityDistributed = quantityDistributedByItem.get(shippingDivision.OrderItem__c) + shippingDivision.Quantity__c;
                            quantityDistributedByItem.put(shippingDivision.OrderItem__c, quantityDistributed);
                        } else {
                            quantityDistributedByItem.put(shippingDivision.OrderItem__c, shippingDivision.Quantity__c);
                        }
                    }

                    for (OrderItem item : listOrderItems) {
                        Decimal quantityUsed = quantityDistributedByItem.get(item.Id);
                        if (item.Quantity > quantityUsed) {
                            ShippingDivison__c shippingDivision = new ShippingDivison__c();
                            shippingDivision.DeliveryDate__c = order.ShippingDate__c;
                            shippingDivision.Quantity__c = item.Quantity - quantityUsed;
                            shippingDivision.OrderItem__c = item.Id;
                            listShippingDivision.add(shippingDivision);
                        }
                    }

                    String divisionErrors = '';
                    List<Database.UpsertResult> insDivisionResults = Database.upsert(listShippingDivision, false);
                    for (Database.UpsertResult result : insDivisionResults){
                        if(!result.isSuccess()){
                            for (Database.error error: insResults.getErrors()){
                                divisionErrors += '\n' + error.getMessage();
                                msg = 'Pedido não pôde ser ' + (newOrder ? 'criado' : 'atualizado');
                                return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg + divisionErrors));
                            }
                        } else {
                            itemsIds.add(result.getId());
                        }
                    }
                }
                
                return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg, String.valueOf(order.Id)));
            }

            String errors = '';
            for (Database.error error: insResults.getErrors()) {
                 errors += '\n' + error.getMessage();
            }
            msg = 'Pedido não pôde ser ' + (newOrder ? 'criado' : 'atualizado');
            return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg + errors));
        } catch (Exception ex) {
            Database.rollback(sp);
            System.debug('Erro: ' + ex.getMessage() + '   -   ' + ex.getStackTraceString());
			throw new AuraHandledException('Exception occured:\r\n' + ex.getMessage() + '\r\n' + ex.getStackTraceString() + '\r\n');
		}
    }

    // @AuraEnabled
    // public static string callout(String orderId){
    //     try {
    //         IntegrationUtils.CalloutResponse response = CalloutOrder.processIntegration(Id.valueOf(orderId));
    //         if(response.success){
    //             return JSON.serializePretty(new AGRO_RemotingResult(false, '200', 'Integrado com o SAP', String.valueOf(response.success)));
    //         }
    //         else{
    //             return JSON.serializePretty(new AGRO_RemotingResult(false, '400', 'Não Integrado com o SAP', String.valueOf(response.errorMessage)));
    //         }
            
    //     } catch (Exception ex) {
    //         System.debug('Erro: ' + ex.getMessage() + '   -   ' + ex.getStackTraceString());
    //         throw new AuraHandledException(ex.getMessage());
    //     }
    // }

    @AuraEnabled
    public static String getFinancialInfos(String data) {
        FinancialResult result = new FinancialResult();
        OrderDataDeserialize orderValues = (OrderDataDeserialize) JSON.deserialize(data, OrderDataDeserialize.class);
        Set<String> pricebookProducts = new Set<String>();
        Date pricebookPaymentDate;
        
        for (PricebookEntry pricebookEntry : [
            SELECT Id,
                   Product2Id,
                   Product2.StockKeepingUnit,
                   Pricebook2.PaymentDate__c
              FROM PricebookEntry
             WHERE Pricebook2Id =: orderValues.pricebookId
               AND IsActive = true
        ]) {
            pricebookProducts.add(pricebookEntry.Product2.StockKeepingUnit);
            pricebookPaymentDate = pricebookEntry.Pricebook2.PaymentDate__c;
        }

        result.correctPayment = Date.valueOf(orderValues.paymentDate) == pricebookPaymentDate ? true : false;
        result.isDiscount = Date.valueOf(orderValues.paymentDate) > pricebookPaymentDate ? false : true;
        Id discountOrAdditionRecType = result.isDiscount ? Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZDAN').getRecordTypeId()
                                                         : Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZJUR').getRecordTypeId();
        
        String companyGroup = '';
        for (Company__c accountCompany : [
            SELECT Id,
                   ClientGroup__c
              FROM Company__c
             WHERE Conta__c =: orderValues.accountId
             LIMIT 1
        ]) {
            companyGroup = accountCompany.ClientGroup__c;
        }

        Id userTerritoryId;
        for (UserTerritory2Association userAssociation : [
            SELECT Id,
                   UserId,
                   Territory2Id
              FROM UserTerritory2Association
             WHERE UserId =: orderValues.ctv
             LIMIT 1
        ]) {
            userTerritoryId = userAssociation.Territory2Id;
        }
        
        Set<Id> setAccountsIds = new Set<Id>();
        for (ObjectTerritory2Association objAssociation : [
            SELECT Id,
                   SobjectType,
                   ObjectId
              FROM ObjectTerritory2Association
             WHERE Territory2Id =: userTerritoryId
        ]) {
            if (objAssociation.SobjectType == 'Account') {
                setAccountsIds.add(objAssociation.ObjectId);
            }
        }

        if (Test.isRunningTest()) {
            result.salesOrg = [SELECT Id FROM SalesOrg__c LIMIT 1].Id;
        } else {
            for (Company__c company : [
                SELECT Id,
                       SalesOrg__c,
                       SalesOffice__c,
                       SalesTeam__c
                  FROM Company__c
                 WHERE Conta__c IN: setAccountsIds
                 LIMIT 1
            ]) {
                result.salesOrg = company.SalesOrg__c;
                result.salesOffice = company.SalesOffice__c;
                result.salesTeam = company.SalesTeam__c;
            }

        }

        Map<String, Decimal> discountByFinancialInfos = new Map<String, Decimal>();
        for (JurosDescontoAntecipao__c financialDiscount : [
            SELECT Id,
                   ConditionType__c,
                   Culture__c,
                   Percentage__c,
                   PriorityLevel__c,
                   ProductGroup__c,
                   Product__c,
                   SalesOffice__c,
                   SalesOrg__c,
                   SalesTeam__c,
                   harvest__c
              FROM JurosDescontoAntecipao__c
             WHERE RecordTypeId =: discountOrAdditionRecType
               AND StartDate__c <=: System.today()
               AND EndDate__c >=: System.today()
               AND SalesOrg__c =: result.salesOrg
               AND harvest__c =: orderValues.safra
               AND AccountType__c =: companyGroup
        ]) {
            System.debug('financialDiscount: ' + financialDiscount);
            String key = financialDiscount.SalesOrg__c + '-' + financialDiscount.harvest__c;
            if (!discountByFinancialInfos.containsKey(key)) {
                discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
            }

            key += financialDiscount.ProductGroup__c != null ? '-' + financialDiscount.ProductGroup__c : '';
            if (!discountByFinancialInfos.containsKey(key)) {
                discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
            }

            key += financialDiscount.SalesOffice__c != null ? '-' + financialDiscount.SalesOffice__c : '';
            if (!discountByFinancialInfos.containsKey(key)) {
                discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
            }

            key = financialDiscount.SalesOrg__c + '-' + financialDiscount.harvest__c;
            key += financialDiscount.SalesOffice__c != null ? '-' + financialDiscount.SalesOffice__c : '';
            key += financialDiscount.Product__c != null ? '-' + financialDiscount.Product__c : '';
            if (!discountByFinancialInfos.containsKey(key)) {
                discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
            }

            key = financialDiscount.SalesOrg__c + '-' + financialDiscount.harvest__c;
            key += financialDiscount.Culture__c != null ? '-' + financialDiscount.Culture__c : '';
            key += financialDiscount.Product__c != null ? '-' + financialDiscount.Product__c : '';
            if (!discountByFinancialInfos.containsKey(key)) {
                discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
            }
        }

        result.financialValues = discountByFinancialInfos;
        return JSON.serialize(new FinancialResultSerialize(result));
    }

    @AuraEnabled
    public static String getSafraInfos(String safraId){
        Safra__c safra = [SELECT Id,
                                 StartDateOrderInsertion__c,
                                 EndDateInsertionOrders__c
                            FROM Safra__c
                           WHERE Id =: safraId];
        return JSON.serialize(new SafraDataSerialize(safra));
    }

    @AuraEnabled
    public static String approvals(String data){
        OrderDeserialize orderData = (OrderDeserialize) JSON.deserialize(data, OrderDeserialize.class);
        Company__c company = new Company__c();

        for (Company__c accountCompany : [
            SELECT Id,
                   ClientGroup__c
              FROM Company__c
             WHERE Conta__c =: orderData.accountData.Id
        ]) {
            company = accountCompany;
        }

        Decimal orderTotalValue = 0;
        Decimal biggerDiscount = 0;
        Id productGroupId;
       
        Set<Id> setProductGroups = new Set<Id>();
        for (ProductDeserialize orderProduct : orderData.productData) {
            orderTotalValue += orderProduct.totalPrice;

            Decimal currentDiscount = 100 - ((orderProduct.totalPrice * 100) / (orderProduct.quantity * orderProduct.listPrice));
            if (biggerDiscount < currentDiscount) {
                biggerDiscount = currentDiscount;
                productGroupId = orderProduct.productGroupId;
            }
        }
        

        User user = [SELECT Id, SellerType__c FROM User WHERE Id =: UserInfo.getUserId()];
        String sellerType = user.SellerType__c != null ? user.SellerType__c : '';

        String approval = '';
        if (company != null) {
            Discount__c orderDiscount = new Discount__c();
            for (Discount__c discount : [
                SELECT Id,
                       Approver__c
                  FROM Discount__c
                 WHERE Status__c = 'Aprovado'
                   AND ClientGroup__c =: company.ClientGroup__c
                   AND ProductGroup__c =: productGroupId
                   AND InitialDate__c <=: System.today()
                   AND EndDate__c >=: System.today()
                   AND MinPercentage__c <=: biggerDiscount
                   AND MaxPercentage__c >=: biggerDiscount
              ORDER BY MinPercentage__c, MaxPercentage__c
            ]) {
                orderDiscount = discount;
            }

            Map<String, String> approvalLevels = new Map<String, String>{
                'GerenteFilial' => 'Gerente Filial',
                'GerenteRegional' => 'Gerente Regional',
                'Diretor' => 'Diretor',
                'ComiteMargem' => 'Comitê de Margem'
            };

            approval = approvalLevels.get(orderDiscount.Approver__c);
            
        }
        return approval;
    }

    public static Decimal stringToDecimal(String value) {
        if (value.contains(',')) value = value.replaceAll(',', '.');
        if (value.contains('%')) value = value.replaceAll('%', '');
        return Decimal.valueOf(value);
    }

    //Classe para deserialização
    public class OrderDeserialize{
        public AccountDeserialize accountData;
        public HeaderDeserialize headerData;
        public List<ProductDeserialize> productData;
        public List<DivisionDeserialize> divisionData;
        public SummaryDeserialize summaryData;
    }

    public class AccountDeserialize {
        public String Id;
        public String Name;
    }

    public class HeaderDeserialize {
       

        public String Id;
        public String AccountId;
        public String tipo_venda;
        //public InformationFields filial;
        public String numero_pedido_cliente;
        public InformationFields safra;
        public InformationFields cultura;
        public InformationFields lista_precos;
        public InformationFields condicao_pagamento;
        public String data_pagamento;
        public String data_entrega;
        public String status_pedido;
        public AccountSerialize cliente_entrega;
        public InformationFields organizacao_vendas;
        public String canal_distribuicao;
        public String setor_atividade;
        public String forma_pagamento;
        public String moeda;
        public String frete;
        public InformationFields ctv_venda;
        public InformationFields pedido_mae;
        public Boolean pedido_mae_check;
        public String observation;
        public String billing_sale_observation;
        //public String cliente_faturamento;
    }

    public class ProductDeserialize{
        public String orderItemId;
        public String productId;
        public String name;
        public String entryId;
        public String sapProductCode;
        public String sapStatus;
        public String unity;
        public String activePrinciple;
        public String productGroupId;
        public String productGroupName;
        public Integer position;
        public Decimal invoicedQuantity;
        public Decimal motherAvailableQuantity;
        public Decimal quantity;
        public Decimal listPrice;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Decimal dosage;
        public String commercialDiscountPercentage;
        public Decimal commercialDiscountValue;
        public String commercialAdditionPercentage;
        public Decimal commercialAdditionValue;
        public String financialAdditionPercentage;
        public Decimal financialAdditionValue;
        public String financialDecreasePercentage;
        public Decimal financialDecreaseValue;
        public Decimal commercialMarginPercentage;
        public Decimal comissionValue;
    }

    public class DivisionDeserialize{
        public String divisionId;
        public String deliveryDate;
        public String deliveryId;
        public String quantityId;
        public String externalId;
        public String orderItemId;
        public String orderItemKey;
        public Decimal confirmedQuantity;
        public Decimal quantity;
        public Integer productPosition;
        public Boolean showInfos;
    }

    public class SummaryDeserialize{
        public String observation;
        public String billing_sale_observation;
    }

    public class SummarySerialize{
        public String observation;
        public String billing_sale_observation;

        public SummarySerialize(){}
        public SummarySerialize(String observation, String billing_sale_observation){
            this.observation = observation;
            this.billing_sale_observation = billing_sale_observation;
        }
    }


    //Classe para serialização
    public class OrderSerialize{
        public HeaderSerialize headerData;
        public List<ProductSerialize> productData;
        public List<DivisionSerialize> divisionData;
        public AccountSerialize accountData;

        OrderSerialize(){}       

        OrderSerialize(AccountSerialize account){
            this.accountData = account;
        }  

        OrderSerialize(HeaderSerialize order, List<ProductSerialize> products, List<DivisionSerialize> divisions, AccountSerialize account){
            this.headerData = order;
            this.productData = products;
            this.divisionData = divisions;
            this.accountData = account;
        }
    }

    public class OrderSerializeAll{
        public HeaderSerialize headerData;
        public List<ProductSerialize> productData;
        public List<DivisionSerialize> divisionData;
        public AccountSerialize accountData;
        public SummarySerialize summaryData;

        OrderSerializeAll(){}       

        OrderSerializeAll(AccountSerialize account){
            this.accountData = account;
        }  

        public OrderSerializeAll(HeaderSerialize order, List<ProductSerialize> products, List<DivisionSerialize> divisions, AccountSerialize account, SummarySerialize summaryData){
            this.headerData = order;
            this.productData = products;
            this.divisionData = divisions;
            this.accountData = account;
            this.summaryData = summaryData;
        }
    }
    
    public class AccountSerialize {
        public String Id;
        public String Name;
        public String Phone;
        public String CNPJ;
        public String CPF;
        public String City;
        public String UF;
        public String CodSap;
        public String Company;
        
        public List<AccountSerialize> accountList;
        AccountSerialize(){}
        AccountSerialize(Account account){
            this.Id = account.Id;
            this.Name = account.Name;
            this.Phone = account.Phone;
            this.CNPJ = account.CNPJ__c;
            this.CPF = account.CPF__c;
            this.City = account.BillingCity;
            this.UF = account.BillingState;
            this.CodSap = account.ExternalId__c;
            this.Company = account.Company__c;
        }

        AccountSerialize(List<AccountSerialize> accountList){
            this.accountList = accountList;
        }
    }
    
    public class HeaderSerialize {
        public String Id;
        public String AccountId;
        public String tipo_venda;
        public String filial;
        public String numero_pedido_cliente;
        public InformationFields safra;
        public InformationFields cultura;
        public InformationFields lista_precos;
        public InformationFields condicao_pagamento;
        public String data_pagamento;
        public String data_entrega;
        public String status_pedido;
        public String cliente_faturamento;
        public AccountSerialize cliente_entrega;
        public InformationFields organizacao_vendas;
        public String canal_distribuicao;
        public String setor_atividade;
        public String forma_pagamento;
        public String moeda;
        public String frete;
        public InformationFields ctv_venda;
        public InformationFields pedido_mae;
        public Boolean pedido_mae_check;
        public String observation;
        public String billing_sale_observation;
        //public String data_entrega;
        //public String cliente_faturamento;
        HeaderSerialize(){}
        HeaderSerialize(Order order, Boolean cloneOrder){
            this.Id = order.Id;
            this.AccountId = order.AccountId;
            this.tipo_venda = order.Type;

            this.cliente_entrega = new AccountSerialize();
            this.cliente_entrega.Id = order.ShippingAccount__c;
            this.cliente_entrega.Name = order.ShippingAccount__r.Name;
            this.cliente_entrega.CNPJ = order.ShippingAccount__r.CNPJ__c;
            this.cliente_entrega.City = order.ShippingAccount__r.BillingCity;
            this.cliente_entrega.UF = order.ShippingAccount__r.BillingState;
            this.cliente_entrega.CPF = order.ShippingAccount__r.CPF__c;
            this.cliente_entrega.Phone = order.ShippingAccount__r.Phone;

            this.lista_precos = (!cloneOrder) || (cloneOrder && order.Pricebook2.InitialDate__c <= System.today() && order.Pricebook2.EndDate__c >= System.today()) ?
                                new InformationFields(order.Pricebook2Id, order.Pricebook2.Name) : null;
            this.data_pagamento = String.valueOf(order.PaymentDate__c);
            this.data_entrega = String.valueOf(order.ShippingDate__c);
            this.numero_pedido_cliente = order.CustomerOrderNumber__c;
            this.safra = new InformationFields(order.Crop__c, order.Crop__r.Name);
            this.cultura = new InformationFields(order.Culture__c, order.Culture__r.Name);
            this.forma_pagamento = order.PaymentForm__c;
            this.status_pedido = order.StatusSF__c;
            this.organizacao_vendas = new InformationFields(order.SalesOrg__c, order.SalesOrg__r.Name);
            this.canal_distribuicao = order.DistributionChannel__c;
            this.setor_atividade = order.ActivitySector__c;
            this.moeda = order.Currency__c;
            this.ctv_venda = new InformationFields(order.SalesCTV__c,  order.SalesCTV__r.Name);
            this.pedido_mae = new InformationFields(order.OrderReference__c, order.OrderReference__r.Name);
            this.pedido_mae_check = order.IsOrderMother__c;
            this.condicao_pagamento = new InformationFields(order.PaymentCondition__c, order.PaymentCondition__r.Name);
            this.frete = order.Incoterms__c;
            this.observation = order.Description;
            this.billing_sale_observation = order.DescriptionBillingSale__c;
        }
    }

    public class InformationFields{
        public String Id;
        public String Name;

        public InformationFields(String id, String name){
            this.Id = id;
            this.Name = name;
        }
    }
    
    public class ProductSerialize{
        public String orderId;
        public String orderItemId;
        public String productId;
        public String name;
        public String sapProductCode;
        public String entryId;
        public String sapStatus;
        public String unity;
        public String activePrinciple;
        public String productGroupId;
        public String productGroupName;
        // public String productGroup;
        public Date serviceDate;
        public Integer position;
        public Decimal multiplicity;
        public Decimal invoicedQuantity;
        public Decimal quantity;
        public Decimal motherAvailableQuantity;
        public Decimal listPrice;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Decimal dosage;
        public String commercialDiscountPercentage;
        public Decimal commercialDiscountValue;
        public String commercialAdditionPercentage;
        public Decimal commercialAdditionValue;
        public String financialAdditionPercentage;
        public Decimal financialAdditionValue;
        public String financialDecreasePercentage;
        public Decimal financialDecreaseValue;
        public Decimal commercialMarginPercentage;
        public Decimal comissionValue;

        ProductSerialize(){}

        ProductSerialize(OrderItem orderItem, Integer position){
            this.position = position;
            this.orderItemId = orderItem.Id;
            this.productId = orderItem.Product2Id;
            this.name = orderItem.Product2.Name;
            this.sapProductCode = orderItem.Product2.ExternalId__c;
            this.multiplicity = orderItem.Product2.Multiplicity__c;
            this.activePrinciple = orderItem.Product2.PrincipleActive__c;
            this.productGroupId = orderItem.Product2.ProductGroup__c;
            this.productGroupName = orderItem.Product2.ProductGroup__r.Name;
            this.entryId = orderItem.PricebookEntryId;
            this.orderId = OrderId;
            this.serviceDate = orderItem.ServiceDate;
            this.quantity = orderItem.AmountUsed__c != 0 && orderItem.AmountUsed__c != null ? orderItem.Quantity - orderItem.AmountUsed__c : orderItem.Quantity;
            this.invoicedQuantity = orderItem.InvoicedQuantity__c;
            this.motherAvailableQuantity = orderItem.AmountUsed__c != null ? orderItem.Quantity - orderItem.AmountUsed__c : null;
            this.listPrice = orderItem.ListPrice;
            this.unitPrice = orderItem.UnitPrice;
            this.totalPrice = orderItem.FinalTotalValue__c;
            this.dosage = orderItem.Dosage__c;
            this.sapStatus = orderItem.Status__c;
            this.unity = orderItem.UnitMeasure__c;
            this.commercialDiscountPercentage = String.valueOf(orderItem.DiscountPercent__c) + '%';
            this.commercialDiscountValue = orderItem.DiscountValue__c;
            this.commercialAdditionPercentage = String.valueOf(orderItem.CommercialAdditionPercent__c) + '%';
            this.commercialAdditionValue = orderItem.CommercialAdditionValue__c;
            this.financialAdditionPercentage = String.valueOf(orderItem.FinancialAdditionPercent__c) + '%';
            this.financialAdditionValue = orderItem.FinancialAdditionValue__c;
            this.financialDecreasePercentage = String.valueOf(orderItem.FinancialDiscountPercent__c) + '%';
            this.financialDecreaseValue = orderItem.FinancialDiscountValue__c;
            this.comissionValue = orderItem.ComissionValue__c;
            this.commercialMarginPercentage = orderItem.CommercialMargin__c;
        }
    }

    public class DivisionSerialize{
        public String divisionId;
        public String deliveryDate;
        public String deliveryId;
        public String quantityId;
        public String externalId;
        public String orderItemId;
        public String orderItemKey;
        public Decimal confirmedQuantity;
        public Decimal quantity;
        public Integer productPosition;
        public Boolean showInfos;

        DivisionSerialize(){}

        DivisionSerialize(ShippingDivison__c shippingDivison, Integer divisionPosition, Integer productPosition){
            this.divisionId = shippingDivison.Id;
            this.deliveryDate = String.valueOf(shippingDivison.DeliveryDate__c);
            this.deliveryId = 'deliveryId-' + divisionPosition;
            this.quantityId = 'quantityId-' + divisionPosition;
            this.orderItemId = shippingDivison.OrderItem__c;
            this.orderItemKey = shippingDivison.OrderItem__r.Product2Id + '-' + shippingDivison.OrderItem__r.Quantity + '-' + shippingDivison.OrderItem__r.UnitPrice;
            this.quantity = shippingDivison.Quantity__c;
            this.externalId = shippingDivison.ExternalId__c;
            this.confirmedQuantity = shippingDivison.ConfirmedQuantity__c;
            this.productPosition = productPosition;
            this.showInfos = true;
        }
    }

    public class SafraDataDeserialize {
        public String initialDate;
        public String endDate;
    }

    public class SafraDataSerialize {
        public String initialDate;
        public String endDate;

        SafraDataSerialize() {}

        SafraDataSerialize(Safra__c safra) {
            this.initialDate = String.valueOf(safra.StartDateOrderInsertion__c);
            this.endDate = String.valueOf(safra.EndDateInsertionOrders__c);
        }
    }

    public class OrderDataDeserialize {
        public String paymentDate;
        public String accountId;
        public String salesOrg;
        public String pricebookId;
        public String safra;
        public String ctv;
        public String culture;
    }

    public class FinancialResult {
        public Boolean isDiscount;
        public Boolean correctPayment;
        public String salesOrg;
        public String salesOffice;
        public String salesTeam;
        public Map<String, Decimal> financialValues;
    }

    public class FinancialResultSerialize {
        public Boolean isDiscount;
        public Boolean correctPayment;
        public String salesOrg;
        public String salesOffice;
        public String salesTeam;
        public Map<String, Decimal> financialValues;

        FinancialResultSerialize() {}

        FinancialResultSerialize(FinancialResult financialResult) {
            this.isDiscount = financialResult.isDiscount;
            this.correctPayment = financialResult.correctPayment;
            this.salesOrg = financialResult.salesOrg;
            this.salesOffice = financialResult.salesOffice;
            this.salesTeam = financialResult.salesTeam;
            this.financialValues = financialResult.financialValues;
        }
    }
}