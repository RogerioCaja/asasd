@isTest
public class CustomAccountLookupControllerTest {
    @TestSetup
    public static void makeData(){
        List<Account> accountList = new List<Account>();
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        accountList.add(parentAccount);

        Account childAccount = new Account(
            Name = 'Child Account',
            Company__c = 'Child Account',
            Phone = '11111111111',
            ExternalId__c = '123457'
        );
        accountList.add(childAccount);
        insert accountList;
    }

    @isTest
    public static void fetchAccountRecordsTest(){
        CustomAccountLookupController.fetchAccountRecords('Child Account');
    }
}