trigger GeneralQuotasTrigger on GeneralQuotas__c (before insert, after insert, before update, after update, before delete, after delete) {
    GeneralQuotasTriggerHandler handler = new GeneralQuotasTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    if (GeneralQuotasTriggerHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                //BEFORE INSERT Method
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