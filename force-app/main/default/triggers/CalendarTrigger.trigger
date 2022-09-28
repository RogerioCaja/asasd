trigger CalendarTrigger on VisitPlanning__c (before insert, before update) {


    CalendarTriggerHandler handler = new CalendarTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    if (CalendarHelper.isTriggerEnabled()) {
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