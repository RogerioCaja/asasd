@isTest
public with sharing class IntegrationINBoletosTest {

    @TestSetup
    static void makeData(){

        

        Account account = new Account(
            Name = 'Testinho11',
            BillingStreet = '',
            BillingState = '' ,
            Phone= '0000011111', 
            BillingCity = ' ', 
            BillingLongitude = 000000,
            BillingLatitude = 000000,
            BillingPostalCode = '',
            ExternalId__c = '020',
            Company__c = 'Empresa 012'
        );
        insert account;

        SalesOrg__c so = new SalesOrg__c(
            Name = 'AgroGalaxy',
            SalesOrganizationCode__c = '1111'
        );
        insert so;
        Boletos__c boletos = new Boletos__c(
            AccountCode__c = account.Id,
            ExpirationDate__c = Date.valueOf('2022-09-21'),
            IssueDate__c = Date.valueOf('2022-09-21'),
            SalesOrg__c = so.Id,
            Value__c = 20.00,
            WritableLine__c = '002'
        );
        insert boletos;

        SalesOrg__c salesOrg = new SalesOrg__c(
            Name = 'AgroGalaxy',
            SalesOrganizationCode__c = '2222'
        );
        insert salesOrg;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='testes@testes.com');

        insert u;
        
    }
    @isTest
    static void verifyIntegrationBoletos(){
        List<TemplateDataIntegrationFields.BoletosINData> listBoletosList = new List<TemplateDataIntegrationFields.BoletosINData>();
        TemplateDataIntegrationFields.BoletosINData listBoletos = new TemplateDataIntegrationFields.BoletosINData();
        listBoletos.CodigoParceiro = '020';
        listBoletos.VencimentoBoleto = Date.valueOf('2022-09-21');
        listBoletos.DataBoleto = Date.valueOf('2022-09-13');
        listBoletos.Empresa = '102';
        listBoletos.ValorBoleto = 20.00;
        listBoletos.LinhaDigitavel = '002';
        listBoletosList.add(listBoletos);

        IntegrationINBoletos.ResponseModel modelo = IntegrationINBoletos.upsertBoletos(listBoletosList);
        //IntegrationINOrderAppdigital.ResponseModel toPass = new IntegrationINOrderAppdigital.ResponseModel(modelo.response);
        System.debug(modelo);
    }
}