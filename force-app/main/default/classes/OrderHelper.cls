public with sharing class OrderHelper {
    public OrderHelper() {

    }

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

    
    public static void calloutOrderToSAP(List<Order> newRecords){
        
        Orderhelper.disableTrigger();
        for(Order order : newRecords){
            if(order.StatusSF__c == 'Aprovado'){
                CalloutOrder.callIntegration(order.Id);
                CalloutOrderDatalake.callIntegration(order.Id);
            }  
        }
        Orderhelper.enableTrigger();
        
    }
}
