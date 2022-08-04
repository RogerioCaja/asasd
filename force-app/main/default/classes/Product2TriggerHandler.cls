public with sharing class Product2TriggerHandler {
    public Product2TriggerHandler() {

    }
    List<Product2> oldRecords {get; set;} //Trigger Old 
    List<Product2> newRecords {get; set;} //Trigger New
    Map<Id, Product2> oldMap {get; set;} //Trigger oldMap
    Map<Id, Product2> newMap {get; set;} //Trigger newMap

    public Product2TriggerHandler (List<Product2> oldRecords, List<Product2> newRecords, Map<Id, Product2> oldMap, Map<Id, Product2> newMap){
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void afterInsert(){
        Product2Helper.createStandardEntries(this.newRecords);
    }
}
