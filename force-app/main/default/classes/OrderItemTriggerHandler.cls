public without sharing class OrderItemTriggerHandler {
    public OrderItemTriggerHandler() {

    }

    List<OrderItem> oldRecords {get; set;} // Trigger.old 
    List<OrderItem> newRecords {get; set;} // Trigger.new
    Map<Id, OrderItem> oldMap {get; set;} // Trigger.oldMap
    Map<Id, OrderItem> newMap {get; set;} // Trigger.newMap

    public OrderItemTriggerHandler(List<OrderItem> oldRecords, List<OrderItem> newRecords, Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap ) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void OnBeforeInsert(){
        OrderItemHelper.insertOrderItem(this.newRecords);
    }
    
    public void OnAfterInsert(){
        
    }
    
    public void OnBeforeUpdate(){
    }
    
    public void OnAfterUpdate(){
        OrderItemHelper.updateOrderItem(this.newRecords, this.oldMap);
    }
    
    public void OnBeforeDelete(){}
    
    public void OnAfterDelete(){}
    
    public void OnUndelete(){}
}
