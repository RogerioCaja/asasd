public with sharing class UserTerritory2AssociationHelper {
    private static Boolean isEnabled;

    static{
        isEnabled = true;
    }

    public static Boolean isTriggerEnabled(){
        return isEnabled;
    }
    
    public static Boolean disableTrigger(){
        return isEnabled = false;
    }

    public static Boolean enableTrigger(){
        return isEnabled = true;
    }

    
    public static void sendTerritoryCTV(List<UserTerritory2Association> newRecords){
        List<String> territoryIdList = new List<String>();
        for(UserTerritory2Association territory : newRecords){
            territoryIdList.add(territory.Territory2Id);
        }
        List<Territory2> territoryUserList  = new List<Territory2>([SELECT id, DeveloperName, LastModifiedDate, ParentTerritory2.DeveloperName, name, Territory2Type.DeveloperName FROM territory2 WHERE Id =: territoryIdList]);
        
        if(!Test.isRunningTest() ){
            CalloutCTVCarteira.sendOrder(territoryUserList);
        }
    }
}