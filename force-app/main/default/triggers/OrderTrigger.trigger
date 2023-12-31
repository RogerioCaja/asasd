trigger OrderTrigger on Order (after insert, before insert, before update, after update, before delete, after delete) {
    OrderTriggerHandler handler = new OrderTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );
    
    if (OrderHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when AFTER_INSERT {
                handler.OnAfterInsert();
            }
            when BEFORE_INSERT{
                //BEFORE INSERT Method
            }
            when AFTER_UPDATE{
                handler.OnAfterUpdate();
            }
            when BEFORE_UPDATE{
                //handler.OnBeforeUpdate();
            }
            when AFTER_DELETE{
                //BEFORE DELETE Method
            }
            when BEFORE_DELETE{
                //BEFORE DELETE Method
            }
        }
    } 
}