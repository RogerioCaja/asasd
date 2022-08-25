@isTest
public class CallExcludePageControllerTest {
    @testSetup public static void makeData() {
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert parentAccount;

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

        Order order = new Order(
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Venda Normal').getRecordTypeId(),
            AccountId = parentAccount.Id,
            Status = '0',
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
            ShippingDate__c = Date.today().addDays(2)
        );
        insert order;

        Product2 prod = new Product2(
            Name = 'Laptop X200', 
            Family = 'Hardware',
            ExternalId__c = '0001',
            ClasseAvaliacao__c = 'av01',
            GrupoQuimico__c = 'bg1',
            MarcadoEliminacao__c = 'tes01',
            NCM__c = '85432000',
            NumeroRegistro__c = '2',
            OrigemMaterial__c = 'sp',
            UnidadeMedida__c = 'un'
        );
        insert prod;
        
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = prod.Id,
            NumeroSap__c = '123',
            UnitMeasure__c = 'L',
            UnitPrice = 10000,
            Quantity = 1,
            ExternalId__c = 'texto',
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id =: prod.Id LIMIT 1][0].Id
        );
        insert orderItem;
    }

    @isTest public static void excludeItemTest() {
        // PageReference pageRef = Page.CallExcludePage;
        // Test.setCurrentPage(pageRef);

        OrderItem orderItem = [SELECT Id FROM OrderItem];
        ApexPages.StandardController sc = new ApexPages.standardController(orderItem);
      
        CallExcludePageController controller = new CallExcludePageController(sc);
    }
}