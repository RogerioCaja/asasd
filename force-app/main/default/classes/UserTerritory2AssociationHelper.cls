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
        
        if(!Test.isRunningTest() ){
            CalloutCTVCarteira.sendOrderFuture(territoryIdList);
        }
    }
}