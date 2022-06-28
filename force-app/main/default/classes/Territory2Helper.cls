public with sharing class Territory2Helper {
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

    
    public static void checkUpdateFieldsCTV(List<Territory2> newRecords){
        if(!Test.isRunningTest() ){
            //CalloutCTVCarteira.processIntegration();
        }
    }
}
