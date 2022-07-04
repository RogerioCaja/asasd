public without sharing class OrderTriggerHandler {

    List<Order> oldRecords {get; set;} // Trigger.old 
    List<Order> newRecords {get; set;} // Trigger.new
    Map<Id, Order> oldMap {get; set;} // Trigger.oldMap
    Map<Id, Order> newMap {get; set;} // Trigger.newMap
    public static Boolean isFirstTime = true;
    public static Boolean isAfterInsert = false;

    public OrderTriggerHandler(List<Order> oldRecords, List<Order> newRecords, Map<Id, Order> oldMap, Map<Id, Order> newMap ) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void OnBeforeInsert(){
    }
    
    public void OnAfterInsert(){
        OrderHelper.sendApprovalProccess(this.newRecords);
        OrderHelper.creatyShareRecord(this.newRecords);
        // OrderHelper.calloutOrderToSAP(this.newRecords);
    }
    
    public void OnBeforeUpdate(){
        // OrderHelper.verifyStatus(this.newRecords);
    }
    
    public void OnAfterUpdate(){
        OrderHelper.sendApprovalProccess(this.oldMap, this.newMap);
        OrderHelper.calloutOrderToSAP(this.newRecords);
    }
    
    public void OnBeforeDelete(){}
    
    public void OnAfterDelete(){}
    
    public void OnUndelete(){}
    
}