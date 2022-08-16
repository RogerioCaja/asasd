@isTest
public class CompaniesRelatedToAccountControllerTest {
    @testSetup public static void makeData() {
        Account account = new Account(
            Name = 'Account',
            Company__c = 'Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert account;

        SalesOrg__c salesOrg = new SalesOrg__c(
            Name = 'Sales Organization',
            SalesOrganizationCode__c = '001'
        );
        insert salesOrg;

        SalesOffice__c salesOffice = new SalesOffice__c(
            Name = 'Sales Office',
            Codigo__c = '001'
        );
        insert salesOffice;

        SalesTeam__c salesTeam = new SalesTeam__c(
            Name = 'Sales team'
        );
        insert salesTeam;

        Company__c company = new Company__c(
            Name = 'Company',
            Blocked__c = false,
            ClientGroup__c = '01',
            Conta__c = account.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            ExternalID__c = '001',
            SupplierCenter__c = '1010'
        );
        insert company;
    }

    @isTest public static void getCompaniesTest() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        CompaniesRelatedToAccountController.getCompanies(accountId);
    }
}