public with sharing class OrderScreenController {
    @AuraEnabled
    public static OrderScreenBaseData getOrder(String recordId) {
        Order order;
        Account account;
        List<OrderItem> ordItemList;

        order = getOrderData(recordId);
        ordItemList = getOrderItemData(order.Id);
        account = getOrderAccountData(order.AccountId);

        return new OrderScreenBaseData(order, ordItemList, account);
    }

    @AuraEnabled
    public static OrderScreenBaseData getAccount(String recordId) {
        Order order;
        Account account;
        List<OrderItem> ordItemList;
        
        order = getOrderData(recordId);
        ordItemList = getOrderItemData(order.Id);
        account = getOrderAccountData(order.AccountId);

        return new OrderScreenBaseData(order, ordItemList, account);
    }

    public static Order getOrderData(Id orderId){
        return [SELECT Id, AccountId FROM Order WHERE Id = :orderId LIMIT 1];
    }

    public static List<OrderItem> getOrderItemData(Id orderId) {
        return [SELECT Id, Product2Id FROM OrderItem WHERE OrderId =: orderId];
    }

    public static Account getOrderAccountData(Id accountId) {
        return [SELECT Id, Name, CNPJ__c, CPF__c FROM Account WHERE Id =: accountId LIMIT 1];
    }

    @AuraEnabled
    public static String saveOrder(Id orderId, String data) {
        try{
            Order order;
            OrderMap orderData = (OrderMap) JSON.deserialize(data, OrderMap.class);

            if(orderId != NULL){
                order = [SELECT Id, AccountId FROM Order WHERE Id =: orderId LIMIT 1];
            }else{
                order = new Order();
            }
            System.debug(order);

            Account acc = [SELECT Id FROM Account WHERE Id =: orderData.accountData.get(0).Id LIMIT 1];
    
            order.AccountId = acc.Id;
            order.Status = 'Draft';
            order.PriceBook2Id = orderData.headerData.lista_precos;
            order.EffectiveDate = Date.today();

            Database.SaveResult insResults = Database.insert(order, false);
            if(insResults.isSuccess()){
                return JSON.serializePretty(new AGRO_RemotingResult(false, '200', 'Pedido criado com sucesso!'));
            }
            String errors = '';
            for (Database.error error: insResults.getErrors()){
                 errors += '\n' + error.getMessage();
            }
            return JSON.serializePretty(new AGRO_RemotingResult(false, '200', 'Pedido não pôde ser criado:'+errors));
        }catch (Exception ex)
		{
			throw new AuraHandledException('Exception occured:\r\n' + ex.getMessage() + '\r\n' + ex.getStackTraceString() + '\r\n');
		}
    }

    public class OrderScreenBaseData{
        @AuraEnabled public Order headerData;
        @AuraEnabled public List<OrderItem> productData;
        @AuraEnabled public Account accountData;

        OrderScreenBaseData(Order order, List<OrderItem> items, Account account){
            this.headerData = order;
            this.productData = items;
            this.accountData = account;
        }
    }

    public class OrderMap{
        public List<AccountData> accountData;
        public HeaderData headerData;
    }
    public class AccountData {
        public String Id;
        public String Name;
    }
    public class HeaderData {
        public String tipo_venda;
        public String cliente_entrega;
        public String lista_precos;
        public String data_pagamento;
        public String data_entrega;
        public String cliente_faturamento;
    }
}
