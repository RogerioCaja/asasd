public with sharing class UserHelper {
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

    
    public static void calloutCTVIntegration(){
        IntegrationUtils.CalloutCTVResponse response = CalloutCTVCarteira.processIntegration();
        System.debug('Response: '  + response);
    }
}