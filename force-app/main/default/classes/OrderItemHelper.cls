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
        List<String> orderList = new List<String>();
        List<OrderItem> orderItemListM = new List<OrderItem>();

        for(OrderItem ord : orderItemList){
            orderList.add(ord.OrderId);
        }
        List<Order> orderIdList = new List<Order>([SELECT Id, OrderReference__c, IsOrderMother__c FROM Order WHERE Id =: orderList]);
        Map<String, Order> ordIdMap = New Map<String, Order>();
        for(Order ordIds : orderIdList){
            ordIdMap.put(ordIds.Id, ordIds);
            System.debug('ordIdMap ' + ordIdMap);
        }
        for(OrderItem ordIt : orderItemList){
            Order ord = ordIdMap.get(ordIt.OrderId);
            
            OrderItem oldOrdIt = new OrderItem();
            oldOrdIt = oldRequest.get(ordIt.id);
            System.debug('OrderReference__c ' + ord);
            System.debug('teste'+ ordIt.Order.IsOrderMother__c);
            if(ordIt.Order.IsOrderMother__c != true && ord.OrderReference__c != null && oldOrdIt.ReasonRefuse__c == null && ordIt.ReasonRefuse__c != null){
                System.debug('Entrou no IF');
                System.debug('OrderReference__c ' + ordIt.Order.OrderReference__c);
                ordList.add(ord.OrderReference__c);
                System.debug('ordList ' + ordList);
                //ordIt.Quantity =  ordIt.Quantity - ordIt.AmountUsed__c; 
            }
        }

        List<OrderItem> ordItemList = ([SELECT Id, OrderId, Order.IsOrderMother__c, Product2Id, AmountUsed__c, Quantity  FROM OrderItem WHERE OrderId =: ordList]);
        Map<String, OrderItem> ordMap = new Map<String, OrderItem>();
        for(OrderItem ordItem : ordItemList){
            string concProductOrder = String.valueOf(ordItem.Product2Id) + String.valueOf(ordItem.OrderId);
            System.debug('concatenação ' + concProductOrder);
            System.debug('ordItem' + ordItem);
            ordMap.put(concProductOrder, ordItem);
            System.debug('ordMap' + ordMap);
            
        }
        for(OrderItem ordemItem : orderItemList){
            Order ord = ordIdMap.get(ordemItem.OrderId);
            
            string concProductOrderRef = String.valueOf(ordemItem.Product2Id) + String.valueOf(ord.OrderReference__c);
            System.debug('ordMap Fora ' + ordMap);
            System.debug('concProductOrderRef ' + concProductOrderRef);
            if(ordMap.containsKey(concProductOrderRef)){
                System.debug('ordMap Dentro' + ordMap);
                OrderItem ordrItem = ordMap.get(concProductOrderRef);
				System.debug('ordrItem ' + ordrItem);
                if(ordemItem.Product2Id == ordrItem.Product2Id){
                    System.debug('orderItemListM ' + orderItemListM);
                    OrderItem orddItem = New OrderItem();
                    orddItem.Id = ordrItem.Id;
                    orddItem.AmountUsed__c =  ordemItem.Quantity - ordrItem.AmountUsed__c; 
                    orderItemListM.add(orddItem);
                    
                }
            }
            
        }
        OrderItemHelper.disableTrigger();
        update orderItemListM;
        OrderItemHelper.enableTrigger();
    }

    public static void insertOrderItem (List<OrderItem> orderItemList){
        List<String> ordList = new List<String>();
        List<String> orderList = new List<String>();
        List<OrderItem> orderItemListM = new List<OrderItem>();
        
        for(OrderItem ord : orderItemList){
            orderList.add(ord.OrderId);
        }
        List<Order> orderIdList = new List<Order>([SELECT Id, OrderReference__c, IsOrderMother__c FROM Order WHERE Id =: orderList]);
        Map<String, Order> ordIdMap = New Map<String, Order>();
        for(Order ordIds : orderIdList){
            ordIdMap.put(ordIds.Id, ordIds);
            System.debug('ordIdMap ' + ordIdMap);
        }
        for(OrderItem ordIt : orderItemList){
            Order ord = ordIdMap.get(ordIt.OrderId);
            
            System.debug('OrderReference__c ' + ord);
            System.debug('teste'+ ordIt.Order.IsOrderMother__c);                     
            if(ordIt.Description !=null && ordIt.Order.IsOrderMother__c != true && ord.OrderReference__c != null && ordIt.Description.Contains('In73gr ins37t x')){
                System.debug('Entrou no IF');
                System.debug('OrderReference__c ' + ordIt.Order.OrderReference__c);
                ordList.add(ord.OrderReference__c);
                System.debug('ordList ' + ordList);
                //ordIt.Quantity =  ordIt.Quantity - ordIt.AmountUsed__c; 
            }
        }

        List<OrderItem> ordItemList = ([SELECT Id, OrderId, Order.IsOrderMother__c, Product2Id, AmountUsed__c, Quantity  FROM OrderItem WHERE OrderId =: ordList]);
        Map<String, OrderItem> ordMap = new Map<String, OrderItem>();
        for(OrderItem ordItem : ordItemList){
            string concProductOrder = String.valueOf(ordItem.Product2Id) + String.valueOf(ordItem.OrderId);
            System.debug('concatenação ' + concProductOrder);
            System.debug('ordItem' + ordItem);
            ordMap.put(concProductOrder, ordItem);
            System.debug('ordMap' + ordMap);
            
        }
        for(OrderItem ordemItem : orderItemList){
            Order ord = ordIdMap.get(ordemItem.OrderId);
            
            string concProductOrderRef = String.valueOf(ordemItem.Product2Id) + String.valueOf(ord.OrderReference__c);
            System.debug('ordMap Fora ' + ordMap);
            System.debug('concProductOrderRef ' + concProductOrderRef);
            if(ordMap.containsKey(concProductOrderRef)){
                System.debug('ordMap Dentro' + ordMap);
                OrderItem ordrItem = ordMap.get(concProductOrderRef);
                System.debug('ordrItem ' + ordrItem);
                if(ordemItem.Product2Id == ordrItem.Product2Id){
                    System.debug('orderItemListM ' + orderItemListM);
                    OrderItem orddItem = New OrderItem();
                    orddItem.Id = ordrItem.Id;
                    orddItem.AmountUsed__c =  ordemItem.Quantity + ordrItem.AmountUsed__c; 
                    orderItemListM.add(orddItem);
                }
            }
        }
        
        OrderItemHelper.disableTrigger();
        upsert orderItemListM;
		OrderItemHelper.enableTrigger();
    }

    public static void cleanDescriptionOrderItem (List<OrderItem> orderItemList){
        List<OrderItem> cleanOrdItemDesc = new List<OrderItem>();
        
        for(OrderItem ordItemClean : orderItemList){
            OrderItem ordItemCl = new OrderItem();
            ordItemCl.Id = ordItemClean.Id;
            if(ordItemClean.Description != null && ordItemClean.Description.contains('In73gr ins37t x')){
                ordItemCl.Description = ordItemClean.Description.replace('In73gr ins37t x', '');
            }
            
            
            cleanOrdItemDesc.add(ordItemCl);
        }
        OrderItemHelper.disableTrigger();
        update cleanOrdItemDesc; 
        OrderItemHelper.enableTrigger();
    }
    
}