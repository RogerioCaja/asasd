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
            ExternalId__c = '123456'
        );
        accountList.add(childAccount);
        insert accountList;

        Company__c company = new Company__c(
            Name = 'Company',
            Blocked__c = false,
            ClientGroup__c = 'A',
            Conta__c = parentAccount.Id
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

        Order order = new Order(
            AccountId = parentAccount.Id,
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type = 'Entrega Armazém Geral',
            ShippingAccount__c = parentAccount.Id,
            PaymentDate__c = Date.today().addDays(-2),
            CustomerOrderNumber__c = '65465',
            EffectiveDate = Date.today(),
            PaymentForm__c = 'Bonificação',
            Currency__c = 'BRL',
            StatusSF__c = 'Em digitação',
            Incoterms__c = 'CIF',
            Crop__c = crop.Id,
            Culture__c = culture.Id,
            SalesCTV__c = UserInfo.getUserId(),
            PaymentCondition__c = paymentCondition.Id,
            ShippingDate__c = Date.today().addDays(2)
        );
        insert order;

        ProductGroup__c productGroup = new ProductGroup__c(
            Name = 'Grãos',
            ExternalId__c = '001'
        );
        insert productGroup;

        Product2 product = new Product2(
            Name = 'Milho',
            ExternalId__c = '001',
            ProductCode = '001',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            PrincipleActive__c = 'Salicilina',
            ProductGroup__c = productGroup.Id,
            Multiplicity__c = 5
        );
        insert product;

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
            ServiceDate = System.today(),
            Quantity = 10,
            UnitPrice = 160,
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
            InvoicedQuantity__c = 0
        );
        insert orderItem;

        ShippingDivison__c shipping = new ShippingDivison__c(
            DeliveryDate__c = System.today().addDays(30),
            Quantity__c = 10,
            ExternalId__c = '001',
            ConfirmedQuantity__c = 0,
            OrderItem__c = orderItem.Id
        );
        insert shipping;
    }

    @isTest
    public static void getOrderDataTest() {
        Id orderId = [SELECT Id FROM Order LIMIT 1].Id;
        OrderScreenController.getOrder(orderId, false);
    }

    @isTest
    public static void saveOrderTest() {
        Order ord = [SELECT Id, AccountId FROM Order LIMIT 1];

        OrderScreenController.HeaderSerialize order = OrderScreenController.getOrderData(ord.Id, false);
        OrderScreenController.AccountSerialize account = OrderScreenController.getOrderAccountData(ord.AccountId);
        List<OrderScreenController.ProductSerialize> ordItemList = OrderScreenController.getOrderItemData(ord.Id);
        List<OrderScreenController.DivisionSerialize> divisionList = OrderScreenController.getShippingDivison();
        OrderScreenController.SummarySerialize summary = new OrderScreenController.SummarySerialize('Observation', 'Observation Sales');

        String data = JSON.serialize(new OrderScreenController.OrderSerializeAll(order, ordItemList, divisionList, account, summary));
        OrderScreenController.saveOrder(null, false, data);
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
}