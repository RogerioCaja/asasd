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
            ClientGroup__c = 'NÃO SEGMENTADO',
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
            SalesCondition__c = salesCondition.Id
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
            DiscountPercent__c = 0,
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
            ExternalId__c = order.Id + '|001'
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
            ClientGroup__c = 'NÃO SEGMENTADO',
            InitialDate__c = System.today().addDays(-90),
            EndDate__c = System.today().addDays(90)
        );
        insert discount;
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
        OrderScreenController.SummarySerialize summary = new OrderScreenController.SummarySerialize('Observation', 'Observation Sales');

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

        String data = JSON.serialize(new OrderScreenController.OrderSerializeAll(order, ordItemList, divisionList, new List<OrderScreenController.CommodityDeserialize>{commodity}, account, summary));
        OrderScreenController.saveOrder(null, false, data, '');
        OrderScreenController.approvals(data);
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
        OrderScreenController.getSafraInfos(safraId);
    }

    @isTest
    public static void getAccountCompaniesTest() {
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        OrderScreenController.getAccountCompanies('{"ctvId":"' + UserInfo.getUserId() + '","accountId":"' + accountId + '","approvalNumber":1}', false);
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

        String data = JSON.serialize(orderData);
        OrderScreenController.getFinancialInfos(data);
    }

    @isTest
    public static void getOrderByOrderItemTest() {
        String itemId = [SELECT Id FROM OrderItem LIMIT 1].Id;
        OrderScreenController.getOrderByOrderItem(itemId);
    }
}