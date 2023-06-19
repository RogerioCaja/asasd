@isTest
public with sharing class pdfBoletoControllerTest {
    public  pdfBoletoControllerTest() {}
        @TestSetup
        static void makeData(){
            Account account = new Account(
                Name = 'Testinho11',
                BillingStreet = '',
                BillingState = '' ,
                Phone= '0000011111',
                BillingCity = ' ',
                BillingLongitude = 000000,
                BillingLatitude = 000000,
                BillingPostalCode = '',
                ExternalId__c = '020',
                Company__c = 'Empresa 012'
            );
            insert account;
            SalesOrg__c so = new SalesOrg__c(
                Name = 'AgroGalaxy',
                SalesOrganizationCode__c = '1111'
            );
            insert so;
            Boletos__c boletos = new Boletos__c(
                AccountCode__c = account.Id,
                ExpirationDate__c = Date.valueOf('2022-09-21'),
                IssueDate__c = Date.valueOf('2022-09-21'),
                SalesOrg__c = so.Id,
                Value__c = 20.00,
                WritableLine__c = '002'
            );
            insert boletos;
        }
        @isTest
        static void BoletosExtension_UnitTest(){
            Pagereference pageRef = Page.BoletoPagePDF;
            Test.setCurrentPage(pageRef);
            Boletos__c boletos = [SELECT Id, WritableLine__c,Name FROM Boletos__c LIMIT 1][0];
             pageRef.getParameters().put('Id', String.valueOf([SELECT Id FROM Boletos__c LIMIT 1].Id));
            ApexPages.StandardController stdController = new ApexPages.StandardController([SELECT Id FROM Boletos__c LIMIT 1][0]);
			Test.setMock(HttpCalloutMock.class, new CalloutBoletoPdfMock(true, String.valueOf(boletos.WritableLine__c), false));
            Test.startTest();
            BoletosPdfController boletoExt = new BoletosPdfController(stdController);
            Test.stopTest();
        }
        
        @isTest
        static void vefifyConstructor(){
        PageReference pageRef = Page.BoletoPagePDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf([SELECT Id FROM Boletos__c LIMIT 1].Id));
        ApexPages.StandardController sc = new ApexPages.StandardController([SELECT Id FROM Boletos__c LIMIT 1][0]);
         Test.setMock(HttpCalloutMock.class, new CalloutBoletoPdfMock(true, String.valueOf([SELECT Id, WritableLine__c FROM Boletos__c LIMIT 1][0].WritableLine__c), false));
         Test.startTest();
         BoletosPdfController boletosController = new BoletosPdfController(sc);
         Test.stopTest();
        }
    @isTest
     static void calloutBoletoToken(){
        Test.setMock(HttpCalloutMock.class, new CalloutBoletoPdfMock(true, '0000023', true));
        Test.startTest();
        String response = BoletosPdfController.getAcessCode();
        Test.stopTest();
        System.assertEquals('fdgfdbvkhjfdv', response, 'O access_token devia vir preenchido');
    }
}