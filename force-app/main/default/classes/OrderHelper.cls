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
            if(order.Status == '0001' && order.StatusSF__c == 'Em digitação') CalloutOrderDatalake.callIntegration(order.Id);
            
            if(order.StatusSF__c == 'Aprovado'){
                calloutsQueue job = new calloutsQueue(order.Id);
                System.enqueueJob(job);
            }
            System.debug('System' + System.URL.getCurrentRequestUrl().GetPath());
            // System.URL.getCurrentRequestUrl().GetPath().contains('/upsertOrderAppdigital/');
            if(order.CodigoSap__c != null && order.StatusSF__c == 'Integrado' && orderMap != null){
                if(System.URL.getCurrentRequestUrl() != null && System.URL.getCurrentRequestUrl().GetPath() != null && System.URL.getCurrentRequestUrl().GetPath().contains('/upsertOrderAppdigital')){
                    String rmCode = orderMap.get(order.Id).ShippingAccount__r.ExternalId__c;
                    String agCode = orderMap.get(order.Id).Account.ExternalId__c;
                    String zcCode = orderMap.get(order.Id).SalesCTV__r.CodigoSap__c;
                    CalloutOrderUpdate.callIntegration(order.Id, rmCode , agCode , zcCode);
                    CalloutOrderDatalake.callIntegration(order.Id);
                }
                
            }  
        }
        Orderhelper.enableTrigger(); 
    }

    public static void calloutOrderToSAPTest(List<Order> newRecords){
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
            if(order.StatusSF__c != 'Integrado'){
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

    public static void sendApprovalProccess(List<Order> newRecords){

        Set<Id> orderToUpdate = new Set<Id>();
        try
        {
            Map<ID,Schema.RecordTypeInfo> orderMap = Order.sObjectType.getDescribe().getRecordTypeInfosById();
            for(Order order : newRecords){
                if(order.Status != '0' && !(order.Description != null ? order.Description.contains('1n73gr4ção N3sc4r4 5F x 4PP') : false)){
                    if(order.MarginCommittee__c || order.Manager_BranchOffice__c || order.Gerente_Regional__c || order.Director__c || orderMap.get(order.RecordTypeId).getName() == 'Venda Barter')
                    {
                        try{
                            Approval.ProcessSubmitRequest administrationRequest = new Approval.ProcessSubmitRequest();
                            administrationRequest.setProcessDefinitionNameOrId('OrderApproval8');
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
                        orderToUpdate.add(order.Id);
                    }
                }
                
            }
            if(orderToUpdate.size() > 0){
                List<Order> orderList = [SELECT Id, StatusSF__c FROM Order WHERE Id IN: orderToUpdate AND StatusSF__c != 'Aprovado'];
                List<Order> orderToUpdateList = new List<Order>();
                for(Order order : orderList){
                    order.StatusSF__c = 'Aprovado';
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
                    if(newMap.get(id).MarginCommittee__c || newMap.get(id).Manager_BranchOffice__c || newMap.get(id).Gerente_Regional__c || newMap.get(id).Director__c || orderMap.get(newMap.get(id).RecordTypeId).getName() == 'Venda Barter')
                    {
                        
                        try{
                            Approval.ProcessSubmitRequest administrationRequest = new Approval.ProcessSubmitRequest();
                            administrationRequest.setProcessDefinitionNameOrId('OrderApproval8');
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
                       orderToUpdate.add(id);
                        
                        
                    }
                }
            }
            if(orderToUpdate.size() > 0){
                List<Order> orderList = [SELECT Id, StatusSF__c, CodigoSAP__c, Description FROM Order WHERE Id IN: orderToUpdate];
                List<Order> orderToUpdateList = new List<Order>();
                for(Order order : orderList){
                    if(order.CodigoSAP__c != null){
                        order.StatusSF__c = 'Integrado';
                    }else{
                        order.StatusSF__c = 'Aprovado';
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
            
            List<Order> orderList = [SELECT Id, OrderNumber, StatusSF__c, CodigoSap__c FROM Order WHERE Id =: orderId];
            calloutOrderToSAPTest(orderList);
            return 'O pedido ' + orderList[0].OrderNumber + ' foi enviado para integração';
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
}