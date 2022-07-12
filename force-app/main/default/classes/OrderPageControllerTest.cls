@isTest
public with sharing class OrderPageControllerTest {
    public OrderPageControllerTest() {

    }

    @TestSetup
    static void makeData(){
        TemplateDefaultFields t = new TemplateDefaultFields();
        t.packageTest();
    }

    @isTest
    public static void verifyDateFormat(){
        String dateTest = OrderPageController.getDatetime();

        System.assert((String.isNotBlank(dateTest) && String.isNotEmpty(dateTest)), 'Os dados resultaram em falha');
    }

    @isTest 
    static void verifyGetOrderById(){
        Order order = OrderPageController.getOrderById([SELECT Id FROM Order LIMIT 1].Id);

        System.assert(order != null, 'Order está vindo nulo');
    }

    @isTest 
    static void verifyGetOrderItemByOrderId(){
        List<OrderItem> orderItemList = OrderPageController.getOrderItemByOrderId([SELECT Id FROM Order LIMIT 1].Id);

        System.assert(orderItemList.size() >= 0 , 'A lista de OrderItem não está sendo retornada');
    }

    @isTest 
    static void verifyGetDivisonByList(){
        List<OrderItem> orderItemList = [SELECT Id FROM OrderItem];
        OrderPageController.getDivisonByList(orderItemList);

    }

    @isTest 
    static void verifyGeneratePDF(){
        // ApexPages.StandardController sc = new ApexPages.StandardController(testAccountPlanInsert);
        OrderPageController orderController = new OrderPageController();
        Id orderId = [SELECT Id FROM Order LIMIT 1].Id;
        Order order = OrderPageController.getOrderById(orderId);
        List<OrderItem> orderItemList = OrderPageController.getOrderItemByOrderId(orderId);
        OrderPageController.OrderDAO testValue = orderController.generatePDF(orderId);

  
        System.assertEquals(order.Account.ExternalId__c, testValue.codeSap, 'Erro no Campo: codeSap');
        System.assertEquals(order.Account.Name, testValue.account, 'Erro no Campo: account');
        System.assertEquals(order.Account.BillingStreet, testValue.accountAddress, 'Erro no Campo: accountAddress');
        System.assertEquals(order.ShippingAccount__r.Name, testValue.ranch, 'Erro no Campo: ranch');
        System.assertEquals(order.Account.BillingCity, testValue.district, 'Erro no Campo: district');
        System.assertEquals(order.Account.StateRegistration__c, testValue.IE, 'Erro no Campo: IE');
        System.assertEquals(order.Account.BillingPostalCode, testValue.CEP, 'Erro no Campo: CEP');
        System.assertEquals(order.Crop__r.Name, testValue.safra, 'Erro no Campo: safra');
        System.assertEquals(order.PaymentForm__c, testValue.paymentCondition, 'Erro no Campo: paymentCondition');
        System.assertEquals(String.valueOf(order.PaymentDate__c), testValue.dueDate, 'Erro no Campo: dueDate');
        System.assertEquals(order.Currency__c, testValue.currencyOrder, 'Erro no Campo: currencyOrder');
        System.assertEquals(order.Culture__r.Name, testValue.culture, 'Erro no Campo: culture');
        System.assertEquals(order.CodigoSap__c, testValue.codeSapOrder, 'Erro no Campo: codeSapOrder');
        System.assert(orderItemList.size() > 0 , 'A lista de OrderItem não está sendo retornada');

        // System.assertEquals(testValue.orderItemList.get(0).productCode, orderItemList.get(0).Product2Id, 'Erro no Campo: Product2Id');
        // System.assertEquals(testValue.orderItemList.get(0).description, orderItemList.get(0).Description, 'Erro no Campo: Description');
        // System.assertEquals(testValue.orderItemList.get(0).culture, order.Culture__c, 'Erro no Campo: Culture__c');
        // System.assertEquals(testValue.orderItemList.get(0).unitOfMeasure, orderItemList.get(0).UnitMeasure__c, 'Erro no Campo: UnitMeasure__c');
        // System.assertEquals(testValue.orderItemList.get(0).unitPrice, orderItemList.get(0).UnitPrice, 'Erro no Campo: UnitPrice');
        // System.assertEquals(testValue.orderItemList.get(0).quantity, orderItemList.get(0).Quantity, 'Erro no Campo: Quantity');
        // System.assertEquals(testValue.orderItemList.get(0).totalAmount, orderItemList.get(0).TotalPrice, 'Erro no Campo: TotalPrice');

    }

    @isTest
    static void vefifyConstructor(){
        PageReference pageRef = Page.OrderPagePDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf([SELECT Id FROM Order LIMIT 1].Id));
        ApexPages.StandardController sc = new ApexPages.StandardController([SELECT Id FROM Order LIMIT 1][0]);
         // ApexPages.StandardController sc = new ApexPages.StandardController(testAccountPlanInsert);
         OrderPageController orderController = new OrderPageController(sc);
    }

    @isTest
    static void vefifyConstructorException(){
        PageReference pageRef = Page.OrderPagePDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', null);
        ApexPages.StandardController sc = new ApexPages.StandardController([SELECT Id FROM Order LIMIT 1][0]);
         // ApexPages.StandardController sc = new ApexPages.StandardController(testAccountPlanInsert);
         OrderPageController orderController = new OrderPageController(sc);

    }
}
