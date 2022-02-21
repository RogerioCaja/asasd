public with sharing class OrderScreenController {
    @AuraEnabled
    public static String getOrder(String recordId) {
        HeaderSerialize order;
        AccountSerialize account;
        List<ProductSerialize> ordItemList;

        order = getOrderData(recordId);
        ordItemList = getOrderItemData(order.Id);
        account = getOrderAccountData(order.AccountId);

        return JSON.serialize(new OrderSerialize(order, ordItemList, account));
    }

    @AuraEnabled
    public static OrderSerialize getAccount(String recordId) {
        OrderSerialize order;
        AccountSerialize account;
        List<ProductSerialize> ordItemList;
        
        account = getOrderAccountData(recordId);

        return new OrderSerialize(account);
    }

    public static HeaderSerialize getOrderData(Id orderId){
        Order order = [SELECT Id, AccountId, Type, ShippingAccount__c, Pricebook2Id, PaymentDate__c, CustomerOrderNumber__c,
        Crop__c, Culture__c, PaymentForm__c, StatusSF__c, SalesOrg__c, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c
        FROM Order 
        WHERE Id = :orderId LIMIT 1];
        return new HeaderSerialize(order);
    }

    public static List<ProductSerialize> getOrderItemData(Id orderId) {
        List<ProductSerialize> prods;
        for(OrderItem item : [SELECT Id, Product2Id FROM OrderItem WHERE OrderId =: orderId]){
            prods.add(new ProductSerialize(item));
        }
        return prods;
    }

    public static AccountSerialize getOrderAccountData(Id accountId) {
        Account account = [SELECT Id, Name, CNPJ__c, CPF__c, Phone FROM Account WHERE Id =: accountId LIMIT 1];
        return new AccountSerialize(account);
    }

    @AuraEnabled
    public static String saveOrder(Id orderId, String data) {
        try{
            Order order;
            String msg;
            Boolean newOrder = true;
            OrderDeserialize orderData = (OrderDeserialize) JSON.deserialize(data, OrderDeserialize.class);

            if(orderId != NULL){
                newOrder = false;
                order = [SELECT Id, AccountId, Type, ShippingAccount__c, Pricebook2Id, PaymentDate__c, CustomerOrderNumber__c,
                Crop__c, Culture__c, PaymentForm__c, StatusSF__c, SalesOrg__c, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c
                FROM Order WHERE Id =: orderId LIMIT 1];
            }else{
                order = new Order();
            }
            System.debug(order);

            Account acc = [SELECT Id FROM Account WHERE Id =: orderData.accountData.Id LIMIT 1];
    
            order.AccountId = acc.Id;
            order.Status = 'Draft';
            order.PriceBook2Id = orderData.headerData.lista_precos;
            order.Type = orderData.headerData.tipo_venda ;
            order.ShippingAccount__c = orderData.headerData.cliente_entrega ;
            order.PaymentDate__c = Date.valueOf(orderData.headerData.data_pagamento) ;
            order.CustomerOrderNumber__c = orderData.headerData.numero_pedido_cliente ;
            order.EffectiveDate = Date.today();
            order.Crop__c = orderData.headerData.safra ;
            order.Culture__c = orderData.headerData.cultura ;
            order.PaymentForm__c = orderData.headerData.forma_pagamento ;
            order.SalesOrg__c = orderData.headerData.organizacao_vendas ;
            order.DistributionChannel__c = orderData.headerData.canal_distribuicao ;
            order.ActivitySector__c = orderData.headerData.setor_atividade ;
            order.Currency__c = orderData.headerData.moeda ;
            order.SalesCTV__c = orderData.headerData.ctv_venda ;
            order.StatusSF__c = orderData.headerData.status_pedido;

            Database.UpsertResult insResults = Database.upsert(order, false);
            if(insResults.isSuccess()){
                msg = 'Pedido ' + (newOrder ? 'criado' : 'atualizado') + ' com sucesso';
                return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg));
            }
            String errors = '';
            for (Database.error error: insResults.getErrors()){
                 errors += '\n' + error.getMessage();
            }
            msg = 'Pedido não pôde ser ' + (newOrder ? 'criado' : 'atualizado');
            return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg + errors));
        }catch (Exception ex)
		{
			throw new AuraHandledException('Exception occured:\r\n' + ex.getMessage() + '\r\n' + ex.getStackTraceString() + '\r\n');
		}
    }

    //Classe para deserialização
    public class OrderDeserialize{
        public AccountDeserialize accountData;
        public HeaderDeserialize headerData;
        public List<ProductDeserialize> productData;
    }

    public class AccountDeserialize {
        public String Id;
        public String Name;
    }

    public class HeaderDeserialize {
        public String tipo_venda;
        public String cliente_entrega;
        public String lista_precos;
        public String data_pagamento;
        public String numero_pedido_cliente;
        public String safra;
        public String cultura;
        public String forma_pagamento;
        public String organizacao_vendas;
        public String canal_distribuicao;
        public String setor_atividade;
        public String moeda;
        public String ctv_venda;
        public String status_pedido;
        //public String data_entrega;
        //public String cliente_faturamento;
    }

    public class ProductDeserialize{
        public Id Id;
        public String Name;
    }


    //Classe para serialização
    public class OrderSerialize{
        public HeaderSerialize headerData;
        public List<ProductSerialize> productData;
        public AccountSerialize accountData;

        OrderSerialize(){}       

        OrderSerialize(AccountSerialize account){
            this.accountData = account;
        }  

        OrderSerialize(HeaderSerialize order, List<ProductSerialize> products, AccountSerialize account){
            this.headerData = order;
            this.productData = products;
            this.accountData = account;
        }
    }
    
    public class AccountSerialize {
        public String Id;
        public String Name;
        public String Phone;
        AccountSerialize(){}
        AccountSerialize(Account account){
            this.Id = account.Id;
            this.Name = account.Name;
            this.Phone = account.Phone;
        }
    }
    
    public class HeaderSerialize {
        public String Id;
        public String AccountId;
        public String tipo_venda;
        public String filial;
        public String numero_pedido_cliente;
        public String safra;
        public String cultura;
        public String lista_precos;
        public String condicao_pagamento;
        public String data_pagamento;
        public String data_entrega;
        public String status_pedido;
        public String cliente_faturamento;
        public String cliente_entrega;
        public String organizacao_vendas;
        public String canal_distribuicao;
        public String setor_atividade;
        public String forma_pagamento;
        public String moeda;
        public String ctv_venda;
        //public String data_entrega;
        //public String cliente_faturamento;
        HeaderSerialize(){}
        HeaderSerialize(Order order){
            this.Id = order.Id;
            this.AccountId = order.AccountId;
            this.tipo_venda = order.Type;
            this.cliente_entrega = order.ShippingAccount__c;
            this.lista_precos = order.Pricebook2Id;
            this.data_pagamento = String.valueOf(order.PaymentDate__c);
            this.numero_pedido_cliente = order.CustomerOrderNumber__c;
            this.safra = order.Crop__c;
            this.cultura = order.Culture__c;
            this.forma_pagamento = order.PaymentForm__c;
            this.status_pedido = order.StatusSF__c;
            this.organizacao_vendas = order.SalesOrg__c;
            this.canal_distribuicao = order.DistributionChannel__c;
            this.setor_atividade = order.ActivitySector__c;
            this.moeda = order.Currency__c;
            this.ctv_venda = order.SalesCTV__c;
        }
    }
    
    public class ProductSerialize{
        public Id Id;
        public String lista_precos;
        ProductSerialize(){}
        ProductSerialize(OrderItem product){
            this.Id = product.Id;
            this.lista_precos = product.Product2Id;
        }
    }
}
