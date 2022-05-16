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
        Set<Id> orderIds = new Set<Id>();
        for(Order order : newRecords){
            orderIds.add(order.Id);
        }
        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Account.ExternalId__c, ShippingAccount__r.ExternalId__c, SalesCTV__r.CodigoSap__c
            FROM Order
            WHERE Id IN: orderIds
        ]);

        Orderhelper.disableTrigger();
        for(Order order : newRecords){
            if(order.StatusSF__c == 'Aprovado'){
                CalloutOrder.callIntegration(order.Id);
                CalloutOrderDatalake.callIntegration(order.Id);
            }
            if(order.CodigoSap__c != null && order.StatusSF__c == 'Integrado' && orderMap != null){
                
                System.debug('Account.ExternalId__c => ' + orderMap.get(order.Id).Account.ExternalId__c);
                String rmCode = orderMap.get(order.Id).ShippingAccount__r.ExternalId__c;
                String agCode = orderMap.get(order.Id).Account.ExternalId__c;
                String zcCode = orderMap.get(order.Id).SalesCTV__r.CodigoSap__c;
                CalloutOrderUpdate.callIntegration(order.Id, rmCode , agCode , zcCode);
            }  
        }
        Orderhelper.enableTrigger();
        
    }
}
