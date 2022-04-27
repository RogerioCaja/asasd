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
        TimeZoneSidKey='America/Los_Angeles', UserName='tetedogas@testorg.com');

        insert u;

        Territory2 objTerr = [SELECT Id FROM Territory2];
        
        UserTerritory2Association userTerrAssociation = new UserTerritory2Association(Territory2Id= objTerr.Id, UserId= u.Id, RoleInTerritory2='Sales / Marketing Manager');
        insert userTerrAssociation;

        ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = account.Id, Territory2Id =objTerr.Id, AssociationCause='Territory2Manual' );
        insert objObjectTerritory2Association;
    }
    @isTest
    static void calloutCTVSuccess(){
        CalloutOrder calloutTest = new CalloutOrder();
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class, new CalloutOrderMock(true, String.valueOf(ord.OrderNumber)));
        Test.startTest();
        IntegrationUtils.CalloutCTVResponse response = CalloutCTVCarteira.processIntegration();
        Test.stopTest();
        System.debug(response);
    } 

    @isTest 
    static void calloutCTVFail(){
        Order ord = [SELECT Id, OrderNumber, StatusSF__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class,new CalloutOrderMock(false, String.valueOf(ord.OrderNumber)));
        Test.startTest();
        IntegrationUtils.CalloutCTVResponse response = CalloutCTVCarteira.processIntegration();
        Test.stopTest();
        System.debug(response);
    }
}
