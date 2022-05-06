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
            Safra__c safra = new Safra__c(
                Code__c = '1223.0',
                Name = 'Safra Teste',
                Name__c = 'Safra Teste',
                BillingStartDate__c = System.today(),
                EndDateBilling__c = System.today(),
                EndDateInsertionOrders__c = System.today(),
                NumberOfDaysAfterPayment__c = System.today(),
                ReleaseStatus__c = 'Ativo',
                StartDateOrderInsertion__c = System.today()
    
            );
            INSERT safra;
            INSERT account;

        }

        @isTest
        static void calloutBpSuccess(){

            Test.setMock(HttpCalloutMock.class, new CalloutBPMock(true));
            Account accountBefore = [SELECT Id, CPF__c FROM Account WHERE ExternalId__c = '11111'];
            System.debug('accountBefore'+ accountBefore);
            Test.startTest();
            CalloutBP.processIntegration();
            Test.stopTest();
            Account accountResult = [SELECT Id, CPF__c FROM Account WHERE ExternalId__c = '11111'];
            System.debug('accountResult'+ accountResult);
        } 
    }