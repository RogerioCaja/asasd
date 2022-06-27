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

    public void OnBeforeInsert(){
    }
    
    public void OnAfterInsert(){
        System.debug('1');
        OrderHelper.sendApprovalProccess(this.newRecords);
    }
    
    public void OnBeforeUpdate(){
        System.debug('2');
        OrderHelper.calloutOrderToSAP(this.newRecords);
    }
    
    public void OnAfterUpdate(){
        System.debug('3');
        OrderHelper.sendApprovalProccess(this.oldMap, this.newMap);
    }
    
    public void OnBeforeDelete(){}
    
    public void OnAfterDelete(){}
    
    public void OnUndelete(){}
    
}