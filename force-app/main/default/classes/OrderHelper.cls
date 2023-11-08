public without sharing class OrderHelper {
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

    public class calloutsQueueBarter implements Queueable, Database.AllowsCallouts{
        private Id orderId;

        public calloutsQueueBarter(Id orderIdParameter){
            this.orderId = orderIdParameter;
        }

        public void execute(QueueableContext context) {
            CalloutOrder.processIntegration(orderId);
            if(!Test.isRunningTest()){
                System.enqueueJob(new calloutsQueue(orderId));
            }
        }
    }

    public class calloutsQueue implements Queueable, Database.AllowsCallouts{ 
        private Id orderId;

        public calloutsQueue(Id orderIdParameter){
            this.orderId = orderIdParameter;
        }

        public void execute(QueueableContext context) {
            CalloutOrder.processIntegration(orderId);
            if(!Test.isRunningTest()){
                System.enqueueJob(new calloutDatalakeQueue(orderId));
            }
        }
    } 

    public class calloutDatalakeQueue implements Queueable { 
        private Id orderId;

        public calloutDatalakeQueue(Id orderIdParameter){
            this.orderId = orderIdParameter;
        }

        public void execute(QueueableContext context) {
            CalloutOrderDatalake.callIntegration(orderId);
        }
    } 
    
    public static void calloutOrderToSAP(List<Order> newRecords){
        Set<Id> orderIds = new Set<Id>();
        String orderTypeName = '';
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
            orderTypeName = Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosById().get(order.RecordTypeId).getName();
            if(order.StatusSF__c == 'Aprovado' && order.Status != 'X'){
                if(orderTypeName == 'Venda Barter' && order.OrderReference__c == null){
                    System.enqueueJob(new calloutsQueueBarter(order.Id));
                }else{
                    System.enqueueJob(new calloutsQueue(order.Id));
                }
                
            }
            else{
                if(!Test.isRunningTest()) CalloutOrderDatalake.callIntegration(order.Id);
            }

            if(order.CodigoSap__c != null && order.StatusSF__c == 'Integrado' && orderMap != null){
                if(System.URL.getCurrentRequestUrl() != null && System.URL.getCurrentRequestUrl().GetPath() != null && System.URL.getCurrentRequestUrl().GetPath().contains('/upsertOrderAppdigital')){
                    String rmCode = orderMap.get(order.Id).ShippingAccount__r.ExternalId__c;
                    String agCode = orderMap.get(order.Id).Account.ExternalId__c;
                    String zcCode = orderMap.get(order.Id).SalesCTV__r.CodigoSap__c;
                    CalloutOrderUpdate.callIntegration(order.Id, rmCode , agCode , zcCode);
                }
                
            }  
        }
        Orderhelper.enableTrigger(); 
    }

    public static void calloutOrderToSAPTest(List<Order> newRecords){
        Set<Id> orderIds = new Set<Id>();
        String orderTypeName = '';
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
            orderTypeName = Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosById().get(order.RecordTypeId).getName();
            if(order.StatusSF__c == 'Aprovado' && order.Status != 'X'){
                if(orderTypeName == 'Venda Barter' && order.OrderReference__c == null){
                    System.enqueueJob(new calloutsQueueBarter(order.Id));
                }else{
                    System.enqueueJob(new calloutsQueue(order.Id));
                }
                
            }
            else{
                if(!Test.isRunningTest()) CalloutOrderDatalake.callIntegration(order.Id);
            }

            if(order.CodigoSap__c != null && order.StatusSF__c == 'Integrado' && orderMap != null){
                if(System.URL.getCurrentRequestUrl() != null && System.URL.getCurrentRequestUrl().GetPath() != null && System.URL.getCurrentRequestUrl().GetPath().contains('/upsertOrderAppdigital')){
                    String rmCode = orderMap.get(order.Id).ShippingAccount__r.ExternalId__c;
                    String agCode = orderMap.get(order.Id).Account.ExternalId__c;
                    String zcCode = orderMap.get(order.Id).SalesCTV__r.CodigoSap__c;
                    CalloutOrderUpdate.callIntegration(order.Id, rmCode , agCode , zcCode);
                }
                
            }  
        }
        Orderhelper.enableTrigger(); 
    }

    public static void checkOrderStatus(List<Order> newRecords, Map<Id, Order> oldMap) {
        Set<Id> salesOrgsIds = new Set<Id>();
        for (Order order : newRecords) {
            salesOrgsIds.add(order.SalesOrg__c);
        }

        Map<Id, String> salesCodeById = new Map<Id, String>();
        for (SalesOrg__c salesOrg : [
            SELECT Id,
                   SalesOrganizationCode__c
              FROM SalesOrg__c
             WHERE Id IN: salesOrgsIds
        ]) {
            System.debug('salesOrg.SalesOrganizationCode__c: ' + salesOrg.SalesOrganizationCode__c);
            salesCodeById.put(salesOrg.Id, salesOrg.SalesOrganizationCode__c);
        }

        Set<String> seedsCodes = new Set<String>();
        for (SalesOrgSeeds__c seed : [
            SELECT Id,
                   SeedCode__c
              FROM SalesOrgSeeds__c
             WHERE SeedCode__c IN: salesCodeById.values()
        ]) {
            System.debug('seed.SeedCode__c: ' + seed.SeedCode__c);
            seedsCodes.add(seed.SeedCode__c);
        }

        Set<Id> ordersToRemoveQuotas = new Set<Id>();
        for (Order order : newRecords) {
            String salesCodeOfOrder = salesCodeById.get(order.SalesOrg__c);
            System.debug('salesCodeOfOrder: ' + salesCodeOfOrder);
            if (seedsCodes.contains(salesCodeOfOrder)) {
                Order oldValues = oldMap.get(order.Id);
                System.debug('oldValues.Status: ' + oldValues.Status);
                System.debug('order.Status: ' + order.Status);
                if (oldValues.Status != 'X' && oldValues.Status != '0' && order.Status == 'X' && order.OrderType__c != 'Pedido Filho') {
                    ordersToRemoveQuotas.add(order.Id);
                }
            }
        }

        if (ordersToRemoveQuotas.size() > 0) {
            Map<Id, Decimal> quantitiesToRemove = new Map<Id, Decimal>();
            for (OrderItem item : [
                SELECT Id,
                       Quantity,
                       IndividualQuotas__c
                  FROM OrderItem
                 WHERE OrderId IN: ordersToRemoveQuotas
            ]) {
                if (!quantitiesToRemove.containsKey(item.IndividualQuotas__c)) {
                    quantitiesToRemove.put(item.IndividualQuotas__c, item.Quantity);
                } else {
                    Decimal quantity = quantitiesToRemove.get(item.IndividualQuotas__c);
                    quantity += item.Quantity;
                    quantitiesToRemove.put(item.IndividualQuotas__c, quantity);
                }
            }
            System.debug('quantitiesToRemove: ' + quantitiesToRemove);

            List<IndividualQuotas__c> individualsQuotasToUpdate = new List<IndividualQuotas__c>();
            for (IndividualQuotas__c individualQuota : [
                SELECT Id,
                       Balance__c,
                       Consumed__c
                  FROM IndividualQuotas__c
                 WHERE Id IN: quantitiesToRemove.keySet()
            ]) {
                Decimal quatityToRemove = quantitiesToRemove.get(individualQuota.Id);
                System.debug('quatityToRemove: ' + quatityToRemove);
                System.debug('individualQuota: ' + individualQuota);
                individualQuota.Balance__c = individualQuota.Balance__c + quatityToRemove;
                individualQuota.Consumed__c = individualQuota.Consumed__c - quatityToRemove;
                individualsQuotasToUpdate.add(individualQuota);
                System.debug('individualQuota: ' + individualQuota);
            }
            update individualsQuotasToUpdate;
        }
    }

    public static void sendApprovalProccess(List<Order> newRecords){

        Set<Id> orderToUpdate = new Set<Id>();
        try
        {
            Map<ID,Schema.RecordTypeInfo> orderMap = Order.sObjectType.getDescribe().getRecordTypeInfosById();
            for(Order order : newRecords){
                if(order.Status != '0' && !(order.Description != null ? order.Description.contains('1n73gr4ção N3sc4r4 5F x 4PP') : false)){
                    if((order.MarginCommittee__c || order.Manager_BranchOffice__c || order.Gerente_Regional__c || order.Director__c || (orderMap.get(order.RecordTypeId).getName() == 'Venda Barter' && order.OrderReference__c == null)) && orderMap.get(order.RecordTypeId).getName() != 'Venda de Serviço')
                    {
                        try{
                            Approval.ProcessSubmitRequest administrationRequest = new Approval.ProcessSubmitRequest();
                            administrationRequest.setProcessDefinitionNameOrId('OrderApproval10');
                            administrationRequest.setComments(order.ApprovalJustification__c);
                            administrationRequest.setObjectId(order.Id);
                            Approval.ProcessResult approvalResult = Approval.process(administrationRequest);
                            System.debug('pedido submetido para aprovação com sucesso: '+ approvalResult.isSuccess());
                        }
                        catch(Exception e){
                            System.debug(e.getMessage());
                        }
                    }
                    else{
                        if(orderMap.get(order.RecordTypeId).getName() == 'Venda de Serviço' && order.Higher_Discount__c > 5){
                            Approval.ProcessSubmitRequest administrationRequest = new Approval.ProcessSubmitRequest();
                            administrationRequest.setProcessDefinitionNameOrId('OrderApproval_ServiceSale');
                            administrationRequest.setComments(order.ApprovalJustification__c);
                            administrationRequest.setObjectId(order.Id);
                            Approval.ProcessResult approvalResult = Approval.process(administrationRequest);
                            System.debug('pedido submetido para aprovação com sucesso: '+ approvalResult.isSuccess());
                        }else{
                            orderToUpdate.add(order.Id);
                        }
                    }

                    
                }
                
            }
            if(orderToUpdate.size() > 0){
                List<Order> orderList = [SELECT Id, StatusSF__c, IsDisableSendIntegration__c FROM Order WHERE Id IN: orderToUpdate AND StatusSF__c != 'Aprovado'];
                List<Order> orderToUpdateList = new List<Order>();
                for(Order order : orderList){
                    order.StatusSF__c = 'Aprovado';
                    order.IsDisableSendIntegration__c = true;
                    orderToUpdateList.add(order);
                }
                //OrderHelper.disableTrigger();
                update orderToUpdateList;
                //OrderHelper.enableTrigger();
            }
        }
        catch(Exception e){
            System.debug(e);
        }
            
    }

    public static void sendApprovalProccess(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        Set<Id> orderIds = new Set<Id>();
        Set<Id> orderToUpdate = new Set<Id>();
        Set<Id> orderToUpdateByIntegration = new Set<Id>();

        for(Id order : newMap.keySet()){
            orderIds.add(order);
        }
        try
        {
            Map<ID,Schema.RecordTypeInfo> orderMap = Order.sObjectType.getDescribe().getRecordTypeInfosById();
            for(Id id : orderIds){
                if(newMap.get(id).Description != null){
                    if(newMap.get(id).Description.contains('1n73gr4ção N3sc4r4 5F x 4PP')){
                        orderToUpdateByIntegration.add(id);
                    }
                }
                if((oldMap.get(id).Status == '0' && newMap.get(id).Status == '001') || ( (newMap.get(id).Description != null ? newMap.get(id).Description.contains('1n73gr4ção N3sc4r4 5F x 4PP') : false) && newMap.get(id).Status == '001')){
                    if((newMap.get(id).MarginCommittee__c || newMap.get(id).Manager_BranchOffice__c || newMap.get(id).Gerente_Regional__c || newMap.get(id).Director__c || (orderMap.get(newMap.get(id).RecordTypeId).getName() == 'Venda Barter' && newMap.get(id).OrderReference__c == null)) && orderMap.get(newMap.get(id).RecordTypeId).getName() != 'Venda de Serviço')
                    {
                      
                        try{
                            Approval.ProcessSubmitRequest administrationRequest = new Approval.ProcessSubmitRequest();
                            administrationRequest.setProcessDefinitionNameOrId('OrderApproval10');
                            administrationRequest.setComments(newMap.get(id).ApprovalJustification__c);
                            administrationRequest.setObjectId(id);
                            Approval.ProcessResult approvalResult = Approval.process(administrationRequest);
                            System.debug('pedido submetido para aprovação com sucesso: '+ approvalResult.isSuccess());
                        }
                        catch(Exception e){
                            System.debug(e.getMessage());
                        }
                    }
                    else{
                        if(orderMap.get(newMap.get(id).RecordTypeId).getName() == 'Venda de Serviço' && newMap.get(id).Higher_Discount__c > 5){
                            Approval.ProcessSubmitRequest administrationRequest = new Approval.ProcessSubmitRequest();
                            administrationRequest.setProcessDefinitionNameOrId('OrderApproval_ServiceSale');
                            administrationRequest.setComments(newMap.get(id).ApprovalJustification__c);
                            administrationRequest.setObjectId(id);
                            Approval.ProcessResult approvalResult = Approval.process(administrationRequest);
                            System.debug('pedido submetido para aprovação com sucesso: '+ approvalResult.isSuccess());
                        }else{
                            orderToUpdate.add(id);
                        }
                    }

                    
                }
            }
            if(orderToUpdate.size() > 0){
                List<Order> orderList = [SELECT Id, StatusSF__c, CodigoSAP__c, IsDisableSendIntegration__c, Description FROM Order WHERE Id IN: orderToUpdate];
                List<Order> orderToUpdateList = new List<Order>();
                for(Order order : orderList){
                    if(order.CodigoSAP__c != null){
                        order.StatusSF__c = 'Integrado';
                        order.IsDisableSendIntegration__c = true;
                    }else{
                        order.StatusSF__c = 'Aprovado';
                        order.IsDisableSendIntegration__c = true;
                    }
                    
                    if(order.Description != null){
                        if(order.Description.contains('1n73gr4ção N3sc4r4 5F x 4PP')){
                            order.Description = order.Description.replace('1n73gr4ção N3sc4r4 5F x 4PP', '');
                        }
                    }
                    orderToUpdateList.add(order);
                }
                update orderToUpdateList;
            }
            if(orderToUpdateByIntegration.size() > 0){
                List<Order> orderList = [SELECT Id, StatusSF__c, Description FROM Order WHERE Id IN: orderToUpdateByIntegration];
                List<Order> orderToUpdateList = new List<Order>();
                for(Order order : orderList){
                    
                        
                    order.Description = order.Description.replace('1n73gr4ção N3sc4r4 5F x 4PP', '');
                      
                    orderToUpdateList.add(order);
                }
                OrderHelper.disableTrigger();
                update orderToUpdateList;
                OrderHelper.enableTrigger();
            }

            

        
        }
        catch(Exception e){
            String errorMessage = 'Tipo de Exceção: ' + e.getTypeName();
            errorMessage += '------------------------------';
            errorMessage += 'Mensagem: ' + e.getMessage();
            errorMessage += '------------------------------';
            errorMessage += 'Causa: ' + e.getCause();
            errorMessage += '------------------------------';
            errorMessage += 'Número da Linha: ' + e.getLineNumber();
            errorMessage += '------------------------------';
            errorMessage += 'Stack trace: ' + e.getStackTraceString();
            System.debug(errorMessage);
        } 
            
    }

    public static void verifyStatus(List<Order> newRecords){
        for(Order order : newRecords){
            if(order.StatusSF__c == 'Integrado' && order.CodigoSap__c != null){
                order.addError('Não é permitido alterar um Pedido que esteja integrado com o SAP');
            }
        }
    }

    @AuraEnabled
    public static String sendToIntegrationTest(String orderId){
        try{
            Id profileId = [SELECT Id FROM Profile WHERE Name='System Administrator' OR Name='Administrador do sistema'][0].Id;

            Id userProfileId = [SELECT ProfileId FROM User WHERE Id =: UserInfo.getUserId() ][0].ProfileId;
    
            if(profileId != userProfileId)
                return '';
            
            List<Order> orderList = [SELECT Id, OrderNumber, OrderReference__c, Status, StatusSF__c, CodigoSap__c, IsDisableSendIntegration__c, RecordTypeId FROM Order WHERE Id =: orderId];
            if(!orderList[0].IsDisableSendIntegration__c){
                orderList[0].IsDisableSendIntegration__c = true;

                OrderHelper.disableTrigger();
                Database.update(orderList, Order.Id);
                OrderHelper.enableTrigger();
                
                calloutOrderToSAPTest(orderList);
                return 'O pedido ' + orderList[0].OrderNumber + ' foi enviado para integração';
            }else{
                return 'O pedido já foi enviado ao SAP, aguarde o código SAP do Pedido ou verifique os Logs de Integração';
            }
            
        }
        catch(Exception e){
            return 'Um erro inesperado aconteceu!';
        }
        
    }
    //  Trigger para preenchimento de OrderShare
    public static void creatyShareRecord(List<Order> orderList){//after insert,update
        List<OrderShare> orderShareList = new List<OrderShare>();
        for(Order ord : orderList){
            if(ord.SalesCTV__c != null && ord.SalesCTV__c != ord.OwnerId && ord.SalesCTV__r.IsActive != false){
                OrderShare orderShare = new OrderShare (OrderAccessLevel = 'Edit', RowCause = 'Manual', UserOrGroupId = ord.SalesCTV__c, OrderId = ord.Id);
                orderShareList.add(orderShare);
            }
            
        }
        if (!orderShareList.isEmpty()) {
            OrderHelper.disableTrigger();
            upsert orderShareList;
            OrderHelper.enableTrigger();
        }
    }

    public static void verifyStatusAndCombos(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        Set<Id> orderIdSet = oldMap.keySet();
        Set<Id> orderCanceledIdSet = new Set<Id>();
        Map<Id, Decimal> comboQuantityShouldRefundMap = new Map<Id, Decimal>();
        Map<Id, Decimal> comboQuantityRemainingMap = new Map<Id, Decimal>();
        List<ComboPromotion__c> comboPromotionToUpdateList = new List<ComboPromotion__c>();

        for(Id  id : orderIdSet){
            if(oldMap.get(id).Status != 'X' && newMap.get(id).Status == 'X'){
                orderCanceledIdSet.add(id);
            }
        }

        List<AggregateResult> countComboPerOrderCanceledList = [SELECT ComboPromotion__r.Id, COUNT(ComboPromotion__c) FROM OrderItem WHERE OrderId IN: orderCanceledIdSet GROUP BY ComboPromotion__r.Id];

        for(AggregateResult aggResult : countComboPerOrderCanceledList){
            comboQuantityShouldRefundMap.put((Id)aggResult.get('Id'), (Decimal)aggResult.get('expr0'));
        }

        for(ComboPromotion__c comboPromotion : [SELECT Id, CombosQuantity__c FROM ComboPromotion__c WHERE Id IN: comboQuantityShouldRefundMap.keySet()]){
            comboQuantityRemainingMap.put(comboPromotion.Id, comboPromotion.CombosQuantity__c);
        }

        for(Id id : comboQuantityShouldRefundMap.keySet()){
            if(comboQuantityRemainingMap.containsKey(id) && comboQuantityShouldRefundMap.containsKey(id)){
                comboPromotionToUpdateList.add(
                    new ComboPromotion__c(
                        Id = id,
                        CombosQuantity__c = (comboQuantityRemainingMap.get(id) + comboQuantityShouldRefundMap.get(id))
                    )
                );
            }
        }

        if(comboPromotionToUpdateList.size() != 0){
            Database.update(comboPromotionToUpdateList);
        }
    }
    
    public static void verifyOrderCanceling(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        Set<Id> orderIds = oldMap.keySet();
        Set<Id> orderReferenceWhereItemsHavingRefundIds = new Set<Id>();
        List<OrderItem> orderItemToUpdateList = new List<OrderItem>();

        if(!System.URL.getCurrentRequestUrl().GetPath().contains('/upsertINOrder')){
            for(Id id : orderIds){
                if((oldMap.get(id).Status != 'X' && newMap.get(id).Status == 'X') && 
                (!newMap.get(id).IsOrderMother__c && newMap.get(id).OrderReference__c != null)
                ){
                    orderReferenceWhereItemsHavingRefundIds.add(oldMap.get(id).OrderReference__c);
                }
            }

            List<OrderItem> orderItemOfOrderMotherList = [SELECT Id, Product2.Id, OrderId FROM OrderItem WHERE OrderId IN: orderReferenceWhereItemsHavingRefundIds];
            Map<String, OrderItem> orderItemOfOrderMotherMap = new Map<String, OrderItem>();
            Map<String, Decimal> orderItemAmountedUsedPerOrderReference = new Map<String, Decimal>();
            Set<String> keysToProductOrder = new Set<String>();
            
            for(OrderItem orderItem : orderItemOfOrderMotherList){
                keysToProductOrder.add(String.valueOf(orderItem.Product2.Id) + String.valueOf(orderItem.OrderId));
                orderItemOfOrderMotherMap.put(String.valueOf(orderItem.Product2.Id) +String.valueOf( orderItem.OrderId), orderItem);
            }

            List<AggregateResult> sumQuantityPerOrderItem = [SELECT Order.OrderReference__c, Product2.Id, SUM(Quantity) 
            FROM OrderItem 
            WHERE Order.OrderReference__c IN: orderReferenceWhereItemsHavingRefundIds 
            AND Order.Status != 'X' 
            AND Order.Status != '0' 
            AND ReasonRefuse__c = null 
            GROUP BY Product2.Id,Order.OrderReference__c];
            
            for(AggregateResult aggResult : sumQuantityPerOrderItem){
                orderItemAmountedUsedPerOrderReference.put((String)aggResult.get('Id') + (String)aggResult.get('OrderReference__c'), (Decimal)aggResult.get('expr0') );
            }

            for(String key : keysToProductOrder){
                OrderItem orderItem = new OrderItem();
                orderItem.Id = orderItemOfOrderMotherMap.get(key).Id;
                orderItem.AmountUsed__c = orderItemAmountedUsedPerOrderReference.containsKey(key) ? orderItemAmountedUsedPerOrderReference.get(key) : 0;
                orderItemToUpdateList.add(orderItem);
            }

            OrderItemHelper.disableTrigger();
            update orderItemToUpdateList;
            OrderItemHelper.enableTrigger();
        }

    }

    @Future
    public static void setStageApprovalProcess(Set<Id> records){
        Set<Id> orderIds = new Set<Id>();
        Map<Id, Order> orderMap = new Map<Id, Order>();
        Map<Id, Datetime> mostRecentProcess = new Map<Id, Datetime>();
        Map<String, String> statusMap = new Map<String, String>{'Pending' => 'Pendente', 'Approved'=> 'Aprovado', 'Rejected'=> 'Rejeitado'};
        Id key;
        
        for(Order order : [SELECT Id, StageStatusApproval__c, Status FROM Order WHERE Id IN: records AND Status = '0001']){
            orderMap.put(order.Id, order);
            orderIds.add(order.Id);
        }
       
  
        List<ProcessInstanceNode> nodes = [SELECT Id, NodeStatus, ProcessNodeName, ProcessInstanceId, ProcessInstance.TargetObjectId, CreatedDate 
                                            FROM ProcessInstanceNode WHERE ProcessInstance.TargetObjectId IN: orderIds ORDER BY CreatedDate];

        for(ProcessInstanceNode node : nodes){
            key = node.ProcessInstance.TargetObjectId;
            if(!mostRecentProcess.containsKey(key) || 
                mostRecentProcess.containsKey(key) && mostRecentProcess.get(key) <= node.CreatedDate){

                
                Order order = orderMap.get(key);
                order.StageStatusApproval__c = node.ProcessNodeName + ' / ' + statusMap.get(node.NodeStatus);
                orderMap.put(order.Id, order);

                mostRecentProcess.put(key, node.CreatedDate);
            }  
            
        }

        if(!orderMap.values().isEmpty()){
            OrderHelper.disableTrigger();
            update orderMap.values();
            OrderHelper.enableTrigger();
        }

       
    }

}