@isTest
    public with sharing class CustomerTaxesHelperTest {
        
        @TestSetup
        static void makeData(){
            
    
            SalesOrg__c salesOrg = new SalesOrg__c(
            Name = 'AgroGalaxy',
            SalesOrganizationCode__c = '1111'
            );
            insert salesOrg;
            Account account = new Account(
                Name = 'Teste 1',
                BillingStreet = ' ',
                BillingState = '' ,
                Phone= '', 
                BpType__c = 'Proprietario',
                BillingCity = ' ', 
                BillingLongitude = 000000,
                BillingLatitude = 00000,
                BillingPostalCode = '',
                ExternalId__c = '11111',
                Company__c = 'Empresa 1'
            );
            insert account;
            CustomerTaxes__c customerTax = new CustomerTaxes__c(
                Account__c = account.Id,
                SalesOrg__c = salesOrg.Id,
                Name__c = 'test'
            );
            insert customerTax;
        }

        @isTest
        public 	static void createsExternalIdSucess(){
            Account account = [SELECT Id FROM Account LIMIT 1];
            SalesOrg__c salesOrg = [SELECT Id FROM SalesOrg__c LIMIT 1];
            List<CustomerTaxes__c> customerList = new List<CustomerTaxes__c>();
            CustomerTaxes__c customerTax = new CustomerTaxes__c(
                Account__c = account.Id,
                SalesOrg__c = salesOrg.Id,
                Name__c = 'test1'
            );
            customerList.add(customerTax);
            Test.startTest();
                upsert customerList;
            Test.stopTest();
        }
        @isTest
        public 	static void createsExternalIdError(){
            Account account = [SELECT Id FROM Account LIMIT 1];
            SalesOrg__c salesOrg = [SELECT Id FROM SalesOrg__c LIMIT 1];
            List<CustomerTaxes__c> customerList = new List<CustomerTaxes__c>();
            CustomerTaxes__c customerTax = new CustomerTaxes__c(
                Account__c = account.Id,
                SalesOrg__c = salesOrg.Id,
                Name__c = 'test'
            );
            customerList.add(customerTax);
            Test.startTest();
                insert customerList;
            Test.stopTest();
        }
    }