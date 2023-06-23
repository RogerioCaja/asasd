@isTest
    public with sharing class BatchCTVSchedulableTest {

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
            insert account;
    
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testes_CTV_TEST@testes.com');
    
            insert u;
    
            SalesOrg__c salesOrg = new SalesOrg__c(
                Name = 'AgroGalaxy',
                SalesOrganizationCode__c = '1111'
            );
            insert salesOrg;
            DistributionChannel__c distributionChannel = new DistributionChannel__c(
                Name = 'Teste',
                Codigo__c = '0001'
            );
            insert distributionChannel;
    
            SalesOffice__c salesOffice = new SalesOffice__c(
                Name = 'Sales Office',
                Codigo__c = '001'
            );
            insert salesOffice;
    
            SalesTeam__c salesTeam = new SalesTeam__c(
                Name = 'Sales team',
                ExternalId__c = '001'
            );
            insert salesTeam;
    
            ActivitySector__c activitySector = new ActivitySector__c(
                Name = 'Teste Activity',
                Codigo__c = '003'
            );
            insert activitySector;
    
            Company__c company = new Company__c(
                Name = 'Company',
                Blocked__c = false,
                ClientGroup__c = '11',
                Conta__c = account.Id,
                SalesOrg__c = salesOrg.Id,
                SalesOffice__c = salesOffice.Id,
                SalesTeam__c = salesTeam.Id,
                ActivitySector__c = activitySector.Id,
                DistributionChannel__c = distributionChannel.Id,
                ExternalID__c = '001',
                SupplierCenter__c = '1010'
            );
            insert company;
        }

        @isTest
        public static void testBatchDeliveryNotificationSchedulable(){
            String sch = '0 0 * * * ?';
            Test.startTest();
            System.schedule('Delivery Notification Schedule Job Test Class', sch, new BatchCTVSchedulable());
            Test.stopTest();
        }
        
    }