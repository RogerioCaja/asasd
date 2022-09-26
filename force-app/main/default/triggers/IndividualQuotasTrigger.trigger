trigger IndividualQuotasTrigger on IndividualQuotas__c (before insert, after insert, before update, after update, before delete, after delete) {
    IndividualQuotasHandler handler = new IndividualQuotasHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    if (IndividualQuotasHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                handler.onBeforeInsert();
            }
            when AFTER_INSERT {
                //AFTER INSERT method
            }
            when BEFORE_UPDATE {
                handler.onBeforeUpdate();
            }
            when AFTER_UPDATE {
                //AFTER INSERT method
            }
            when BEFORE_DELETE {
                //AFTER DELETE Method
            }
            when AFTER_DELETE {
                //BEFORE DELETE Method
            }
        }
    }
}