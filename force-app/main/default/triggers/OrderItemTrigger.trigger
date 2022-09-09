trigger OrderItemTrigger on OrderItem (after insert, before insert, before update, after update, before delete, after delete) {
    OrderItemTriggerHandler handler = new OrderItemTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    if (OrderItemHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when AFTER_INSERT {
            }
            when BEFORE_INSERT{
                handler.OnBeforeInsert();
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
