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
                    if(orddItem.AmountUsed__c < 0){
                        orddItem.AmountUsed__c = orddItem.AmountUsed__c * (-1);                            
                    } 
                    orderItemListM.add(orddItem);
                    
                }
            }
            
        }
        OrderItemHelper.disableTrigger();
        update orderItemListM;
        OrderItemHelper.enableTrigger();
    }

    public static void updateQuotes(List<OrderItem> orderItemList){
        Set<Id> generalQuotasId = new Set<Id>();
        Set<Id> individualQuotasId = new Set<Id>();
        Set<Id> orderId = new Set<Id>();

        for(OrderItem ordItemForOrder : orderItemList){
            orderId.add(ordItemForOrder.OrderId);
        }
        Map<Id, Order> orderList = new Map<Id, Order>([SELECT id, SalesOrg__c, SalesOrg__r.SalesOrganizationCode__c FROM Order WHERE Id =: orderId]);
    

        for(OrderItem ordItem : orderItemList){
            Order order = orderList.get(ordItem.OrderId);

            if(ordItem.Description != null && ordItem.ReasonRefuse__c != null && ordItem.Description.contains('In73gr ins37t x') && order.SalesOrg__c != null && order.SalesOrg__r.SalesOrganizationCode__c == '1300'){
                individualQuotasId.add(ordItem.IndividualQuotas__c); 
            } 
        }

        
        List<IndividualQuotas__c> individualQuotasList = new List<IndividualQuotas__c>([SELECT id, Quantity__c, Balance__c, Consumed__c, GeneralQuotas__c FROM IndividualQuotas__c WHERE id  =: individualQuotasId]);
        
        for(IndividualQuotas__c indQuotas : individualQuotasList){
            generalQuotasId.add(indQuotas.GeneralQuotas__c); 
        }
        
        List<GeneralQuotas__c> generalQuotasList = new List<GeneralQuotas__c>([SELECT id, Quantity__c,Consumed__c,Balance__c FROM GeneralQuotas__c WHERE Id =: generalQuotasId]);
      
        List<IndividualQuotas__c> individualQuotasListUpdate = new List<IndividualQuotas__c>();
        
        for(IndividualQuotas__c indQuotas : individualQuotasList){
            indQuotas.Balance__c = indQuotas.Quantity__c; 
            
            indQuotas.Consumed__c = 0;
          
            
            IndividualQuotas__c individualQuotas = new IndividualQuotas__c();
          
            individualQuotasListUpdate.add(indQuotas);
        }
        
        OrderItemHelper.disableTrigger();
        upsert individualQuotasListUpdate;
        OrderItemHelper.enableTrigger();
        
        List<IndividualQuotas__c> sumIndividualQuotasList = new List<IndividualQuotas__c>([SELECT id, Quantity__c, Balance__c, Consumed__c, GeneralQuotas__c FROM IndividualQuotas__c WHERE  GeneralQuotas__c =: generalQuotasId]);

        Map<Id, IndividualQuotas__c> individualQuotasMap = new Map<Id, IndividualQuotas__c>();

        Map<Id, Decimal> sumIndividualQuotasMap = new Map<Id, Decimal>();

        

        
        System.debug('sumIndividualQuotasList ' + sumIndividualQuotasList);
        for(IndividualQuotas__c indQuotas : sumIndividualQuotasList){
    
            IndividualQuotas__c individualQuotas = new IndividualQuotas__c();
            if(individualQuotasMap.containsKey(indQuotas.GeneralQuotas__c)){
                individualQuotas = individualQuotasMap.get(indQuotas.GeneralQuotas__c);
                individualQuotas.Consumed__c += indQuotas.Consumed__c;
                
               // individualQuotas.Balance__c += indQuotas.Balance__c;
                individualQuotasMap.put(indQuotas.GeneralQuotas__c, individualQuotas);
            }
            else {
                individualQuotasMap.put(indQuotas.GeneralQuotas__c, indQuotas);
            }
        }

        List<GeneralQuotas__c> generalQuotasListUpdate = new List<GeneralQuotas__c>();
        System.debug('generalQuotasList ' + generalQuotasList);
        for(GeneralQuotas__c generalQuotas: generalQuotasList){
            System.debug('individualQuotasMap ' + individualQuotasMap);
            
                IndividualQuotas__c individualQuotas = individualQuotasMap.get(generalQuotas.Id);
                System.debug('individualQuotas ' + individualQuotas);
            	generalQuotas.Consumed__c = individualQuotas.Consumed__c;
            	generalQuotas.Balance__c = generalQuotas.Quantity__c - individualQuotas.Consumed__c;
            	generalQuotasListUpdate.add(generalQuotas);
               
        }
        
        
        
        
        OrderItemHelper.disableTrigger();
        upsert generalQuotasListUpdate;
        
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