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
            if(ordIt.Order.IsOrderMother__c != true && ord.OrderReference__c != null){
                System.debug('Entrou no IF');
                System.debug('OrderReference__c ' + ordIt.Order.OrderReference__c);
                ordList.add(ord.OrderReference__c);
                System.debug('ordList ' + ordList);
                //ordIt.Quantity =  ordIt.Quantity - ordIt.ItemBalance__c; 
            }
        }
        List<AggregateResult> sumQuantityPerOrderItem = [SELECT Order.OrderReference__c, Product2.Id, SUM(Quantity) FROM OrderItem WHERE Order.OrderReference__c IN: ordList AND Order.Status != 'X' AND Order.Status != '0' AND ReasonRefuse__c = null GROUP BY Product2.Id,Order.OrderReference__c];
        Map<String, Decimal> orderItemAmountedUsedPerOrderReference = new Map<String, Decimal>();
        for(AggregateResult aggResult : sumQuantityPerOrderItem){
            orderItemAmountedUsedPerOrderReference.put((String)aggResult.get('Id') + (String)aggResult.get('OrderReference__c'), (Decimal)aggResult.get('expr0') );
        }
        List<OrderItem> ordItemList = ([SELECT Id, OrderId, Order.IsOrderMother__c, Product2Id, ItemBalance__c, Quantity  FROM OrderItem WHERE OrderId =: ordList]);
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
                    orddItem.ItemBalance__c = orderItemAmountedUsedPerOrderReference.containsKey(concProductOrderRef) ? (ordrItem.Quantity - orderItemAmountedUsedPerOrderReference.get(concProductOrderRef)) : ordrItem.Quantity;
                    // orddItem.ItemBalance__c =  ordemItem.Quantity - ordrItem.ItemBalance__c;
                    // if(orddItem.ItemBalance__c < 0){
                    //     orddItem.ItemBalance__c = orddItem.ItemBalance__c * (-1);                            
                    // } 
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
            if(ordItem.Description != null && ordItem.ReasonRefuse__c != null && ordItem.Description.contains('In73gr ins37t x') && order.SalesOrg__c != null && order.SalesOrg__r.SalesOrganizationCode__c == '1700'){
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
        
        
        
        
        // OrderItemHelper.disableTrigger();
        // upsert generalQuotasListUpdate;
        // OrderItemHelper.enableTrigger();
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
                //ordIt.Quantity =  ordIt.Quantity - ordIt.ItemBalance__c; 
            }
        }
        List<OrderItem> ordItemList = ([SELECT Id, OrderId, Order.IsOrderMother__c, Product2Id, ItemBalance__c, Quantity  FROM OrderItem WHERE OrderId =: ordList]);
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
            Decimal calcAmountUsed;
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
                    System.debug('ordemItem.Quantity ' + ordemItem.Quantity);
                    System.debug('ordrItem.ItemBalance__c ' + ordrItem.ItemBalance__c);
                    if(ordrItem.ItemBalance__c != null){
                        calcAmountUsed = ordrItem.ItemBalance__c - ordemItem.Quantity;
                    }
                    else {
                        calcAmountUsed = ordemItem.Quantity;
                    }
                   
                    orddItem.ItemBalance__c =  calcAmountUsed; 
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

    public static void conditionsCalc (List<TemplateDataIntegrationFields.OrderItemINData> request, List<TemplateDataIntegrationFields.ConditionInsert> conditionList) {
        
        Decimal porcentagemZCBA;
        Decimal porcentagemZCBI;
        Decimal valorCorretagem;

        for(TemplateDataIntegrationFields.OrderItemINData orderItemsForConditions : request) {
            
            for(TemplateDataIntegrationFields.ConditionInsert  conditionsAssignment : conditionList){
                conditionsAssignment.KPOSN = conditionsAssignment.KPOSN.replaceFirst('^0+','');
                
                if(conditionsAssignment.KPOSN == orderItemsForConditions.orderItemCode){
                    
                    if(conditionsAssignment.KSCHL == 'ZPR0'){
                        orderItemsForConditions.precoUnitario = (Decimal.valueOf(conditionsAssignment.KBETR) / Decimal.valueOf(conditionsAssignment.KPEIN));
                        orderItemsForConditions.precoPraticado = orderItemsForConditions.precoUnitario;
                        System.debug('precoUnitario' + orderItemsForConditions.precoUnitario);
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZDAC'){ //Antigo ZDAN
                        System.debug('conditionsAssignment.KSCHL' + conditionsAssignment.KSCHL);
                       orderItemsForConditions.porcentagemDescontoFin = Decimal.valueOf(conditionsAssignment.KBETR);
                        System.debug('porcentagemDescontoFin' + orderItemsForConditions.porcentagemDescontoFin);
                        
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZJUC'){ //Antigo ZJUR
                        orderItemsForConditions.porcentagemAcrescFin = Decimal.valueOf(conditionsAssignment.KBETR);
                        System.debug('porcentagemAcrescFin' + orderItemsForConditions.porcentagemAcrescFin);
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZMAR'){
                        orderItemsForConditions.margemComercial = Decimal.valueOf(conditionsAssignment.KBETR);
                        System.debug('orderItemsForConditions.margemComercial ' + orderItemsForConditions.margemComercial);
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZFRE'){
                        orderItemsForConditions.freteItem = Decimal.valueOf(conditionsAssignment.KBETR);
                        System.debug('freteItem ' + orderItemsForConditions.freteItem);
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZROY'){
                        orderItemsForConditions.valorZroy = Decimal.valueOf(conditionsAssignment.KBETR);
                        orderItemsForConditions.valorTotalZroy = Decimal.valueOf(conditionsAssignment.KBETR) * orderItemsForConditions.quantidade;
                        System.debug('valorZroy ' + orderItemsForConditions.valorZroy);
                        System.debug('valorTotalZroy ' + orderItemsForConditions.valorTotalZroy);
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZTRA'){
                        orderItemsForConditions.valorZtra = Decimal.valueOf(conditionsAssignment.KBETR);
                        orderItemsForConditions.valorTotalZtra = Decimal.valueOf(conditionsAssignment.KBETR) * orderItemsForConditions.quantidade;
                        System.debug('valorZtra ' + orderItemsForConditions.valorZtra);
                        System.debug('valorTotalZtra ' + orderItemsForConditions.valorTotalZtra);
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZCP0'){
                        Decimal custoPraticado = Decimal.valueOf(conditionsAssignment.KBETR) / orderItemsForConditions.quantidade;
                        orderItemsForConditions.custoPreco = custoPraticado;
                        System.debug('custoPreco ' + orderItemsForConditions.custoPreco);
                    }

                    if(conditionsAssignment.KSCHL == 'ZCOR'){
                        valorCorretagem = Decimal.valueOf(conditionsAssignment.KBETR);
                        
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZCBI'){
                        if(Decimal.valueOf(conditionsAssignment.KBETR) > 0){
                            porcentagemZCBI = Decimal.valueOf(conditionsAssignment.KBETR);
                        }
                        else {
                            porcentagemZCBI = Decimal.valueOf(conditionsAssignment.KBETR) * (-1);
                        }
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZCBA'){
                        if(Decimal.valueOf(conditionsAssignment.KBETR) > 0){
                            porcentagemZCBA = Decimal.valueOf(conditionsAssignment.KBETR); 
                        }
                        else {
                            porcentagemZCBA = Decimal.valueOf(conditionsAssignment.KBETR) * (-1);
                        }
                    }
                    
                    if(conditionsAssignment.KSCHL == 'ZDEC'){
                        orderItemsForConditions.porcentagemAcrescComercial = 0;
                        orderItemsForConditions.porcentagemDesconto = 0;
                        System.debug('KBETR ' + Decimal.valueOf(conditionsAssignment.KBETR));
                        if(Decimal.valueOf(conditionsAssignment.KBETR) > 0){
                            orderItemsForConditions.porcentagemAcrescComercial = Decimal.valueOf(conditionsAssignment.KBETR);
                            System.debug('porcentagemAcrescComercial ' + orderItemsForConditions.porcentagemAcrescComercial);
                        }
                        else {
                            orderItemsForConditions.porcentagemDesconto = Decimal.valueOf(conditionsAssignment.KBETR);
                            orderItemsForConditions.porcentagemDesconto *= (-1);
                            System.debug('porcentagemDesconto ' + orderItemsForConditions.porcentagemDesconto);
                        }
                    }
                    
                }
            }
			

			Decimal valorDescontoFinanceiro = 0;
			Decimal valorAcrescimoFinanceiro = 0;
			Decimal valorDescontoComercial = 0;
            Decimal valorAcrescimoComercial = 0;
            Decimal valorDescontoComboZCBI = 0;
            Decimal valorDescontoComboZCBA = 0;
            Decimal valorFinal = orderItemsForConditions.precoUnitario * orderItemsForConditions.quantidade;
            orderItemsForConditions.valorTotal = valorFinal;
            
            if(orderItemsForConditions.porcentagemDescontoFin > 0){
                valorDescontoFinanceiro = valorFinal * (orderItemsForConditions.porcentagemDescontoFin / 100);
                orderItemsForConditions.valorDescontoFin = valorDescontoFinanceiro;
                valorFinal = valorFinal - valorDescontoFinanceiro; //Bateu
                orderItemsForConditions.precoPraticado = (valorFinal) / orderItemsForConditions.quantidade;
                orderItemsForConditions.valorTotal = valorFinal;
                System.debug('valorFinal ' + valorFinal);
                System.debug('valorDescontoFinanceiro ' + valorDescontoFinanceiro);
            }
            
            if (orderItemsForConditions.porcentagemAcrescFin > 0){
                valorAcrescimoFinanceiro = valorFinal * (orderItemsForConditions.porcentagemAcrescFin / 100);
                orderItemsForConditions.valorAcrescFin = valorAcrescimoFinanceiro;
                valorFinal = valorFinal + valorAcrescimoFinanceiro;
                orderItemsForConditions.precoPraticado = (valorFinal) / orderItemsForConditions.quantidade;
                orderItemsForConditions.valorTotal = valorFinal;
                System.debug('valorFinal ' + valorFinal);
                System.debug('valorAcrescimoFinanceiro ' + valorAcrescimoFinanceiro);
            }
            
            if(porcentagemZCBI > 0){
                valorDescontoComboZCBI = valorFinal * (porcentagemZCBI / 100);
                orderItemsForConditions.valorZCBI = valorDescontoComboZCBI;
                valorFinal = valorFinal - valorDescontoComboZCBI;
                orderItemsForConditions.precoPraticado = (valorFinal) / orderItemsForConditions.quantidade;
                orderItemsForConditions.valorTotal = valorFinal;
                System.debug('ZCBI ' + orderItemsForConditions.valorZCBI);
            }
            
            if(porcentagemZCBA > 0){
                valorDescontoComboZCBA = valorFinal * (porcentagemZCBA / 100);
                orderItemsForConditions.valorZCBA = valorDescontoComboZCBA;
                valorFinal = valorFinal - valorDescontoComboZCBA;
                orderItemsForConditions.precoPraticado = (valorFinal) / orderItemsForConditions.quantidade;
                orderItemsForConditions.valorTotal = valorFinal;
                System.debug('valorZCBA ' + orderItemsForConditions.valorZCBA);
            }
            
            if (orderItemsForConditions.porcentagemDesconto != 0 && orderItemsForConditions.porcentagemDesconto != null){
                valorDescontoComercial = valorFinal  * (orderItemsForConditions.porcentagemDesconto / 100);
                System.debug('porcentagemDesconto ' + (orderItemsForConditions.porcentagemDesconto / 100));
                System.debug('valorDescontoComercial ' + valorDescontoComercial);
                orderItemsForConditions.precoPraticado = (valorFinal - valorDescontoComercial) / orderItemsForConditions.quantidade;
                orderItemsForConditions.valorTotal = (valorFinal - valorDescontoComercial);
                System.debug('valorFinalFinal  ' + orderItemsForConditions.valorTotal);
                orderItemsForConditions.descontoValor = valorDescontoComercial;
            }
            
            if(orderItemsForConditions.porcentagemAcrescComercial != 0 && orderItemsForConditions.porcentagemAcrescComercial != null){
               valorAcrescimoComercial = valorFinal * (orderItemsForConditions.porcentagemAcrescComercial / 100);
               System.debug('valorAcrescimoComercial ' + valorAcrescimoComercial);
               orderItemsForConditions.precoPraticado = (valorFinal + valorAcrescimoComercial) / orderItemsForConditions.quantidade;
               orderItemsForConditions.valorTotal = (valorFinal + valorAcrescimoComercial);
               orderItemsForConditions.valorAcrescComercial = valorAcrescimoComercial;        
            }
            
            System.debug('Valor Final   ' + valorFinal);
            System.debug('valorAcrescComercial  ' + orderItemsForConditions.valorAcrescComercial);
            System.debug('Desconto Valor ' + orderItemsForConditions.descontoValor);
            System.debug('Preço Praticado ' + orderItemsForConditions.precoPraticado);
            if(valorCorretagem != 0 && valorCorretagem != null){
                orderItemsForConditions.valorTotal += valorCorretagem;
            }
            porcentagemZCBA = 0;
            porcentagemZCBI = 0;
            valorCorretagem = 0;
        }
    }
    
}