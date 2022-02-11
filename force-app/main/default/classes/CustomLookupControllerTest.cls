@isTest
public class CustomLookupControllerTest {
    
    @TestSetup
    public static void makeData(){

        Account pc = (Account)TestFactory.createSObject(new Account());
        insert pc;
    }

    @isTest
    public static void fetchRecords(){

        Account acc = [SELECT Id FROM Account LIMIT 1];

        CustomLookupController.fetchRecords('Account', 'Name', 'teste', null);
        CustomLookupController.fetchRecords('Account', 'Name', 'teste', acc.Id);
    }
    
}