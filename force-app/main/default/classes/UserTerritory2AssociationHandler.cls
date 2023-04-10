public with sharing class UserTerritory2AssociationHandler {

    List<UserTerritory2Association> oldRecords {get; set;} // Trigger.old 
    List<UserTerritory2Association> newRecords {get; set;} // Trigger.new
    Map<Id, UserTerritory2Association> oldMap {get; set;} // Trigger.oldMap
    Map<Id, UserTerritory2Association> newMap {get; set;} // Trigger.newMap

    public UserTerritory2AssociationHandler(List<UserTerritory2Association> oldRecords, List<UserTerritory2Association> newRecords, Map<Id, UserTerritory2Association> oldMap, Map<Id, UserTerritory2Association> newMap ) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void onBeforeInsert(){
        UserTerritory2AssociationHelper.validateUserTerritory2Association(this.newRecords);
    }

    public void onBeforeUpdate(){
        UserTerritory2AssociationHelper.validateUserTerritory2Association(this.newRecords);
    }

    public void onAfterDelete(){
        UserTerritory2AssociationHelper.sendTerritoryCTV(this.oldRecords);
    }
}