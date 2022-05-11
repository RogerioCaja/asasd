@isTest
public with sharing class CalloutOrderTest {

    @TestSetup
    static void makeData(){
        TemplateDefaultFields t = new TemplateDefaultFields();
        t.packageTest();
    }
    public CalloutOrderTest() {}

    @isTest
    static void calloutOrderSuccess(){
        CalloutOrder calloutTest = new CalloutOrder();
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class, new CalloutOrderMock(true, String.valueOf(ord.OrderNumber)));
        Test.startTest();
        IntegrationUtils.CalloutResponse response = CalloutOrder.processIntegration(ord.Id);
        Test.stopTest();
        System.debug(response);
        System.assertEquals(true, response.success, 'O status era para vir Verdadeiro');
        System.assertEquals('', response.errorMessage, 'A mensagem de Erro deveria vir vazia');
        
    } 

    @isTest 
    static void calloutOrderFail(){
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class,new CalloutOrderMock(false, String.valueOf(ord.OrderNumber)));
        Test.startTest();
        IntegrationUtils.CalloutResponse response = CalloutOrder.processIntegration(ord.Id);
        Test.stopTest();
        System.debug(response);
        System.assertEquals(false, response.success, 'O status era para vir falso');
    }

    @isTest 
    static void calloutOrderException(){
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class, new ExceptionCallouts());
        Test.startTest();
        IntegrationUtils.CalloutResponse response = CalloutOrder.processIntegration(ord.Id);
        Test.stopTest();
        System.assertEquals('Error', response.errorMessage, 'Deveria ter falhado');
    }

    @isTest
    static void calloutOrderTrigger(){
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class,new CalloutOrderMock(true, String.valueOf(ord.OrderNumber)));
        ord.StatusSF__c = 'Aprovado';
        
        Test.startTest();
        update ord;
        Test.stopTest();
        
        Order ord1 = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        System.assertEquals('Integrado', ord1.StatusSF__c);
    }
}
