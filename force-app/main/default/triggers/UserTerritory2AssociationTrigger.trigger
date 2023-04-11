trigger UserTerritory2AssociationTrigger on UserTerritory2Association (before insert, before update, after delete) {

    UserTerritory2AssociationHandler handler = new UserTerritory2AssociationHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

        switch on Trigger.operationType {
            when BEFORE_INSERT {
                handler.onBeforeInsert();
            }
            when AFTER_INSERT {
            }
            when BEFORE_UPDATE {
                handler.onBeforeUpdate();
            }
            when AFTER_UPDATE {
            }
            when BEFORE_DELETE {
            }
            when AFTER_DELETE {
                handler.onAfterDelete();
            }
        }
}