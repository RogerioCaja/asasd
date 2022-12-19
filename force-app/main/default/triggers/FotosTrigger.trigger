trigger FotosTrigger on Fotos__c (before insert, before update, after insert, after update) {

    FotosTriggerHandler handler = new FotosTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    if (FotosHelper.isTriggerEnabled()){
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
             when BEFORE_UPDATE{
                handler.OnBeforeUpdate();
            }
            // when AFTER_DELETE{
            //     //BEFORE DELETE Method
            // }
            // when BEFORE_DELETE{
            //     //BEFORE DELETE Method
            // }
        }
    }
}