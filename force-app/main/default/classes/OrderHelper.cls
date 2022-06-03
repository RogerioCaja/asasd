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

        List<Order> orderToUpdate = new List<Order>();
        for(Order order : newRecords){
            if(order.Status != '0'){
                if(!order.MarginCommittee__c || !order.MarginCommittee__c || !order.Gerente_Regional__c || !order.Director__c)
                    {
                        try{
                            Approval.ProcessSubmitRequest administrationRequest = new Approval.ProcessSubmitRequest();
                            administrationRequest.setProcessDefinitionNameOrId('OrderApproval3');
                            administrationRequest.setObjectId(order.Id);
                            Approval.ProcessResult approvalResult = Approval.process(administrationRequest);
                            System.debug('pedido submetido para aprovação com sucesso: '+ approvalResult.isSuccess());
                        }
                        catch(Exception e){
                            System.debug(e.getMessage());
                        }
                    }
                    else{
                        order.StatusSF__c = 'Aprovado';
                        orderToUpdate.add(order);
                    }
            }
            
        }
        if(orderToUpdate.size() > 0)
            update orderToUpdate;
    }
}
