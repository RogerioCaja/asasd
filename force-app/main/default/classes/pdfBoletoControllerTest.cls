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
        static void vefifyConstructor(){
        PageReference pageRef = Page.BoletoPagePDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf([SELECT Id FROM Boletos__c LIMIT 1].Id));
        ApexPages.StandardController sc = new ApexPages.StandardController([SELECT Id FROM Boletos__c LIMIT 1][0]);
         // ApexPages.StandardController sc = new ApexPages.StandardController(testAccountPlanInsert);
         BoletosPdfController boletosController = new BoletosPdfController(sc);
        }

        
    
}
