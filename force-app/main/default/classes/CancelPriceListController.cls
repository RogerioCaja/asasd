public without sharing class CancelPriceListController {
    @AuraEnabled
    public static Boolean cancelPriceList(Id recordId) {
        Id priceRecType = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId();
        JurosDescontoAntecipao__c priceList = [SELECT Id, IsActive__c, RecordTypeId FROM JurosDescontoAntecipao__c WHERE Id =: recordId LIMIT 1];
        
        if (priceList.IsActive__c && priceList.RecordTypeId == priceRecType) {
            priceList.IsActive__c = false;
            update priceList;
            return true;
        }
        return false;
    }
}