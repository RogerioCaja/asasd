@isTest
    public class CalloutVisitsTest {
      
        @TestSetup
        static void makeData(){
    
            Safra__c safra = new Safra__c(
                Code__c = '111',
                Name = 'Safra Teste',
                Name__c = 'Safra Teste',
                BillingStartDate__c = System.today(),
                EndDateBilling__c = System.today(),
                EndDateInsertionOrders__c = System.today(),
                NumberOfDaysAfterPayment__c = System.today(),
                ReleaseStatus__c = 'Ativo',
                StartDateOrderInsertion__c = System.today()
    
            );
            insert safra;
    
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
            Account account2 = new Account(
                Name = 'Teste 2',
                BillingStreet = ' ',
                BillingState = '' ,
                ParentId = account.Id,
                Phone= '', 
                BillingCity = ' ', 
                BpType__c = 'Propriedade',
                BillingLongitude = 000000,
                BillingLatitude = 00000,
                BillingPostalCode = '',
                ExternalId__c = '2222',
                Company__c = 'Empresa 1'
            );
            insert account2;


            Cultura__c cultura = new Cultura__c(
                Name = 'Safrinha',
                Name__c = 'Safrinha',
                Codigo__c = '1234'
            );
            insert cultura;

            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
            User u = new User(
                Alias = 'standt', Email='standarduser@testorg.com', CodigoSap__c = '010',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='testes_BP_TEST@testes.com');
            insert u;

            SalesOrg__c so = new SalesOrg__c(
                Name = 'AgroGalaxy',
                SalesOrganizationCode__c = '1111'
            );
            insert so;

            VisitPlanning__c vp = new VisitPlanning__c(
                Name = 'test Visit',
                ExternalId__c = 'test123',
                MainBP__c = account.Id,
                BP_Property__c = account2.Id,
                CTVvisit__c = 'Teste',
                VisitSeller__c = u.Id,
                Status__c = 'Agendado',
                Objetivo__c = 'Evento',
                EndTime__c  = Time.newInstance(1, 2, 3, 6),  
			    StartTime__c = Time.newInstance(1, 2, 3, 1),
                Culture__c = cultura.Id,
                EndDate__c = System.today(),
                InitialDate__c = System.today(),
                Safra__c = safra.id,
                SellOrg__c = so.Id
            );
            insert vp;
            TechnicalReport__c technicalReport = new TechnicalReport__c(
                EndDate__c  = System.today(),
                EndTime__c = Time.newInstance(1, 2, 3, 1),
                CancellationReason__c = '',
                Note__c = 'test',
                Status__c = 'Gerado',
                VisitPlanning__c = vp.Id
            );
            insert technicalReport;
            
        }
        
        @isTest
        static void verifyIntegrationOUTVisit(){
            List<VisitPlanning__c> visitList = new List<VisitPlanning__c>([SELECT Id,Name, MainBP__r.ExternalId__c, BP_Property__r.ExternalId__c, InitialDate__c, EndDate__c, StartTime__c, EndTime__c, 
            Status__c, Objetivo__c, Safra__r.Code__c, Culture__r.Codigo__c, Email__c, Presential__c, Reminder__c, Displacement__c, VisitSeller__r.CodigoSap__c, Note__c, ReschedulingReason__c, 
            CancellationReason__c, ExternalId__c FROM VisitPlanning__c LIMIT 1]);
            List<String> visitIdList = new List<String>();
            for(VisitPlanning__c visit : visitList){
                visitIdList.add(visit.Id);
            }
            Test.startTest();
            CalloutVisits.callIntegration(visitIdList);
            Test.stopTest();
            
        }
    }