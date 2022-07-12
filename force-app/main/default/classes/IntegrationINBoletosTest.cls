@isTest
public with sharing class IntegrationINBoletosTest {

    @TestSetup
    static void makeData(){

        Boletos__c boletos = new Boletos__c(
            AccountCode__c ='020',
            ExpirationDate__c = Date.valueOf('2022-09-21'),
            IssueDate__c = Date.valueOf('2022-09-21'),
            SalesOrg__c = '102',
            Value__c = 20.00,
            WritableLine__c = '002'
        );
        insert boletos;

        Account account = new Account(
            Name = 'Testinho11',
            BillingStreet = '',
            BillingState = '' ,
            Phone= '0000011111', 
            BillingCity = ' ', 
            BillingLongitude = 01010101,
            BillingLatitude = 001100,
            BillingPostalCode = '',
            ExternalId__c = '2884',
            Company__c = 'Empresa 012'
        );
        insert account;

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
        listBoletos.codigoParceiro = '020';
        listBoletos.vencimentoBoleto = Date.valueOf('2022-09-21');
        listBoletos.dataBoleto = Date.valueOf('2022-09-13');
        listBoletos.empresa = '102';
        listBoletos.valorBoleto = 20.00;
        listBoletos.linhaDigitavel = '002';
        listBoletosList.add(listBoletos);

        IntegrationINBoletos.ResponseModel modelo = IntegrationINBoletos.upsertBoletos(listBoletosList);
        //IntegrationINOrderAppdigital.ResponseModel toPass = new IntegrationINOrderAppdigital.ResponseModel(modelo.response);
        System.debug(modelo);
    }
}