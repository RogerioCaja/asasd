public without sharing class IndividualQuotasHandler {
    public IndividualQuotasHandler() {}

    List<IndividualQuotas__c> oldRecords {get; set;} // Trigger.old 
    List<IndividualQuotas__c> newRecords {get; set;} // Trigger.new
    Map<Id, IndividualQuotas__c> oldMap {get; set;} // Trigger.oldMap
    Map<Id, IndividualQuotas__c> newMap {get; set;} // Trigger.newMap

    public IndividualQuotasHandler(List<IndividualQuotas__c> oldRecords, List<IndividualQuotas__c> newRecords, Map<Id, IndividualQuotas__c> oldMap, Map<Id, IndividualQuotas__c> newMap) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void onBeforeInsert() {
        IndividualQuotasHelper.changeGeneralValues(newRecords, null);
    }
    
    public void onBeforeUpdate() {
        IndividualQuotasHelper.changeGeneralValues(newRecords, oldMap);
    }
}