@isTest
public with sharing class FotosHelperTest {
    
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

        
    }
	@isTest
    public 	static void verifyInsertFoto(){
        
        Account acct = [SELECT Id FROM Account WHERE Name='Teste 1' LIMIT 1];
            
        Account acct2 = [SELECT Id FROM Account WHERE Name='Teste 2' LIMIT 1];
        
        Cultura__c cult = [SELECT Id FROM Cultura__c WHERE Name='Safrinha' LIMIT 1];
        
        Safra__c safr = [SELECT Id FROM Safra__c WHERE Name='Safra Teste' LIMIT 1];
        
        User us = [SELECT Id FROM User WHERE CodigoSap__c = '010' LIMIT 1];
        
		VisitPlanning__c visit = new VisitPlanning__c();
            
            visit.Name = 'Test';
        	visit.MainBP__c = acct.Id;
        	visit.BP_Property__c = acct2.Id;
        	visit.InitialDate__c = Date.valueOf('2022-09-21');
        	visit.EndDate__c = Date.valueOf('2022-09-23');
        	visit.StartTime__c = Time.newInstance(18, 30, 2, 20);
        	visit.EndTime__c = Time.newInstance(18, 30, 2, 22);
        	visit.Status__c = 'Agendado';
        	visit.Objetivo__c = 'Evento';
        	visit.Safra__c = safr.Id;
        	visit.Culture__c = cult.Id;
        	visit.Email__c = 'test@gmail.com';
        	visit.Presential__c = true;
        	visit.Reminder__c = false;
        	visit.Displacement__c  = 'Sim';
        	visit.VisitSeller__c = us.Id;
        	visit.Note__c = 'test1';
        	visit.ReschedulingReason__c = 'test1';
        	visit.CancellationReason__c = 'test1';
        	//visit.ExternalId__c = '00232';
        	

        	insert visit;
        	
        	TechnicalReport__c techReport = new TechnicalReport__c();
            
            techReport.ExternalId__c = '001';
            techReport.Status__c = 'Gerado';
            techReport.rtrControl__c = 10;
            techReport.Note__c = 'Visita realizada';
        	techReport.VisitPlanning__c = visit.id;
			techReport.EndTime__c = Time.newInstance(18, 30, 2, 20);
            techReport.EndDate__c = Date.valueOf('2022-09-23');
            techReport.CancellationReason__c = 'teste';
        	insert techReport;
        
        
        	Fotos__c fotos = new Fotos__c();
            	fotos.Observation__c = 'Teste de foto';
            	fotos.RTR__c = techReport.id;
        		fotos.FotoControl__c = 10;

       		 insert fotos;
        
        	Fotos__c fotos2 = new Fotos__c();
            	fotos2.Observation__c = 'Teste de foto2';
            	fotos2.RTR__c = techReport.id;
        		

       		 insert fotos2;
        
        	Fotos__c fotos3 = new Fotos__c();
            	fotos3.Observation__c = 'Teste de foto2';
            	fotos3.RTR__c = techReport.id;
        		
			FotosHelper.disableTrigger();
       		 insert fotos3;
        	FotosHelper.enableTrigger();
    }
    
}