@isTest
public with sharing class CalloutCTVCarteiraTest {

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
    static void calloutCTVSuccess(){
        Account account = [SELECT Id FROM Account LIMIT 1];
        User u = [SELECT Id FROM User WHERE UserName='testes_CTV_TEST@testes.com' LIMIT 1];
        Territory2Type terrModel = [SELECT Id FROM Territory2Type LIMIT 1];
        Territory2Model model = [SELECT Id FROM Territory2Model LIMIT 1];
        Territory2 objTerr = new Territory2(); 
            objTerr.Description = 'Description__c';
            objTerr.Name = 'Name';
            objTerr.DeveloperName = 'Name';
            objTerr.Territory2TypeId = terrModel.Id;
            objTerr.Territory2ModelId = model.Id;
        insert objTerr;

        UserTerritory2Association userTerrAssociation = new UserTerritory2Association(Territory2Id= objTerr.Id, UserId= u.Id, RoleInTerritory2='Sales / Marketing Manager');
        insert userTerrAssociation;
        List<Territory2> territoryList = new List<Territory2>();
        territoryList.add(objTerr);
        CalloutOrder calloutTest = new CalloutOrder();
        Test.setMock(HttpCalloutMock.class, new CalloutCTVMock(true));
        Test.startTest();
        CalloutCTVCarteira.sendOrder(territoryList);
        Test.stopTest();
    } 
    @isTest
    static void calloutCTVRequestMethod(){
        List<Company__c> companyList = new List<Company__c>([SELECT Name,Blocked__c, Status__c, ClientGroup__c,Conta__c,SalesOrg__c,DistributionChannel__r.Codigo__c, ActivitySector__r.Codigo__c,SalesOrg__r.SalesOrganizationCode__c,SalesOffice__r.Codigo__c,SalesTeam__r.ExternalId__c,SalesOffice__c,SalesTeam__c,ActivitySector__c,DistributionChannel__c,ExternalID__c,SupplierCenter__c FROM Company__c WHERE ExternalID__c = '001']);
        System.debug('companyList: '+ companyList);
        Map<String,List<Company__c>> compMap = new Map<String,List<Company__c>>();
        Map<String,List<Company__c>> compMap2 = new Map<String,List<Company__c>>();
        compMap.put('001',companyList);
        compMap2.put('000',companyList);
        List<CalloutCTVCarteira.ClienteParameters> clientList= new List<CalloutCTVCarteira.ClienteParameters>();
        Test.startTest();
        clientList.add(new CalloutCTVCarteira.ClienteParameters('001', compMap));
        clientList.add(new CalloutCTVCarteira.ClienteParameters('001', compMap2));
        Test.stopTest();
        System.debug('clientList: '+ clientList);
    } 
}
