@isTest
public class OrderScreenControllerTest {
    @TestSetup
    public static void makeData() {
        List<Account> accountList = new List<Account>();
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        accountList.add(parentAccount);

        Account childAccount = new Account(
            Name = 'Child Account',
            Company__c = 'Child Account',
            Phone = '11111111111',
            ExternalId__c = '123457'
        );
        accountList.add(childAccount);
        insert accountList;

        SalesCondition__c salesCondition = new SalesCondition__c(
            Name = 'Condição',
            ExternalId__c = '001'
        );
        insert salesCondition;

        SalesOrg__c salesOrg = new SalesOrg__c(
            Name = 'Sales Organization',
            SalesOrganizationCode__c = '001'
        );
        insert salesOrg;

        SalesOffice__c salesOffice = new SalesOffice__c(
            Name = 'Sales Office',
            Codigo__c = '001'
        );
        insert salesOffice;

        SalesTeam__c salesTeam = new SalesTeam__c(
            Name = 'Sales team'
        );
        insert salesTeam;

        Company__c company = new Company__c(
            Name = 'Company',
            Blocked__c = false,
            ClientGroup__c = '01',
            Conta__c = parentAccount.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            ExternalID__c = '001',
            SupplierCenter__c = '1010'
        );
        insert company;

        Safra__c crop = new Safra__c(
            Name = 'Safra 01',
            Name__c = 'Safra 1',
            Code__c = '001',
            BillingStartDate__c = System.today(),
            StartDateOrderInsertion__c = System.today(),
            EndDateBilling__c = System.today().addDays(90),
            EndDateInsertionOrders__c = System.today().addDays(90),
            NumberOfDaysAfterPayment__c = System.today().addDays(10),
            PaymentBaseDate__c = System.today().addDays(90),
            ReleaseStatus__c = 'Ativo'
        );
        insert crop;

        Delimitadores__c delimiter = new Delimitadores__c(
            Name = 'a',
            Safra__c = crop.Id,
            SalesOrg__c = salesOrg.Id,
            salesCondition__c = salesCondition.Id, 
            StartDateBilling__c = System.today(),
            StartDateOV__c = System.today(),
            EndDateBilling__c = System.today().addDays(90),
            EndDateOV__c = System.today().addDays(90),
            LimitDateAfterPayment__c = System.today().addDays(10),
            FinancialBaseDate__c = System.today().addDays(90)
        );

        insert delimiter;

        Cultura__c culture = new Cultura__c(
            Name = 'Culture 01',
            Name__c = 'Culture 01',
            Codigo__c = '001'
        );
        insert culture;

        CondicaoPagamento__c paymentCondition = new CondicaoPagamento__c(
            Name = 'Boleto',
            Code__c = '001'
        );
        insert paymentCondition;

        ProductHierarchy__c productHierarchy = new ProductHierarchy__c(
            Name = 'Hierarquia',
            External_Id__c = '001'
        );
        insert productHierarchy;

        Order order = new Order(
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Venda Normal').getRecordTypeId(),
            OrderType__c = 'Pedido Normal',
            AccountId = parentAccount.Id,
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type = 'Venda Normal',
            ShippingAccount__c = parentAccount.Id,
            PaymentDate__c = Date.today().addDays(-2),
            CustomerOrderNumber__c = '65465',
            EffectiveDate = Date.today(),
            PaymentForm__c = 'A',
            Currency__c = 'BRL',
            StatusSF__c = 'Em digitação',
            Incoterms__c = 'CIF',
            Crop__c = crop.Id,
            Culture__c = culture.Id,
            SalesCTV__c = UserInfo.getUserId(),
            PaymentCondition__c = paymentCondition.Id,
            ShippingDate__c = Date.today().addDays(2),
            Hectare__c = 10,
            SalesCondition__c = salesCondition.Id,
            SalesOrg__c = salesOrg.Id
        );
        OrderHelper.disableTrigger();
        insert order;
        OrderHelper.enableTrigger();

        ProductGroup__c productGroup = new ProductGroup__c(
            Name = 'Grãos',
            ExternalId__c ='001'
        );
        insert productGroup;

        List<Product2> lstProducts = new List<Product2>();
        Product2 product = new Product2(
            Name = 'Milho',
            ExternalId__c = '001',
            ProductCode = '001',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            PrincipleActive__c = 'Salicilina',
            ProductGroup__c = productGroup.Id,
            Multiplicity__c = 5,
            ClasseAvaliacao__c = 'A',
            GrupoQuimico__c = 'A',
            MarcadoEliminacao__c = 'A',
            NCM__c = 'A',
            NumeroRegistro__c = '2',
            OrigemMaterial__c = 'Ferro',
            UnidadeMedida__c = 'Quilos',
            ProductHierarchy__c = productHierarchy.Id
        );
        lstProducts.add(product);

        Product2 commodity = new Product2(
            Name = 'Soja',
            ExternalId__c = '002',
            ProductCode = '002',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            ProductType__c = 'ZCOM',
            PrincipleActive__c = 'Salicilina',
            ProductGroup__c = productGroup.Id,
            Multiplicity__c = 5,
            ClasseAvaliacao__c = 'chucrute',
            GrupoQuimico__c = 'Só o quimico',
            MarcadoEliminacao__c = 'S',
            NCM__c = 'S',
            NumeroRegistro__c = '0002',
            OrigemMaterial__c = 'Himalaia', 
            UnidadeMedida__c = 'KG',
            ProductHierarchy__c = productHierarchy.Id
        );
        lstProducts.add(commodity);

        Product2Helper.disableTrigger();
        insert lstProducts;
        Product2Helper.enableTrigger();

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 150,
            CostPrice__c = 112,
            IsActive = true
        );
        insert pricebookEntry;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product.Id,
            ListPrice = 150,
            ListPrice__c = 150,
            ServiceDate = System.today(),
            Quantity = 10,
            UnitPrice = 160,
            PracticedCost__c = 130,
            PracticedPrice__c = 160,
            Status__c = '5',
            UnitMeasure__c = 'Each',
            FinalTotalValue__c = 1600,
            DiscountPercent__c = 10,
            DiscountValue__c = 0,
            CommercialAdditionPercent__c = 6.6666,
            CommercialAdditionValue__c = 100,
            FinancialAdditionPercent__c = 0,
            FinancialAdditionValue__c = 0,
            FinancialDiscountPercent__c = 0,
            FinancialDiscountValue__c = 0,
            ComissionValue__c = 0,
            CommercialMargin__c = 2,
            Dosage__c = 5,
            InvoicedQuantity__c = 0,
            NumeroSap__c = '001',
            ExternalId__c = order.Id + '|001',
            Brokerage__c = 10,
            ItemBalance__c = 10,
            TotalTSIAmount__c = 500,
            TotalRoyaltyAmount__c = 200
        );
        OrderHelper.disableTrigger();
        insert orderItem;
        OrderHelper.enableTrigger();

        ShippingDivison__c shipping = new ShippingDivison__c(
            DeliveryDate__c = System.today().addDays(30),
            Quantity__c = 5,
            ExternalId__c = '001',
            ConfirmedQuantity__c = 0,
            OrderItem__c = orderItem.Id
        );
        insert shipping;

        FormPayment__c formsOfPayment = new FormPayment__c(
            Order__c = order.Id,
            PaymentType__c = 'Germoplasma',
            PaymentDate__c = System.today(),
            Amount__c = 1600
        );
        insert formsOfPayment;

        List<JurosDescontoAntecipao__c> listJda = new List<JurosDescontoAntecipao__c>();
        JurosDescontoAntecipao__c productPrice = new JurosDescontoAntecipao__c(
            RecordTypeId = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId(),
            Account__c = parentAccount.Id,
            Product__c = product.Id,
            ProductGroup__c = productGroup.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            Culture__c = culture.Id,
            harvest__c = crop.Id,
            SalesCondition__c = salesCondition.Id,
            Currency__c = 'BRL',
            IsActive__c = true,
            StartDate__c = System.today().addDays(-5),
            EndDate__c = System.today().addDays(5),
            ExternalId__c = '001',
            UnitPrice__c = 150,
            Cost__c = 112
        );
        listJda.add(productPrice);

        JurosDescontoAntecipao__c productDiscount = new JurosDescontoAntecipao__c(
            RecordTypeId = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZDAN').getRecordTypeId(),
            Account__c = parentAccount.Id,
            Product__c = product.Id,
            ProductGroup__c = productGroup.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            Culture__c = culture.Id,
            harvest__c = crop.Id,
            SalesCondition__c = salesCondition.Id,
            Currency__c = 'BRL',
            IsActive__c = true,
            StartDate__c = System.today().addDays(-5),
            EndDate__c = System.today().addDays(5),
            ExternalId__c = '002'
        );
        listJda.add(productDiscount);

        JurosDescontoAntecipao__c productAddition = new JurosDescontoAntecipao__c(
            RecordTypeId = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZJUR').getRecordTypeId(),
            Account__c = parentAccount.Id,
            Product__c = product.Id,
            ProductGroup__c = productGroup.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            Culture__c = culture.Id,
            harvest__c = crop.Id,
            SalesCondition__c = salesCondition.Id,
            Currency__c = 'BRL',
            IsActive__c = true,
            StartDate__c = System.today().addDays(-5),
            EndDate__c = System.today().addDays(5),
            ExternalId__c = '003'
        );
        listJda.add(productAddition);

        JurosDescontoAntecipao__c commodityPrice = new JurosDescontoAntecipao__c(
            RecordTypeId = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId(),
            Account__c = parentAccount.Id,
            Product__c = commodity.Id,
            ProductGroup__c = productGroup.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            Culture__c = culture.Id,
            harvest__c = crop.Id,
            SalesCondition__c = salesCondition.Id,
            Currency__c = 'BRL',
            IsActive__c = true,
            StartDate__c = System.today().addDays(-5),
            EndDate__c = System.today().addDays(5),
            ExternalId__c = '004'
        );
        listJda.add(commodityPrice);
        insert listJda;

        OrgVProduct__c orgV = new OrgVProduct__c(
            Product__c = product.Id,
            SalesOrg__c = salesOrg.Id,
            Status__c = 'Adicionada',
            SupplierCenter__c = '1010'
        );
        insert orgV;

        Comissao__c comission = new Comissao__c(
            ProductHierarchy__c = productHierarchy.Id,
            CommissionPercentage__c = 3,
            SellerType__c = 'CTV',
            ProductGroup__c = productGroup.Id
        );
        insert comission;

        Discount__c discount = new Discount__c(
            Margin__c = 1,
            ProductGroup__c = productGroup.Id,
            Status__c = 'Aprovado',
            Approver__c = 'ComiteMargem',
            ClientGroup__c = '01',
            InitialDate__c = System.today().addDays(-90),
            EndDate__c = System.today().addDays(90),
            SalesOrg__c = salesOrg.Id
        );
        insert discount;

        Discount__c discount1 = new Discount__c(
            ProductGroup__c = productGroup.Id,
            Status__c = 'Aprovado',
            MinPercentage__c = 9,
            MaxPercentage__c = 15,
            Approver__c = 'GerenteFilial',
            ClientGroup__c = '01',
            InitialDate__c = System.today().addDays(-90),
            EndDate__c = System.today().addDays(90),
            SalesOrg__c = salesOrg.Id
        );
        insert discount1;

        Discount__c discount2 = new Discount__c(
            Product__c = product.Id,
            Status__c = 'Aprovado',
            MinPercentage__c = 9,
            MaxPercentage__c = 15,
            Approver__c = 'GerenteRegional',
            ClientGroup__c = '01',
            InitialDate__c = System.today().addDays(-90),
            EndDate__c = System.today().addDays(90),
            SalesOrg__c = salesOrg.Id
        );
        insert discount2;

        Discount__c discount3 = new Discount__c(
            Product__c = product.Id,
            Status__c = 'Aprovado',
            MinPercentage__c = 9,
            MaxPercentage__c = 15,
            Approver__c = 'Diretor',
            ClientGroup__c = '01',
            InitialDate__c = System.today().addDays(-90),
            EndDate__c = System.today().addDays(90),
            SalesOrg__c = salesOrg.Id
        );
        insert discount3;

        GeneralQuotas__c generalQuota = new GeneralQuotas__c(
            Quantity__c = 1000,
            Balance__c = 1000,
            Consumed__c = 0,
            Crop__c = crop.Id,
            Cultivate__c = product.Id
        );
        insert generalQuota;

        IndividualQuotas__c individualQuota = new IndividualQuotas__c(
            Quantity__c = 1000,
            Balance__c = 1000,
            Consumed__c = 0,
            Cultivate__c = product.Id,
            GeneralQuotas__c = generalQuota.Id,
            Crop__c = crop.Id,
            Seller__c = UserInfo.getUserId()
        );
        insert individualQuota;

        DistributionCenter__c distrCenter = new DistributionCenter__c(
            Name = 'Distribution Center',
            Code__c = '001',
            SalesOrg__c = salesOrg.Id
        );
        insert distrCenter;

        List<ComboPromotion__c> combos = new List<ComboPromotion__c>();
        ComboPromotion__c combo = new ComboPromotion__c(
            RecordTypeId = Schema.SObjectType.ComboPromotion__c.getRecordTypeInfosByDeveloperName().get('Specific_Items').getRecordTypeId(),
            ComboType__c = 'Indústria',
            CombosQuantity__c = 50,
            PaymentCondition__c = paymentCondition.Id,
            DiscountPercentage__c = 3,
            Safra__c = crop.Id,
            SalesOrg__c = salesOrg.Id,
            SalesCondition__c = salesCondition.Id,
            Status__c = 'Ativo'
        );
        combos.add(combo);

        ComboPromotion__c combo2 = new ComboPromotion__c(
            RecordTypeId = Schema.SObjectType.ComboPromotion__c.getRecordTypeInfosByDeveloperName().get('ProductMix').getRecordTypeId(),
            ComboType__c = 'Indústria',
            CombosQuantity__c = 50,
            PaymentCondition__c = paymentCondition.Id,
            DiscountPercentage__c = 3,
            Safra__c = crop.Id,
            SalesOrg__c = salesOrg.Id,
            SalesCondition__c = salesCondition.Id,
            Status__c = 'Ativo'
        );
        combos.add(combo2);

        ComboPromotion__c combo3 = new ComboPromotion__c(
            RecordTypeId = Schema.SObjectType.ComboPromotion__c.getRecordTypeInfosByDeveloperName().get('PaymentCondition').getRecordTypeId(),
            ComboType__c = 'Indústria',
            CombosQuantity__c = 50,
            PaymentCondition__c = paymentCondition.Id,
            DiscountPercentage__c = 3,
            Safra__c = crop.Id,
            SalesOrg__c = salesOrg.Id,
            SalesCondition__c = salesCondition.Id,
            Status__c = 'Ativo'
        );
        combos.add(combo3);
        insert combos;

        List<FormerProduct__c> formers = new List<FormerProduct__c>();
        FormerProduct__c former = new FormerProduct__c(
            Product__c = product.Id,
            MinQuantity__c = 5,
            ComboPromotion__c = combo.Id
        );
        formers.add(former);

        FormerProduct__c former2 = new FormerProduct__c(
            Product__c = product.Id,
            MinQuantity__c = 5,
            ComboPromotion__c = combo2.Id
        );
        formers.add(former2);
        insert formers;

        BenefitProduct__c benefit = new BenefitProduct__c(
            Product__c = product.Id,
            MinQuantity__c = 5,
            ComboPromotion__c = combo.Id,
            DiscountPercentage__c = 5
        );
        insert benefit;

        ProductMix__c mix = new ProductMix__c(
            Quantity__c = 10,
            ProductGroup__c = productGroup.Id,
            ComboPromotion__c = combo3.Id
        );
        insert mix;
    }

    @isTest
    public static void getOrderDataTest() {
        Id orderId = [SELECT Id FROM Order LIMIT 1].Id;
        OrderScreenController.getOrder(orderId, false, false);
    }

    @isTest
    public static void checkMotherQuantitiesTest() {
        Id orderId = [SELECT Id FROM Order LIMIT 1].Id;
        OrderScreenController.checkMotherQuantities(orderId);
    }

    @isTest
    public static void saveOrderTest() {
        Order ord = [SELECT Id, AccountId FROM Order LIMIT 1];

        OrderScreenController.HeaderSerialize order = OrderScreenController.getOrderData(ord.Id, false);
        order.companyId = [SELECT Id FROM Company__c LIMIT 1].Id;
        OrderScreenController.AccountSerialize account = OrderScreenController.getOrderAccountData(ord.AccountId);
        List<OrderScreenController.ProductSerialize> ordItemList = OrderScreenController.getOrderItemData(ord.Id, false);
        List<OrderScreenController.DivisionSerialize> divisionList = OrderScreenController.getShippingDivison();
        List<OrderScreenController.FormOfPaymentSerialize> formsOfPayment = OrderScreenController.getFormsOfPayment(ord.Id);
        OrderScreenController.SummarySerialize summary = new OrderScreenController.SummarySerialize('Observation', 'Observation Sales', 150);

        OrderScreenController.CommodityDeserialize commodity = new OrderScreenController.CommodityDeserialize();
        commodity.product = 'Soja';
        commodity.productId = [SELECT Id FROM Product2 WHERE Name = 'Soja' LIMIT 1].Id;
        commodity.desage = '10';
        commodity.area = '10';
        commodity.discount = '0';
        commodity.margin = '3';
        commodity.marginValue = '3';
        commodity.totalDelivery = '10';
        commodity.quantity = 10;
        commodity.commodityPrice = 120;
        commodity.startDate = '2022-01-01';
        commodity.endDate = '2099-01-01';
        commodity.saved = true;


        String data = JSON.serialize(new OrderScreenController.OrderSerializeAll(order, ordItemList, divisionList, new List<OrderScreenController.CommodityDeserialize>{commodity}, formsOfPayment, account, summary, null, null));
        OrderScreenController.saveOrder(null, false, data, '', null);
        String valueToValidate = OrderScreenController.approvals(data);
        Assert.areEqual('Gerente Filial/Gerente Regional/Diretor BU', valueToValidate, 'Deveria vir o valor de Gerente Filial/Gerente Regional/Diretor BU');
    }

    @isTest
    public static void getAccountDataTest() {
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        OrderScreenController.getAccount(accountId);
    }

    @isTest
    public static void getAccountDataChildTest() {
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Child Account' LIMIT 1].Id;
        OrderScreenController.getAccountDataChild(accountId);
    }

    @isTest
    public static void getSafraInfosTest() {
        Id safraId = [SELECT Id FROM Safra__c LIMIT 1].Id;
        Id salesOrgId = [SELECT Id FROM SalesOrg__c  LIMIT 1].Id;
        Id salesConditionId = [SELECT Id FROM SalesCondition__c LIMIT 1].Id;
        OrderScreenController.getSafraInfos(safraId, salesConditionId, salesOrgId);
    }

    @isTest
    public static void getAccountCompaniesTest() {
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        OrderScreenController.getAccountCompanies('{"ctvId":"' + UserInfo.getUserId() + '","accountId":"' + accountId + '","approvalNumber":1}', false, false, false, true);
    }

    @isTest
    public static void getFinancialInfosTest() {
        OrderScreenController.OrderDataDeserialize orderData = new OrderScreenController.OrderDataDeserialize();
        orderData.paymentDate = String.valueOf(System.today());
        orderData.salesOrg = [SELECT Id FROM SalesOrg__c LIMIT 1].Id;
        orderData.salesOffice = [SELECT Id FROM SalesOffice__c LIMIT 1].Id;
        orderData.salesTeam = [SELECT Id FROM SalesTeam__c LIMIT 1].Id;
        orderData.safra = [SELECT Id FROM Safra__c LIMIT 1].Id;
        orderData.culture = [SELECT Id FROM Cultura__c LIMIT 1].Id;
        orderData.salesCondition = [SELECT Id FROM SalesCondition__c LIMIT 1].Id;
        orderData.clientGroup = '07';

        String data = JSON.serialize(orderData);
        OrderScreenController.getFinancialInfos(data);
    }

    @isTest
    public static void getOrderByOrderItemTest() {
        String itemId = [SELECT Id FROM OrderItem LIMIT 1].Id;
        OrderScreenController.getOrderByOrderItem(itemId);
    }

    @isTest
    public static void checkQuotaQuantityTest() {
        List<String> prodsIds = new List<String>();
        for (Product2 prod : [SELECT Id FROM Product2]) {
            prodsIds.add(prod.Id);
        }

        OrderScreenController.QuotaData data = new OrderScreenController.QuotaData();
        data.productsIds = prodsIds;
        data.sellerId = UserInfo.getUserId();
        data.cropId = [SELECT Id FROM Safra__c LIMIT 1].Id;

        OrderScreenController.checkQuotaQuantity(JSON.serialize(data));
    }

    @isTest
    public static void checkItemQuotaTest() {
        List<String> prodsIds = new List<String>();
        Map<String, Decimal> quantities = new Map<String, Decimal>();
        for (Product2 prod : [SELECT Id FROM Product2]) {
            prodsIds.add(prod.Id);
            quantities.put(prod.Id, 500);
        }

        OrderScreenController.QuotaData data = new OrderScreenController.QuotaData();
        data.productsIds = prodsIds;
        data.sellerId = UserInfo.getUserId();
        data.cropId = [SELECT Id FROM Safra__c LIMIT 1].Id;

        OrderScreenController.checkItemQuota(data, quantities);   
    }

    @isTest
    public static void getAccountDistrCentersTest() {
        OrderScreenController.getAccountDistrCenters([SELECT Id FROM SalesOrg__c LIMIT 1].Id);
    }

    @isTest
    public static void verifyProductDisponibilityTest() {
        List<String> prodsIds = new List<String>();
        for (Product2 prod : [SELECT Id FROM Product2]) {
            prodsIds.add(prod.Id);
        }

        OrderScreenController.DisponibilityData disponibilityData = new OrderScreenController.DisponibilityData();
        disponibilityData.orderProductsId = prodsIds;
        disponibilityData.salesOrgId = [SELECT Id FROM SalesOrg__c LIMIT 1].Id;
        disponibilityData.supplierCenter = '1010';
        OrderScreenController.verifyProductDisponibility(JSON.serialize(disponibilityData));
    }

    @isTest
    public static void getPaymentTypesTest() {
        OrderScreenController.getPaymentTypes();
    }

    @isTest
    public static void checkSalesOrgFreightTest() {
        OrderScreenController.checkSalesOrgFreight([SELECT Id FROM SalesOrg__c LIMIT 1].Id);
    }

    @isTest
    public static void getSpecificCombosTest() {
        OrderScreenController.HeaderValues data = new OrderScreenController.HeaderValues();
        data.cropId = [SELECT Id FROM Safra__c LIMIT 1].Id;
        data.salesOrgId = [SELECT Id FROM SalesOrg__c LIMIT 1].Id;
        data.salesConditionId = [SELECT Id FROM SalesCondition__c LIMIT 1].Id;
        data.rowsToSkip = 0;

        OrderScreenController.CompanyInfos company = new OrderScreenController.CompanyInfos();
        company.supplierCenter = '1010';
        company.salesOrgId = data.salesOrgId;
        company.salesOfficeId = [SELECT Id FROM SalesOffice__c LIMIT 1].Id;
        company.salesTeamId = [SELECT Id FROM SalesTeam__c LIMIT 1].Id;
        
        CustomLookupController.ProductParams params = new CustomLookupController.ProductParams();
        params.salesConditionId = data.salesConditionId;
        params.accountId = [SELECT AccountId FROM Order LIMIT 1].AccountId;
        params.ctvId = UserInfo.getUserId();
        params.safra = data.cropId;
        params.productCurrency = 'BRL';
        params.culture = [SELECT Id FROM Cultura__c LIMIT 1].Id;
        params.orderType = 'Venda Normal';
        params.numberOfRowsToSkip = 0;
        params.dontGetSeeds = false;
        params.paymentDate = String.valueOf(System.today());
        params.activitySectorName = 'INSUMOS';
        params.supplierCenter = '1010';
        params.salesOrgId = company.salesOrgId;
        params.salesOfficeId = company.salesOfficeId;
        params.salesTeamId = company.salesTeamId;
        
        List<Id> ids = new List<Id>();
        OrderScreenController.getSpecificCombos(JSON.serialize(data), JSON.serialize(company), JSON.serialize(params) , false, ids);
    }

    @isTest
    public static void getMixAndConditionCombosTest() {
        OrderScreenController.HeaderValues data = new OrderScreenController.HeaderValues();
        data.cropId = [SELECT Id FROM Safra__c LIMIT 1].Id;
        data.salesOrgId = [SELECT Id FROM SalesOrg__c  LIMIT 1].Id;
        data.salesConditionId = [SELECT Id FROM SalesCondition__c  LIMIT 1].Id;
        OrderScreenController.getMixAndConditionCombos(JSON.serialize(data));
    }

    @isTest
    static void getMTOTypesTest(){
        OrderScreenController.getMTOTypes();
    }
}