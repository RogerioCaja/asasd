public without sharing class OrderScreenController {
    public static Map<Id, Integer> orderItemsPosition;
    public static Decimal totalCost;
    public static Decimal totalDiscount;
    public static Decimal totalQuantity;

    @AuraEnabled
    public static String getOrder(String recordId, Boolean cloneOrder, Boolean checkQuantities) {
        HeaderSerialize order;
        AccountSerialize account;
        AccountSerialize bpAccount;
        List<ProductSerialize> ordItemList = new List<ProductSerialize>();
        List<DivisionSerialize> divisionList = new List<DivisionSerialize>();
        List<CommoditySerialize> commodityList = new List<CommoditySerialize>();
        List<TaxDataSerialize> commodityTax = new List<TaxDataSerialize>();
        List<FormOfPaymentSerialize> formsOfPayment = new List<FormOfPaymentSerialize>();
        
        order = getOrderData(recordId, cloneOrder);
        if (order.condicao_venda != null) {
            ordItemList = getOrderItemData(order.Id, cloneOrder);
            divisionList = getShippingDivison();
            
            Decimal productQuantity = 0;
            for (ProductSerialize item : ordItemList) {
                productQuantity += item.quantity + (item.amountUsed != null ? item.amountUsed : 0);
            }
            order.freightPerUnit = order.freightValue != null ? order.freightValue / productQuantity : 0;
            order.motherTotalQuantity = productQuantity;
        }

        if (order.bpStorage != null) {
            bpAccount = getOrderAccountData(order.bpStorage);
        }

        if (order.recTypeId == Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('VendaBarter').getRecordTypeId()) {
            commodityList = getCommodityData(order.Id);
            commodityTax = getcommodityTax(commodityList[0].commodityId);
        }
        account = getOrderAccountData(order.AccountId);
        formsOfPayment = getFormsOfPayment(order.Id);

        return JSON.serialize(new OrderSerialize(order, ordItemList, divisionList, account, commodityList, formsOfPayment, commodityTax, bpAccount));
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
        Order order = [SELECT Id, OrderNumber, Description, DescriptionBillingSale__c, AccountId, Type, ShippingAccount__c , ShippingAccount__r.Phone,  ShippingAccount__r.Name, Higher_Discount__c,
        ShippingAccount__r.BillingCity, ShippingAccount__r.BillingState ,ShippingAccount__r.CPF__c, ShippingAccount__r.CNPJ__c , SalesCondition__c, SalesCondition__r.Name, FreightValue__c,
        Pricebook2.InitialDate__c, Pricebook2.EndDate__c, PaymentDate__c,  CustomerOrderNumber__c, Crop__c , Crop__r.Name, Culture__c , Culture__r.Name, OrderMargin__c, RecordTypeId, MTO__c,
        PaymentForm__c, StatusSF__c, CodigoSAP__c, SalesOrg__c, SalesOrg__r.Name, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c, SalesCTV__r.Name, OrderType__c, BPStorage__c,
        PaymentCondition__c, PaymentCondition__r.Name, ShippingDate__c, Incoterms__c, OrderReference__c, OrderReference__r.Name, IsOrderMother__c, Company__c, CompanyReceiver__c, CompanyReceiver__r.SupplierCenter__c, Hectare__c, Status, DistributionCenter__c
        FROM Order 
        WHERE Id = :orderId LIMIT 1];
        return new HeaderSerialize(order, cloneOrder);
    }

    public static Map<String, Decimal> verifyConditionsToCalcBrokerage(Id orderId){
        Order order = [SELECT Id, SalesOrg__c, OrderReference__c, OrderType__c FROM Order WHERE Id =: orderId LIMIT 1];
        Map<String, Decimal> productBrokerageUnitMap = new Map<String,Decimal>();
        Id orderDefinitive;
        Boolean seedSale = isSeedSale(order.SalesOrg__c, null);
        if(seedSale && order.OrderType__c != 'Pedido Filho'){
            orderDefinitive = order.Id;
        }else if(seedSale && order.OrderType__c == 'Pedido Filho'){
            orderDefinitive = order.OrderReference__c;
        }

        if(orderDefinitive != null){
            List<OrderItem> orderItemList = [SELECT Brokerage__c, Quantity, Product2Id FROM OrderItem WHERE OrderId =: orderDefinitive];
            for(OrderItem orderItem : orderItemList){
                productBrokerageUnitMap.put(orderItem.Product2Id, (orderItem.Brokerage__c / orderItem.Quantity));
            }
        }
        return productBrokerageUnitMap;

    }
    public static List<ProductSerialize> getOrderItemData(Id orderId, Boolean cloneOrder) {
        Map<String, Decimal> productBrokerageUnitMap = verifyConditionsToCalcBrokerage(orderId);

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
                   Brokerage__c,
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
                   ItemBalance__c,
                   PTA__c,
                   PriceListCode__c,
                   ReasonRefuse__c,
                   Sieve__c,
                   Class__c,
                   TSIValue__c,
                   RoyaltyAmount__c,
                   TotalTSIAmount__c,
                   TotalRoyaltyAmount__c,
                   ComboPromotion__c,
                   AgrogalaxyComboDiscount__c,
                   IndustryComboDiscount__c
              FROM OrderItem
             WHERE OrderId =: orderId
        ]){
            if (item.ReasonRefuse__c == null || item.ReasonRefuse__c == '') {
                Decimal itemPracticedCost = item.PracticedCost__c != null ? item.PracticedCost__c : 0;
                Decimal itemDiscount = item.DiscountValue__c != null ? item.DiscountValue__c : 0;
                totalCost += itemPracticedCost * item.Quantity;
                totalDiscount += itemDiscount;
                totalQuantity += item.Quantity;
                Decimal brokerageUnit = productBrokerageUnitMap.containsKey(item.Product2Id) ? productBrokerageUnitMap.get(item.Product2Id) : null;
                prods.add(new ProductSerialize(item, counter, cloneOrder, brokerageUnit));
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

    public static List<TaxDataSerialize> getcommodityTax(Id orderCommodityId) {
        List<TaxDataSerialize> taxes = new List<TaxDataSerialize>();
        for (CommodityTaxes__c commodityTax : [
            SELECT Id,
                   Tax__c,
                   Commodity__c,
                   Commodity__r.Product__c,
                   DeductionAmount__c,
                   PercentageDeducted__c
              FROM CommodityTaxes__c
             WHERE Commodity__c =: orderCommodityId
        ]) {
            taxes.add(new TaxDataSerialize(commodityTax));
        }
        return taxes;
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
        Account account = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState, StateRegistration__c, Parent.Name, ShippingStreet, Number__c, Complement__c, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCity, Neighborhood__c, Email__c FROM Account WHERE Id =: accountId LIMIT 1];
        return new AccountSerialize(account);
    }

    @AuraEnabled
    public static String getAccountDataChild(Id accountId){
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
                accountList = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState, Parent.Name, StateRegistration__c, ShippingStreet, Number__c, Complement__c, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCity, Neighborhood__c, Email__c FROM Account WHERE Status__c = 'Ativo' AND ((ParentId =: accountId AND Id IN: relatedAccounts AND ExternalId__c LIKE '0002%') OR (Id =: accountId AND CNPJ__c != null AND CPF__c = null) OR (ParentId IN: familyAccountIds AND ExternalId__c LIKE '0002%' AND Id IN: relatedAccounts))];
            } else {
                accountList = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState, Parent.Name, StateRegistration__c, ShippingStreet, Number__c, Complement__c, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCity, Neighborhood__c, Email__c FROM Account WHERE Status__c = 'Ativo' AND ((ParentId =: accountId AND ExternalId__c LIKE '0002%') OR (Id =: accountId AND CNPJ__c != null AND CPF__c = null) OR ((ParentId IN: familyAccountIds AND ExternalId__c LIKE '0002%')))];
            }

            for(Account account : accountList) accountListSerialize.add(new AccountSerialize(account));
            return JSON.serialize(new AccountSerialize(accountListSerialize));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Set<Id> getTerritoryAccounts() {
        try {
            Set<Id> sellerTerritoryIds = new Set<Id>();
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
                    sellerTerritoryIds.add(userAssociation.Territory2Id);
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
			else if (userTerritoryType == 'SellerPosition') territoryQuery += 'WHERE Id IN: sellerTerritoryIds';
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
                         .selectFields(new Set<String>{'ItemBalance__c', 'Quantity'});

            String query = new Q(Order.SObjectType)
                           .addSubquery(subQuery)
                           .selectFields(new Set<String>{'Id', 'CustomerOrderNumber__c'})
                           .add(Q.condition('Id').equalsTo(orderId))
                           .build();
            Order motherOrder = Database.query(query);

            Boolean isAvalaible = false;
            for (OrderItem orderItem : motherOrder.OrderItems) {
                if (orderItem.ItemBalance__c > 0) isAvalaible = true;
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
        /* Map<Id, GeneralQuotas__c> generalQuotasById = new Map<Id, GeneralQuotas__c>([
            SELECT Id, Balance__c, Consumed__c
              FROM GeneralQuotas__c
             WHERE Id IN: generalQuotasIds
        ]); */

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
            
            if (productQuantity > quota.balance) {
                result.hasQuota = false;
                result.invalidProductsNames = result.invalidProductsNames != '' ? result.invalidProductsNames + ', ' + quota.productName : quota.productName;
            } else {
                /* GeneralQuotas__c generalQuota = generalQuotasById.get(quota.generalQuotaId);
                System.debug('generalQuota: ' + generalQuota);
                generalQuota.Balance__c = (generalQuota.Balance__c != null ? generalQuota.Balance__c : 0) - productQuantity;
                generalQuota.Consumed__c = (generalQuota.Consumed__c != null ? generalQuota.Consumed__c : 0) + productQuantity;
                System.debug('generalQuota: ' + generalQuota);
                result.generalQuotasToUpdate.add(generalQuota); */

                IndividualQuotas__c individualQuota = individualQuotasById.get(quota.individualQuotaId);
                System.debug('individualQuota: ' + individualQuota);
                individualQuota.Balance__c = (individualQuota.Balance__c != null ? individualQuota.Balance__c : 0) - productQuantity;
                individualQuota.Consumed__c = (individualQuota.Consumed__c != null ? individualQuota.Consumed__c : 0) + productQuantity;
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
                order = [SELECT Id, Description, DescriptionBillingSale__c, AccountId, Type, ShippingAccount__c, SalesCondition__c, PaymentDate__c, ShippingDate__c, PaymentCondition__c, CustomerOrderNumber__c, OrderType__c, OrderReference__c, Higher_Discount__c,
                                Crop__c, Culture__c, PaymentForm__c, StatusSF__c, SalesOrg__c, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c, EffectiveDate, Company__c, Hectare__c, OrderMargin__c, Status, FreightValue__c, BPStorage__c
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
                       ActivitySector__r.Name,
                       DistributionChannel__c
                  FROM Company__c
                 WHERE Id =: orderData.headerData.companyId
            ]) {
                company = accountCompany;
            }

            Map<Id, OrderItem> motherItems = new Map<Id, OrderItem>();
            Boolean newDivision = false;
            Decimal motherQuantity = 0;
            Decimal motherFreight = 0;
            Map<String, Decimal> individualValuesByType = new Map<String, Decimal>();
            if (orderData.headerData.pedido_mae.Id != null || order.OrderReference__c != null) {
                for (OrderItem item : [
                    SELECT Id,
                           Product2Id,
                           Quantity,
                           ItemBalance__c,
                           NumeroSap__c,
                           FinalTotalValue__c,
                           TotalTSIAmount__c,
                           TotalRoyaltyAmount__c,
                           FreightValue__c,
                           OrderId,
                           Order.FreightValue__c,
                           Order.OrderReference__r.FreightValue__c,
                           ReasonRefuse__c
                      FROM OrderItem
                     WHERE OrderId =: orderData.headerData.pedido_mae.Id
                        OR OrderId =: order.OrderReference__c
                ]) {
                    if (item.ReasonRefuse__c == null || item.ReasonRefuse__c == '') {
                        motherQuantity += item.Quantity;
                        if (item.OrderId != orderData.headerData.pedido_mae.Id) {
                            motherFreight = item.Order.OrderReference__r.FreightValue__c != null ? item.Order.OrderReference__r.FreightValue__c : 0;
                        } else {
                            motherFreight = item.Order.FreightValue__c != null ? item.Order.FreightValue__c : 0;
                        }

                        if (!individualValuesByType.containsKey('Germoplasma')) {
                            individualValuesByType.put('Germoplasma', item.FinalTotalValue__c);
                        } else {
                            Decimal currentGermoplasma = individualValuesByType.get('Germoplasma') + item.FinalTotalValue__c;
                            individualValuesByType.put('Germoplasma', currentGermoplasma);
                        }

                        if (item.TotalRoyaltyAmount__c != null && item.TotalRoyaltyAmount__c > 0) {
                            if (!individualValuesByType.containsKey('Royalties')) {
                                individualValuesByType.put('Royalties', item.TotalRoyaltyAmount__c);
                            } else {
                                Decimal currentRoyalty = individualValuesByType.get('Royalties') + item.TotalRoyaltyAmount__c;
                                individualValuesByType.put('Royalties', currentRoyalty);
                            }
                        }
                        
                        if (item.TotalTSIAmount__c != null && item.TotalTSIAmount__c > 0) {
                            if (!individualValuesByType.containsKey('TSI')) {
                                individualValuesByType.put('TSI', item.TotalTSIAmount__c);
                            } else {
                                Decimal currentTSI = individualValuesByType.get('TSI') + item.TotalTSIAmount__c;
                                individualValuesByType.put('TSI', currentTSI);
                            }
                        }
                        
                        motherItems.put(item.Product2Id, item);
                    }
                }
                newDivision = newOrder ? true : false;
            }
    
            Decimal orderTotalValue = 0;
            Decimal biggerDiscount = 0;
            Decimal tsiTotalValue = 0;
            Decimal royaltyTotalValue = 0;
            Boolean seedSale = isSeedSale(company.SalesOrg__c, null);
            Map<Id, Decimal> discountByProductIds = new Map<Id, Decimal>();
            Set<Id> productGroupsIds = new Set<Id>();
            Set<Id> productSubGroupsIds = new Set<Id>();

            
            Set<Id> setOrderItemsIds = new Set<Id>();
            List<Id> listProductsIds = new List<Id>();
            Set<Id> setProductHierarchyIds = new Set<Id>();
            Map<String, Decimal> quantitiesById = new Map<String, Decimal>();
            Map<String, Decimal> smallerMarginByProductGroup = new Map<String, Decimal>();
            Map<String, Decimal> smallerMarginByProductSubGroup = new Map<String, Decimal>();
            Map<String, Decimal> smallerMarginByProductId = new Map<String, Decimal>();
            Map<String, Decimal> IdOrderItemToQuantity = new Map<String, Decimal>();
            
            Decimal productQuantities = 0;
            for (ProductDeserialize orderProduct : orderData.productData) {
                if (seedSale && orderProduct.brokerage != null && orderProduct.brokerage > 0) {
                    orderTotalValue += orderProduct.totalPriceWithBrokerage;
                } else {
                    orderTotalValue += orderProduct.totalPrice;
                }
                
                if (orderProduct.orderItemId != null) {
                    setOrderItemsIds.add(orderProduct.orderItemId);
                }

                if (orderProduct.productId != null) {
                    IdOrderItemToQuantity.put(orderProduct.productId, orderProduct.quantity);
                    listProductsIds.add(orderProduct.productId);
                    if (!smallerMarginByProductId.containsKey(orderProduct.productId)) {
                        smallerMarginByProductId.put(orderProduct.productId, orderProduct.commercialMarginPercentage);
                    } else {
                        Decimal currentMargin = smallerMarginByProductId.get(orderProduct.productId);
                        currentMargin = currentMargin > orderProduct.commercialMarginPercentage ? orderProduct.commercialMarginPercentage : currentMargin;
                        smallerMarginByProductId.put(orderProduct.productId, currentMargin);
                    }
                }

                if(orderProduct.productSubgroupId != null){
                    if (!smallerMarginByProductSubGroup.containsKey(orderProduct.productSubgroupId)) {
                        smallerMarginByProductSubGroup.put(orderProduct.productSubgroupId, orderProduct.commercialMarginPercentage);
                    } else {
                        Decimal currentMargin = smallerMarginByProductSubGroup.get(orderProduct.productSubgroupId);
                        currentMargin = currentMargin > orderProduct.commercialMarginPercentage ? orderProduct.commercialMarginPercentage : currentMargin;
                        smallerMarginByProductSubGroup.put(orderProduct.productSubgroupId, currentMargin);
                    }
                }

                if (orderProduct.productGroupId != null && !orderProduct.containsCombo) {
                    if (!smallerMarginByProductGroup.containsKey(orderProduct.productGroupId)) {
                        smallerMarginByProductGroup.put(orderProduct.productGroupId, orderProduct.commercialMarginPercentage);
                    } else {
                        Decimal currentMargin = smallerMarginByProductGroup.get(orderProduct.productGroupId);
                        currentMargin = currentMargin > orderProduct.commercialMarginPercentage ? orderProduct.commercialMarginPercentage : currentMargin;
                        smallerMarginByProductGroup.put(orderProduct.productGroupId, currentMargin);
                    }
                }

                if (orderProduct.productHierarchyId != null && orderProduct.productHierarchyId != '') {
                    setProductHierarchyIds.add(orderProduct.productHierarchyId);
                }

                Decimal currentDiscount = orderProduct.commercialDiscountPercentage != '' ? (stringToDecimal(orderProduct.commercialDiscountPercentage) != null ? stringToDecimal(orderProduct.commercialDiscountPercentage) : 0) : 0;
                if (currentDiscount > 0) {
                    productGroupsIds.add(orderProduct.productGroupId);
                    productSubGroupsIds.add(orderProduct.productSubgroupId);
                    discountByProductIds.put(orderProduct.productId, currentDiscount);
                }

                if (order.OrderReference__c != null && motherItems.containsKey(orderProduct.productId) && order.Status == '0' && typeOrder != 'prepedido') {
                    OrderItem motherItem = motherItems.get(orderProduct.productId);
                    if (motherItem.ItemBalance__c - orderProduct.quantity < 0) {
                        return JSON.serializePretty(new AGRO_RemotingResult(true, '200', 'Não é possível efetivar o pedido por ter excedido as quantidades do pedido mãe.'));
                    }
                }

                if (seedSale) {
                    tsiTotalValue += orderProduct.tsiTotalPrice;
                    royaltyTotalValue += orderProduct.royaltyTotalPrice;
                }

                productQuantities += orderProduct.quantity;
                quantitiesById.put(orderProduct.productId, orderProduct.quantity);
            }

            QuantitiesResult quantitiesResult;
            Boolean childOrder = orderData.headerData.pedido_mae.Id != null;
            if (seedSale && (company.ActivitySector__r.Name.toUpperCase() == 'SEMENTE' || company.ActivitySector__r.Name.toUpperCase() == 'SEMENTES') && !childOrder) {
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
            
            try {
                for (Id orderItemId : setOrderItemsIds) {
                    Double auxiliar = 0;
                    for (DivisionDeserialize division : orderData.divisionData) {
                        if (division.orderItemKey == orderItemId) {
                            auxiliar += division.quantity;
                        }
                        if (auxiliar > IdOrderItemToQuantity.get(division.orderItemKey)) {
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Não é possível ultrapassar nas remessas a quantidade adquirida.'));
                        }
                    }
                }
            } catch (Exception ex) {
                System.debug('Erro: ' + ex.getMessage() + '  -  ' + ex.getStackTraceString());
            }
            

            Map<String, Decimal> orderMarginMap = new Map<String, Decimal>();
            if (orderData.headerData.pedido_mae.Id == null && company != null && company.ClientGroup__c != null) {
                for (Discount__c discount : [
                    SELECT Id,
                           Margin__c,
                           ProductGroup__c,
                           ProductsSubGroup__c,
                           Product__c
                      FROM Discount__c
                     WHERE Status__c = 'Aprovado'
                       AND Approver__c = 'ComiteMargem'
                       AND ClientGroup__c =: company.ClientGroup__c
                       AND SalesOrg__c =: company.SalesOrg__c
                       AND (
                            ProductGroup__c IN: smallerMarginByProductGroup.keySet() OR
                            ProductsSubGroup__c IN: smallerMarginByProductSubGroup.keySet() OR
                            Product__c IN: smallerMarginByProductId.keySet()
                       )
                       AND InitialDate__c <=: System.today()
                       AND EndDate__c >=: System.today()
                  ORDER BY Margin__c
                ]) {
                    if(discount.Product__c != null){
                        orderMarginMap.put(discount.Product__c, discount.Margin__c);
                    }else if(discount.ProductsSubGroup__c != null){
                        orderMarginMap.put(discount.ProductsSubGroup__c, discount.Margin__c);
                    }else if(discount.ProductGroup__c != null){
                        orderMarginMap.put(discount.ProductGroup__c, discount.Margin__c);
                    }
                }
            }

            order.MarginCommittee__c = false;
            for (String productId : smallerMarginByProductId.keySet()) {
                if (orderMarginMap.get(productId) >= smallerMarginByProductId.get(productId)) {
                    order.MarginCommittee__c = true;
                }
            }

            if(!order.MarginCommittee__c){
                for (String subGroupId : smallerMarginByProductSubGroup.keySet()) {
                    if (orderMarginMap.get(subGroupId) >= smallerMarginByProductGroup.get(subGroupId)) {
                        order.MarginCommittee__c = true;
                    }
                }
            }
            
            if(!order.MarginCommittee__c){
                for (String groupId : smallerMarginByProductGroup.keySet()) {
                    if (orderMarginMap.get(groupId) >= smallerMarginByProductGroup.get(groupId)) {
                        order.MarginCommittee__c = true;
                    }
                }
            }
            

            Map<String, PricebookEntry> entriesByProductsIds = new Map<String, PricebookEntry>();
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
                    entriesByProductsIds.put(entry.Product2Id + 'BRL', entry);
                }
            } else {
                for (PricebookEntry entry : [
                    SELECT Id,
                           Product2Id,
                           Pricebook2Id,
                           UnitPrice, 
                           CurrencyIsoCode
                      FROM PricebookEntry
                     WHERE Pricebook2.IsStandard = true
                       AND Product2Id IN: listProductsIds
                ]) {
                    pricebookId = entry.Pricebook2Id;
                    entriesByProductsIds.put(entry.Product2Id + String.valueOf(entry.CurrencyIsoCode), entry);
                }
            }
            
            List<String> deleteItems = itemsToExclude != null ? (List<String>) JSON.deserialize(itemsToExclude, List<String>.class) : new List<String>();
            Map<Id, OrderItem> orderItemsById = new Map<Id, OrderItem>();
            for (OrderItem ordItem : [
                SELECT Id, Product2Id, OrderId, ReasonRefuse__c
                  FROM OrderItem
                 WHERE Id IN: setOrderItemsIds
                    OR Id IN: deleteItems
            ]) {
                if (ordItem.ReasonRefuse__c == null || ordItem.ReasonRefuse__c == '') orderItemsById.put(ordItem.Id, ordItem);
            }

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

            if (company != null && orderData.headerData.pedido_mae.Id == null) {
                Id userTerritoryId;
                for (UserTerritory2Association userAssociation : [
                    SELECT Id,
                           UserId,
                           Territory2Id
                      FROM UserTerritory2Association
                     WHERE UserId =: orderData.headerData.ctv_venda.Id
                     AND 
                     Territory2Id IN (SELECT Territory2Id FROM ObjectTerritory2Association WHERE ObjectId =: orderData.accountData.Id)
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

                
                Decimal greaterDiscount = 0;
                Decimal smallerDiscount;

                if(!discountByProductIds.values().isEmpty()){
                    List<Decimal> discountSorted = discountByProductIds.values();
                    discountSorted.sort();
                    greaterDiscount = discountSorted[discountSorted.size() - 1];
                    smallerDiscount = discountSorted[0];
                }

                Map<String, Integer> approvalLevels = new Map<String, Integer>{
                    'GerenteFilial' => 1,
                    'GerenteRegional' => 2,
                    'Diretor' => 3,
                    'Diretor Torre' => 4
                };

                Map<String, Discount__c> discountByPriority = new Map<String, Discount__c>();
                for (Discount__c discount : [
                    SELECT Id,
                           Approver__c,
                           ProductGroup__c,
                           ProductsSubGroup__c,
                           Product__c,
                           MinPercentage__c,
                           MaxPercentage__c
                      FROM Discount__c
                     WHERE Status__c = 'Aprovado'
                       AND ClientGroup__c =: company.ClientGroup__c
                       AND SalesOrg__c =: company.SalesOrg__c
                       AND (
                            ProductGroup__c IN: productGroupsIds OR
                            ProductsSubGroup__c IN: productSubGroupsIds OR 
                            Product__c IN: listProductsIds
                       )
                       AND InitialDate__c <=: System.today()
                       AND EndDate__c >=: System.today()
                       AND (MinPercentage__c <=: smallerDiscount AND MaxPercentage__c >=: greaterDiscount)
                  ORDER BY MinPercentage__c, MaxPercentage__c
                ]) {
                    
                    if(discount.Product__c != null){
                        discountLogics(discountByPriority, discount, ('p-' + String.valueOf(discount.Product__c)), approvalLevels);
                    }else if(discount.ProductsSubGroup__c != null){
                        discountLogics(discountByPriority, discount, ('sg-' + String.valueOf(discount.ProductsSubGroup__c)), approvalLevels);
                    }else if(discount.ProductGroup__c != null){
                        discountLogics(discountByPriority, discount, ('g-' + String.valueOf(discount.ProductGroup__c)), approvalLevels);
                    }
        
                }

                Integer approvalNumber = 0;
                approvalNumber = setApprovalNumber(discountByPriority, approvalLevels);
                
                Integer counter = 0;
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
                order.ApprovalTowerDirector__c = null;
                order.TowerDirector__c = false;

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
                if (approvalNumber >= 4){
                    order.ApprovalTowerDirector__c = approvalsByTerritory.get(approvalByCounter.get(3));
                    order.TowerDirector__c = true;
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
            order.CurrencyIsoCode = orderData.headerData.moeda ;
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
            order.MTO__c = orderData.headerData.mto;
            order.FinalTotalValue__c = orderTotalValue;
            order.Company__c = company.Id;
            order.CompanyReceiver__c = orderData.headerData.companyFromDeliveredAccount.Id;
            order.DistributionCenter__c = orderData.summaryData.centerId != null ? orderData.summaryData.centerId : orderData.headerData.centerId;
            order.OrderType__c = orderData.headerData.pedido_mae.Id != null ? 'Pedido Filho' : (order.IsOrderMother__c ? 'Pedido Mãe' : 'Pedido Normal');
            order.OrderMargin__c = orderData.summaryData.orderMargin != null ? (orderData.summaryData.orderMargin.contains(' sacas') ?
                                   stringToDecimal(orderData.summaryData.orderMargin.replace(' sacas', '')) : stringToDecimal((orderData.summaryData.orderMargin))) : 0;
            order.ApprovalJustification__c = orderData.summaryData.justification;
            order.BPStorage__c = orderData.bpAccount != null ? orderData.bpAccount.Id : null;
            order.Higher_Discount__c = biggerDiscount;

            Decimal currentFreight = orderData.summaryData.freightValue;
            if (order.OrderType__c == 'Pedido Filho') {
                Account currentAccount = [SELECT Id, ParentId FROM Account WHERE Id =: order.ShippingAccount__c];
                order.AccountId = currentAccount.ParentId != null ? currentAccount.ParentId : currentAccount.Id;
            }

            if (order.Incoterms__c == 'CIF') {
                order.FinalTotalValue__c = order.FinalTotalValue__c + currentFreight;
            }
            order.FreightValue__c = (currentFreight != null) ? currentFreight : 0;

            Decimal germoTotalValue = order.FinalTotalValue__c;
            if (seedSale) {
                order.FinalTotalValue__c = order.FinalTotalValue__c + tsiTotalValue + royaltyTotalValue;
            }

            if (individualValuesByType.containsKey('Germoplasma') && seedSale) {
                Decimal currentGermoplasma = individualValuesByType.get('Germoplasma') + motherFreight;
                individualValuesByType.put('Germoplasma', currentGermoplasma);
            }

            if (Test.isRunningTest() || newOrder) {
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

                Map<Id, Decimal> quantitiesByProductGroup = new Map<Id, Decimal>();
                Set<Id> combosIds = new Set<Id>();

                Integer itemCounter = setOrderItemsIds.size() + 1;
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
                        orderItem.PricebookEntryId = entriesByProductsIds.get(orderProduct.productId + orderData.headerData.moeda).Id;
                        orderItem.Product2Id = orderProduct.productId;
                        orderItem.ListPrice = entriesByProductsIds.get(orderProduct.productId + orderData.headerData.moeda).UnitPrice != null ? entriesByProductsIds.get(orderProduct.productId + orderData.headerData.moeda).UnitPrice.setScale(2) : 0;
                        orderItem.UnitPrice = orderProduct.unitPrice != null ? orderProduct.unitPrice.setScale(2) : 0;
                        orderItem.ItemBalance__c = order.IsOrderMother__c ? orderProduct.quantity : null;
                        orderItem.ServiceDate = System.today();
                        itemCounter++;
                    }
                    
                    if (motherItems.containsKey(orderProduct.productId) && typeOrder != 'prepedido') {
                        OrderItem motherItem = motherItems.get(orderProduct.productId);
                        motherItem.ItemBalance__c = motherItem.ItemBalance__c != null ? motherItem.ItemBalance__c - orderProduct.quantity : 0;
                        motherItems.put(orderProduct.productId, motherItem);
                    }

                    orderItem.CommitteeTrigger__c = false;
                    if (orderMarginMap.get(orderProduct.productGroupId) >= orderProduct.commercialMarginPercentage && !orderProduct.containsCombo) {
                        orderItem.CommitteeTrigger__c = true;
                    }

                    if (quantitiesResult != null && typeOrder != 'prepedido') {
                        orderItem.IndividualQuotas__c = quantitiesResult.individualQuotasByProdId.get(orderProduct.productId);
                    }

                    if (quantitiesByProductGroup.containsKey(orderProduct.productGroupId)) {
                        Decimal currentQuantity = quantitiesByProductGroup.get(orderProduct.productGroupId);
                        currentQuantity += orderProduct.quantity;
                        quantitiesByProductGroup.put(orderProduct.productGroupId, currentQuantity);
                    } else {
                        quantitiesByProductGroup.put(orderProduct.productGroupId, orderProduct.quantity);
                    }

                    combosIds.add(orderProduct.comboId);
                    orderItem.IndustryComboDiscount__c = orderProduct.industryCombo ? orderProduct.comboDiscountValue : 0;
                    orderItem.AgrogalaxyComboDiscount__c = !orderProduct.industryCombo ? orderProduct.comboDiscountValue : 0;
                    orderItem.ComboPromotion__c = orderProduct.comboId;
                    orderItem.UnitPricePerBag__c = commodityPrice > 0 ? (orderProduct.unitPrice / commodityPrice) : null;
                    orderItem.TotalPricePerBag__c = commodityPrice > 0 ? (orderItem.UnitPricePerBag__c * orderProduct.quantity) : null;
                    orderItem.Quantity = orderProduct.quantity;
                    orderItem.ListPrice__c = orderProduct.listPrice != null ? orderProduct.listPrice : 0;
                    orderItem.PracticedPrice__c = orderProduct.unitPrice != null ? orderProduct.unitPrice : 0;
                    orderItem.Dosage__c = orderProduct.dosage != null ? orderProduct.dosage.setScale(6) : 0;
                    orderItem.Status__c = orderProduct.sapStatus != null ? statusValueByLabel.get(orderProduct.sapStatus) : null;
                    orderItem.UnitMeasure__c = orderProduct.unity;
                    orderItem.FinalTotalValue__c = !(seedSale) ? orderProduct.totalPrice : orderProduct.totalPriceWithBrokerage;
                    orderItem.Brokerage__c = orderProduct.brokerage;
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
                    orderItem.TSIValue__c = orderProduct.tListPrice;
                    orderItem.RoyaltyAmount__c = orderProduct.rListPrice;
                    orderItem.TotalTSIAmount__c = orderProduct.tsiTotalPrice;
                    orderItem.TotalRoyaltyAmount__c = orderProduct.royaltyTotalPrice;
                    listOrderItems.add(orderItem);
                }

                List<OrderItem> itemsToDelete = new List<OrderItem>();
                for (String itemToDeleteId : deleteItems) {
                    OrderItem itemToDelete = orderItemsById.get(itemToDeleteId);
                    if (itemToDelete != null && itemToDelete.OrderId != null && itemToDelete.OrderId == order.Id) {
                        itemsToDelete.add(itemToDelete);
                    }
                }

                OrderHelper.disableTrigger();
                update motherItems.values();
                delete itemsToDelete;
                OrderHelper.enableTrigger();

                String orderItemErrors = '';
                Set<Id> itemsIds = new Set<Id>();
                
                if (newOrder) OrderHelper.disableTrigger();
                List<Database.UpsertResult> insOrderItemResults = Database.upsert(listOrderItems, false);
                OrderHelper.enableTrigger();
                if (newOrder) {
                    OrderHelper.sendApprovalProccess(new List<Order>{order});
                    OrderHelper.creatyShareRecord(new List<Order>{order});
                }
                
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
                    // System.debug('quantitiesResult.generalQuotasToUpdate: ' + quantitiesResult.generalQuotasToUpdate);
                    // update quantitiesResult.generalQuotasToUpdate;
                    System.debug('quantitiesResult.individualQuotasToUpdate: ' + quantitiesResult.individualQuotasToUpdate);
                    IndividualQuotasHelper.disableTrigger();
                    GeneralQuotasTriggerHelper.disableTrigger();
                    update quantitiesResult.individualQuotasToUpdate;
                    GeneralQuotasTriggerHelper.enableTrigger();
                    IndividualQuotasHelper.enableTrigger();
                }

                if (orderData.comboData != null && typeOrder != 'prepedido') {
                    Map<Id, ComboPromotion__c> combosById = new Map<Id, ComboPromotion__c>([
                        SELECT Id, CombosQuantity__c
                          FROM ComboPromotion__c
                         WHERE Id IN: combosIds
                    ]);
    
                    for (ComboDeserialize combo : orderData.comboData) {
                        ComboPromotion__c currentCombo = combosById.get(combo.comboId);
                        if (currentCombo != null) {
                            currentCombo.CombosQuantity__c = currentCombo.CombosQuantity__c - combo.comboQuantity;
                            combosById.put(combo.comboId, currentCombo);
                        }
                    }
                    update combosById.values();

                }

                Set<Id> setDivisionIds = new Set<Id>();
                List<ShippingDivison__c> listShippingDivision = new List<ShippingDivison__c>();

                Map<String, OrderItem> mapOrderItems = new Map<String, OrderItem>();
                for (OrderItem orderItem : [
                    SELECT Id,
                           Product2Id,
                           Quantity,
                           UnitPrice,
                           NumeroSap__c,
                           ReasonRefuse__c
                      FROM OrderItem
                     WHERE Id IN: itemsIds
                ]) {
                    if (orderItem.ReasonRefuse__c == null || orderItem.ReasonRefuse__c == '') mapOrderItems.put(orderItem.Product2Id, orderItem);
                }
                
                Map<Id, Integer> divisionCounterByItemId = new Map<Id, Integer>();
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
                               OrderItem__c,
                               ExternalId__c
                          FROM ShippingDivison__c
                         WHERE Id IN: setDivisionIds
                    ]) {
                        divisionsById.put(shippingDivison.Id, shippingDivison);
                        divisionCounterByItemId = getDivisionCounter(divisionCounterByItemId, String.valueOf(shippingDivison.OrderItem__c));
                    }

                    Map<Id, Decimal> quantityDistributedByItem = new Map<Id, Decimal>();
                    for (DivisionDeserialize division : divisionsByKey.values()) {
                        ShippingDivison__c shippingDivision;
                        if (!newOrder && !cloneOrder && divisionsById.containsKey(division.divisionId)) {
                            shippingDivision = divisionsById.get(division.divisionId);
                        } else {
                            shippingDivision = new ShippingDivison__c();
                            String key = mapOrderItems.get(division.orderItemKey).Id;
                            divisionCounterByItemId = getDivisionCounter(divisionCounterByItemId, String.valueOf(key));
                            Integer divisionCounter = divisionCounterByItemId.get(key);
                            String divisionSapNumber = divisionCounter >= 10 ? '0' + String.valueOf(divisionCounter) : '00' + String.valueOf(divisionCounter);
                            
                            shippingDivision.SapNumber__c = divisionSapNumber;
                            shippingDivision.ExternalId__c = order.Id + '|' + mapOrderItems.get(division.orderItemKey).NumeroSap__c + '|' + shippingDivision.SapNumber__c;
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
                            divisionCounterByItemId = getDivisionCounter(divisionCounterByItemId, String.valueOf(item.Id));
                            Integer divisionCounter = divisionCounterByItemId.get(item.Id);
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
                        }
                    }
                } else if (order.OrderType__c != 'Pedido Mãe') {
                    for (OrderItem item : listOrderItems) {
                        divisionCounterByItemId = getDivisionCounter(divisionCounterByItemId, String.valueOf(item.Id));
                        Integer divisionCounter = divisionCounterByItemId.get(item.Id);
                        String divisionSapNumber = divisionCounter >= 10 ? '0' + String.valueOf(divisionCounter) : '00' + String.valueOf(divisionCounter);
                        ShippingDivison__c shippingDivision = new ShippingDivison__c();
                        shippingDivision.ExternalId__c = order.Id + '|' + mapOrderItems.get(item.Product2Id).NumeroSap__c + '|' + divisionSapNumber;
                        shippingDivision.SapNumber__c = divisionSapNumber;
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

                Decimal toatlCommodityValue = 0;
                List<OrderCommodity__c> upsCommodities = new List<OrderCommodity__c>();
                if (orderData.commodityData != null && orderData.commodityData.size() > 0) {
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
                        orderCommodity.CurrencyIsoCode = orderData.headerData.moeda;
                        upsCommodities.add(orderCommodity);

                        toatlCommodityValue = commodity.commodityPrice * orderCommodity.BagQuantity__c;
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

                if (orderData.taxData != null && orderData.taxData.size() > 0) {
                    List<CommodityTaxes__c> upsCommoditiesTaxes = new List<CommodityTaxes__c>();
                    Set<Id> setCommodityTaxIds = new Set<Id>();
                    for (TaxData tax : orderData.taxData) {
                        setCommodityTaxIds.add(tax.commodityTaxId);
                    }

                    Map<Id, CommodityTaxes__c> taxesById = new Map<Id, CommodityTaxes__c>();
                    for (CommodityTaxes__c commodityTax : [
                        SELECT Id
                          FROM CommodityTaxes__c
                         WHERE Id IN: setCommodityTaxIds
                    ]) {
                        System.debug('commodityTax: ' + commodityTax);
                        taxesById.put(commodityTax.Id, commodityTax);
                    }

                    for (TaxData taxData : orderData.taxData) {
                        System.debug('orderData.taxData: ' + orderData.taxData);
                        if (taxData.taxProduct == upsCommodities[0].Product__c) {
                            CommodityTaxes__c commodityTax;
                            if (!newOrder && !cloneOrder && taxesById.containsKey(taxData.commodityTaxId)) {
                                commodityTax = taxesById.get(taxData.commodityTaxId);
                            } else {
                                commodityTax = new CommodityTaxes__c();
                            }

                            commodityTax.Tax__c = taxData.taxId;
                            commodityTax.Commodity__c = upsCommodities[0].Id;
                            commodityTax.DeductionAmount__c = toatlCommodityValue * (taxData.taxPercentage / 100);
                            commodityTax.PercentageDeducted__c = taxData.taxPercentage;
                            System.debug('commodityTax: ' + commodityTax);
                            upsCommoditiesTaxes.add(commodityTax);
                        }
                    }
                    
                    if (upsCommoditiesTaxes.size() > 0) {
                        String commodityErrors = '';
                        List<Database.UpsertResult> upsCommoditiesTaxesResults = Database.upsert(upsCommoditiesTaxes, false);
                        for (Database.UpsertResult result : upsCommoditiesTaxesResults){
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
                    SELECT Id,
                           ExternalId__c
                      FROM FormPayment__c
                     WHERE Id IN: setPaymentIds
                       AND Order__c =: order.Id
                ]) {
                    paymentFormsById.put(formOfPayment.Id, formOfPayment);
                }

                if(orderData.formsOfPayment != null) {
                    Integer counter = paymentFormsById != null ? paymentFormsById.size() + 1 : 1;
                    for (FormOfPaymentDeserialize payment : orderData.formsOfPayment) {
                        if ((payment.paymentType == 'TSI' && tsiTotalValue > 0) ||
                            (payment.paymentType == 'Royalties' && royaltyTotalValue > 0) ||
                            (payment.paymentType == 'Germoplasma' && germoTotalValue > 0)) {
                            FormPayment__c formOfPayment;
                            if (payment.paymentId != null && payment.paymentId != '' && !newOrder && !cloneOrder && paymentFormsById.containsKey(payment.paymentId)) {
                                formOfPayment = paymentFormsById.get(payment.paymentId);
                            } else {
                                formOfPayment = new FormPayment__c();
                                formOfPayment.Order__c = order.Id;
                                formOfPayment.ExternalId__c = order.Id + '|' + counter;
                                counter++;
                            }
                            
                            Decimal paymentValueToUse = Decimal.valueOf(payment.value);
                            if (childOrder) {
                                Decimal currentTypeValue = payment.paymentType == 'Germoplasma' ? germoTotalValue :
                                                           (payment.paymentType == 'Royalties' ? royaltyTotalValue : tsiTotalValue);
                                Decimal motherAmount = individualValuesByType.get(payment.paymentType);
                                paymentValueToUse = (currentTypeValue * paymentValueToUse) / motherAmount;
                            }

                            formOfPayment.PaymentType__c = payment.paymentType;
                            formOfPayment.PaymentDate__c = Date.valueOf(payment.paymentDay);
                            formOfPayment.Amount__c = paymentValueToUse;
                            upsFormsOfPayment.add(formOfPayment);
                        }
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
			String msg = 'Ocorreu um erro em OrderScreenController Linha: ' +ex.getLineNumber() + '. Contate o administrador';
            
            return JSON.serializePretty(new AGRO_RemotingResult(true, '200', msg));
		}
    }

    private static void discountLogics(Map<String, Discount__c> discountByPriority, Discount__c discount, String keyDiscount,Map<String, Integer> approvalLevels){
        if (!discountByPriority.containsKey(keyDiscount)) {
            discountByPriority.put(keyDiscount, discount);
        } else {
            String discountApprover = discountByPriority.get(keyDiscount).Approver__c;
            if (approvalLevels.get(discount.Approver__c) > approvalLevels.get(discountApprover)) {
                discountByPriority.put(keyDiscount, discount);
            }
        }
    }

    private static Integer setApprovalNumber(Map<String, Discount__c> discountByPriority, Map<String, Integer> approvalLevels){
       Map<String, List<Integer>> discountNumberMap = new Map<String, List<Integer>>();
        discountNumberMap.put('p', new List<Integer>());
        discountNumberMap.put('sg', new List<Integer>());
        discountNumberMap.put('g', new List<Integer>());
        String key1 = '';
        String key2 = '';
        String key3 = '';

        for (Discount__c approverDiscount : discountByPriority.values()) {
            key1 = 'p-' + String.valueOf(approverDiscount.Product__c);
            key2 = 'sg-' + String.valueOf(approverDiscount.ProductsSubGroup__c);
            key3 = 'g-' + String.valueOf(approverDiscount.ProductGroup__c);

            if(discountByPriority.containsKey(key1)){
                discountNumberMap.get('p').add(approvalLevels.get(discountByPriority.get(key1).Approver__c));
            }else if(discountByPriority.containsKey(key2)){
                discountNumberMap.get('sg').add(approvalLevels.get(discountByPriority.get(key2).Approver__c));
            }else if(discountByPriority.containsKey(key3)){
                discountNumberMap.get('g').add(approvalLevels.get(discountByPriority.get(key3).Approver__c));
            }
        }

        List<Integer> discountNumberSorted = new List<Integer>();
        if(!discountNumberMap.get('p').isEmpty()){
            discountNumberSorted = discountNumberMap.get('p');
            discountNumberSorted.sort();
            return discountNumberSorted[discountNumberSorted.size() - 1];
        }

        if(!discountNumberMap.get('sg').isEmpty()){
            discountNumberSorted = discountNumberMap.get('sg');
            discountNumberSorted.sort();
            return discountNumberSorted[discountNumberSorted.size() - 1];
        }

        if(!discountNumberMap.get('g').isEmpty()){
            discountNumberSorted = discountNumberMap.get('g');
            discountNumberSorted.sort();
            return discountNumberSorted[discountNumberSorted.size() - 1];
        }

        return 0;
    }


    public static Map<Id, Integer> getDivisionCounter(Map<Id, Integer> divisionCounterByItemId, String orderItemId) {
        Integer divisionCounter;
        if (divisionCounterByItemId.containsKey(orderItemId)) {
            divisionCounter = divisionCounterByItemId.get(orderItemId) + 1;
            divisionCounterByItemId.put(orderItemId, divisionCounter);
        } else {
            divisionCounter = 1;
            divisionCounterByItemId.put(orderItemId, divisionCounter);
        }
        return divisionCounterByItemId;
    }

    @AuraEnabled
    public static String getSpecificCombos(String data, String companyData, String productData, Boolean childOrder, List<Id> existingCombosIds) {
        String companiesData = getAccountCompanies(companyData, false, false, false, childOrder);
        CompanyInfos company = new CompanyInfos();

        if (Test.isRunningTest()) {
            company = (CompanyInfos) JSON.deserialize(companyData, CompanyInfos.class);
        } else {
            CompanyInfosSerialize companyInfos = (CompanyInfosSerialize) JSON.deserialize(companiesData, CompanyInfosSerialize.class);
            company = companyInfos.listCompanyInfos[0];
        }
        
        HeaderValues comboData = (HeaderValues) JSON.deserialize(data, HeaderValues.class);
        CustomLookupController.ProductParams productParams = (CustomLookupController.ProductParams) JSON.deserialize(productData, CustomLookupController.ProductParams.class);
        productParams.supplierCenter = company.supplierCenter;
        productParams.salesOrgId = company.salesOrgId;
        productParams.salesOfficeId = company.salesOfficeId;
        productParams.salesTeamId = company.salesTeamId;
        productParams.dontGetSeeds = productParams.dontGetSeeds;
        productParams.activitySectorName = company.activitySectorName;
        
        Map<Id, ComboPromotionData> result = new Map<Id, ComboPromotionData>();
        Map<Id, Set<Id>> combosByProductId = new Map<Id, Set<Id>>();
        Set<Id> combosIds = new Set<Id>();
        Set<Id> mixCombosIds = new Set<Id>();
        Set<Id> recTypes = new Set<Id>();
        recTypes.add(Schema.SObjectType.ComboPromotion__c.getRecordTypeInfosByDeveloperName().get('ProductMix').getRecordTypeId());
        recTypes.add(Schema.SObjectType.ComboPromotion__c.getRecordTypeInfosByDeveloperName().get('Specific_Items').getRecordTypeId());
        
        for (ComboPromotion__c promotion : [
            SELECT Id,
                   ComboType__c,
                   Condition__c,
                   CombosQuantity__c,
                   PaymentCondition__c,
                   DiscountPercentage__c,
                   RecordType.DeveloperName
              FROM ComboPromotion__c
             WHERE RecordTypeId IN: recTypes
               AND Status__c = 'Ativo'
               AND 
               (
                    (Id IN: existingCombosIds)
                    OR
                    (
                        Safra__c =: comboData.cropId
                    AND SalesOrg__c =: company.salesOrgId
                    AND SalesCondition__c =: comboData.salesConditionId
                    AND (PaymentCondition__c = null OR PaymentCondition__c =: comboData.paymentConditionId)
                    AND CombosQuantity__c > 0
                    AND (SalesTeam__c = null OR SalesTeam__c =: productParams.salesTeamId)
                    AND (SalesOffice__c = null OR SalesOffice__c =: productParams.salesOfficeId)
                    )
               )
             LIMIT 4
            OFFSET :comboData.rowsToSkip
        ]) {
            if(promotion.RecordType.DeveloperName == 'Specific_Items' || (promotion.RecordType.DeveloperName == 'ProductMix' && promotion.Condition__c == 'Total')){
                ComboPromotionData comboPromotionData = new ComboPromotionData();
                comboPromotionData.comboQuantity = 0;
                comboPromotionData.comboId = promotion.Id;
                comboPromotionData.comboType = promotion.ComboType__c;
                comboPromotionData.comboCondition = promotion.Condition__c;
                comboPromotionData.paymentConditionId = promotion.PaymentCondition__c;
                comboPromotionData.comboAvailableQuantity = promotion.CombosQuantity__c;
                comboPromotionData.comboDiscountPercentage = promotion.DiscountPercentage__c;
                comboPromotionData.specificItemCombo = promotion.RecordType.DeveloperName == 'Specific_Items' ? true : false;
                comboPromotionData.recTypeDevName = promotion.RecordType.DeveloperName;
                comboPromotionData.groupQuantities = new List<GroupData>();
                comboPromotionData.formerItems = new List<ComboItems>();
                comboPromotionData.benefitItems = new List<ComboItems>();

                if (promotion.RecordType.DeveloperName == 'ProductMix') {
                    mixCombosIds.add(promotion.Id);
                }

                combosIds.add(promotion.Id);
                result.put(promotion.Id, comboPromotionData);
            }
        }

        List<String> prodsIds = new List<String>();
        for (FormerProduct__c formerProd : [
            SELECT Id,
                   Product__c,
                   Product__r.Name,
                   Product__r.ExternalId__c,
                   MinQuantity__c,
                   ComboPromotion__c
              FROM FormerProduct__c
             WHERE ComboPromotion__c IN: combosIds
        ]) {
            ComboPromotionData comboPromotionData = result.get(formerProd.ComboPromotion__c);
            String productCode = formerProd.Product__r.ExternalId__c != null ? String.valueOf(Integer.valueOf(formerProd.Product__r.ExternalId__c) * 1) : '';
            ComboItems formerItem = new ComboItems();
            formerItem.comboId = formerProd.ComboPromotion__c;
            formerItem.productId = formerProd.Product__c;
            formerItem.productName = formerProd.Product__r.Name;
            formerItem.productCode = productCode;
            formerItem.minQUantity = formerProd.MinQuantity__c;

            if(mixCombosIds.contains(formerProd.ComboPromotion__c)){
                GroupData groupData = new GroupData();
                groupData.productId = formerProd.Product__c;
                groupData.productName = formerProd.Product__r.Name;
                groupData.productCode = productCode;
                groupData.quantity = formerProd.MinQuantity__c;
                comboPromotionData.groupQuantities.add(groupData);
            }
            
            prodsIds.add(formerProd.Product__c);
            comboPromotionData.formerItems.add(formerItem);
            result.put(formerProd.ComboPromotion__c, comboPromotionData);

            if (!combosByProductId.containsKey(formerProd.Product__c)) {
                combosByProductId.put(formerProd.Product__c, new Set<Id>{formerProd.ComboPromotion__c});
            } else {
                Set<Id> productCombos = combosByProductId.get(formerProd.Product__c);
                productCombos.add(formerProd.ComboPromotion__c);
                combosByProductId.put(formerProd.Product__c, productCombos);
            }
        }

        for (BenefitProduct__c benefitProd : [
            SELECT Id,
                   Product__c,
                   Product__r.Name,
                   Product__r.ExternalId__c,
                   MinQuantity__c,
                   ComboPromotion__c,
                   DiscountPercentage__c
              FROM BenefitProduct__c
             WHERE ComboPromotion__c IN: combosIds
        ]) {
            ComboPromotionData comboPromotionData = result.get(benefitProd.ComboPromotion__c);
            String productCode = benefitProd.Product__r.ExternalId__c != null ? String.valueOf(Integer.valueOf(benefitProd.Product__r.ExternalId__c) * 1) : '';
            ComboItems benefitItem = new ComboItems();
            benefitItem.comboId = benefitProd.ComboPromotion__c;
            benefitItem.productId = benefitProd.Product__c;
            benefitItem.productName = benefitProd.Product__r.Name;
            benefitItem.productCode = productCode;
            benefitItem.minQUantity = benefitProd.MinQuantity__c;
            benefitItem.discountPercentage = benefitProd.DiscountPercentage__c;
            
            prodsIds.add(benefitProd.Product__c);
            comboPromotionData.benefitItems.add(benefitItem);
            result.put(benefitProd.ComboPromotion__c, comboPromotionData);

            if (!combosByProductId.containsKey(benefitProd.Product__c)) {
                combosByProductId.put(benefitProd.Product__c, new Set<Id>{benefitProd.ComboPromotion__c});
            } else {
                Set<Id> productCombos = combosByProductId.get(benefitProd.Product__c);
                productCombos.add(benefitProd.ComboPromotion__c);
                combosByProductId.put(benefitProd.Product__c, productCombos);
            }
        }

        Set<Id> existingPrices = new Set<Id>();
        CustomLookupController.ProductDataResult productPrices = CustomLookupController.fetchProductsRecords('', JSON.serialize(productParams), false, prodsIds, false, false, false);
        for (CustomLookupController.ProductData products : productPrices.recordsDataList) {
            existingPrices.add(products.Id);
        }

        Set<Id> combosToRemove = new Set<Id>();
        for (Id idProduct : combosByProductId.keySet()) {
            if (!existingPrices.contains(idProduct)) {
                combosToRemove.addAll(combosByProductId.get(idProduct));
            }
        }

        List<ComboPromotionData> availableCombos = new List<ComboPromotionData>();
        for (Id idCombo : result.keySet()) {
            if (!combosToRemove.contains(idCombo)) {
                availableCombos.add(result.get(idCombo));
            }
        }
        return JSON.serialize(availableCombos);
    }

    @AuraEnabled
    public static String getAccountCompanies(String data, Boolean isHeader, Boolean verifyUserType, Boolean priceScreen, Boolean childOrder) {
        GetCompanyInfos companyInfos = (GetCompanyInfos) JSON.deserialize(data, GetCompanyInfos.class);
        Set<Id> userTerritoriesIds = new Set<Id>();
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
        List<Id> territoriesRelatedToCtv = new List<Id>();
        for (UserTerritory2Association userAssociation : [
            SELECT Id,
                   UserId,
                   Territory2Id,
                   Territory2.Territory2Type.DeveloperName
              FROM UserTerritory2Association
             WHERE UserId =: companyInfos.ctvId
        ]) {
            territoriesRelatedToCtv.add(userAssociation.Territory2Id);
        }
        if (companyInfos.accountId != null && companyInfos.accountId != '') {
            for (ObjectTerritory2Association objAssociation : [
                SELECT Id,
                       Territory2Id,
                       Territory2.Territory2Type.DeveloperName
                  FROM ObjectTerritory2Association
                 WHERE ObjectId =: companyInfos.accountId
                   AND Territory2Id IN: territoriesRelatedToCtv
            ]) {
                userTerritoriesIds.add(objAssociation.Territory2Id);
            }
        } else {
            for (ObjectTerritory2Association objAssociation : [
                SELECT Id,
                       Territory2Id,
                       Territory2.Territory2Type.DeveloperName
                  FROM ObjectTerritory2Association
                 WHERE Territory2Id IN: territoriesRelatedToCtv
            ]) {
                userTerritoriesIds.add(objAssociation.Territory2Id);
            }
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
            'Diretor' => 3,
            'Diretor Torre' => 4
        };
        Integer counter = 0;
        List<Territory2> salesTeamTerritories;
        Set<Id> territoriesIds = new Set<Id>();
        while (counter < companyInfos.approvalNumber) {
            for (Id userTerritoryId : userTerritoriesIds) {
                Territory2 territory = territoryAndParents.containsKey(userTerritoryId) ? territoryAndParents.get(userTerritoryId) : new Territory2();
                if (territory != null && territory.ParentTerritory2Id != null) {
                    territoriesIds.add(territory.Id);
                }
                if (counter == 1) {
                    salesTeamTerritories.add(territory);
                }
            }
            counter++;
        }
        if (salesTeamTerritories == null && territoriesIds.size() > 0) {
            salesTeamTerritories = new List<Territory2>();
            for (Id userTerritoryId : territoriesIds) {
                if (territoryAndParents.get(userTerritoryId) != null && territoryAndParents.get(territoryAndParents.get(userTerritoryId).ParentTerritory2Id) != null) {
                    salesTeamTerritories.add(territoryAndParents.get(territoryAndParents.get(userTerritoryId).ParentTerritory2Id));
                }
            }
        }
        Set<String> fieldSet = new Set<String>{
            'Id','SalesOrg__c', 'SalesTeam__r.Name', 'SalesTeam__r.ShowBarterPrices__c', 'SalesOffice__c',
            'ClientGroup__c', 'SupplierCenter__c','ActivitySector__c','ActivitySector__r.Name',
            'DistributionChannel__c','DistributionChannel__r.Name', 'Status__c'
        };
        Q proQuery = new Q(Company__c.SObjectType);
        proQuery.selectFields(fieldSet);
        if (companyInfos.accountId != '') proQuery.add(Q.condition('Conta__c').equalsTo(companyInfos.accountId));
        proQuery.add(Q.condition('Status__c').equalsTo('Adicionada'));
        List<CompanyInfos> companyList = new List<CompanyInfos>();
        if (salesTeamTerritories != null && salesTeamTerritories.size() > 0) {
            List<String> salesTeamsDevNames = new List<String>();
            for (Territory2 salesTeamTerritory : salesTeamTerritories) {
                if (salesTeamTerritory.DeveloperName != null) {
                    String salesTeamDevName = salesTeamTerritory.DeveloperName.substring(0, 1) == 'X' || salesTeamTerritory.DeveloperName.substring(0, 1) == 'Z' ?
                                              salesTeamTerritory.DeveloperName.substring(1, salesTeamTerritory.DeveloperName.length()) : salesTeamTerritory.DeveloperName;
                    salesTeamsDevNames.add(salesTeamDevName);
                }
            }
            if (salesTeamsDevNames.size() > 0) {
                proQuery.add(Q.condition('SalesTeam__r.ExternalId__c').isIn(salesTeamsDevNames));
                proQuery.add(Q.condition('SalesOrg__r.SalesOrganizationCode__c').isIn(new List<String>(SalesOrgSettings__c.getAll().keySet())));
                if(companyInfos.orderType == 'Venda de Serviço')
                    proQuery.add(Q.condition('ActivitySector__r.Codigo__c').equalsTo('40'));
                else {
                    proQuery.add(Q.condition('ActivitySector__r.Codigo__c').isIn(new List<String>{'10', '30'}));
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
                    company.clientGroup = salesTeamCompany.ClientGroup__c;
                    company.selected = false;
                    company.showBarterPrices = salesTeamCompany.SalesTeam__r.ShowBarterPrices__c;
                    companyList.add(company);
                }
            }
        }
        if(isHeader)
            return JSON.serialize(new CompanyInfosHeaderSerialize(companyList[0].companyId, companyList[0].salesOrgId, companyList[0].supplierCenter));
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
            distrData.centerName = distrCenter.Name;
            distrData.code = distrCenter.Code__c;
            distrData.salesOrgName = distrCenter.SalesOrg__r.Name;
            distrData.selected = false;
            listDistrCenter.add(distrData);
        }

        return JSON.serialize(listDistrCenter);
    }

    public class DistrCenterData {
        public String centerId;
        public String centerName;
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
        
        String salesOrgName = [SELECT Name FROM SalesOrg__c WHERE Id =: orderValues.salesOrg LIMIT 1].Name;
        String salesConditionName = [SELECT ExternalId__c FROM SalesCondition__c WHERE Id =: orderValues.salesCondition LIMIT 1].ExternalId__c;
        String safraName = [SELECT Name FROM Safra__c WHERE Id =: orderValues.safra LIMIT 1].Name;
        
        String keyDelimiter = safraName + ' ' + salesConditionName + ' ' + salesOrgName;
        Date safraPaymentDate;
        for (Delimitadores__c delimiter : [
            SELECT Id,
                   Name, 
                   FinancialBaseDate__c
              FROM Delimitadores__c
             WHERE 
                Name =: keyDelimiter 
                AND StartDateOV__c <=: System.today()
                AND EndDateOV__c >=: System.today()

        ]) {
            safraPaymentDate = delimiter.FinancialBaseDate__c;
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
        result.clientGroup = orderValues.clientGroup;
        Map<String, Decimal> discountByFinancialInfos = new Map<String, Decimal>();
        for (JurosDescontoAntecipao__c financialDiscount : [
            SELECT Id,
                   ConditionType__c,
                   Percentage__c,
                   ProductGroup__c,
                   Product__c,
                   SalesOrg__c,
                   SalesTeam__c,
                   harvest__c,
                   ClientGroup__c
              FROM JurosDescontoAntecipao__c
             WHERE RecordTypeId =: discountOrAdditionRecType
               AND StartDate__c <=: System.today()
               AND EndDate__c >=: System.today()
               AND SalesOrg__c =: result.salesOrg
               AND harvest__c =: orderValues.safra
        ]) {
            if ((financialDiscount.SalesTeam__c == result.salesTeam || financialDiscount.SalesTeam__c == null) &&
                (financialDiscount.ClientGroup__c == result.clientGroup || financialDiscount.ClientGroup__c == null))  {
                String key = financialDiscount.SalesOrg__c + '-' + financialDiscount.harvest__c;
                key += financialDiscount.ClientGroup__c != null ? '-' + financialDiscount.ClientGroup__c : '';
                key += financialDiscount.Product__c != null ? '-' + financialDiscount.Product__c : '';
                if (financialDiscount.ClientGroup__c != null && financialDiscount.Product__c != null && !discountByFinancialInfos.containsKey(key)) {
                    discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
                    continue;
                }

                key = financialDiscount.SalesOrg__c + '-' + financialDiscount.harvest__c;
                key += financialDiscount.SalesTeam__c != null ? '-' + financialDiscount.SalesTeam__c : '';
                key += financialDiscount.Product__c != null ? '-' + financialDiscount.Product__c : '';
                if (financialDiscount.SalesTeam__c != null && financialDiscount.Product__c != null && !discountByFinancialInfos.containsKey(key)) {
                    discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
                    continue;
                }

                key = financialDiscount.SalesOrg__c + '-' + financialDiscount.harvest__c;
                key += financialDiscount.SalesTeam__c != null ? '-' + financialDiscount.SalesTeam__c : '';
                key += financialDiscount.ProductGroup__c != null ? '-' + financialDiscount.ProductGroup__c : '';
                if (financialDiscount.SalesTeam__c != null && financialDiscount.ProductGroup__c != null && !discountByFinancialInfos.containsKey(key)) {
                    discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
                    continue;
                }
                
                key = financialDiscount.SalesOrg__c + '-' + financialDiscount.harvest__c;
                key += financialDiscount.ProductGroup__c != null ? '-' + financialDiscount.ProductGroup__c : '';
                if (financialDiscount.ProductGroup__c != null && !discountByFinancialInfos.containsKey(key)) {
                    discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
                    continue;
                }

                key = financialDiscount.SalesOrg__c + '-' + financialDiscount.harvest__c;
                if (financialDiscount.ClientGroup__c == null && financialDiscount.SalesTeam__c == null && financialDiscount.Product__c == null &&
                    financialDiscount.ProductGroup__c == null && !discountByFinancialInfos.containsKey(key)) {
                    discountByFinancialInfos.put(key, financialDiscount.Percentage__c);
                    continue;
                }
            }
        }

        result.financialValues = discountByFinancialInfos;
        return JSON.serialize(new FinancialResultSerialize(result));
    }

    @AuraEnabled
    public static String getSafraInfos(String safraId, String salesConditionId, String salesOrgId){
        
        String salesOrgName = [SELECT Name FROM SalesOrg__c WHERE Id =: salesOrgId LIMIT 1].Name;
        String salesConditionName = [SELECT ExternalId__c FROM SalesCondition__c WHERE Id =: salesConditionId LIMIT 1].ExternalId__c;
        String safraName = [SELECT Name FROM Safra__c WHERE Id =: safraId LIMIT 1].Name;
        
        String keyDelimiter = safraName + ' ' +  salesConditionName + ' ' + salesOrgName;

        try{
            Delimitadores__c delimiter = [
                SELECT Id,
                    StartDateBilling__c,
                    LimitDateAfterPayment__c,
                    EndDateBilling__c,
                    FinancialBaseDate__c
                FROM Delimitadores__c
                WHERE Name =: keyDelimiter
                AND StartDateOV__c <=: System.today()
                AND EndDateOV__c >=: System.today()
            ];

            return JSON.serialize(new SafraDataSerialize(delimiter));
        }catch(Exception err){
            return 'Não foi possível encontrar as datas da Safra selecionada, contate o time de Pricing AgroGalaxy.';
        }
    }

    @AuraEnabled
    public static String getPaymentTypes() {
        List<ComboboxValues> listPaymentType = new List<ComboboxValues>();
        List<Schema.PicklistEntry> paymentTypes = FormPayment__c.PaymentType__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry sp : paymentTypes) {
            ComboboxValues paymentForm = new ComboboxValues();
            paymentForm.label = sp.getLabel();
            paymentForm.value = sp.getValue();
            listPaymentType.add(paymentForm);
        }
        return JSON.serialize(listPaymentType);
    }

    @AuraEnabled
    public static String getMTOTypes() {
        List<ComboboxValues> listPaymentType = new List<ComboboxValues>();
        List<Schema.PicklistEntry> mtoTypes = Order.MTO__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry sp : mtoTypes) {
            ComboboxValues paymentForm = new ComboboxValues();
            paymentForm.label = sp.getLabel();
            paymentForm.value = sp.getValue();
            listPaymentType.add(paymentForm);
        }
        return JSON.serialize(listPaymentType);
    }

    public class ComboboxValues {
        public String label;
        public String value;
    }

    @AuraEnabled
    public static String getMixAndConditionCombos(String data) {
        try {
            HeaderValues comboData = (HeaderValues) JSON.deserialize(data, HeaderValues.class);
            System.debug('ComboData => ' + comboData);
            Map<Id, ComboPromotionData> result = new Map<Id, ComboPromotionData>();
            Set<Id> mixCombosIds = new Set<Id>();
            Set<Id> conditionCombosIds = new Set<Id>();
            
            Set<Id> recTypes = new Set<Id>();
            recTypes.add(Schema.SObjectType.ComboPromotion__c.getRecordTypeInfosByDeveloperName().get('ProductMix').getRecordTypeId());
            recTypes.add(Schema.SObjectType.ComboPromotion__c.getRecordTypeInfosByDeveloperName().get('PaymentCondition').getRecordTypeId());
    
            for (ComboPromotion__c promotion : [
                SELECT Id,
                       ComboType__c,
                       Condition__c,
                       CombosQuantity__c,
                       PaymentCondition__c,
                       DiscountPercentage__c,
                       RecordType.DeveloperName
                  FROM ComboPromotion__c
                 WHERE Safra__c =: comboData.cropId
                   AND SalesOrg__c =: comboData.salesOrgId
                   AND (SalesCondition__c = null OR SalesCondition__c =: comboData.salesConditionId)
                   AND (PaymentCondition__c = null OR PaymentCondition__c =: comboData.paymentConditionId)
                   AND (SalesTeam__c = null OR SalesTeam__c =: comboData.salesTeamId)
                   AND (SalesOffice__c = null OR SalesOffice__c =: comboData.salesOfficeId)
                   AND CombosQuantity__c > 0
                   AND RecordTypeId IN: recTypes
                   AND Status__c = 'Ativo'
            ]) {
                ComboPromotionData comboPromotionData = new ComboPromotionData();
                comboPromotionData.comboQuantity = 0;
                comboPromotionData.comboId = promotion.Id;
                comboPromotionData.comboType = promotion.ComboType__c;
                comboPromotionData.comboCondition = promotion.Condition__c;
                comboPromotionData.recTypeDevName = promotion.RecordType.DeveloperName;
                comboPromotionData.comboAvailableQuantity = promotion.CombosQuantity__c;
                comboPromotionData.comboDiscountPercentage = promotion.DiscountPercentage__c;
                comboPromotionData.specificItemCombo = false;
                comboPromotionData.groupQuantities = new List<GroupData>();
                
                if (promotion.RecordType.DeveloperName == 'ProductMix') {
                    mixCombosIds.add(promotion.Id);
                } else {
                    conditionCombosIds.add(promotion.Id);
                    comboPromotionData.paymentConditionId = promotion.PaymentCondition__c;
                }

                result.put(promotion.Id, comboPromotionData);
            }

            for (FormerProduct__c formerProd : [
                SELECT Id,
                       Product__c,
                       Product__r.Name,
                       Product__r.ExternalId__c,
                       MinQuantity__c,
                       ComboPromotion__c
                  FROM FormerProduct__c
                 WHERE ComboPromotion__c IN: mixCombosIds
            ]) {
                ComboPromotionData comboPromotionData = result.get(formerProd.ComboPromotion__c);
                GroupData groupData = new GroupData();
                groupData.productId = formerProd.Product__c;
                groupData.productName = formerProd.Product__r.Name;
                groupData.productCode = formerProd.Product__r.ExternalId__c;
                groupData.quantity = formerProd.MinQuantity__c;
                comboPromotionData.groupQuantities.add(groupData);
            }

            for (ProductMix__c prodMix : [
                SELECT Id,
                       Quantity__c,
                       ProductGroup__c,
                       ComboPromotion__c
                  FROM ProductMix__c
                 WHERE ComboPromotion__c IN: conditionCombosIds
            ]) {
                ComboPromotionData comboPromotionData = result.get(prodMix.ComboPromotion__c);
                GroupData groupData = new GroupData();
                groupData.productGroupId = prodMix.ProductGroup__c;
                groupData.quantity = prodMix.Quantity__c;
                comboPromotionData.groupQuantities.add(groupData);
            }

            return JSON.serialize(result.values());
        } catch (Exception ex) {
            System.debug('Erro: ' + ex.getMessage() + '   -   ' + ex.getStackTraceString());
            return 'Error';
        }
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
        Id productGroupId;
       
        Decimal biggerDiscount = 0;
        Set<Id> setProductGroups = new Set<Id>();
        List<Id> listProductsIds = new List<Id>();
        Map<Id, Decimal> discountByProductIds = new Map<Id, Decimal>();
        Set<Id> productGroupsIds = new Set<Id>();
        Set<Id> productSubGroupsIds = new Set<Id>();
        Map<String, Decimal> smallerMarginByProductSubGroup = new Map<String, Decimal>();
        Map<String, Decimal> smallerMarginByProductId = new Map<String, Decimal>();
            
        for (ProductDeserialize orderProduct : orderData.productData) {
            orderTotalValue += orderProduct.totalPrice;

            Decimal currentDiscount = orderProduct.commercialDiscountPercentage != '' ? (stringToDecimal(orderProduct.commercialDiscountPercentage) != null ? stringToDecimal(orderProduct.commercialDiscountPercentage) : 0) : 0;
            if (currentDiscount > 0) {
                productGroupsIds.add(orderProduct.productGroupId);
                productSubGroupsIds.add(orderProduct.productSubgroupId);
                discountByProductIds.put(orderProduct.productId, currentDiscount);
            }

            if (orderProduct.productId != null) {
                listProductsIds.add(orderProduct.productId);
                if (!smallerMarginByProductId.containsKey(orderProduct.productId)) {
                    smallerMarginByProductId.put(orderProduct.productId, orderProduct.commercialMarginPercentage);
                } else {
                    Decimal currentMargin = smallerMarginByProductId.get(orderProduct.productId);
                    currentMargin = currentMargin > orderProduct.commercialMarginPercentage ? orderProduct.commercialMarginPercentage : currentMargin;
                    smallerMarginByProductId.put(orderProduct.productId, currentMargin);
                }
            }

            if(orderProduct.productSubgroupId != null){
                if (!smallerMarginByProductSubGroup.containsKey(orderProduct.productSubgroupId)) {
                    smallerMarginByProductSubGroup.put(orderProduct.productSubgroupId, orderProduct.commercialMarginPercentage);
                } else {
                    Decimal currentMargin = smallerMarginByProductSubGroup.get(orderProduct.productSubgroupId);
                    currentMargin = currentMargin > orderProduct.commercialMarginPercentage ? orderProduct.commercialMarginPercentage : currentMargin;
                    smallerMarginByProductSubGroup.put(orderProduct.productSubgroupId, currentMargin);
                }
            }

            if (orderProduct.productGroupId != null && !orderProduct.containsCombo) {
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
                       ProductGroup__c,
                       ProductsSubGroup__c,
                       Product__c
                  FROM Discount__c
                 WHERE Status__c = 'Aprovado'
                   AND Approver__c = 'ComiteMargem'
                   AND ClientGroup__c =: company.ClientGroup__c
                   AND SalesOrg__c =: company.SalesOrg__c
                   AND (
                            ProductGroup__c IN: smallerMarginByProductGroup.keySet() OR
                            ProductsSubGroup__c IN: smallerMarginByProductSubGroup.keySet() OR
                            Product__c IN: smallerMarginByProductId.keySet()
                       )
                   AND InitialDate__c <=: System.today()
                   AND EndDate__c >=: System.today()
              ORDER BY Margin__c
            ]) {
                if(discount.Product__c != null){
                    orderMarginMap.put(discount.Product__c, discount.Margin__c);
                }else if(discount.ProductsSubGroup__c != null){
                    orderMarginMap.put(discount.ProductsSubGroup__c, discount.Margin__c);
                }else if(discount.ProductGroup__c != null){
                    orderMarginMap.put(discount.ProductGroup__c, discount.Margin__c);
                }
            }
        }

        
        for (String productId : smallerMarginByProductId.keySet()) {
            if (orderMarginMap.get(productId) >= smallerMarginByProductId.get(productId)) {
                approval += '- ' + 'Comitê de Margem';
            }
        }

        if(!approval.contains('- Comitê de Margem')){
            for (String subGroupId : smallerMarginByProductSubGroup.keySet()) {
                if (orderMarginMap.get(subGroupId) >= smallerMarginByProductGroup.get(subGroupId)) {
                    approval += '- ' + 'Comitê de Margem';
                }
            }
        }
        
        if(!approval.contains('- Comitê de Margem')){
            for (String groupId : smallerMarginByProductGroup.keySet()) {
                if (orderMarginMap.get(groupId) >= smallerMarginByProductGroup.get(groupId)) {
                    approval += '- ' + 'Comitê de Margem';
                }
            }
        }

      
        
        if (company != null) {
            Decimal greaterDiscount = 0;
            Decimal smallerDiscount;

            if(!discountByProductIds.values().isEmpty()){
                List<Decimal> discountSorted = discountByProductIds.values();
                discountSorted.sort();
                greaterDiscount = discountSorted[discountSorted.size() - 1];
                smallerDiscount = discountSorted[0];
            }

            Map<String, Integer> approvalLevels = new Map<String, Integer>{
                'GerenteFilial' => 1,
                'GerenteRegional' => 2,
                'Diretor' => 3,
                'Diretor Torre' => 4
            };

            Map<String, Discount__c> discountByPriority = new Map<String, Discount__c>();
            for (Discount__c discount : [
                SELECT Id,
                       Approver__c,
                       ProductGroup__c,
                       ProductsSubGroup__c,
                       Product__c,
                       MinPercentage__c,
                       MaxPercentage__c
                  FROM Discount__c
                 WHERE Status__c = 'Aprovado'
                   AND ClientGroup__c =: company.ClientGroup__c
                   AND SalesOrg__c =: company.SalesOrg__c
                   AND (
                            ProductGroup__c IN: productGroupsIds OR
                            ProductsSubGroup__c IN: productSubGroupsIds OR 
                            Product__c IN: listProductsIds
                       )
                    AND InitialDate__c <=: System.today()
                   AND EndDate__c >=: System.today()
                   AND (MinPercentage__c <=: smallerDiscount AND MaxPercentage__c >=: greaterDiscount)
              ORDER BY MinPercentage__c, MaxPercentage__c
            ]) {
                if(discount.Product__c != null){
                    discountLogics(discountByPriority, discount, ('p-' + String.valueOf(discount.Product__c)), approvalLevels);
                }else if(discount.ProductsSubGroup__c != null){
                    discountLogics(discountByPriority, discount, ('sg-' + String.valueOf(discount.ProductsSubGroup__c)), approvalLevels);
                }else if(discount.ProductGroup__c != null){
                    discountLogics(discountByPriority, discount, ('g-' + String.valueOf(discount.ProductGroup__c)), approvalLevels);
                }
            }

            Integer approvalNumber = 0;
            approvalNumber = setApprovalNumber(discountByPriority, approvalLevels);
                
            if(approvalNumber == 4){
                approval += 'Gerente Filial/Gerente Regional/Diretor BU/Diretor Torre';
            }
            if(approvalNumber == 3){
                approval += 'Gerente Filial/Gerente Regional/Diretor BU';
            }
            if(approvalNumber == 2){
                approval += 'Gerente Filial/Gerente Regional';
            }
            if(approvalNumber == 1){
                approval += 'Gerente Filial';
            }
        }
        return approval;
    }

    @AuraEnabled
    public static String getTaxes(String accountId, String salesOrgId) {
        try {
            Set<Id> taxIds = new Set<Id>();
            for (CustomerTaxes__c customerTax : [
                SELECT Id,
                       Tax__c
                  FROM CustomerTaxes__c
                 WHERE Account__c =: accountId
                   AND SalesOrg__c =: salesOrgId
                   AND Status__c = 'Ativo'
            ]) {
                taxIds.add(customerTax.Tax__c);
            }

            List<TaxData> taxValues = new List<TaxData>();
            for (TaxCommodities__c taxCommodity : [
                SELECT Id,
                       Commodity__c,
                       Impostos_Barter__c,
                       TaxPercentage__c
                  FROM TaxCommodities__c
                 WHERE Impostos_Barter__c IN: taxIds
            ]) {
                TaxData currentTax = new TaxData();
                currentTax.taxId = taxCommodity.Impostos_Barter__c;
                currentTax.taxValue = 0;
                currentTax.taxPercentage = taxCommodity.TaxPercentage__c;
                currentTax.taxProduct = taxCommodity.Commodity__c;
                taxValues.add(currentTax);
            }

            return JSON.serialize(taxValues);
        } catch (Exception ex) {
            System.debug('Erro: ' + ex.getMessage() + '   -   ' + ex.getStackTraceString());
            return 'Error';
        }
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

    @AuraEnabled
    public static string getParentIdFromAccountProperty(String accountId){
        try {
            Account parentName = [SELECT Parent.Name FROM Account Where Id =: String.escapeSingleQuotes(accountId) LIMIT 1];
            if(parentName != null)
                return parentName.Parent.Name;
            else
                return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Decimal stringToDecimal(String value) {
        if (value.contains(',')) value = value.replaceAll(',', '.');
        if (value.contains('%')) value = value.replaceAll('%', '');
        return Decimal.valueOf(value);
    }

    //Classe para deserialização
    public class OrderDeserialize{
        public AccountDeserialize accountData;
        public AccountDeserialize bpAccount;
        public HeaderDeserialize headerData;
        public List<ProductDeserialize> productData;
        public List<DivisionDeserialize> divisionData;
        public List<CommodityDeserialize> commodityData;
        public List<ComboDeserialize> comboData;
        public List<TaxData> taxData;
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
        public String  mto;
        public String  centerId;
        public Decimal freightValue;
        public Decimal freightPerUnit;
        public Decimal motherTotalQuantity;
        public Boolean emptyHectar;
        public Boolean pedido_mae_check;
        public Boolean pre_pedido;
        public Boolean firstTime;
        public AccountSerialize  cliente_entrega;
        public InformationFields safra;
        public InformationFields cultura;
        public InformationFields condicao_venda;
        public InformationFields condicao_pagamento;
        public InformationFields organizacao_vendas;
        public InformationFields companyFromDeliveredAccount;
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
        public String  comboDiscountPercent;
        public String  priceListCode;
        public String  sieve;
        public String  productClass;
        public String  comboId;
        public String  brokeragePerUnit;
        public Integer position;
        public Boolean ptaProduct;
        public Boolean industryCombo;
        public Boolean containsCombo;
        public Decimal invoicedQuantity;
        public Decimal motherAvailableQuantity;
        public Decimal quantity;
        public Decimal listPrice;
        public Decimal listCost;
        public Decimal practicedCost;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Decimal totalPriceWithBrokerage;
        public Decimal dosage;
        public Decimal brokerage;
        public Decimal commercialDiscountValue;
        public Decimal commercialAdditionValue;
        public Decimal financialAdditionValue;
        public Decimal financialDecreaseValue;
        public Decimal commercialMarginPercentage;
        public Decimal comissionValue;
        public Decimal comboDiscountValue;
        public Decimal tListPrice;
        public Decimal rListPrice;
        public Decimal tsiTotalPrice;
        public Decimal royaltyTotalPrice;
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
        public Decimal quantity;
        public Decimal commodityPrice;
        public Boolean saved;
    }

    public class ComboDeserialize {
        public String  comboId;
        public Decimal comboQuantity;
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

    public class TaxData {
        public String  taxId;
        public String  commodityTaxId;
        public String  commodityId;
        public String  taxProduct;
        public Decimal taxValue;
        public Decimal taxPercentage;
    }

    public class TaxDataSerialize {
        public String  taxId;
        public String  commodityTaxId;
        public String  commodityId;
        public String  taxProduct;
        public Decimal taxValue;
        public Decimal taxPercentage;

        public TaxDataSerialize(){}
        public TaxDataSerialize(CommodityTaxes__c tax){
            this.taxId = tax.Tax__c;
            this.commodityTaxId = tax.Id;
            this.commodityId = tax.Commodity__c;
            this.taxProduct = tax.Commodity__r.Product__c;
            this.taxValue = tax.DeductionAmount__c;
            this.taxPercentage = tax.PercentageDeducted__c;
        }
    }


    //Classe para serialização
    public class OrderSerialize{
        public HeaderSerialize headerData;
        public AccountSerialize accountData;
        public AccountSerialize bpAccount;
        public List<ProductSerialize> productData;
        public List<DivisionSerialize> divisionData;
        public List<CommoditySerialize> commodityData;
        public List<TaxDataSerialize> taxData;
        public List<FormOfPaymentSerialize> formsOfPayment;

        OrderSerialize(){}       

        OrderSerialize(AccountSerialize account){
            this.accountData = account;
        }  

        OrderSerialize(HeaderSerialize order, List<ProductSerialize> products, List<DivisionSerialize> divisions, AccountSerialize account, List<CommoditySerialize> commodities, List<FormOfPaymentSerialize> formsOfPayment, List<TaxDataSerialize> taxData, AccountSerialize bpAccount){
            this.headerData = order;
            this.productData = products;
            this.divisionData = divisions;
            this.accountData = account;
            this.commodityData = commodities;
            this.taxData = taxData;
            this.formsOfPayment = formsOfPayment;
            this.bpAccount = bpAccount;
        }
    }

    public class OrderSerializeAll{
        public HeaderSerialize headerData;
        public List<ProductSerialize> productData;
        public List<DivisionSerialize> divisionData;
        public List<CommodityDeserialize> commodityData;
        public List<TaxData> taxData;
        public List<FormOfPaymentSerialize> formsOfPayment;
        public AccountSerialize accountData;
        public AccountSerialize bpAccount;
        public SummarySerialize summaryData;

        OrderSerializeAll(){}       

        OrderSerializeAll(AccountSerialize account){
            this.accountData = account;
        }  

        public OrderSerializeAll(HeaderSerialize order, List<ProductSerialize> products, List<DivisionSerialize> divisions, List<CommodityDeserialize> commodities, List<FormOfPaymentSerialize> formsOfPayment, AccountSerialize account, SummarySerialize summaryData, List<TaxData> taxData, AccountSerialize bpAccount){
            this.headerData = order;
            this.productData = products;
            this.divisionData = divisions;
            this.commodityData = commodities;
            this.taxData = taxData;
            this.formsOfPayment = formsOfPayment;
            this.accountData = account;
            this.summaryData = summaryData;
            this.bpAccount = bpAccount;
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
        public String IE;
        public String ParentName;
        public String ShippingStreet;
        public String AccountNumber;
        public String Complement;
        public String ShippingState;
        public String ShippingPostalCode;
        public String ShippingCountry;
        public String ShippingCity;
        public String Neighborhood;
        public String Email;
        
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
            this.IE = account.StateRegistration__c;
            this.ParentName = account.Parent.Name;
            this.ShippingStreet = account.ShippingStreet;
            this.AccountNumber = account.Number__c != null ? account.Number__c : ' ';
            this.Complement = account.Complement__c;
            this.ShippingState = account.ShippingState;
            this.ShippingPostalCode = account.ShippingPostalCode;
            this.ShippingCountry = account.ShippingCountry;
            this.ShippingCity = account.ShippingCity;
            this.Neighborhood = account.Neighborhood__c;
            this.Email = account.Email__c;
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
        public InformationFields  companyFromDeliveredAccount;
        public String  supplierCenterDeliveredAccount;
        public String  recTypeId;
        public String  hectares;
        public String  bpStorage;
        public String  mto;
        public Decimal freightValue;
        public Decimal freightPerUnit;
        public Decimal motherTotalQuantity;
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
            this.bpStorage = order.BPStorage__c;

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
            this.mto = order.MTO__c;
            this.condicao_pagamento = new InformationFields(order.PaymentCondition__c, order.PaymentCondition__r.Name);
            this.frete = order.Incoterms__c;
            this.observation = order.Description;
            this.billing_sale_observation = order.DescriptionBillingSale__c;
            this.centerId = order.DistributionCenter__c;
            this.freightValue = order.FreightValue__c;
            this.orderMargin = String.valueOf(order.OrderMargin__c) + '%';
            this.companyId = order.Company__c;
            this.companyFromDeliveredAccount = new InformationFields(order.CompanyReceiver__c, '');
            this.supplierCenterDeliveredAccount = order.CompanyReceiver__r.SupplierCenter__c;
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
        public String  comboId;
        public String  comboDiscountPercent;
        public String  brokeragePerUnit;
        public Integer position;
        public Boolean ptaProduct;
        public Boolean industryCombo;
        public Boolean containsCombo;
        public Decimal multiplicity;
        public Decimal invoicedQuantity;
        public Decimal quantity;
        public Decimal motherAvailableQuantity;
        public Decimal listPrice;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Decimal totalPriceWithBrokerage;
        public Decimal listCost;
        public Decimal practicedCost;
        public Decimal dosage;
        public Decimal brokerage;
        public Decimal commercialDiscountValue;
        public Decimal commercialAdditionValue;
        public Decimal financialAdditionValue;
        public Decimal financialDecreaseValue;
        public Decimal commercialMarginPercentage;
        public Decimal comissionValue;
        public Decimal comboDiscountValue;
        public Decimal tListPrice;
        public Decimal rListPrice;
        public Decimal tsiTotalPrice;
        public Decimal royaltyTotalPrice;
        public Decimal amountUsed;

        ProductSerialize(){}

        ProductSerialize(OrderItem orderItem, Integer position, Boolean cloneOrder, Decimal brokeragePerUnit){
            this.comboId = orderItem.ComboPromotion__c;
            this.containsCombo = orderItem.ComboPromotion__c != null ? true : false;
            this.industryCombo = orderItem.IndustryComboDiscount__c != 0 ? true : false;
            this.comboDiscountPercent = '0%';
            this.comboDiscountValue = this.comboId != null ? (this.industryCombo ? orderItem.IndustryComboDiscount__c : orderItem.AgrogalaxyComboDiscount__c) : 0;
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
            this.quantity = !cloneOrder ? (orderItem.ItemBalance__c != null ? orderItem.ItemBalance__c : orderItem.Quantity) : orderItem.Quantity;
            this.amountUsed = orderItem.Quantity - (orderItem.ItemBalance__c != null ? orderItem.ItemBalance__c : 0);
            this.invoicedQuantity = orderItem.InvoicedQuantity__c;
            this.motherAvailableQuantity = orderItem.ItemBalance__c != null ? orderItem.ItemBalance__c : null;
            this.listPrice = orderItem.ListPrice__c;
            this.unitPrice = orderItem.PracticedPrice__c;
            this.brokerage = brokeragePerUnit != null ? this.quantity * brokeragePerUnit : orderItem.Brokerage__c;
            this.totalPrice = orderItem.FinalTotalValue__c - this.comboDiscountValue;
            this.totalPriceWithBrokerage = this.brokerage != null ? (this.totalPrice + this.brokerage) : this.totalPrice;
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
            this.tListPrice = orderItem.TSIValue__c != null ? orderItem.TSIValue__c : 0;
            this.rListPrice = orderItem.RoyaltyAmount__c != null ? orderItem.RoyaltyAmount__c : 0;
            this.tsiTotalPrice = this.tListPrice * this.quantity;
            this.royaltyTotalPrice = this.rListPrice * this.quantity;
            this.brokeragePerUnit = brokeragePerUnit != null ? String.valueOf(brokeragePerUnit) : '';
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

        SafraDataSerialize(Delimitadores__c delimiter) {
            this.initialDate = String.valueOf(delimiter.StartDateBilling__c);
            this.paymentDate = String.valueOf(delimiter.LimitDateAfterPayment__c);
            this.endDateBilling = String.valueOf(delimiter.EndDateBilling__c);
            this.startDateBilling = String.valueOf(delimiter.StartDateBilling__c);
            this.paymentBaseDate = String.valueOf(delimiter.FinancialBaseDate__c);
        }
    }

    public class OrderDataDeserialize {
        public String paymentDate;
        public String salesOrg;
        public String salesOffice;
        public String salesTeam;
        public String safra;
        public String culture;
        public String salesCondition;
        public String clientGroup;
    }

    public class FinancialResult {
        public String  salesOrg;
        public String  salesOffice;
        public String  salesTeam;
        public String  clientGroup;
        public Integer dayDifference;
        public Boolean isDiscount;
        public Boolean correctPayment;
        public Map<String, Decimal> financialValues;
    }

    public class FinancialResultSerialize {
        public String  salesOrg;
        public String  salesOffice;
        public String  salesTeam;
        public String  clientGroup;
        public Integer dayDifference;
        public Boolean isDiscount;
        public Boolean correctPayment;
        public Map<String, Decimal> financialValues;

        FinancialResultSerialize() {}

        FinancialResultSerialize(FinancialResult financialResult) {
            this.salesOrg = financialResult.salesOrg;
            this.salesOffice = financialResult.salesOffice;
            this.salesTeam = financialResult.salesTeam;
            this.clientGroup = financialResult.clientGroup;
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
        public String  clientGroup;
        public Boolean selected;
        public Boolean showBarterPrices;
    }

    public class CompanyInfosSerialize {
        public List<CompanyInfos> listCompanyInfos;

        CompanyInfosSerialize() {}

        CompanyInfosSerialize(List<CompanyInfos> companyInfos) {
            this.listCompanyInfos = companyInfos;
        }
    }

    public class CompanyInfosHeader {
        public String  companyId;
        public String  salesOrgId;
        public String  supplierCenter;
    }

    public class CompanyInfosHeaderSerialize {
        public CompanyInfosHeader companyInfoHeader = new CompanyInfosHeader();

        CompanyInfosHeaderSerialize() {}

        CompanyInfosHeaderSerialize(String companyId, String salesOrgId, String supllierCenter) {
            this.companyInfoHeader.companyId      = companyId;
            this.companyInfoHeader.salesOrgId     = salesOrgId;
            this.companyInfoHeader.supplierCenter = supllierCenter;
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

        public QuotaData(){}

        public QuotaData(String cropId, String sellerId, List<String> productsIds){
            this.cropId = cropId;
            this.sellerId = sellerId;
            this.productsIds = productsIds;
        }
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
        // public List<GeneralQuotas__c> generalQuotasToUpdate = new List<GeneralQuotas__c>();
        public List<IndividualQuotas__c> individualQuotasToUpdate = new List<IndividualQuotas__c>();
    }

    public class HeaderValues {
        public String  cropId;
        public String  salesOrgId;
        public String  salesTeamId;
        public String  salesOfficeId;
        public String  salesConditionId;
        public String  paymentConditionId;
        public Integer rowsToSkip;
    }

    public class ComboPromotionData {
        public String  comboId;
        public String  comboType;
        public String  recTypeDevName;
        public String  comboCondition;
        public String  paymentConditionId;
        public Decimal comboAvailableQuantity;
        public Decimal comboDiscountPercentage;
        public Boolean specificItemCombo;
        public Integer comboQuantity;
        public List<GroupData>  groupQuantities;
        public List<ComboItems> formerItems;
        public List<ComboItems> benefitItems;
    }

    public class ComboItems {
        public String  comboId;
        public String  productId;
        public String  productName;
        public String  productCode;
        public Decimal minQUantity;
        public Decimal discountPercentage;
    }

    public class GroupData {
        public String  productId;
        public String  productName;
        public String  productCode;
        public String  productGroupId;
        public Decimal quantity;
    }
}