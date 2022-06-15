@isTest
public class LookupTest {
    @testSetup public static void makeData() {
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert parentAccount;

        Account childAccount = new Account(
            Name = 'Child Account',
            Company__c = 'Child Account',
            Phone = '11111111111',
            ExternalId__c = '123457'
        );
        insert childAccount;

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
            ClientGroup__c = 'NÃO SEGMENTADO',
            Conta__c = parentAccount.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            ExternalID__c = '001',
            SupplierCenter__c = '1010'
        );
        insert company;
    }
    @isTest public static void getRecordsTest() {
        Id parentAccountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        Id childAccountId = [SELECT Id FROM Account WHERE Name != 'Parent Account' LIMIT 1].Id;
        Lookup.getRecords('{"targetObject":"Company__c","searchFields":["Name"],"searchValue":"Empresa","moreFields":[], "relations": [{"parentRelationField": "Conta__c", "parentRecord": "' + parentAccountId + '"}], "differentRelations": [{"parentRelationField": "Conta__c", "parentRecord": "' + childAccountId + '"}], "accountId":"' + parentAccountId + '"}');
    }
}