@isTest
    public with sharing class CalloutBpTest {
    
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
                ExternalId__c = '11111',
                Company__c = 'Empresa 01'
            );
    
            INSERT account;

        }

        @isTest
        static void calloutBpSuccess(){

            Test.setMock(HttpCalloutMock.class, new CalloutBPMock(true));
            Test.startTest();
            CalloutBP.processIntegration();
            Test.stopTest();
        } 
    }