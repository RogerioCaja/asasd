@isTest
public class OrderScreenControllerTest {
    @TestSetup
    public static void makeData() {
        List<Account> accountList = new List<Account>();
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        accountList.add(parentAccount);

        Account childAccount = new Account(
            Name = 'Child Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        accountList.add(childAccount);
        insert accountList;

        Order order = new Order(
            AccountId = parentAccount.Id,
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type = '1',
            ShippingAccount__c = parentAccount.Id,
            PaymentDate__c = Date.valueOf('2022-03-30'),
            CustomerOrderNumber__c = '65465',
            EffectiveDate = Date.today(),
            PaymentForm__c = 'Bonificação',
            Currency__c = 'BRL',
            StatusSF__c = 'Em digitação',
            Incoterms__c = 'CIF'
        );
        insert order;

        Product2 product = new Product2(
            Name = 'Milho',
            ExternalId__c = '001',
            ProductCode = '001',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            PrincipleActive__c = 'Salicilina'
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
            CommercialMargin__c = 2
        );
        insert orderItem;
    }

    @isTest
    public static void getOrderDataTest() {
        Id orderId = [SELECT Id FROM Order LIMIT 1].Id;
        String orderData = OrderScreenController.getOrder(orderId);
        OrderScreenController.saveOrder(null, orderData);
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
}