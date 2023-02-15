@isTest
public class CancelPriceListControllerTest {
    @testSetup public static void makeData() {
        JurosDescontoAntecipao__c listPrice = new JurosDescontoAntecipao__c();
        listPrice.RecordTypeId = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId();
        listPrice.IsActive__c = true;
        insert listPrice;
    }

    @isTest public static void cancelPriceListTest() {
        Boolean response = CancelPriceListController.cancelPriceList([SELECT Id FROM JurosDescontoAntecipao__c LIMIT 1].Id);
        System.assert(response);
    }
}