trigger Product2Trigger on Product2 (after insert, after update) {

    Product2TriggerHandler handler = new Product2TriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    if (Product2Helper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_INSERT {
                handler.OnAfterInsert();
            }
            when AFTER_UPDATE {
                handler.OnAfterUpdate();
            }
        }
    }
}