trigger CalendarTrigger on VisitPlanning__c (before insert, before update, after insert, after update) {


    CalendarTriggerHandler handler = new CalendarTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    if (CalendarHelper.isTriggerEnabled()) {
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
            
        }
    }
}