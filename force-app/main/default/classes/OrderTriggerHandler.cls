public without sharing class OrderTriggerHandler {

    List<Order> oldRecords {get; set;} // Trigger.old 
    List<Order> newRecords {get; set;} // Trigger.new
    Map<Id, Order> oldMap {get; set;} // Trigger.oldMap
    Map<Id, Order> newMap {get; set;} // Trigger.newMap

    public OrderTriggerHandler(List<Order> oldRecords, List<Order> newRecords, Map<Id, Order> oldMap, Map<Id, Order> newMap ) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    
    public void OnAfterInsert(){
        OrderHelper.sendApprovalProccess(this.newRecords);
        OrderHelper.creatyShareRecord(this.newRecords);
    }
    
    public void OnBeforeUpdate(){
        OrderHelper.checkOrderStatus(this.newRecords, this.oldMap);
        OrderHelper.verifyStatusAndCombos(this.oldMap, this.newMap);
    }
    
    public void OnAfterUpdate(){
        OrderHelper.verifyOrderCanceling(this.oldMap, this.newMap);
        OrderHelper.sendApprovalProccess(this.oldMap, this.newMap);
        OrderHelper.calloutOrderToSAP(this.newRecords);
        OrderHelper.creatyShareRecord(this.newRecords);
        OrderHelper.setStageApprovalProcess(this.newMap);
    }
    
    
}