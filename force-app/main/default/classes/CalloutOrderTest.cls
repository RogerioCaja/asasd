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
        Test.setMock(HttpCalloutMock.class, new CalloutOrderMock(true, String.valueOf(ord.OrderNumber), false));
        Test.startTest();
        IntegrationUtils.CalloutResponse response = CalloutOrder.processIntegration(ord.Id);
        Test.stopTest();
        System.debug(response);
        System.assertEquals(true, response.success, 'O status era para vir Verdadeiro');
        System.assertEquals('', response.errorMessage, 'A mensagem de Erro deveria vir vazia');
        
    } 

    @isTest
    static void calloutOrderToken(){
     
        Test.setMock(HttpCalloutMock.class, new CalloutOrderMock(true, '0000023', true));
        Test.startTest();
        String response = CalloutOrder.getAccessToken();
        Test.stopTest();
        
        System.assertEquals('fdgfdbvkhjfdv', response, 'O access_token devia vir preenchido');
      
        
    } 

    @isTest
    static void calloutOrderUpdateToken(){
     
        Test.setMock(HttpCalloutMock.class, new CalloutOrderMock(true, '0000023', true));
        Test.startTest();
        String response = CalloutOrderUpdate.getAccessToken();
        Test.stopTest();
        
        System.assertEquals('fdgfdbvkhjfdv', response, 'O access_token devia vir preenchido');
      
        
    } 


    @isTest 
    static void calloutOrderFail(){
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class,new CalloutOrderMock(false, String.valueOf(ord.OrderNumber), false));
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
    static void calloutOrderUpdateException(){
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class, new ExceptionCallouts());
        Test.startTest();
        IntegrationUtils.CalloutUpdateResponse response = CalloutOrderUpdate.processIntegration(ord.Id, 'a', 'b', 'c');
        Test.stopTest();
        System.assertEquals('Error', response.errorMessage, 'Deveria ter falhado');
    }

    @isTest
    static void calloutOrderTrigger(){
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class,new CalloutOrderMock(true, String.valueOf(ord.OrderNumber), false));
        ord.StatusSF__c = 'Aprovado';
        
        Test.startTest();
        update ord;
        Test.stopTest();
        
        Order ord1 = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        System.assertEquals('Integrado', ord1.StatusSF__c);
    }

    
    @isTest 
    static void calloutTestCodeSAP(){
        String valueActual = CalloutOrder.getCodeTypeOrder('VendaContaOrdem', false );
        System.assertEquals('ZRCO', valueActual, 'O valor devia ter sido ZRCO');
        valueActual = CalloutOrder.getCodeTypeOrder('VendaContaOrdem', true);
        System.assertEquals('ZCCO', valueActual, 'O valor devia ter sido ZCCO');
    }

    @isTest 
    static void calloutUpdateOrder(){
        CalloutOrderUpdate calloutTest = new CalloutOrderUpdate();
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class, new CalloutOrderMock(true, String.valueOf(ord.OrderNumber), false));
        Test.startTest();
        IntegrationUtils.CalloutUpdateResponse response = CalloutOrderUpdate.processIntegration(ord.Id, 'a', 'b', 'c');
        Test.stopTest();
        System.debug(response);
        System.assertEquals(true, response.success, 'O status era para vir Verdadeiro');
        System.assertEquals('', response.errorMessage, 'A mensagem de Erro deveria vir vazia');
    }
}
