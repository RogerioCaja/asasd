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
            Account accountFather = new Account(
                Name = 'Teste 2',
                BillingStreet = ' ',
                BillingState = '' ,
                ParentId = account.Id,
                Phone= '', 
                BillingCity = ' ', 
                BillingLongitude = 000000,
                BillingLatitude = 00000,
                BillingPostalCode = '',
                ExternalId__c = '2234',
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
            
            INSERT accountFather;
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testes_BP_TEST@testes.com',CodigoSap__c = 'test1');
            INSERT u;
            User u2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='tes2@testes.com',CodigoSap__c = 'test2');
            INSERT u2;

            SalesOrg__c salesOrg = new SalesOrg__c(
            Name = 'AgroGalaxy',
            SalesOrganizationCode__c = '2222'
            );
            insert salesOrg;
            SalesTeam__c salesTeam = new SalesTeam__c(
                Name = 'Equipe Teste',
                ExternalId__c = '2222'
            );
            insert salesTeam;
        }
        @future(callout = true)
        public static void processIntegration(){
            Account account = [SELECT Id FROM Account LIMIT 1];
            UserTerritory2Association userTerritory = [SELECT Territory2Id  FROM UserTerritory2Association WHERE RoleInTerritory2 =:'Sales / Marketing Manager' LIMIT 1];
            ObjectTerritory2Association objObjectTerritory2AssociationCreation = new ObjectTerritory2Association(ObjectId = account.Id, Territory2Id = userTerritory.Territory2Id, AssociationCause='Territory2Manual');
            insert objObjectTerritory2AssociationCreation;  
        }
        @future(callout = true)
        public static void processIntegration2(){
            Account account = [SELECT Id FROM Account LIMIT 1];
            UserTerritory2Association userTerritory = [SELECT Territory2Id  FROM UserTerritory2Association WHERE RoleInTerritory2 =:'Sales / Marketing Manage' LIMIT 1];
            ObjectTerritory2Association objObjectTerritory2AssociationCreation = new ObjectTerritory2Association(ObjectId = account.Id, Territory2Id = userTerritory.Territory2Id, AssociationCause='Territory2Manual');
            insert objObjectTerritory2AssociationCreation;  
            List<ObjectTerritory2Association> objObjectTerritory2Association = new List<ObjectTerritory2Association>([SELECT Id, ObjectId, Territory2Id  FROM ObjectTerritory2Association]);
            System.debug('objObjectTerritory2Association: '+ objObjectTerritory2Association);

        }
        @future(callout = true)
        public static void checkResult(){
            Account accountResult = [SELECT Id, ExternalId__c, Email__c, CPF__c FROM Account WHERE ExternalId__c = '11111'];

            List<ObjectTerritory2Association> objObjectTerritory2Association = new List<ObjectTerritory2Association>([SELECT Id, ObjectId, Territory2Id  FROM ObjectTerritory2Association]);
            System.debug('objObjectTerritory2Association: '+ objObjectTerritory2Association);
            System.debug('accountResult: '+ accountResult);
        }
        @isTest
        static void calloutBpSuccess(){
            Account account = [SELECT Id FROM Account LIMIT 1];
            User u = [SELECT Id FROM User WHERE UserName='testes_BP_TEST@testes.com' LIMIT 1];
            Territory2Type terrModel = [SELECT Id FROM Territory2Type LIMIT 1];
            Territory2Model model = [SELECT Id FROM Territory2Model LIMIT 1];
            Territory2 objTerr = new Territory2(); 
                objTerr.Description = 'Description__c';
                objTerr.Name = 'Name';
                objTerr.DeveloperName = 'Name';
                objTerr.Territory2TypeId = terrModel.Id;
                objTerr.Territory2ModelId = model.Id;
            insert objTerr;
            Territory2 objTerr2 = new Territory2(); 
            objTerr2.Description = 'Description';
            objTerr2.Name = 'Nam2e';
            objTerr2.DeveloperName = 'Name2';
            objTerr2.Territory2TypeId = terrModel.Id;
            objTerr2.Territory2ModelId = model.Id;
            insert objTerr2;
            UserTerritory2Association userTerrAssociation = new UserTerritory2Association(Territory2Id= objTerr.Id, UserId= u.Id, RoleInTerritory2='Sales / Marketing Manager');
            insert userTerrAssociation;
            UserTerritory2Association userTerrAssociation2 = new UserTerritory2Association(Territory2Id= objTerr2.Id, UserId= u.Id, RoleInTerritory2='Sales / Marketing Manage');
            insert userTerrAssociation2;
            processIntegration();
            processIntegration2();  
            List<Account> resultAccountsList = new List<Account>([SELECT Id,Name, ParentId FROM Account]);
            System.debug('resultAccountsList'+ resultAccountsList);
            
            Test.setMock(HttpCalloutMock.class, new CalloutBPMock(true));
            Account accountBefore = [SELECT Id, Email__c, CPF__c FROM Account WHERE ExternalId__c = '11111'];
            System.debug('accountBefore'+ accountBefore);
            Test.startTest();
            CalloutBP.processIntegration();
            Test.stopTest();
            checkResult();
        } 
    }