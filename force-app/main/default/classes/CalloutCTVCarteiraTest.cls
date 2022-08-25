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
        //ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = account.Id, Territory2Id =objTerr.Id, AssociationCause='Territory2Manual' );
        //insert objObjectTerritory2Association;

        List<Territory2> territoryList = new List<Territory2>();
        territoryList.add(objTerr);
        CalloutOrder calloutTest = new CalloutOrder();
        Test.setMock(HttpCalloutMock.class, new CalloutCTVMock(true));
        Test.startTest();
        CalloutCTVCarteira.sendOrder(territoryList);
        Test.stopTest();
    } 
}
