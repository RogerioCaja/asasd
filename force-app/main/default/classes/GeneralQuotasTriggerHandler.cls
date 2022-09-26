public without sharing class GeneralQuotasTriggerHandler {
    public GeneralQuotasTriggerHandler() {}

    List<GeneralQuotas__c> oldRecords {get; set;} // Trigger.old 
    List<GeneralQuotas__c> newRecords {get; set;} // Trigger.new
    Map<Id, GeneralQuotas__c> oldMap {get; set;} // Trigger.oldMap
    Map<Id, GeneralQuotas__c> newMap {get; set;} // Trigger.newMap

    public GeneralQuotasTriggerHandler(List<GeneralQuotas__c> oldRecords, List<GeneralQuotas__c> newRecords, Map<Id, GeneralQuotas__c> oldMap, Map<Id, GeneralQuotas__c> newMap) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void onBeforeUpdate() {
        GeneralQuotasTriggerHelper.verifyUsedQuantities(newRecords, newMap);
    }
}