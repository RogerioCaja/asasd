public with sharing class AccountHelper {
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

    public static void calloutCTVIntegrationUpdateBefore(List<Account> accountList){
        List<String> accountIdList = new List<String>();
        for(Account acc : accountList){
            accountIdList.add(acc.Id);
        }
        List<ObjectTerritory2Association> terrytoryObjectList = new List<ObjectTerritory2Association>([SELECT Id, Territory2Id, ObjectId  FROM ObjectTerritory2Association WHERE ObjectId =: accountIdList]);

        Decimal size = terrytoryObjectList.size();
        for(Account acc : accountList){
            acc.NumberTerritorys__c = size;
        }
    }

    public static void calloutCTVIntegrationUpdateAfter(List<Account> accountList){
        Decimal goToIntregration = 0;
        List<String> accountIdList = new List<String>();
        for(Account acc : accountList){
            accountIdList.add(acc.Id);
        }
        List<ObjectTerritory2Association> terrytoryObjectList = new List<ObjectTerritory2Association>([SELECT Id, Territory2Id, ObjectId  FROM ObjectTerritory2Association WHERE ObjectId =: accountIdList]);

        Decimal size = terrytoryObjectList.size();
        for(Account acc : accountList){
            if(acc.NumberTerritorys__c != size){
                CalloutCTVCarteira.processIntegration();
                break;
            }
        }
    }

    public static void calloutCTVIntegration(List<Account> accountList){
        List<String> accountIdList = new List<String>();
        for(Account acc : accountList){
            accountIdList.add(acc.Id);
        }
        List<ObjectTerritory2Association> terrytoryObject = new List<ObjectTerritory2Association>([SELECT Id, Territory2Id, ObjectId  FROM ObjectTerritory2Association WHERE ObjectId =: accountIdList]);
        if(!terrytoryObject.isEmpty())
            CalloutCTVCarteira.processIntegration();
    }
}
    