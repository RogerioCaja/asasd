@isTest
    public with sharing class AccountTest {

        @TestSetup
        static void makeData(){
    
            Territory2Model terrModel = new Territory2Model(DeveloperName='ModelName',Name = 'Name');
            insert terrModel;
            
        }
        @future
        public static void insertTerritoryAssociation() {
            Account acc = [SELECT Id, ExternalId__c FROM Account WHERE Name = 'Teste 1' LIMIT 1];
            Territory2Model terrModel = [SELECT Id, DeveloperName FROM Territory2Model WHERE DeveloperName = 'ModelName' LIMIT 1];
            List<Territory2Type> terriType   = [SELECT Id, DeveloperName FROM Territory2Type where  DeveloperName = 'SalesTeam' LIMIT 1];
            Territory2 objTerr = [SELECT Id FROM Territory2 where  DeveloperName = 'TestTerritory' LIMIT 1];
            ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = acc.Id, Territory2Id =objTerr.Id, AssociationCause='Territory2Manual' );
            insert objObjectTerritory2Association;
            System.debug('objObjectTerritory2Association'+ objObjectTerritory2Association);
        }
        @future
        public static void insertTerritory() {
            Territory2Model terrModel = [SELECT Id, DeveloperName FROM Territory2Model WHERE DeveloperName = 'ModelName' LIMIT 1];
            List<Territory2Type> terriType   = [SELECT Id, DeveloperName FROM Territory2Type where  DeveloperName = 'SalesTeam' LIMIT 1];
            Territory2 objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId=terrModel.Id, Name='TestTerritory', Territory2TypeId=terriType[0].Id);
            insert objTerr;
        }
        @future
        public static void test() {
            Account account = [SELECT Id, ExternalId__c FROM Account WHERE Name = 'Teste 1' LIMIT 1];
            account.Company__c = 'Empresa Nova';
            update account;
        }
        @isTest 
        static void accountUpdateIntegrationTest(){
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
            
            insertTerritory();
            insertTerritoryAssociation();
            Test.startTest();
            test();
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