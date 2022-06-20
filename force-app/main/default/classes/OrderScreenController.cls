public without sharing class OrderScreenController {
    public static Map<Id, Integer> orderItemsPosition;

    @AuraEnabled
    public static String getOrder(String recordId, Boolean cloneOrder, Boolean checkQuantities) {
        HeaderSerialize order;
        AccountSerialize account;
        List<ProductSerialize> ordItemList = new List<ProductSerialize>();
        List<DivisionSerialize> divisionList = new List<DivisionSerialize>();

        order = getOrderData(recordId, cloneOrder);
        if (order.condicao_venda != null) {
            ordItemList = getOrderItemData(order.Id, cloneOrder);
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
        ShippingAccount__r.BillingCity, ShippingAccount__r.BillingState ,ShippingAccount__r.CPF__c, ShippingAccount__r.CNPJ__c , SalesCondition__c, SalesCondition__r.Name, 
        Pricebook2.InitialDate__c, Pricebook2.EndDate__c, PaymentDate__c,  CustomerOrderNumber__c, Crop__c , Crop__r.Name, Culture__c , Culture__r.Name, OrderMargin__c,
        PaymentForm__c, StatusSF__c, CodigoSAP__c, SalesOrg__c, SalesOrg__r.Name, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c, SalesCTV__r.Name, OrderType__c,
        PaymentCondition__c, PaymentCondition__r.Name, ShippingDate__c, Incoterms__c, OrderReference__c, OrderReference__r.Name, IsOrderMother__c, Company__c, Hectare__c, Status
        FROM Order 
        WHERE Id = :orderId LIMIT 1];
        return new HeaderSerialize(order, cloneOrder);
    }

    public static List<ProductSerialize> getOrderItemData(Id orderId, Boolean cloneOrder) {
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
                   Product2.ProductHierarchy__c,
                   Product2.ProductGroup__r.Name,
                   Product2.ProductSubgroup__c,
                   Product2.ProductSubgroup__r.Name,
                   InvoicedQuantity__c,
                   OrderId,
                   Order.IsOrderMother__c,
                   PricebookEntryId,
                   ServiceDate,
                   Quantity,
                   ListPrice,
                   ListPrice__c,
                   UnitPrice,
                   FinalTotalValue__c,
                   ListCost__c,
                   PracticedCost__c,
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
            prods.add(new ProductSerialize(item, counter, cloneOrder));
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
    public static Boolean checkMotherQuantities(Id orderId) {
        try 
        {
            List<InformationFields> orders = new List<InformationFields>();
            Q subQuery = new Q('OrderItems')
                         .selectFields(new Set<String>{'AmountUsed__c', 'Quantity'});

            String query = new Q(Order.SObjectType)
                           .addSubquery(subQuery)
                           .selectFields(new Set<String>{'Id', 'CustomerOrderNumber__c'})
                           .add(Q.condition('Id').equalsTo(orderId))
                           .build();
            Order motherOrder = Database.query(query);

            Boolean isAvalaible = false;
            for (OrderItem orderItem : motherOrder.OrderItems) {
                if (orderItem.AmountUsed__c < orderItem.Quantity) isAvalaible = true;
            }

            return isAvalaible;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String saveOrder(Id orderId, Boolean cloneOrder, String data, string typeOrder) {
        Savepoint sp = Database.setSavepoint();
        try{
            Order order;
            String msg;
            Boolean newOrder = true;
            System.debug('data: ' + data);
            OrderDeserialize orderData = (OrderDeserialize) JSON.deserialize(data, OrderDeserialize.class);
            
            if (orderId != null && !cloneOrder) {
                newOrder = false;
                order = [SELECT Id, Description, DescriptionBillingSale__c, AccountId, Type, ShippingAccount__c, SalesCondition__c, PaymentDate__c, ShippingDate__c, PaymentCondition__c, CustomerOrderNumber__c, OrderType__c,
                                Crop__c, Culture__c, PaymentForm__c, StatusSF__c, SalesOrg__c, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c, EffectiveDate, Company__c, Hectare__c, OrderMargin__c
                FROM Order WHERE Id =: orderId LIMIT 1];
            } else {
                order = new Order();
                order.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get(orderData.headerData.tipo_venda).getRecordTypeId();
            }
            System.debug('order: ' + order);

            Account acc = [SELECT Id FROM Account WHERE Id =: orderData.accountData.Id LIMIT 1];
            Company__c company = new Company__c();
            for (Company__c accountCompany : [
                SELECT Id,
                       SalesOrg__c,
                       ClientGroup__c,
                       ActivitySector__c,
                       DistributionChannel__c
                  FROM Company__c
                 WHERE Id =: orderData.headerData.companyId
            ]) {
                company = accountCompany;
            }
    
            Decimal orderTotalValue = 0;
            Decimal biggerDiscount = 0;
            Id productGroupId;
            Set<Id> setOrderItemsIds = new Set<Id>();
            Set<Id> setProductsIds = new Set<Id>();
            Set<Id> setProductHierarchyIds = new Set<Id>();
            Map<String, Decimal> smallerMarginByProductGroup = new Map<String, Decimal>();
            for (ProductDeserialize orderProduct : orderData.productData) {
                orderTotalValue += orderProduct.totalPrice;
                if (orderProduct.orderItemId != null) {
                    setOrderItemsIds.add(orderProduct.orderItemId);
                }

                if (orderProduct.productId != null) {
                    setProductsIds.add(orderProduct.productId);
                }

                if (orderProduct.productGroupId != null) {
                    if (!smallerMarginByProductGroup.containsKey(orderProduct.productGroupId)) {
                        smallerMarginByProductGroup.put(orderProduct.productGroupId, orderProduct.commercialMarginPercentage);
                    } else {
                        Decimal currentMargin = smallerMarginByProductGroup.get(orderProduct.productGroupId);
                        currentMargin = currentMargin > orderProduct.commercialMarginPercentage ? orderProduct.commercialMarginPercentage : currentMargin;
                        smallerMarginByProductGroup.put(orderProduct.productGroupId, currentMargin);
                    }
                }

                if(orderProduct.productHierarchyId != null && orderProduct.productHierarchyId != ''){
                    setProductHierarchyIds.add(orderProduct.productHierarchyId);
                }

                Decimal currentDiscount = orderProduct.commercialDiscountPercentage != '' ? (stringToDecimal(orderProduct.commercialDiscountPercentage) != null ? stringToDecimal(orderProduct.commercialDiscountPercentage).setScale(2) : 0) : 0;
                if (biggerDiscount < currentDiscount) {
                    biggerDiscount = currentDiscount;
                    productGroupId = orderProduct.productGroupId;
                }
            }

            Map<String, Decimal> orderMarginMap = new Map<String, Decimal>();
            if (company != null && company.ClientGroup__c != null) {
                for (Discount__c discount : [
                    SELECT Id,
                           Margin__c,
                           ProductGroup__c
                      FROM Discount__c
                     WHERE Status__c = 'Aprovado'
                       AND Approver__c = 'ComiteMargem'
                       AND ClientGroup__c =: company.ClientGroup__c
                       AND ProductGroup__c IN: smallerMarginByProductGroup.keySet()
                       AND InitialDate__c <=: System.today()
                       AND EndDate__c >=: System.today()
                  ORDER BY Margin__c
                ]) {
                    orderMarginMap.put(discount.ProductGroup__c, discount.Margin__c);
                }
            }

            for (String groupId : smallerMarginByProductGroup.keySet()) {
                if (orderMarginMap.get(groupId) >= smallerMarginByProductGroup.get(groupId)) {
                    order.MarginCommittee__c = true;
                }
            }

            Map<Id, PricebookEntry> entriesByProductsIds = new Map<Id, PricebookEntry>();
            Id pricebookId;
            for (PricebookEntry entry : [
                SELECT Id,
                       Product2Id,
                       Pricebook2Id,
                       UnitPrice
                  FROM PricebookEntry
                 WHERE Pricebook2.IsStandard = true
                   AND Product2Id IN: setProductsIds
            ]) {
                pricebookId = entry.Pricebook2Id;
                entriesByProductsIds.put(entry.Product2Id, entry);
            }
            
            Map<Id, OrderItem> orderItemsById = new Map<Id, OrderItem>([
                SELECT Id
                  FROM OrderItem
                 WHERE Id IN: setOrderItemsIds
            ]);
            String salesCTVId = orderData.headerData.ctv_venda != null ? orderData.headerData.ctv_venda.Id : '';
            User user = [SELECT Id, SellerType__c FROM User WHERE Id =: salesCTVId];
            String sellerType = user.SellerType__c != null ? user.SellerType__c : '';

            Map<Id, Comissao__c> commissionByHierarchy = new Map<Id, Comissao__c>();
            if (sellerType != '') {
                for (Comissao__c commission : [
                    SELECT Id,
                           ProductHierarchy__c,
                           SellerType__c,
                           CommissionPercentage__c 
                    FROM Comissao__c
                   WHERE ProductHierarchy__c IN: setProductHierarchyIds
                     AND SellerType__c =: sellerType
                ]) {
                    if (!commissionByHierarchy.containsKey(commission.ProductHierarchy__c)) {
                        commissionByHierarchy.put(commission.ProductHierarchy__c, commission);
                    }
                }
            }
            System.debug('commissionByHierarchy => ' + commissionByHierarchy);
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

            order.AccountId = acc.Id;
            order.Status = 'Draft';
            order.PriceBook2Id = pricebookId;
            order.SalesCondition__c = orderData.headerData.condicao_venda.Id;
            order.Type = orderData.headerData.tipo_venda ;
            order.ShippingAccount__c = orderData.headerData.cliente_entrega.Id ;
            order.PaymentDate__c = Date.valueOf(orderData.headerData.data_pagamento) ;
            order.CustomerOrderNumber__c = orderData.headerData.numero_pedido_cliente ;
            order.EffectiveDate = newOrder ? Date.today() : order.EffectiveDate;
            order.Crop__c = orderData.headerData.safra.Id ;
            order.Culture__c = orderData.headerData.cultura.Id ;
            order.PaymentForm__c = orderData.headerData.forma_pagamento ;
            order.SalesOrg__c = company.SalesOrg__c;
            order.DistributionChannel__c = company.DistributionChannel__c ;
            order.ActivitySector__c = company.ActivitySector__c ;
            order.Currency__c = orderData.headerData.moeda ;
            order.SalesCTV__c = orderData.headerData.ctv_venda.Id ;
            order.StatusSF__c = orderData.headerData.status_pedido;
            order.Status = typeOrder == 'prepedido' ? '0' : '001';
            order.Incoterms__c = orderData.headerData.frete;
            order.Incoterms2__c = orderData.headerData.frete;
            order.Description = orderData.summaryData.observation;
            order.PaymentCondition__c = orderData.headerData.condicao_pagamento.Id;
            order.ShippingDate__c = Date.valueOf(orderData.headerData.data_entrega);
            order.DescriptionBillingSale__c = orderData.summaryData.billing_sale_observation;
            order.OrderReference__c = orderData.headerData.pedido_mae.Id;
            order.IsOrderMother__c = orderData.headerData.pedido_mae.Id != null ? false : Boolean.valueOf(orderData.headerData.pedido_mae_check);
            order.Hectare__c = orderData.headerData.hectares;
            order.FinalTotalValue__c = orderTotalValue;
            order.Company__c = company.Id;
            order.OrderType__c = orderData.headerData.pedido_mae.Id != null ? 'Pedido Filho' : (order.IsOrderMother__c ? 'Pedido Mãe' : 'Pedido Normal');
            order.OrderMargin__c = orderData.summaryData.orderMargin != null ? (orderData.summaryData.orderMargin.contains(' sacas') ?
                                     stringToDecimal(orderData.summaryData.orderMargin.replace(' sacas', '')) : stringToDecimal((orderData.summaryData.orderMargin))) : 0;

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
                        orderItem.PricebookEntryId = entriesByProductsIds.get(orderProduct.productId).Id;
                        orderItem.Product2Id = orderProduct.productId;
                        orderItem.ListPrice = entriesByProductsIds.get(orderProduct.productId).UnitPrice != null ? entriesByProductsIds.get(orderProduct.productId).UnitPrice.setScale(2) : 0;
                        orderItem.UnitPrice = orderProduct.unitPrice != null ? orderProduct.unitPrice.setScale(2) : 0;
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
                    orderItem.ListPrice__c = orderProduct.listPrice != null ? orderProduct.listPrice.setScale(2) : 0;
                    orderItem.PracticedPrice__c = orderProduct.unitPrice != null ? orderProduct.unitPrice.setScale(2) : 0;
                    orderItem.Dosage__c = orderProduct.dosage != null ? orderProduct.dosage.setScale(2) : 0;
                    orderItem.Status__c = orderProduct.sapStatus != null ? statusValueByLabel.get(orderProduct.sapStatus) : null;
                    orderItem.UnitMeasure__c = orderProduct.unity;
                    orderItem.FinalTotalValue__c = orderProduct.totalPrice;
                    orderItem.ListCost__c = orderProduct.listCost != null ? orderProduct.listCost.setScale(2) : 0;
                    orderItem.PracticedCost__c = orderProduct.practicedCost != null ? orderProduct.practicedCost.setScale(2) : 0;
                    orderItem.DiscountPercent__c = orderProduct.commercialDiscountPercentage != '' ? (stringToDecimal(orderProduct.commercialDiscountPercentage) != null ? stringToDecimal(orderProduct.commercialDiscountPercentage).setScale(2) : 0) : 0;
                    orderItem.DiscountValue__c = orderProduct.commercialDiscountValue != null ? orderProduct.commercialDiscountValue.setScale(2) : 0;
                    orderItem.CommercialAdditionPercent__c = orderProduct.commercialAdditionPercentage != '' ? (stringToDecimal(orderProduct.commercialAdditionPercentage) != null ? stringToDecimal(orderProduct.commercialAdditionPercentage).setScale(2) : 0) : 0;
                    orderItem.CommercialAdditionValue__c = orderProduct.commercialAdditionValue != null ? orderProduct.commercialAdditionValue.setScale(2) : 0;
                    orderItem.FinancialAdditionPercent__c = orderProduct.financialAdditionPercentage != '' ? (stringToDecimal(orderProduct.financialAdditionPercentage) != null ? stringToDecimal(orderProduct.financialAdditionPercentage).setScale(2) : 0) : 0;
                    orderItem.FinancialAdditionValue__c = orderProduct.financialAdditionValue != null ? orderProduct.financialAdditionValue.setScale(2) : 0;
                    orderItem.FinancialDiscountPercent__c = orderProduct.financialDecreasePercentage != '' ? (stringToDecimal(orderProduct.financialDecreasePercentage) != null ? stringToDecimal(orderProduct.financialDecreasePercentage).setScale(2) : 0) : 0;
                    orderItem.FinancialDiscountValue__c = orderProduct.financialDecreaseValue != null ? orderProduct.financialDecreaseValue.setScale(2) : 0;
                    orderItem.ComissionValue__c = orderProduct.comissionValue != null ? orderProduct.comissionValue.setScale(2) : 0;
                    orderItem.CommercialMargin__c = orderProduct.commercialMarginPercentage != null ? orderProduct.commercialMarginPercentage.setScale(2) : 0;
                    orderItem.PercentComission__c = orderProduct.productHierarchyId != null && orderProduct.productHierarchyId != '' ?
                                                    (commissionByHierarchy.get(orderProduct.productHierarchyId) != null ?
                                                        (commissionByHierarchy.get(orderProduct.productHierarchyId).CommissionPercentage__c != null ? commissionByHierarchy.get(orderProduct.productHierarchyId).CommissionPercentage__c : 0) :
                                                        0
                                                    ) :
                                                    0;
                    orderItem.ComissionValue__c = orderItem.PercentComission__c != 0 ? ((orderItem.FinalTotalValue__c * orderItem.PercentComission__c) / 100).setScale(2) : 0;
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
                List<ShippingDivison__c> listShippingDivision = new List<ShippingDivison__c>();
                if (orderData.divisionData != null && orderData.divisionData.size() > 0) {
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
                        mapOrderItems.put(key, orderItem.Id);
                    }

                    Map<String, DivisionDeserialize> divisionsByKey = new Map<String, DivisionDeserialize>();
                    for (DivisionDeserialize division : orderData.divisionData) {
                        if (division.divisionId != null) {
                            setDivisionIds.add(division.divisionId);
                        }

                        String key = division.deliveryDate + '-' + division.orderItemId;
                        if (divisionsByKey.containsKey(key)) {
                            DivisionDeserialize existingDivision = divisionsByKey.get(key);
                            existingDivision.quantity += division.quantity;
                            divisionsByKey.put(key, existingDivision);
                        } else {
                            divisionsByKey.put(key, division);
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

                    Map<Id, Decimal> quantityDistributedByItem = new Map<Id, Decimal>();
                    for (DivisionDeserialize division : divisionsByKey.values()) {
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
                } else if (order.OrderType__c != 'Pedido Mãe') {
                    for (OrderItem item : listOrderItems) {
                        ShippingDivison__c shippingDivision = new ShippingDivison__c();
                        shippingDivision.DeliveryDate__c = order.ShippingDate__c;
                        shippingDivision.Quantity__c = item.Quantity;
                        shippingDivision.OrderItem__c = item.Id;
                        listShippingDivision.add(shippingDivision);
                    }
                }

                if (listShippingDivision.size() > 0) {
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

                if (orderData.commodityData != null && orderData.commodityData.size() > 0) {
                    List<OrderCommodity__c> insCommodities = new List<OrderCommodity__c>();
                    for (CommodityDeserialize commodity : orderData.commodityData) {
                        OrderCommodity__c orderCommodity = new OrderCommodity__c();
                        orderCommodity.Name = commodity.product;
                        orderCommodity.BagQuantity__c = Decimal.valueOf(commodity.totalDelivery.replace(' sacas', ''));
                        orderCommodity.BagMargin__c = Decimal.valueOf(commodity.marginValue.replace(' sacas', ''));
                        orderCommodity.CommodityPrice__c = commodity.commodityPrice;
                        orderCommodity.Order__c = order.Id;
                        orderCommodity.Product__c = commodity.productId;
                        insCommodities.add(orderCommodity);
                    }
                    if (insCommodities.size() > 0) {
                        String commodityErrors = '';
                        List<Database.UpsertResult> insCommoditiesResults = Database.upsert(insCommodities, false);
                        for (Database.UpsertResult result : insCommoditiesResults){
                            if(!result.isSuccess()){
                                for (Database.error error: insResults.getErrors()){
                                    commodityErrors += '\n' + error.getMessage();
                                    msg = 'Pedido não pôde ser ' + (newOrder ? 'criado' : 'atualizado');
                                    return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg + commodityErrors));
                                }
                            } else {
                                itemsIds.add(result.getId());
                            }
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

    @AuraEnabled
    public static String getAccountCompanies(String data) {
        GetCompanyInfos companyInfos = (GetCompanyInfos) JSON.deserialize(data, GetCompanyInfos.class);
        Id userTerritoryId;
        for (UserTerritory2Association userAssociation : [
            SELECT Id,
                   UserId,
                   Territory2Id
              FROM UserTerritory2Association
             WHERE UserId =: companyInfos.ctvId
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

        Map<String, Integer> approvalLevels = new Map<String, Integer>{
            'GerenteFilial' => 1,
            'GerenteRegional' => 2,
            'Diretor' => 3
        };

        Integer counter = 0;
        Territory2 salesTeamTerritory;
        Map<Integer, Id> approvalByCounter = new Map<Integer, Id>();
        while (counter < companyInfos.approvalNumber) {
            Territory2 territory = territoryAndParents.containsKey(userTerritoryId) ? territoryAndParents.get(userTerritoryId) : new Territory2();

            if (territory != null && territory.ParentTerritory2Id != null) {
                userTerritoryId = territory.Id;
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

        List<CompanyInfos> companyList = new List<CompanyInfos>();
        if (salesTeamTerritory != null && salesTeamTerritory.DeveloperName != null) {
            String salesTeamDevName = salesTeamTerritory.DeveloperName.substring(0, 1) == 'X' ? salesTeamTerritory.DeveloperName.substring(1, salesTeamTerritory.DeveloperName.length()) : salesTeamTerritory.DeveloperName;
            for (Company__c salesTeamCompany : [
                SELECT Id,
                       SalesOrg__c,
                       SalesTeam__r.Name,
                       SalesOffice__c,
                       SupplierCenter__c,
                       ActivitySector__c,
                       ActivitySector__r.Name,
                       DistributionChannel__c,
                       DistributionChannel__r.Name
                  FROM Company__c
                 WHERE Conta__c =: companyInfos.accountId
                   AND SalesTeam__r.ExternalId__c =: salesTeamDevName
            ]) {
                CompanyInfos company = new CompanyInfos();
                company.companyId = salesTeamCompany.Id;
                company.salesOrgId = salesTeamCompany.SalesOrg__c;
                company.salesTeamId = salesTeamCompany.SalesTeam__c;
                company.salesOfficeId = salesTeamCompany.SalesOffice__c;
                company.salesTeamName = salesTeamCompany.SalesTeam__r.Name;
                company.supplierCenter = salesTeamCompany.SupplierCenter__c;
                company.activitySectorId = salesTeamCompany.ActivitySector__c;
                company.activitySectorName = salesTeamCompany.ActivitySector__r.Name;
                company.distributionChannelId = salesTeamCompany.DistributionChannel__c;
                company.distributionChannelName = salesTeamCompany.DistributionChannel__r.Name;
                company.selected = false;
                companyList.add(company);
            }
        }
        return JSON.serialize(new CompanyInfosSerialize(companyList));
    }

    @AuraEnabled
    public static String getFinancialInfos(String data) {
        FinancialResult result = new FinancialResult();
        OrderDataDeserialize orderValues = (OrderDataDeserialize) JSON.deserialize(data, OrderDataDeserialize.class);
        
        Date safraPaymentDate;
        for (Safra__c safra : [
            SELECT Id,
                   PaymentBaseDate__c
              FROM Safra__c
             WHERE Id =: orderValues.safra
        ]) {
            safraPaymentDate = safra.PaymentBaseDate__c;
        }

        result.dayDifference = safraPaymentDate.daysBetween(Date.valueOf(orderValues.paymentDate));
        if (result.dayDifference == 0) result.correctPayment = true;
        else if (result.dayDifference > 0) result.isDiscount = false;
        else result.isDiscount = true;

        result.correctPayment = Date.valueOf(orderValues.paymentDate) == safraPaymentDate ? true : false;
        result.isDiscount = Date.valueOf(orderValues.paymentDate) > safraPaymentDate ? false : true;
        Id discountOrAdditionRecType = result.isDiscount ? Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZDAN').getRecordTypeId()
                                                         : Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZJUR').getRecordTypeId();
        
        result.salesOrg = orderValues.salesOrg;
        result.salesOffice = orderValues.salesOffice;
        result.salesTeam = orderValues.salesTeam;
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
        ]) {
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
                                 BillingStartDate__c,
                                 EndDateBilling__c,
                                 NumberOfDaysAfterPayment__c
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
             WHERE Id =: orderData.headerData.companyId
        ]) {
            company = accountCompany;
        }

        Decimal orderTotalValue = 0;
        Decimal biggerDiscount = 0;
        Id productGroupId;
       
        Set<Id> setProductGroups = new Set<Id>();
        for (ProductDeserialize orderProduct : orderData.productData) {
            orderTotalValue += orderProduct.totalPrice;

            Decimal currentDiscount = orderProduct.commercialDiscountPercentage != '' ? (stringToDecimal(orderProduct.commercialDiscountPercentage) != null ? stringToDecimal(orderProduct.commercialDiscountPercentage).setScale(2) : 0) : 0;
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
        public List<CommodityDeserialize> commodityData;
        public SummaryDeserialize summaryData;
    }

    public class AccountDeserialize {
        public String Id;
        public String Name;
    }

    public class HeaderDeserialize {
        public String  Id;
        public String  AccountId;
        public String  tipo_venda;
        public String  numero_pedido_cliente;
        public String  data_pagamento;
        public String  data_entrega;
        public String  status_pedido;
        public String  tipo_pedido;
        public String  codigo_sap;
        public String  canal_distribuicao;
        public String  setor_atividade;
        public String  forma_pagamento;
        public String  moeda;
        public String  frete;
        public String  observation;
        public String  billing_sale_observation;
        public String  orderMargin;
        public String  companyId;
        public Boolean pedido_mae_check;
        public Boolean pre_pedido;
        public Boolean firstTime;
        public Decimal hectares;
        public AccountSerialize  cliente_entrega;
        public InformationFields safra;
        public InformationFields cultura;
        public InformationFields condicao_venda;
        public InformationFields condicao_pagamento;
        public InformationFields organizacao_vendas;
        public InformationFields ctv_venda;
        public InformationFields pedido_mae;
        //public InformationFields filial;
        //public String cliente_faturamento;
    }

    public class ProductDeserialize{
        public String  orderItemId;
        public String  productId;
        public String  name;
        public String  entryId;
        public String  sapProductCode;
        public String  sapStatus;
        public String  unity;
        public String  activePrinciple;
        public String  productGroupId;
        public String  productHierarchyId;
        public String  productGroupName;
        public String  productSubgroupId;
        public String  productSubgroupName;
        public String  commercialDiscountPercentage;
        public String  commercialAdditionPercentage;
        public String  financialAdditionPercentage;
        public String  financialDecreasePercentage;
        public Integer position;
        public Decimal invoicedQuantity;
        public Decimal motherAvailableQuantity;
        public Decimal quantity;
        public Decimal listPrice;
        public Decimal listCost;
        public Decimal practicedCost;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Decimal dosage;
        public Decimal commercialDiscountValue;
        public Decimal commercialAdditionValue;
        public Decimal financialAdditionValue;
        public Decimal financialDecreaseValue;
        public Decimal commercialMarginPercentage;
        public Decimal comissionValue;
    }

    public class DivisionDeserialize{
        public String  divisionId;
        public String  deliveryDate;
        public String  deliveryId;
        public String  quantityId;
        public String  externalId;
        public String  orderItemId;
        public String  orderItemKey;
        public Decimal confirmedQuantity;
        public Decimal quantity;
        public Integer productPosition;
        public Boolean showInfos;
    }

    public class CommodityDeserialize {
        public String  product;
        public String  productId;
        public String  desage;
        public String  area;
        public String  discount;
        public String  margin;
        public String  marginValue;
        public String  totalDelivery;
        public Decimal quantity;
        public Decimal commodityPrice;
        public Boolean saved;
    }

    public class SummaryDeserialize{
        public String observation;
        public String billing_sale_observation;
        public String orderMargin;
    }

    public class SummarySerialize{
        public String observation;
        public String billing_sale_observation;
        public String orderMargin;

        public SummarySerialize(){}
        public SummarySerialize(String observation, String billing_sale_observation){
            this.observation = observation;
            this.billing_sale_observation = billing_sale_observation;
            this.orderMargin = orderMargin;
        }
    }


    //Classe para serialização
    public class OrderSerialize{
        public HeaderSerialize headerData;
        public AccountSerialize accountData;
        public List<ProductSerialize> productData;
        public List<DivisionSerialize> divisionData;

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
        public String  Id;
        public String  AccountId;
        public String  tipo_venda;
        public String  filial;
        public String  numero_pedido_cliente;
        public String  data_pagamento;
        public String  data_entrega;
        public String  status_pedido;
        public String  tipo_pedido;
        public String  codigo_sap;
        public String  cliente_faturamento;
        public String  canal_distribuicao;
        public String  setor_atividade;
        public String  forma_pagamento;
        public String  moeda;
        public String  frete;
        public String  observation;
        public String  billing_sale_observation;
        public String  orderMargin;
        public String  companyId;
        public Boolean pedido_mae_check;
        public Boolean pre_pedido;
        public Boolean firstTime;
        public Decimal hectares;
        public InformationFields safra;
        public InformationFields cultura;
        public InformationFields condicao_venda;
        public InformationFields condicao_pagamento;
        public InformationFields ctv_venda;
        public InformationFields pedido_mae;
        public InformationFields organizacao_vendas;
        public AccountSerialize  cliente_entrega;
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

            this.condicao_venda = new InformationFields(order.SalesCondition__c, order.SalesCondition__r.Name);
            this.data_pagamento = String.valueOf(order.PaymentDate__c);
            this.data_entrega = String.valueOf(order.ShippingDate__c);
            this.numero_pedido_cliente = order.CustomerOrderNumber__c;
            this.safra = new InformationFields(order.Crop__c, order.Crop__r.Name);
            this.cultura = new InformationFields(order.Culture__c, order.Culture__r.Name);
            this.forma_pagamento = order.PaymentForm__c;
            this.status_pedido = order.StatusSF__c;
            this.pre_pedido = order.Status == '0' ? true : false;
            this.firstTime = true;
            this.tipo_pedido = order.OrderType__c;
            this.codigo_sap = order.CodigoSAP__c;
            this.organizacao_vendas = new InformationFields(order.SalesOrg__c, order.SalesOrg__r.Name);
            this.canal_distribuicao = order.DistributionChannel__c;
            this.setor_atividade = order.ActivitySector__c;
            this.moeda = order.Currency__c;
            this.ctv_venda = new InformationFields(order.SalesCTV__c,  order.SalesCTV__r.Name);
            this.pedido_mae = new InformationFields(order.OrderReference__c, order.OrderReference__r.Name);
            this.pedido_mae_check = order.IsOrderMother__c;
            this.hectares = order.Hectare__c;
            this.condicao_pagamento = new InformationFields(order.PaymentCondition__c, order.PaymentCondition__r.Name);
            this.frete = order.Incoterms__c;
            this.observation = order.Description;
            this.billing_sale_observation = order.DescriptionBillingSale__c;
            this.orderMargin = String.valueOf(order.OrderMargin__c) + '%';
            this.companyId = order.Company__c;
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
        public Date    serviceDate;
        public String  orderId;
        public String  orderItemId;
        public String  productId;
        public String  name;
        public String  sapProductCode;
        public String  entryId;
        public String  sapStatus;
        public String  unity;
        public String  activePrinciple;
        public String  productGroupId;
        public String  productHierarchyId;
        public String  productGroupName;
        public String  productSubgroupId;
        public String  productSubgroupName;
        public String  commercialDiscountPercentage;
        public String  commercialAdditionPercentage;
        public String  financialAdditionPercentage;
        public String  financialDecreasePercentage;
        public Integer position;
        public Decimal multiplicity;
        public Decimal invoicedQuantity;
        public Decimal quantity;
        public Decimal motherAvailableQuantity;
        public Decimal listPrice;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Decimal listCost;
        public Decimal practicedCost;
        public Decimal dosage;
        public Decimal commercialDiscountValue;
        public Decimal commercialAdditionValue;
        public Decimal financialAdditionValue;
        public Decimal financialDecreaseValue;
        public Decimal commercialMarginPercentage;
        public Decimal comissionValue;

        ProductSerialize(){}

        ProductSerialize(OrderItem orderItem, Integer position, Boolean cloneOrder){
            this.position = position;
            this.orderItemId = orderItem.Id;
            this.productId = orderItem.Product2Id;
            this.name = orderItem.Product2.Name;
            this.sapProductCode = orderItem.Product2.ExternalId__c;
            this.multiplicity = orderItem.Product2.Multiplicity__c;
            this.activePrinciple = orderItem.Product2.PrincipleActive__c;
            this.productGroupId = orderItem.Product2.ProductGroup__c;
            this.productHierarchyId = orderItem.Product2.ProductHierarchy__c;
            this.productGroupName = orderItem.Product2.ProductGroup__r.Name;
            this.productSubgroupId = orderItem.Product2.ProductSubgroup__c;
            this.productSubgroupName = orderItem.Product2.ProductSubgroup__r.Name;
            this.entryId = orderItem.PricebookEntryId;
            this.orderId = OrderId;
            this.serviceDate = orderItem.ServiceDate;
            this.quantity = !cloneOrder ? (orderItem.AmountUsed__c != 0 && orderItem.AmountUsed__c != null ? orderItem.Quantity - orderItem.AmountUsed__c : orderItem.Quantity) : orderItem.Quantity;
            this.invoicedQuantity = orderItem.InvoicedQuantity__c;
            this.motherAvailableQuantity = orderItem.AmountUsed__c != null ? orderItem.Quantity - orderItem.AmountUsed__c : null;
            this.listPrice = orderItem.ListPrice__c;
            this.unitPrice = orderItem.UnitPrice;
            this.totalPrice = orderItem.FinalTotalValue__c;
            this.listCost = orderItem.ListCost__c;
            this.practicedCost = orderItem.PracticedCost__c;
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
        public String  divisionId;
        public String  deliveryDate;
        public String  deliveryId;
        public String  quantityId;
        public String  externalId;
        public String  orderItemId;
        public String  orderItemKey;
        public Boolean showInfos;
        public Integer productPosition;
        public Decimal confirmedQuantity;
        public Decimal quantity;

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
        public String paymentDate;
        public String endDateBilling;
    }

    public class SafraDataSerialize {
        public String initialDate;
        public String endDate;
        public String paymentDate;
        public String endDateBilling;

        SafraDataSerialize() {}

        SafraDataSerialize(Safra__c safra) {
            this.initialDate = String.valueOf(safra.BillingStartDate__c);
            this.endDate = String.valueOf(safra.EndDateBilling__c);
            this.paymentDate = String.valueOf(safra.NumberOfDaysAfterPayment__c);
            this.endDateBilling = String.valueOf(safra.EndDateBilling__c);
        }
    }

    public class OrderDataDeserialize {
        public String paymentDate;
        public String salesOrg;
        public String salesOffice;
        public String salesTeam;
        public String safra;
        public String culture;
    }

    public class FinancialResult {
        public String  salesOrg;
        public String  salesOffice;
        public String  salesTeam;
        public Integer dayDifference;
        public Boolean isDiscount;
        public Boolean correctPayment;
        public Map<String, Decimal> financialValues;
    }

    public class FinancialResultSerialize {
        public String  salesOrg;
        public String  salesOffice;
        public String  salesTeam;
        public Integer dayDifference;
        public Boolean isDiscount;
        public Boolean correctPayment;
        public Map<String, Decimal> financialValues;

        FinancialResultSerialize() {}

        FinancialResultSerialize(FinancialResult financialResult) {
            this.salesOrg = financialResult.salesOrg;
            this.salesOffice = financialResult.salesOffice;
            this.salesTeam = financialResult.salesTeam;
            this.dayDifference = financialResult.dayDifference;
            this.isDiscount = financialResult.isDiscount;
            this.correctPayment = financialResult.correctPayment;
            this.financialValues = financialResult.financialValues;
        }
    }

    public class GetCompanyInfos {
        public String  ctvId;
        public String  accountId;
        public Integer approvalNumber;
    }

    public class CompanyInfos {
        public String  companyId;
        public String  salesOrgId;
        public String  salesTeamId;
        public String  salesOfficeId;
        public String  salesTeamName;
        public String  supplierCenter;
        public String  activitySectorId;
        public String  activitySectorName;
        public String  distributionChannelId;
        public String  distributionChannelName;
        public Boolean selected;
    }

    public class CompanyInfosSerialize {
        public List<CompanyInfos> listCompanyInfos;

        CompanyInfosSerialize() {}

        CompanyInfosSerialize(List<CompanyInfos> companyInfos) {
            this.listCompanyInfos = companyInfos;
        }
    }
}