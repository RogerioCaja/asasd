public without sharing class OrderScreenController {
    public static Map<Id, Integer> orderItemsPosition;
    public static Decimal totalCost;
    public static Decimal totalDiscount;
    public static Decimal totalQuantity;

    @AuraEnabled
    public static String getOrder(String recordId, Boolean cloneOrder, Boolean checkQuantities) {
        HeaderSerialize order;
        AccountSerialize account;
        List<ProductSerialize> ordItemList = new List<ProductSerialize>();
        List<DivisionSerialize> divisionList = new List<DivisionSerialize>();
        List<CommoditySerialize> commodityList = new List<CommoditySerialize>();
        List<FormOfPaymentSerialize> formsOfPayment = new List<FormOfPaymentSerialize>();
        
        order = getOrderData(recordId, cloneOrder);
        if (order.condicao_venda != null) {
            ordItemList = getOrderItemData(order.Id, cloneOrder);
            divisionList = getShippingDivison();
        }

        if (order.recTypeId == Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('VendaBarter').getRecordTypeId()) {
            commodityList = getCommodityData(order.Id);
        }
        account = getOrderAccountData(order.AccountId);
        formsOfPayment = getFormsOfPayment(order.Id);

        return JSON.serialize(new OrderSerialize(order, ordItemList, divisionList, account, commodityList, formsOfPayment));
    }

    @AuraEnabled
    public static String getOrderByOrderItem(String recordId){
        String orderId = getOrderId(recordId);
        return getOrder(orderId, false, false);
    }

    @AuraEnabled 
    public static String getOrderByFormOfPayment(String recordId){
        String orderId = [SELECT Order__c FROM FormPayment__c WHERE Id =: recordId LIMIT 1].Order__c;
        return orderId;
    }

    public static String getOrderId(String recordId){
        String orderId = [SELECT OrderId FROM OrderItem WHERE Id =: recordId].OrderId;
        return orderId;
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
        Order order = [SELECT Id, OrderNumber, Description, DescriptionBillingSale__c, AccountId, Type, ShippingAccount__c , ShippingAccount__r.Phone,  ShippingAccount__r.Name, 
        ShippingAccount__r.BillingCity, ShippingAccount__r.BillingState ,ShippingAccount__r.CPF__c, ShippingAccount__r.CNPJ__c , SalesCondition__c, SalesCondition__r.Name, FreightValue__c,
        Pricebook2.InitialDate__c, Pricebook2.EndDate__c, PaymentDate__c,  CustomerOrderNumber__c, Crop__c , Crop__r.Name, Culture__c , Culture__r.Name, OrderMargin__c, RecordTypeId,
        PaymentForm__c, StatusSF__c, CodigoSAP__c, SalesOrg__c, SalesOrg__r.Name, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c, SalesCTV__r.Name, OrderType__c,
        PaymentCondition__c, PaymentCondition__r.Name, ShippingDate__c, Incoterms__c, OrderReference__c, OrderReference__r.Name, IsOrderMother__c, Company__c, Hectare__c, Status, DistributionCenter__c
        FROM Order 
        WHERE Id = :orderId LIMIT 1];
        return new HeaderSerialize(order, cloneOrder);
    }

    public static List<ProductSerialize> getOrderItemData(Id orderId, Boolean cloneOrder) {
        List<ProductSerialize> prods = new List<ProductSerialize>();
        orderItemsPosition = new Map<Id, Integer>();
        totalCost = 0;
        totalDiscount = 0;
        totalQuantity = 0;
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
                   PracticedPrice__c,
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
                   AmountUsed__c,
                   PTA__c,
                   PriceListCode__c,
                   ReasonRefuse__c,
                   Sieve__c,
                   Class__c
              FROM OrderItem
             WHERE OrderId =: orderId
        ]){
            if (item.ReasonRefuse__c == null || item.ReasonRefuse__c == '') {
                Decimal itemPracticedCost = item.PracticedCost__c != null ? item.PracticedCost__c : 0;
                Decimal itemDiscount = item.DiscountValue__c != null ? item.DiscountValue__c : 0;
                totalCost += itemPracticedCost * item.Quantity;
                totalDiscount += itemDiscount;
                totalQuantity += item.Quantity;
                prods.add(new ProductSerialize(item, counter, cloneOrder));
                orderItemsPosition.put(item.Id, counter);
                counter++;
            }
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

    public static List<CommoditySerialize> getCommodityData(Id orderId) {
        List<CommoditySerialize> commodities = new List<CommoditySerialize>();
        for (OrderCommodity__c orderCommodity : [
            SELECT Id,
                   Name,
                   BagQuantity__c,
                   BagMargin__c,
                   CommodityPrice__c,
                   Order__c,
                   Order__r.Hectare__c,
                   Order__r.FinalTotalValue__c,
                   Product__c,
                   Product__r.Name,
                   StartDate__c,
                   EndDate__c
              FROM OrderCommodity__c
             WHERE Order__c =: orderId
        ]) {
            commodities.add(new CommoditySerialize(orderCommodity));
        }

        return commodities;
    }

    public static List<FormOfPaymentSerialize> getFormsOfPayment(Id orderId) {
        List<FormOfPaymentSerialize> payments = new List<FormOfPaymentSerialize>();
        Integer counter = 1;
        
        for (FormPayment__c payment : [
            SELECT Id,
                   PaymentDate__c,
                   PaymentType__c,
                   Amount__c
              FROM FormPayment__c
             WHERE Order__c =: orderId
        ]) {
            payments.add(new FormOfPaymentSerialize(payment, counter));
            counter++;
        }
        return payments;
    }

    public static AccountSerialize getOrderAccountData(Id accountId) {
        Account account = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE Id =: accountId LIMIT 1];
        return new AccountSerialize(account);
    }

    @AuraEnabled
    public static string getAccountDataChild(Id accountId){
        try {
            List<Account> accountList = new List<Account>();
            List<AccountSerialize> accountListSerialize = new List<AccountSerialize>();
            List<SObject> recordsData = new List<SObject>();
            Set<Id> familyAccountIds = new Set<Id>();
			String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;

            familyAccountIds.add(accountId);
            for (Account familyAccount : [
                SELECT Id
                  FROM Account
                 WHERE ParentId =: accountId
                   AND ExternalId__c LIKE '0001%'
                   AND Status__c = 'Ativo'
            ]) {
                familyAccountIds.add(familyAccount.Id);
            }
			
            if (profileName != 'Balcão') {
                Set<Id> relatedAccounts = getTerritoryAccounts();
                accountList = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE Status__c = 'Ativo' AND ((ParentId =: accountId AND Id IN: relatedAccounts AND ExternalId__c LIKE '0002%') OR (Id =: accountId AND CNPJ__c != null AND CPF__c = null) OR (ParentId IN: familyAccountIds AND ExternalId__c LIKE '0002%' AND Id IN: relatedAccounts))];
            } else {
                accountList = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE Status__c = 'Ativo' AND ((ParentId =: accountId AND ExternalId__c LIKE '0002%') OR (Id =: accountId AND CNPJ__c != null AND CPF__c = null) OR ((ParentId IN: familyAccountIds AND ExternalId__c LIKE '0002%')))];
            }

            for(Account account : accountList) accountListSerialize.add(new AccountSerialize(account));
            return JSON.serialize(new AccountSerialize(accountListSerialize));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Set<Id> getTerritoryAccounts() {
        try {
            Id sellerTerritoryId;
            String userTerritoryType = '';
            Set<Id> userTerritories = new Set<Id>();
            List<String> territoryTypes = new List<String>{'Torre', 'SalesOrg', 'SalesOffice', 'SalesTeam', 'SellerPosition'};

            for (UserTerritory2Association userAssociation : [
                SELECT Id,
                       Territory2Id,
                       Territory2.Territory2Type.DeveloperName
                  FROM UserTerritory2Association
                 WHERE UserId =: UserInfo.getUserId()
            ]) {
				if (userAssociation.Territory2.Territory2Type.DeveloperName == 'SellerPosition') {
                    sellerTerritoryId = userAssociation.Territory2Id;
                }

                userTerritories.add(userAssociation.Territory2Id);
                userTerritoryType = territoryTypes.indexOf(userAssociation.Territory2.Territory2Type.DeveloperName) > territoryTypes.indexOf(userTerritoryType) &&
                                    territoryTypes.indexOf(userTerritoryType) > -1 ? userTerritoryType : userAssociation.Territory2.Territory2Type.DeveloperName;
            }

            Set<Id> relatedTerritories = new Set<Id>();
			String territoryQuery = 'SELECT Id, Territory2Type.DeveloperName FROM Territory2 ';
			if (userTerritoryType == 'Torre') territoryQuery += 'WHERE ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id IN: userTerritories';
			else if (userTerritoryType == 'SalesOrg') territoryQuery += 'WHERE ParentTerritory2.ParentTerritory2.ParentTerritory2Id IN: userTerritories';
			else if (userTerritoryType == 'SalesOffice') territoryQuery += 'WHERE ParentTerritory2.ParentTerritory2Id IN: userTerritories';
			else if (userTerritoryType == 'SalesTeam') territoryQuery += 'WHERE ParentTerritory2Id IN: userTerritories';
			else if (userTerritoryType == 'SellerPosition') territoryQuery += 'WHERE Id =: sellerTerritoryId';
			else territoryQuery += 'WHERE Id = null';
			
			for(SObject sobj : Database.query(territoryQuery)) {
				relatedTerritories.add((Id)sobj.get('Id'));
			}

			Set<Id> relatedAccounts = new Set<Id>();
			for (ObjectTerritory2Association associatedAccount : [
				SELECT Id,
				       SobjectType,
					   ObjectId
				  FROM ObjectTerritory2Association
				 WHERE Territory2Id IN: relatedTerritories
			]) {
				if (associatedAccount.SobjectType == 'Account') {
					relatedAccounts.add(associatedAccount.ObjectId);
				}
			}

            return relatedAccounts;
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
    public static String checkQuotaQuantity(String data){
        QuotaData quotaData = (QuotaData) JSON.deserialize(data, QuotaData.class);
        List<QuotaResult> result = new List<QuotaResult>();
        for (IndividualQuotas__c individualQuota : [
            SELECT Id,
                   Balance__c,
                   Consumed__c,
                   Cultivate__c,
                   Cultivate__r.Name,
                   GeneralQuotas__c,
                   GeneralQuotas__r.Balance__c
              FROM IndividualQuotas__c
             WHERE Crop__c =: quotaData.cropId
               AND Seller__c =: quotaData.sellerId
               AND Cultivate__c IN: quotaData.productsIds
        ]) {
            QuotaResult quota = new QuotaResult();
            quota.productId = individualQuota.Cultivate__c;
            quota.productName = individualQuota.Cultivate__r.Name;
            quota.generalQuotaId = individualQuota.GeneralQuotas__c;
            quota.individualQuotaId = individualQuota.Id;
            quota.balance = individualQuota.Balance__c;
            quota.generalBalance = individualQuota.GeneralQuotas__r.Balance__c;
            quota.consumed = individualQuota.Consumed__c;
            result.add(quota);
        }

        return JSON.serialize(result);
    }

    public static QuantitiesResult checkItemQuota(QuotaData quotaData, Map<String, Decimal> quantitiesById) {
        QuantitiesResult result = new QuantitiesResult();
        System.debug('quotaData: ' + quotaData);
        String data = checkQuotaQuantity(JSON.serialize(quotaData));
        List<QuotaResult> quotaResult = (List<QuotaResult>) JSON.deserialize(data, List<QuotaResult>.class);

        Set<Id> generalQuotasIds = new Set<Id>();
        Set<Id> individualQuotasIds = new Set<Id>();
        for (QuotaResult getIds : quotaResult) {
            generalQuotasIds.add(getIds.generalQuotaId);
            individualQuotasIds.add(getIds.individualQuotaId);
        }

        System.debug('generalQuotasIds: ' + generalQuotasIds);
        Map<Id, GeneralQuotas__c> generalQuotasById = new Map<Id, GeneralQuotas__c>([
            SELECT Id, Balance__c, Consumed__c
              FROM GeneralQuotas__c
             WHERE Id IN: generalQuotasIds
        ]);

        System.debug('individualQuotasIds: ' + individualQuotasIds);
        Map<Id, IndividualQuotas__c> individualQuotasById = new Map<Id, IndividualQuotas__c>([
            SELECT Id, Balance__c, Consumed__c
              FROM IndividualQuotas__c
             WHERE Id IN: individualQuotasIds
        ]);
        
        for (QuotaResult quota : quotaResult) {
            System.debug('quota: ' + quota);
            Decimal productQuantity = quantitiesById.get(quota.productId);
            System.debug('productQuantity: ' + productQuantity);
            
            if (productQuantity > quota.balance || productQuantity > quota.generalBalance) {
                result.hasQuota = false;
                result.invalidProductsNames = result.invalidProductsNames != '' ? result.invalidProductsNames + ', ' + quota.productName : quota.productName;
            } else {
                GeneralQuotas__c generalQuota = generalQuotasById.get(quota.generalQuotaId);
                System.debug('generalQuota: ' + generalQuota);
                generalQuota.Balance__c = generalQuota.Balance__c - productQuantity;
                generalQuota.Consumed__c = generalQuota.Consumed__c + productQuantity;
                System.debug('generalQuota: ' + generalQuota);
                result.generalQuotasToUpdate.add(generalQuota);

                IndividualQuotas__c individualQuota = individualQuotasById.get(quota.individualQuotaId);
                System.debug('individualQuota: ' + individualQuota);
                individualQuota.Balance__c = individualQuota.Balance__c - productQuantity;
                individualQuota.Consumed__c = individualQuota.Consumed__c + productQuantity;
                System.debug('individualQuota: ' + individualQuota);
                result.individualQuotasToUpdate.add(individualQuota);

                result.individualQuotasByProdId.put(quota.productId, quota.individualQuotaId);
            }
        }

        return result;
    }

    @AuraEnabled
    public static String saveOrder(Id orderId, Boolean cloneOrder, String data, String typeOrder, String itemsToExclude) {
        Savepoint sp = Database.setSavepoint();
        try {
            Order order;
            String msg;
            Boolean newOrder = true;
            System.debug('data: ' + data);
            OrderDeserialize orderData = (OrderDeserialize) JSON.deserialize(data, OrderDeserialize.class);
            
            if (orderId != null && !cloneOrder) {
                newOrder = false;
                order = [SELECT Id, Description, DescriptionBillingSale__c, AccountId, Type, ShippingAccount__c, SalesCondition__c, PaymentDate__c, ShippingDate__c, PaymentCondition__c, CustomerOrderNumber__c, OrderType__c, OrderReference__c,
                                Crop__c, Culture__c, PaymentForm__c, StatusSF__c, SalesOrg__c, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c, EffectiveDate, Company__c, Hectare__c, OrderMargin__c, Status, FreightValue__c
                FROM Order WHERE Id =: orderId LIMIT 1];
            } else {
                order = new Order();
                order.OwnerId = orderData.headerData.ctv_venda.Id;
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

            Map<Id, OrderItem> motherItems = new Map<Id, OrderItem>();
            Boolean newDivision = false;
            if (orderData.headerData.pedido_mae.Id != null || order.OrderReference__c != null) {
                for (OrderItem item : [
                    SELECT Id,
                           Product2Id,
                           Quantity,
                           AmountUsed__c,
                           NumeroSap__c
                      FROM OrderItem
                     WHERE OrderId =: orderData.headerData.pedido_mae.Id
                        OR OrderId =: order.OrderReference__c
                ]) {
                    motherItems.put(item.Product2Id, item);
                }
                newDivision = newOrder ? true : false;
            }
    
            Decimal orderTotalValue = 0;
            Decimal biggerDiscount = 0;
            Id productGroupId;
            Set<Id> setOrderItemsIds = new Set<Id>();
            List<Id> listProductsIds = new List<Id>();
            Set<Id> setProductHierarchyIds = new Set<Id>();
            Map<String, Decimal> quantitiesById = new Map<String, Decimal>();
            Map<String, Decimal> smallerMarginByProductGroup = new Map<String, Decimal>();
            for (ProductDeserialize orderProduct : orderData.productData) {
                orderTotalValue += orderProduct.totalPrice;
                if (orderProduct.orderItemId != null) {
                    setOrderItemsIds.add(orderProduct.orderItemId);
                }

                if (orderProduct.productId != null) {
                    listProductsIds.add(orderProduct.productId);
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

                Decimal currentDiscount = orderProduct.commercialDiscountPercentage != '' ? (stringToDecimal(orderProduct.commercialDiscountPercentage) != null ? stringToDecimal(orderProduct.commercialDiscountPercentage) : 0) : 0;
                if (biggerDiscount < currentDiscount) {
                    biggerDiscount = currentDiscount;
                    productGroupId = orderProduct.productGroupId;
                }

                if (order.OrderReference__c != null && motherItems.containsKey(orderProduct.productId) && order.Status == '0' && typeOrder != 'prepedido') {
                    OrderItem motherItem = motherItems.get(orderProduct.productId);
                    if (motherItem.AmountUsed__c + orderProduct.quantity > motherItem.Quantity) {
                        return JSON.serializePretty(new AGRO_RemotingResult(true, '200', 'Não é possível efetivar o pedido por ter excedido as quantidades do pedido mãe.'));
                    }
                }

                quantitiesById.put(orderProduct.productId, orderProduct.quantity);
            }

            Boolean seedSale = isSeedSale(company.SalesOrg__c, null);
            QuantitiesResult quantitiesResult;
            if (seedSale) {
                QuotaData quotaData = new QuotaData();
                quotaData.cropId = orderData.headerData.safra.Id;
                quotaData.sellerId = orderData.headerData.ctv_venda.Id;
                quotaData.productsIds = new List<String>();
                quotaData.productsIds.addAll(listProductsIds);
                
                quantitiesResult = new QuantitiesResult();
                quantitiesResult = checkItemQuota(quotaData, quantitiesById);
                System.debug('quantitiesResult: ' + quantitiesResult);
                if (!quantitiesResult.hasQuota) {
                    return JSON.serializePretty(new AGRO_RemotingResult(true, '200', 'Quantidade indisponível no(s) produto(s) ' + quantitiesResult.invalidProductsNames + '.'));
                }
            }

            Map<String, Decimal> orderMarginMap = new Map<String, Decimal>();
            if (orderData.headerData.pedido_mae.Id == null && company != null && company.ClientGroup__c != null) {
                for (Discount__c discount : [
                    SELECT Id,
                           Margin__c,
                           ProductGroup__c
                      FROM Discount__c
                     WHERE Status__c = 'Aprovado'
                       AND Approver__c = 'ComiteMargem'
                       AND ClientGroup__c =: company.ClientGroup__c
                       AND SalesOrg__c =: company.SalesOrg__c
                       AND ProductGroup__c IN: smallerMarginByProductGroup.keySet()
                       AND InitialDate__c <=: System.today()
                       AND EndDate__c >=: System.today()
                  ORDER BY Margin__c
                ]) {
                    orderMarginMap.put(discount.ProductGroup__c, discount.Margin__c);
                }
            }

            order.MarginCommittee__c = false;
            for (String groupId : smallerMarginByProductGroup.keySet()) {
                if (orderMarginMap.get(groupId) >= smallerMarginByProductGroup.get(groupId)) {
                    order.MarginCommittee__c = true;
                }
            }

            Map<Id, PricebookEntry> entriesByProductsIds = new Map<Id, PricebookEntry>();
            Id pricebookId;
            if (Test.isRunningTest()) {
                for (PricebookEntry entry : [
                    SELECT Id,
                           Product2Id,
                           Pricebook2Id,
                           UnitPrice
                      FROM PricebookEntry
                     WHERE Product2Id IN: listProductsIds
                ]) {
                    pricebookId = entry.Pricebook2Id;
                    entriesByProductsIds.put(entry.Product2Id, entry);
                }
            } else {
                for (PricebookEntry entry : [
                    SELECT Id,
                           Product2Id,
                           Pricebook2Id,
                           UnitPrice
                      FROM PricebookEntry
                     WHERE Pricebook2.IsStandard = true
                       AND Product2Id IN: listProductsIds
                ]) {
                    pricebookId = entry.Pricebook2Id;
                    entriesByProductsIds.put(entry.Product2Id, entry);
                }
            }
            
            List<String> deleteItems = itemsToExclude != null ? (List<String>) JSON.deserialize(itemsToExclude, List<String>.class) : new List<String>();
            Map<Id, OrderItem> orderItemsById = new Map<Id, OrderItem>([
                SELECT Id, Product2Id, OrderId
                  FROM OrderItem
                 WHERE Id IN: setOrderItemsIds
                    OR Id IN: deleteItems
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
                       AND SalesOrg__c =: company.SalesOrg__c
                ]) {
                    if (!commissionByHierarchy.containsKey(commission.ProductHierarchy__c)) {
                        commissionByHierarchy.put(commission.ProductHierarchy__c, commission);
                    }
                }
            }

            if (company != null && orderData.headerData.pedido_mae.Id == null) {
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
                       AND SalesOrg__c =: company.SalesOrg__c
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

                order.ApprovalBranchManager__c = null;
                order.Manager_BranchOffice__c = false;
                order.ApprovalRegionalManager__c = null;
                order.Gerente_Regional__c = false;
                order.ApprovalDirector__c = null;
                order.Director__c = false;

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
            if(typeOrder == 'gerarpedido') order.EffectiveOrderDate__c = Date.today();
            order.Incoterms__c = orderData.headerData.frete;
            order.Incoterms2__c = orderData.headerData.frete;
            order.Description = orderData.summaryData.observation;
            order.PaymentCondition__c = orderData.headerData.condicao_pagamento.Id;
            order.ShippingDate__c = Date.valueOf(orderData.headerData.data_entrega);
            order.DescriptionBillingSale__c = orderData.summaryData.billing_sale_observation;
            order.OrderReference__c = order.OrderReference__c != null ? order.OrderReference__c : orderData.headerData.pedido_mae.Id;
            order.IsOrderMother__c = orderData.headerData.pedido_mae.Id != null ? false : Boolean.valueOf(orderData.headerData.pedido_mae_check);
            order.Hectare__c = orderData.headerData.hectares.contains(',') ? Decimal.valueOf(orderData.headerData.hectares.replace(',', '.').trim()) : Decimal.valueOf(orderData.headerData.hectares.trim());
            order.FinalTotalValue__c = orderTotalValue;
            order.Company__c = company.Id;
            order.DistributionCenter__c = orderData.summaryData.centerId != null ? orderData.summaryData.centerId : orderData.headerData.centerId;
            order.OrderType__c = orderData.headerData.pedido_mae.Id != null ? 'Pedido Filho' : (order.IsOrderMother__c ? 'Pedido Mãe' : 'Pedido Normal');
            order.OrderMargin__c = orderData.summaryData.orderMargin != null ? (orderData.summaryData.orderMargin.contains(' sacas') ?
                                   stringToDecimal(orderData.summaryData.orderMargin.replace(' sacas', '')) : stringToDecimal((orderData.summaryData.orderMargin))) : 0;
            order.ApprovalJustification__c = orderData.summaryData.justification;

            if (order.OrderType__c == 'Pedido Filho') {
                order.AccountId = [SELECT Id, ParentId FROM Account WHERE Id =: order.ShippingAccount__c].ParentId;
            }

            if (order.Incoterms__c == 'CIF') {
                order.FinalTotalValue__c = order.FinalTotalValue__c + orderData.summaryData.freightValue;
            }
            order.FreightValue__c = (orderData.summaryData.freightValue != null) ? orderData.summaryData.freightValue : 0;

            if (Test.isRunningTest()) {
                OrderHelper.disableTrigger();
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

                Decimal commodityPrice = 0;
                if (orderData.commodityData != null && orderData.commodityData.size() > 0) {
                    for (CommodityDeserialize commodity : orderData.commodityData) {
                        commodityPrice = commodity.commodityPrice;
                    }
                }

                Integer itemCounter = setOrderItemsIds.size() + 1;
                Boolean childOrder = order.OrderType__c == 'Pedido Filho';
                for (ProductDeserialize orderProduct : orderData.productData) {
                    OrderItem orderItem;
                    if (!newOrder && orderItemsById.containsKey(orderProduct.orderItemId)) {
                        orderItem = orderItemsById.get(orderProduct.orderItemId);
                    } else {
                        orderItem = new OrderItem();
                        String sapNumber = childOrder ? motherItems.get(orderProduct.productId).NumeroSap__c : String.valueOf(itemCounter * 10);
                        orderItem.NumeroSap__c = sapNumber;
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
                    
                    if (motherItems.containsKey(orderProduct.productId) && typeOrder != 'prepedido') {
                        OrderItem motherItem = motherItems.get(orderProduct.productId);
                        motherItem.AmountUsed__c = motherItem.AmountUsed__c != null ? motherItem.AmountUsed__c + orderProduct.quantity : 0;
                        motherItems.put(orderProduct.productId, motherItem);
                    }

                    orderItem.CommitteeTrigger__c = false;
                    if (orderMarginMap.get(orderProduct.productGroupId) >= orderProduct.commercialMarginPercentage) {
                        orderItem.CommitteeTrigger__c = true;
                    }

                    if (quantitiesResult != null && typeOrder != 'prepedido') {
                        orderItem.IndividualQuotas__c = quantitiesResult.individualQuotasByProdId.get(orderProduct.productId);
                    }

                    orderItem.UnitPricePerBag__c = commodityPrice > 0 ? (orderProduct.unitPrice / commodityPrice) : null;
                    orderItem.TotalPricePerBag__c = commodityPrice > 0 ? (orderItem.UnitPricePerBag__c * orderProduct.quantity) : null;
                    orderItem.Quantity = orderProduct.quantity;
                    orderItem.ListPrice__c = orderProduct.listPrice != null ? orderProduct.listPrice : 0;
                    orderItem.PracticedPrice__c = orderProduct.unitPrice != null ? orderProduct.unitPrice : 0;
                    orderItem.Dosage__c = orderProduct.dosage != null ? orderProduct.dosage.setScale(6) : 0;
                    orderItem.Status__c = orderProduct.sapStatus != null ? statusValueByLabel.get(orderProduct.sapStatus) : null;
                    orderItem.UnitMeasure__c = orderProduct.unity;
                    orderItem.FinalTotalValue__c = orderProduct.totalPrice;
                    orderItem.ListCost__c = orderProduct.listCost != null ? orderProduct.listCost : 0;
                    orderItem.PracticedCost__c = orderProduct.practicedCost != null ? orderProduct.practicedCost : 0;
                    orderItem.DiscountPercent__c = orderProduct.commercialDiscountPercentage != '' ? (stringToDecimal(orderProduct.commercialDiscountPercentage) != null ? stringToDecimal(orderProduct.commercialDiscountPercentage) : 0) : 0;
                    orderItem.DiscountValue__c = childOrder ? 0 : (orderProduct.commercialDiscountValue != null ? orderProduct.commercialDiscountValue : 0);
                    orderItem.CommercialAdditionPercent__c = orderProduct.commercialAdditionPercentage != '' ? (stringToDecimal(orderProduct.commercialAdditionPercentage) != null ? stringToDecimal(orderProduct.commercialAdditionPercentage) : 0) : 0;
                    orderItem.CommercialAdditionValue__c = childOrder ? 0 : (orderProduct.commercialAdditionValue != null ? orderProduct.commercialAdditionValue : 0);
                    orderItem.FinancialAdditionPercent__c = orderProduct.financialAdditionPercentage != '' ? (stringToDecimal(orderProduct.financialAdditionPercentage) != null ? stringToDecimal(orderProduct.financialAdditionPercentage) : 0) : 0;
                    orderItem.FinancialAdditionValue__c = childOrder ? 0 : (orderProduct.financialAdditionValue != null ? orderProduct.financialAdditionValue : 0);
                    orderItem.FinancialDiscountPercent__c = orderProduct.financialDecreasePercentage != '' ? (stringToDecimal(orderProduct.financialDecreasePercentage) != null ? stringToDecimal(orderProduct.financialDecreasePercentage) : 0) : 0;
                    orderItem.FinancialDiscountValue__c = childOrder ? 0 : (orderProduct.financialDecreaseValue != null ? orderProduct.financialDecreaseValue : 0);
                    orderItem.ComissionValue__c = orderProduct.comissionValue != null ? orderProduct.comissionValue : 0;
                    orderItem.CommercialMargin__c = orderProduct.commercialMarginPercentage != null ? orderProduct.commercialMarginPercentage : 0;
                    orderItem.PercentComission__c = orderProduct.productHierarchyId != null && orderProduct.productHierarchyId != '' ?
                                                    (commissionByHierarchy.get(orderProduct.productHierarchyId) != null ?
                                                        (commissionByHierarchy.get(orderProduct.productHierarchyId).CommissionPercentage__c != null ? commissionByHierarchy.get(orderProduct.productHierarchyId).CommissionPercentage__c : 0) :
                                                        0
                                                    ) :
                                                    0;
                    orderItem.ComissionValue__c = orderItem.PercentComission__c != 0 ? ((orderItem.FinalTotalValue__c * orderItem.PercentComission__c) / 100) : 0;
                    orderItem.PTA__c = orderProduct.ptaProduct;
                    orderItem.PriceListCode__c = orderProduct.priceListCode;
                    orderItem.Sieve__c = orderProduct.sieve;
                    orderItem.Class__c = orderProduct.productClass;
                    listOrderItems.add(orderItem);
                }

                List<OrderItem> itemsToDelete = new List<OrderItem>();
                for (String itemToDeleteId : deleteItems) {
                    OrderItem itemToDelete = orderItemsById.get(itemToDeleteId);
                    if (itemToDelete.OrderId == order.Id) {
                        itemsToDelete.add(itemToDelete);
                    }
                }

                OrderHelper.disableTrigger();
                update motherItems.values();
                delete itemsToDelete;
                OrderHelper.enableTrigger();

                String orderItemErrors = '';
                Set<Id> itemsIds = new Set<Id>();
                OrderHelper.disableTrigger();
                List<Database.UpsertResult> insOrderItemResults = Database.upsert(listOrderItems, false);
                OrderHelper.enableTrigger();
                for (Database.UpsertResult result : insOrderItemResults){
                    System.debug('result => ' + result);
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

                if (typeOrder != 'prepedido' && quantitiesResult != null) {
                    System.debug('quantitiesResult.generalQuotasToUpdate: ' + quantitiesResult.generalQuotasToUpdate);
                    update quantitiesResult.generalQuotasToUpdate;
                    System.debug('quantitiesResult.individualQuotasToUpdate: ' + quantitiesResult.individualQuotasToUpdate);
                    update quantitiesResult.individualQuotasToUpdate;
                }

                Integer divisionCounter = 1;
                Set<Id> setDivisionIds = new Set<Id>();
                List<ShippingDivison__c> listShippingDivision = new List<ShippingDivison__c>();

                Map<String, OrderItem> mapOrderItems = new Map<String, OrderItem>();
                for (OrderItem orderItem : [
                    SELECT Id,
                           Product2Id,
                           Quantity,
                           UnitPrice,
                           NumeroSap__c
                      FROM OrderItem
                     WHERE Id IN: itemsIds
                ]) {
                    mapOrderItems.put(orderItem.Product2Id, orderItem);
                }
                
                if (orderData.divisionData != null && orderData.divisionData.size() > 0 && typeOrder != 'prepedido') {
                    Map<String, DivisionDeserialize> divisionsByKey = new Map<String, DivisionDeserialize>();
                    for (DivisionDeserialize division : orderData.divisionData) {
                        if (division.divisionId != null) {
                            setDivisionIds.add(division.divisionId);
                        }

                        String key = division.deliveryDate + '-' + division.orderItemKey;
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
                        SELECT Id,
                               ExternalId__c
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
                            String divisionSapNumber = divisionCounter >= 10 ? '0' + String.valueOf(divisionCounter) : '00' + String.valueOf(divisionCounter);
                            shippingDivision.SapNumber__c = divisionSapNumber;
                            shippingDivision.ExternalId__c = order.Id + '|' + mapOrderItems.get(division.orderItemKey).NumeroSap__c + '|' + shippingDivision.SapNumber__c;
                            divisionCounter++;
                        }

                        shippingDivision.DeliveryDate__c = Date.valueOf(division.deliveryDate);
                        shippingDivision.Quantity__c = division.quantity;
                        shippingDivision.ConfirmedQuantity__c = division.confirmedQuantity != null ? division.confirmedQuantity : 0;
                        shippingDivision.OrderItem__c = !cloneOrder && !newDivision && division.orderItemId != null ?
                                                        division.orderItemId : mapOrderItems.get(division.orderItemKey).Id;
                        listShippingDivision.add(shippingDivision);

                        if (quantityDistributedByItem.containsKey(shippingDivision.OrderItem__c)) {
                            Decimal quantityDistributed = quantityDistributedByItem.get(shippingDivision.OrderItem__c) + shippingDivision.Quantity__c;
                            quantityDistributedByItem.put(shippingDivision.OrderItem__c, quantityDistributed);
                        } else {
                            quantityDistributedByItem.put(shippingDivision.OrderItem__c, shippingDivision.Quantity__c);
                        }
                    }

                    if (order.OrderType__c == 'Pedido Normal') {
                        for (OrderItem item : listOrderItems) {
                            String divisionSapNumber = divisionCounter >= 10 ? '0' + String.valueOf(divisionCounter) : '00' + String.valueOf(divisionCounter);
                            if (quantityDistributedByItem.containsKey(item.Id)) {
                                Decimal quantityUsed = quantityDistributedByItem.get(item.Id);
                                if (item.Quantity > quantityUsed) {
                                    ShippingDivison__c shippingDivision = new ShippingDivison__c();
                                    shippingDivision.ExternalId__c = order.Id + '|' + mapOrderItems.get(item.Product2Id).NumeroSap__c + '|' + divisionSapNumber;
                                    shippingDivision.SapNumber__c = divisionSapNumber;
                                    shippingDivision.DeliveryDate__c = order.ShippingDate__c;
                                    shippingDivision.Quantity__c = item.Quantity - quantityUsed;
                                    shippingDivision.OrderItem__c = item.Id;
                                    listShippingDivision.add(shippingDivision);
                                }
                            } else {
                                ShippingDivison__c shippingDivision = new ShippingDivison__c();
                                shippingDivision.ExternalId__c = order.Id + '|' + mapOrderItems.get(item.Product2Id).NumeroSap__c + '|' + divisionSapNumber;
                                shippingDivision.SapNumber__c = divisionSapNumber;
                                shippingDivision.DeliveryDate__c = order.ShippingDate__c;
                                shippingDivision.Quantity__c = item.Quantity;
                                shippingDivision.OrderItem__c = item.Id;
                                listShippingDivision.add(shippingDivision);
                            }

                            divisionCounter++;
                        }
                    }
                } else if (order.OrderType__c != 'Pedido Mãe') {
                    for (OrderItem item : listOrderItems) {
                        String divisionSapNumber = divisionCounter >= 10 ? '0' + String.valueOf(divisionCounter) : '00' + String.valueOf(divisionCounter);
                        ShippingDivison__c shippingDivision = new ShippingDivison__c();
                        shippingDivision.ExternalId__c = order.Id + '|' + mapOrderItems.get(item.Product2Id).NumeroSap__c + '|' + divisionSapNumber;
                        shippingDivision.SapNumber__c = divisionSapNumber;
                        shippingDivision.DeliveryDate__c = order.ShippingDate__c;
                        shippingDivision.Quantity__c = item.Quantity;
                        shippingDivision.OrderItem__c = item.Id;
                        listShippingDivision.add(shippingDivision);
                        divisionCounter++;
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
                    List<OrderCommodity__c> upsCommodities = new List<OrderCommodity__c>();
                    Set<Id> setCommodityIds = new Set<Id>();
                    for (CommodityDeserialize commodity : orderData.commodityData) {
                        setCommodityIds.add(commodity.commodityId);
                    }

                    Map<Id, OrderCommodity__c> commoditiesById = new Map<Id, OrderCommodity__c>();
                    for (OrderCommodity__c commodity : [
                        SELECT Id
                          FROM OrderCommodity__c
                         WHERE Id IN: setCommodityIds
                    ]) {
                        commoditiesById.put(commodity.Id, commodity);
                    }

                    for (CommodityDeserialize commodity : orderData.commodityData) {
                        OrderCommodity__c orderCommodity;
                        if (!newOrder && !cloneOrder && commoditiesById.containsKey(commodity.commodityId)) {
                            orderCommodity = commoditiesById.get(commodity.commodityId);
                        } else {
                            orderCommodity = new OrderCommodity__c();
                            orderCommodity.Order__c = order.Id;
                        }

                        orderCommodity.Name = commodity.product;
                        orderCommodity.BagQuantity__c = Decimal.valueOf(commodity.totalDelivery.replace(' sacas', ''));
                        orderCommodity.BagMargin__c = Decimal.valueOf(commodity.marginValue.replace(' sacas', ''));
                        orderCommodity.CommodityPrice__c = commodity.commodityPrice;
                        orderCommodity.Product__c = commodity.productId;
                        orderCommodity.StartDate__c = Date.valueOf(commodity.startDate);
                        orderCommodity.EndDate__c = Date.valueOf(commodity.endDate);
                        orderCommodity.DeliveryAddress__c = commodity.deliveryAddress;
                        upsCommodities.add(orderCommodity);
                    }
                    
                    if (upsCommodities.size() > 0) {
                        String commodityErrors = '';
                        List<Database.UpsertResult> upsCommoditiesResults = Database.upsert(upsCommodities, false);
                        for (Database.UpsertResult result : upsCommoditiesResults){
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

                Set<Id> setPaymentIds = new Set<Id>();
                if(orderData.formsOfPayment != null){
                    for (FormOfPaymentDeserialize payment : orderData.formsOfPayment) {
                        if (payment.paymentId != null && payment.paymentId != '') {
                            setPaymentIds.add(payment.paymentId);
                        }
                    }
                }
                

                List<FormPayment__c> upsFormsOfPayment = new List<FormPayment__c>();
                Map<Id, FormPayment__c> paymentFormsById = new Map<Id, FormPayment__c>();
                for (FormPayment__c formOfPayment : [
                    SELECT Id
                      FROM FormPayment__c
                     WHERE Id IN: setPaymentIds
                ]) {
                    paymentFormsById.put(formOfPayment.Id, formOfPayment);
                }

                if(orderData.formsOfPayment != null){
                    for (FormOfPaymentDeserialize payment : orderData.formsOfPayment) {
                        FormPayment__c formOfPayment;
                        if (payment.paymentId != null && payment.paymentId != '' && !newOrder && !cloneOrder && paymentFormsById.containsKey(payment.paymentId)) {
                            formOfPayment = paymentFormsById.get(payment.paymentId);
                        } else {
                            formOfPayment = new FormPayment__c();
                            formOfPayment.Order__c = order.Id;
                        }

                        formOfPayment.PaymentType__c = payment.paymentType;
                        formOfPayment.PaymentDate__c = Date.valueOf(payment.paymentDay);
                        formOfPayment.Amount__c = Decimal.valueOf(payment.value);
                        upsFormsOfPayment.add(formOfPayment);
                    }
                }
                
                if (upsFormsOfPayment.size() > 0) {
                    String commodityErrors = '';
                    List<Database.UpsertResult> upsFormsOfPaymentResults = Database.upsert(upsFormsOfPayment, false);
                    for (Database.UpsertResult result : upsFormsOfPaymentResults){
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
    public static String getAccountCompanies(String data, Boolean isHeader, Boolean verifyUserType, Boolean priceScreen) {
        GetCompanyInfos companyInfos = (GetCompanyInfos) JSON.deserialize(data, GetCompanyInfos.class);
        Id userTerritoryId;
        Boolean sellerPosition = false;

        for (UserTerritory2Association userAssociation : [
            SELECT Id,
                   Territory2.Territory2Type.DeveloperName
              FROM UserTerritory2Association
             WHERE UserId =: UserInfo.getUserId()
             LIMIT 1
        ]) {
            sellerPosition = userAssociation.Territory2.Territory2Type.DeveloperName == 'SellerPosition' ? true : false;
        }
        
        if (verifyUserType) {
            sellerPosition = true;
            return JSON.serialize(sellerPosition);
        }
        
        for (UserTerritory2Association userAssociation : [
            SELECT Id,
                   UserId,
                   Territory2Id,
                   Territory2.Territory2Type.DeveloperName
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
        
        Set<String> fieldSet = new Set<String>{
            'Id','SalesOrg__c', 'SalesTeam__r.Name', 'SalesOffice__c',
            'SupplierCenter__c','ActivitySector__c','ActivitySector__r.Name',
             'DistributionChannel__c','DistributionChannel__r.Name', 'Status__c'
        };
        Q proQuery = new Q(Company__c.SObjectType);
        proQuery.selectFields(fieldSet);
        if (companyInfos.accountId != '') proQuery.add(Q.condition('Conta__c').equalsTo(companyInfos.accountId));
        proQuery.add(Q.condition('Status__c').equalsTo('Adicionada'));
        
        List<CompanyInfos> companyList = new List<CompanyInfos>();
        if (salesTeamTerritory != null && salesTeamTerritory.DeveloperName != null) {
            String salesTeamDevName = salesTeamTerritory.DeveloperName.substring(0, 1) == 'X' ? salesTeamTerritory.DeveloperName.substring(1, salesTeamTerritory.DeveloperName.length()) : salesTeamTerritory.DeveloperName;
            proQuery.add(Q.condition('SalesTeam__r.ExternalId__c').equalsTo(salesTeamDevName));
            proQuery.add(Q.condition('SalesOrg__r.SalesOrganizationCode__c').isIn(new List<String>{'1000', '1300'}));
            if(companyInfos.orderType != 'Venda de Serviço')
                proQuery.add(Q.condition('ActivitySector__r.Codigo__c').notEqualsTo('40'));
            else {
                proQuery.add(Q.condition('ActivitySector__r.Codigo__c').equalsTo('40'));
            }

            if (companyInfos.accountId == '') proQuery.addLimit(1);
            for (Company__c salesTeamCompany : Database.query(proQuery.build())) {
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
        if(isHeader)
            return companyList[0].salesOrgId;
        else
            return JSON.serialize(new CompanyInfosSerialize(companyList));
    }

    @AuraEnabled
    public static String getAccountDistrCenters(String salesOrgId) {
        List<DistrCenterData> listDistrCenter = new List<DistrCenterData>();
        for (DistributionCenter__c distrCenter : [
            SELECT Id,
                   Name,
                   Code__c,
                   SalesOrg__r.Name
              FROM DistributionCenter__c
             WHERE SalesOrg__c =: salesOrgId
          ORDER BY Code__c
        ]) {
            DistrCenterData distrData = new DistrCenterData();
            distrData.centerId = distrCenter.Id;
            distrData.code = distrCenter.Code__c;
            distrData.salesOrgName = distrCenter.SalesOrg__r.Name;
            distrData.selected = false;
            listDistrCenter.add(distrData);
        }

        return JSON.serialize(listDistrCenter);
    }

    public class DistrCenterData {
        public String centerId;
        public String code;
        public String salesOrgName;
        public Boolean selected;
    }

    @AuraEnabled
    public static String verifyProductDisponibility(String data) {
        DisponibilityData disponibilityData = (DisponibilityData) JSON.deserialize(data, DisponibilityData.class);
        List<String> availableProds = new List<String>();
        for (OrgVProduct__c orgVProduct : [
            SELECT Id,
                   Product__c
              FROM OrgVProduct__c
             WHERE Product__c IN: disponibilityData.orderProductsId
               AND SalesOrg__c =: disponibilityData.salesOrgId
               AND Status__c = 'Adicionada'
               AND SupplierCenter__c =: disponibilityData.supplierCenter
        ]) {
            availableProds.add(orgVProduct.Product__c);
        }

        return JSON.serialize(availableProds);
    }

    @AuraEnabled
    public static Boolean isSeedSale(String salesOrgId, String productGroupName) {
        String salesOrgCode = [SELECT Id, SalesOrganizationCode__c FROM SalesOrg__c WHERE Id =: salesOrgId].SalesOrganizationCode__c;
        Boolean isSeed = false;
        for (SalesOrgSeeds__c seed : [
            SELECT Id,
                   SeedCode__c
              FROM SalesOrgSeeds__c
             WHERE SeedCode__c =: salesOrgCode
        ]) {
            if(productGroupName != null){
                if(productGroupName == 'SEMENTES'){
                    isSeed = true;
                }
            }else{
                isSeed = true;
            }
        }

        return isSeed;
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
        Safra__c safra = [
            SELECT Id,
                   BillingStartDate__c,
                   EndDateBilling__c,
                   NumberOfDaysAfterPayment__c,
                   PaymentBaseDate__c
              FROM Safra__c
             WHERE Id =: safraId
        ];

        return JSON.serialize(new SafraDataSerialize(safra));
    }

    @AuraEnabled
    public static String getPaymentTypes() {
        List<PaymentType> listPaymentType = new List<PaymentType>();
        List<Schema.PicklistEntry> paymentTypes = FormPayment__c.PaymentType__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry sp : paymentTypes) {
            PaymentType paymentForm = new PaymentType();
            paymentForm.label = sp.getLabel();
            paymentForm.value = sp.getValue();
            listPaymentType.add(paymentForm);
        }
        return JSON.serialize(listPaymentType);
    }

    public class PaymentType {
        public String label;
        public String value;
    }

    @AuraEnabled
    public static String approvals(String data){
        OrderDeserialize orderData = (OrderDeserialize) JSON.deserialize(data, OrderDeserialize.class);
        Map<String, Decimal> smallerMarginByProductGroup = new Map<String, Decimal>();
        Company__c company = new Company__c();

        for (Company__c accountCompany : [
            SELECT Id,
                    SalesOrg__c,
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

            Decimal currentDiscount = orderProduct.commercialDiscountPercentage != '' ? (stringToDecimal(orderProduct.commercialDiscountPercentage) != null ? stringToDecimal(orderProduct.commercialDiscountPercentage) : 0) : 0;
            if (biggerDiscount < currentDiscount) {
                biggerDiscount = currentDiscount;
                productGroupId = orderProduct.productGroupId;
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
        }
        

        User user = [SELECT Id, SellerType__c FROM User WHERE Id =: UserInfo.getUserId()];
        String sellerType = user.SellerType__c != null ? user.SellerType__c : '';

        String approval = '';
        Map<String, Decimal> orderMarginMap = new Map<String, Decimal>();
            if (orderData.headerData.pedido_mae.Id == null && company != null && company.ClientGroup__c != null) {
                for (Discount__c discount : [
                    SELECT Id,
                           Margin__c,
                           ProductGroup__c
                      FROM Discount__c
                     WHERE Status__c = 'Aprovado'
                       AND Approver__c = 'ComiteMargem'
                       AND ClientGroup__c =: company.ClientGroup__c
                       AND SalesOrg__c =: company.SalesOrg__c
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
                    approval += '- ' + 'Comitê de Margem';
                }
            }

        
        if (company != null) {
            Discount__c orderDiscount = new Discount__c();
            for (Discount__c discount : [
                SELECT Id,
                       Approver__c
                  FROM Discount__c
                 WHERE Status__c = 'Aprovado'
                   AND ClientGroup__c =: company.ClientGroup__c
                   AND SalesOrg__c =: company.SalesOrg__c
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

            if(orderDiscount.Approver__c == 'Diretor'){
                approval += approvalLevels.get('GerenteFilial') + '/' + approvalLevels.get('GerenteRegional') + '/' + approvalLevels.get(orderDiscount.Approver__c);
            }
            if(orderDiscount.Approver__c == 'GerenteRegional'){
                approval += approvalLevels.get('GerenteFilial') + '/' + approvalLevels.get(orderDiscount.Approver__c);
            }
            if(orderDiscount.Approver__c == 'GerenteFilial'){
                approval += approvalLevels.get(orderDiscount.Approver__c);
            }
        }
        return approval;
    }

    @AuraEnabled
    public static Boolean needJustification(){
        try {
            String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
            Boolean isNeed = [SELECT NeedJustification__c FROM ApprovalProfiles__c WHERE Name =: profileName].NeedJustification__c;

            return isNeed;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkSalesOrgFreight(String salesOrgId) {
        Boolean showFreight = [SELECT Id, Freight__c FROM SalesOrg__c WHERE Id =: salesOrgId].Freight__c;
        return showFreight;
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
        public List<FormOfPaymentDeserialize> formsOfPayment;
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
        public String  hectares;
        public Decimal freightValue;
        public Boolean emptyHectar;
        public String  centerId;
        public Boolean pedido_mae_check;
        public Boolean pre_pedido;
        public Boolean firstTime;
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
        public String  priceListCode;
        public String  sieve;
        public String  productClass;
        public Integer position;
        public Boolean ptaProduct;
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
        public String  commodityId;
        public String  product;
        public String  productId;
        public String  desage;
        public String  area;
        public String  discount;
        public String  margin;
        public String  marginValue;
        public String  totalDelivery;
        public String  startDate;
        public String  endDate;
        public String  deliveryAddress;
        public Decimal quantity;
        public Decimal commodityPrice;
        public Boolean saved;
    }

    public class FormOfPaymentDeserialize {
        public Date    paymentDay;
        public String  paymentType;
        public String  value;
        public String  paymentTypeId;
        public String  paymentDayId;
        public String  valueId;
        public String  paymentId;
        public String  paymentKey;
        public Integer paymentPosition;
        public Boolean saved;
    }

    public class SummaryDeserialize{
        public String  observation;
        public String  billing_sale_observation;
        public String  orderMargin;
        public String  justification;
        public String  centerId;
        public Decimal freightValue;
    }

    public class SummarySerialize{
        public String  observation;
        public String  billing_sale_observation;
        public String  orderMargin;
        public String  justification;
        public String  centerId;
        public Decimal freightValue;
        
        public SummarySerialize(){}
        public SummarySerialize(String observation, String billing_sale_observation, Decimal freightValue){
            this.observation = observation;
            this.billing_sale_observation = billing_sale_observation;
            this.orderMargin = orderMargin;
            this.freightValue = freightValue;
        }
    }


    //Classe para serialização
    public class OrderSerialize{
        public HeaderSerialize headerData;
        public AccountSerialize accountData;
        public List<ProductSerialize> productData;
        public List<DivisionSerialize> divisionData;
        public List<CommoditySerialize> commodityData;
        public List<FormOfPaymentSerialize> formsOfPayment;

        OrderSerialize(){}       

        OrderSerialize(AccountSerialize account){
            this.accountData = account;
        }  

        OrderSerialize(HeaderSerialize order, List<ProductSerialize> products, List<DivisionSerialize> divisions, AccountSerialize account, List<CommoditySerialize> commodities, List<FormOfPaymentSerialize> formsOfPayment){
            this.headerData = order;
            this.productData = products;
            this.divisionData = divisions;
            this.accountData = account;
            this.commodityData = commodities;
            this.formsOfPayment = formsOfPayment;
        }
    }

    public class OrderSerializeAll{
        public HeaderSerialize headerData;
        public List<ProductSerialize> productData;
        public List<DivisionSerialize> divisionData;
        public List<CommodityDeserialize> commodityData;
        public AccountSerialize accountData;
        public SummarySerialize summaryData;

        OrderSerializeAll(){}       

        OrderSerializeAll(AccountSerialize account){
            this.accountData = account;
        }  

        public OrderSerializeAll(HeaderSerialize order, List<ProductSerialize> products, List<DivisionSerialize> divisions, List<CommodityDeserialize> commodities, AccountSerialize account, SummarySerialize summaryData){
            this.headerData = order;
            this.productData = products;
            this.divisionData = divisions;
            this.commodityData = commodities;
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
        public String  orderNumber;
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
        public String  recTypeId;
        public String  hectares;
        public Decimal freightValue;
        public Boolean emptyHectar;
        public String  centerId;
        public Boolean pedido_mae_check;
        public Boolean pre_pedido;
        public Boolean firstTime;
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
            this.orderNumber = order.OrderNumber;
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
            this.emptyHectar = order.Hectare__c == null;
            this.hectares = order.Hectare__c == null ? '1,00' : String.valueOf(order.Hectare__c).contains('.') ? String.valueOf(order.Hectare__c).replace('.', ',') : String.valueOf(order.Hectare__c);
            this.condicao_pagamento = new InformationFields(order.PaymentCondition__c, order.PaymentCondition__r.Name);
            this.frete = order.Incoterms__c;
            this.observation = order.Description;
            this.billing_sale_observation = order.DescriptionBillingSale__c;
            this.centerId = order.DistributionCenter__c;
            this.freightValue = order.FreightValue__c;
            this.orderMargin = String.valueOf(order.OrderMargin__c) + '%';
            this.companyId = order.Company__c;
            this.recTypeId = order.RecordTypeId;
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
        public String  priceListCode;
        public String  sieve;
        public String  productClass;
        public Integer position;
        public Boolean ptaProduct;
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
            this.unitPrice = orderItem.PracticedPrice__c;
            this.totalPrice = orderItem.FinalTotalValue__c;
            this.listCost = orderItem.ListCost__c;
            this.practicedCost = orderItem.PracticedCost__c;
            this.dosage = orderItem.Dosage__c;
            this.sapStatus = orderItem.Status__c;
            this.unity = orderItem.UnitMeasure__c;
            this.commercialDiscountPercentage = orderItem.DiscountPercent__c != null ? (orderItem.DiscountPercent__c == 0 ? '0%' : String.valueOf(orderItem.DiscountPercent__c) + '%') : '0%';
            this.commercialDiscountValue = orderItem.DiscountValue__c != null ? orderItem.DiscountValue__c : 0;
            this.commercialAdditionPercentage = orderItem.CommercialAdditionPercent__c != null ? (orderItem.CommercialAdditionPercent__c == 0 ? '0%' : String.valueOf(orderItem.CommercialAdditionPercent__c) + '%') : '0%';
            this.commercialAdditionValue = orderItem.CommercialAdditionValue__c != null ? orderItem.CommercialAdditionValue__c : 0;
            this.financialAdditionPercentage = orderItem.FinancialAdditionPercent__c != null ? (orderItem.FinancialAdditionPercent__c == 0 ? '0%' : String.valueOf(orderItem.FinancialAdditionPercent__c) + '%') : '0%';
            this.financialAdditionValue = orderItem.FinancialAdditionValue__c != null ? orderItem.FinancialAdditionValue__c : 0;
            this.financialDecreasePercentage = orderItem.FinancialDiscountPercent__c != null ? (orderItem.FinancialDiscountPercent__c == 0 ? '0%' : String.valueOf(orderItem.FinancialDiscountPercent__c) + '%') : '0%';
            this.financialDecreaseValue = orderItem.FinancialDiscountValue__c != null ? orderItem.FinancialDiscountValue__c : 0;
            this.comissionValue = orderItem.ComissionValue__c;
            this.commercialMarginPercentage = orderItem.CommercialMargin__c;
            this.ptaProduct = orderItem.PTA__c;
            this.priceListCode = orderItem.PriceListCode__c;
            this.sieve = orderItem.Sieve__c != null ? orderItem.Sieve__c : '';
            this.productClass = orderItem.Class__c != null ? orderItem.Class__c : '';
        }
    }

    public class DivisionSerialize{
        public String  divisionId;
        public String  productId;
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
            this.productId = shippingDivison.OrderItem__r.Product2Id;
            this.deliveryDate = String.valueOf(shippingDivison.DeliveryDate__c);
            this.deliveryId = 'deliveryId-' + divisionPosition;
            this.quantityId = 'quantityId-' + divisionPosition;
            this.orderItemId = shippingDivison.OrderItem__c;
            this.orderItemKey = shippingDivison.OrderItem__r.Product2Id;
            this.quantity = shippingDivison.Quantity__c;
            this.externalId = shippingDivison.ExternalId__c;
            this.confirmedQuantity = shippingDivison.ConfirmedQuantity__c;
            this.productPosition = productPosition;
            this.showInfos = true;
        }
    }

    public class CommoditySerialize {
        public String  commodityId;
        public String  product;
        public String  productId;
        public String  discount;
        public String  margin;
        public String  marginValue;
        public String  totalDelivery;
        public String  startDate;
        public String  endDate;
        public Decimal commodityPrice;
        public Decimal area;
        public Decimal quantity;
        public Decimal cotation;
        public Boolean saved;

        CommoditySerialize(){}

        CommoditySerialize(OrderCommodity__c ordercommodity) {
            Decimal margin = ((1 - (totalCost / orderCommodity.Order__r.FinalTotalValue__c)) * 100);
            this.commodityId = orderCommodity.Id;
            this.product = orderCommodity.Product__r.Name;
            this.productId = orderCommodity.Product__c;
            this.discount = (totalDiscount / orderCommodity.CommodityPrice__c) + ' sacas';
            this.commodityPrice = orderCommodity.CommodityPrice__c;
            this.area = orderCommodity.Order__r.Hectare__c;
            this.quantity = totalQuantity;
            this.margin = margin.setScale(4) + '%';
            this.marginValue = (((orderCommodity.Order__r.FinalTotalValue__c * margin) / 100) / this.commodityPrice).setScale(4) + ' sacas';
            this.totalDelivery = orderCommodity.BagQuantity__c + ' sacas';
            this.cotation = orderCommodity.CommodityPrice__c;
            this.startDate = String.valueOf(orderCommodity.StartDate__c);
            this.endDate = String.valueOf(orderCommodity.EndDate__c);
            this.saved = true;
        }
    }

    public class FormOfPaymentSerialize {
        public String  paymentDay;
        public String  paymentType;
        public String  value;
        public String  paymentTypeId;
        public String  paymentDayId;
        public String  valueId;
        public String  paymentId;
        public String  paymentKey;
        public Integer paymentPosition;
        public Boolean saved;

        FormOfPaymentSerialize(){}

        FormOfPaymentSerialize(FormPayment__c payments, Integer counter) {
            this.paymentDay = String.valueOf(payments.PaymentDate__c);
            this.paymentType = payments.PaymentType__c;
            this.value = String.valueOf(payments.Amount__c);
            this.paymentTypeId = 'paymentTypeId-' + counter;
            this.paymentDayId = 'paymentDayId-' + counter;
            this.valueId = 'valueId-' + counter;
            this.paymentId = payments.Id;
            this.paymentKey = payments.PaymentType__c + '-' + String.valueOf(payments.PaymentDate__c);
            this.paymentPosition = counter;
            this.saved = true;
        }
    }

    public class SafraDataDeserialize {
        public String initialDate;
        public String paymentDate;
        public String endDateBilling;
        public String startDateBilling;
        public String paymentBaseDate;
    }

    public class SafraDataSerialize {
        public String initialDate;
        public String paymentDate;
        public String endDateBilling;
        public String startDateBilling;
        public String paymentBaseDate;

        SafraDataSerialize() {}

        SafraDataSerialize(Safra__c safra) {
            this.initialDate = String.valueOf(safra.BillingStartDate__c);
            this.paymentDate = String.valueOf(safra.NumberOfDaysAfterPayment__c);
            this.endDateBilling = String.valueOf(safra.EndDateBilling__c);
            this.startDateBilling = String.valueOf(safra.BillingStartDate__c);
            this.paymentBaseDate = String.valueOf(safra.PaymentBaseDate__c);
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
        public String  orderType;
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

    public class DisponibilityData {
        public List<String> orderProductsId;
        public String salesOrgId;
        public String supplierCenter;
    }

    
    public class QuotaData {
        public String cropId;
        public String sellerId;
        public List<String> productsIds;
    }

    public class QuotaResult {
        public String  productId;
        public String  productName;
        public String  generalQuotaId;
        public String  individualQuotaId;
        public Decimal balance;
        public Decimal generalBalance;
        public Decimal consumed;
    }

    public class QuantitiesResult {
        public Boolean hasQuota = true;
        public String invalidProductsNames = '';
        public Map<Id, Id> individualQuotasByProdId = new Map<Id, Id>();
        public List<GeneralQuotas__c> generalQuotasToUpdate = new List<GeneralQuotas__c>();
        public List<IndividualQuotas__c> individualQuotasToUpdate = new List<IndividualQuotas__c>();
    }
}