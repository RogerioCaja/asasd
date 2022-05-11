@isTest
    public with sharing class AccountTest {


        @isTest 
        static void calloutUserIntegration(){
            Account account = new Account(
            Name = 'Teste 1',
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
            Test.startTest();
            insert account;
            delete account;
            Test.stopTest();
        }
    }