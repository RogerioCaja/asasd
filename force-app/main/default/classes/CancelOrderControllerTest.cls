@isTest
public class CancelOrderControllerTest {
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

        List<Order> lstOrder = new List<Order>();
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
        lstOrder.add(order);

        Order order2 = new Order(
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Venda Normal').getRecordTypeId(),
            AccountId = parentAccount.Id,
            Status = '001',
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
        lstOrder.add(order2);

        OrderHelper.disableTrigger();
        insert lstOrder;
        OrderHelper.enableTrigger();
    }

    @isTest public static void cancelOrderTest() {
        Id orderId = [SELECT Id FROM Order WHERE Status = '0' LIMIT 1].Id;
        Boolean returnValue = CancelOrderController.cancelOrder(orderId);
        System.assert(returnValue);
    }

    @isTest public static void dontCancelOrderTest() {
        Id orderId = [SELECT Id FROM Order WHERE Status = '001' LIMIT 1].Id;
        Boolean returnValue = CancelOrderController.cancelOrder(orderId);
        System.assert(!returnValue);
    }
}