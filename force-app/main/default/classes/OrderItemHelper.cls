public without sharing class OrderItemHelper {
    
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

    public static void updateOrderItem (List<OrderItem> orderItemList, Map<Id, OrderItem> oldRequest){
        List<String> ordList = new List<String>();
        List<OrderItem> orderItemListM = new List<OrderItem>();

        for(OrderItem ordIt : orderItemList){
            
            OrderItem oldOrdIt = new OrderItem();
            oldOrdIt = oldRequest.get(ordIt.id);
            
            if(ordIt.Order.IsOrderMother__c == true && ordIt.Order.OrderReference__c != null && oldOrdIt.ReasonRefuse__c == null && ordIt.ReasonRefuse__c != null){
                ordList.add(ordIt.Order.OrderReference__c);
                //ordIt.Quantity =  ordIt.Quantity - ordIt.AmountUsed__c; 
            }
        }

        List<OrderItem> ordItemList = ([SELECT Id, OrderId, Order.IsOrderMother__c, Product2Id  FROM OrderItem WHERE OrderId =: ordList]);
        Map<String, OrderItem> ordMap = new Map<String, OrderItem>();
        for(OrderItem ordItem : ordItemList){
            string concProductOrder = String.valueOf(ordItem.Product2Id) + String.valueOf(ordItem.OrderId);
            ordMap.put(concProductOrder, ordItem);     
        }
        for(OrderItem ordemItem : orderItemList){
            string concProductOrderRef = String.valueOf(ordemItem.Product2Id) + String.valueOf(ordemItem.Order.OrderReference__c);
            if(ordMap.containsKey(concProductOrderRef)){
                OrderItem ordrItem = ordMap.get(concProductOrderRef);

                if(ordemItem.Product2Id == ordrItem.Product2Id){
                    ordemItem.Quantity =  ordemItem.Quantity - ordemItem.AmountUsed__c; 
                    orderItemListM.add(ordemItem);
                }
            }
            
        }
        OrderHelper.disableTrigger();
        upsert orderItemListM;
        OrderHelper.enableTrigger();
    }
}
