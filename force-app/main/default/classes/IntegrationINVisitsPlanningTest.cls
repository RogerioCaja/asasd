@isTest
public class IntegrationINVisitsPlanningTest {
  
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
            Phone= '', 
            BillingCity = ' ', 
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
            TimeZoneSidKey='America/Los_Angeles', UserName='testes_BP_TEST@testes.com',CodigoSap__c = 'test1');
        insert u;
    }
    
    @isTest
    static void verifyIntegrationINVisitPlanning(){
        List<TemplateDataIntegrationFields.TechnicalReportINData> technicalList = new List<TemplateDataIntegrationFields.TechnicalReportINData>();
        TemplateDataIntegrationFields.TechnicalReportINData technical = new TemplateDataIntegrationFields.TechnicalReportINData();
        technical.Observation = '';
        technical.EndTime = Time.newInstance(18, 30, 2, 20);
        technical.EndDate = Date.valueOf('2022-09-23');
        technical.Status = 'Gerado';
        technicalList.add(technical);


        List<TemplateDataIntegrationFields.VisitPlanningINData> visitList = new List<TemplateDataIntegrationFields.VisitPlanningINData>();
        TemplateDataIntegrationFields.VisitPlanningINData visit = new TemplateDataIntegrationFields.VisitPlanningINData();
        visit.Name = 'Test';
        visit.BpCode = '11111';
        visit.BpPropertyCode = '2222';
        visit.PlanStartDate = Date.valueOf('2022-09-21');
        visit.PlanEndDate = Date.valueOf('2022-09-23');
        visit.StartTime = Time.newInstance(18, 30, 2, 20);
        visit.EndTime = Time.newInstance(18, 30, 2, 22);
        visit.Status = 'Agendado';
        visit.Objective = 'Evento';
        visit.Crop = '111';
        visit.Culture = '1234';
        visit.Email = 'test@gmail.com';
        visit.Presential = true;
        visit.Reminder = false;
        visit.Displacement  = 'test1';
        visit.CtvVisit = '010';
        visit.Observation = 'test1';
        visit.ReasonRescheduling = 'test1';
        visit.ReasonCancellation = 'test1';
        visit.TechnicalReports.addAll(technicalList);
        visitList.add(visit);
        
        Test.startTest();
        IntegrationINCropDelimitation.ResponseModel model = IntegrationINVisitsPlanning.upsertVisitsPlanning(visitList);
        Test.stopTest();
        
        System.debug(model);
    }
}