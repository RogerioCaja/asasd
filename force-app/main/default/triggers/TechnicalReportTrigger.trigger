trigger TechnicalReportTrigger on TechnicalReport__c (before insert, after insert, after update) {

    TechnicalReportTriggerHandler handler = new TechnicalReportTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    if (TechnicalReportHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when AFTER_INSERT {
                handler.OnAfterInsert();
            }
            when BEFORE_INSERT{
                handler.OnBeforeInsert();
            }
            when AFTER_UPDATE{
                handler.OnAfterUpdate();
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