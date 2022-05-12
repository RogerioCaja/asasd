@isTest
    public with sharing class AccountTest {

        @TestSetup
        static void makeData(){
    
            Account account = new Account(
                Name = 'Teste 1',
                BillingStreet = ' ',
                BillingState = '' ,
                Phone= '', 
                BillingCity = ' ', 
                BillingLongitude = 000000,
                BillingLatitude = 00000,
                BillingPostalCode = '',
                ExternalId__c = '288',
                Company__c = 'Empresa 01'
            );
            insert account;
            
        }
        @isTest 
        static void accountUpdateIntegrationTest(){
            Account account = [SELECT Id, Company__c FROM Account WHERE Name = 'Teste 1' LIMIT 1];
            account.Company__c = 'Empresa Nova';
            Test.startTest();
            update account;
            Test.stopTest();
        }

        @isTest 
        static void accountInserAndDeleteIntegrationTest(){
            Account account = new Account(
            Name = 'Teste 2',
            BillingStreet = ' ',
            BillingState = '' ,
            Phone= '', 
            BillingCity = ' ', 
            BillingLongitude = 000000,
            BillingLatitude = 00000,
            BillingPostalCode = '',
            ExternalId__c = '11111',
            Company__c = 'Empresa 01'
            );  
            insert account;
            Test.startTest();
            
            delete account;
            Test.stopTest();
        }
    }