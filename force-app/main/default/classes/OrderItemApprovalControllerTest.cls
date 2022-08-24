@isTest
public class OrderItemApprovalControllerTest {
    @testSetup public static void makeData() {
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert parentAccount;
        
        Order order = new Order(
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Venda Normal').getRecordTypeId(),
            AccountId = parentAccount.Id,
            ShippingAccount__c = parentAccount.Id,
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type = 'Venda Normal',
            PaymentDate__c = Date.today().addDays(-2),
            CustomerOrderNumber__c = '65465',
            EffectiveDate = Date.today(),
            PaymentForm__c = 'A',
            Currency__c = 'BRL',
            StatusSF__c = 'Em digitação',
            Incoterms__c = 'CIF',
            ShippingDate__c = Date.today().addDays(2),
            Hectare__c = 10
        );
        OrderHelper.disableTrigger();
        insert order;
        OrderHelper.enableTrigger();

        Product2 product = new Product2(
            Name = 'Milho',
            ExternalId__c = '001',
            ProductCode = '001',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            PrincipleActive__c = 'Salicilina',
            Multiplicity__c = 5,
            ClasseAvaliacao__c = 'A',
            GrupoQuimico__c = 'A',
            MarcadoEliminacao__c = 'A',
            NCM__c = 'A',
            NumeroRegistro__c = '2',
            OrigemMaterial__c = 'Ferro',
            UnidadeMedida__c = 'Quilos'
        );
        Product2Helper.disableTrigger();
        insert product;
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
    }
    @isTest public static void getorderItemsTest() {
        Id orderId = [SELECT Id FROM Order LIMIT 1].Id;
        OrderItemApprovalController controller = new OrderItemApprovalController();
        controller.recordId = orderId;
        controller.getorderItems();
    }
}