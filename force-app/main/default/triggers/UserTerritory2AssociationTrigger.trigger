trigger UserTerritory2AssociationTrigger on UserTerritory2Association (after delete) {

        switch on Trigger.operationType {
            when BEFORE_INSERT {
            }
            when AFTER_INSERT {
            }
            when BEFORE_UPDATE {
            }
            when AFTER_UPDATE {
            }
            when BEFORE_DELETE {
            }
            when AFTER_DELETE {
                UserTerritory2AssociationHelper.sendTerritoryCTV(Trigger.new);
            }
        }
}