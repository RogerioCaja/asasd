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

    public static void sendApprovalProccess(List<Order> newRecords){

        Set<Id> orderToUpdate = new Set<Id>();
        try
        {
            Map<ID,Schema.RecordTypeInfo> orderMap = Order.sObjectType.getDescribe().getRecordTypeInfosById();
            for(Order order : newRecords){
                if(order.Status != '0'){
                    if(order.MarginCommittee__c || order.Manager_BranchOffice__c || order.Gerente_Regional__c || order.Director__c || orderMap.get(newMap.get(id).RecordTypeId).getName() == 'VendaBarter')
                    {
                        try{
                            Approval.ProcessSubmitRequest administrationRequest = new Approval.ProcessSubmitRequest();
                            administrationRequest.setProcessDefinitionNameOrId('OrderApproval4');
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
                List<Order> orderList = [SELECT Id, StatusSF__c FROM Order WHERE Id IN: orderToUpdate];
                List<Order> orderToUpdateList = new List<Order>();
                for(Order order : orderList){
                    order.StatusSF__c = 'Aprovado';
                    orderToUpdateList.add(order);
                }
                update orderToUpdateList;
            }
        }
        catch(Exception e){
            System.debug(e);
        }
            
    }

    public static void sendApprovalProccess(Map<Id, Order> oldMap, Map<Id, Order> newMap){

        Set<Id> orderIds = new Set<Id>();
        Set<Id> orderToUpdate = new Set<Id>();

        for(Order order : newMap){
            orderIds.add(order.Id);
        }
        try
        {
            Map<ID,Schema.RecordTypeInfo> orderMap = Order.sObjectType.getDescribe().getRecordTypeInfosById();
            for(Id id : orderIds){
                if(oldMap.get(id).Status == '0' && newMap.get(id).Status == '001'){
                    if(newMap.get(id).MarginCommittee__c || newMap.get(id).Manager_BranchOffice__c || newMap.get(id).Gerente_Regional__c || newMap.get(id).Director__c || orderMap.get(newMap.get(id).RecordTypeId).getName() == 'VendaBarter')
                    {
                        try{
                            Approval.ProcessSubmitRequest administrationRequest = new Approval.ProcessSubmitRequest();
                            administrationRequest.setProcessDefinitionNameOrId('OrderApproval4');
                            administrationRequest.setObjectId(order.Id);
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
                List<Order> orderList = [SELECT Id, StatusSF__c FROM Order WHERE Id IN: orderToUpdate];
                List<Order> orderToUpdateList = new List<Order>();
                for(Order order : orderList){
                    order.StatusSF__c = 'Aprovado';
                    orderToUpdateList.add(order);
                }
                update orderToUpdateList;
            }
        }
        catch(Exception e){
            System.debug(e);
        }
            
    }
}
