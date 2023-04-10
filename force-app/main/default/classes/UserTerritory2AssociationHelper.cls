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

    public static void validateUserTerritory2Association(List<UserTerritory2Association> newRecords){
        List<AggregateResult> territoriesHasOneUser  = [SELECT Territory2Id, COUNT(UserId) FROM UserTerritory2Association WHERE UserId != null GROUP BY Territory2Id HAVING COUNT(UserId) >= 1];
        Set<Id> territoriesNotAcceptInsertion = new Set<Id>();
        for(AggregateResult territory : territoriesHasOneUser){
            territoriesNotAcceptInsertion.add((Id)territory.get('Territory2Id'));
        }

        for(UserTerritory2Association userTerritory2Association : newRecords){
            if(territoriesNotAcceptInsertion.contains(userTerritory2Association.Territory2Id)){
                userTerritory2Association.addError('Não é possível inserir mais de 1 usuário no mesmo território');
            }
        }
    }
}