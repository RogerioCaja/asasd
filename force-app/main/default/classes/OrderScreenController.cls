public without sharing class OrderScreenController {
    @AuraEnabled
    public static String getOrder(String recordId) {
        System.debug('recordId: ' + recordId);
        HeaderSerialize order;
        AccountSerialize account;
        List<ProductSerialize> ordItemList;

        order = getOrderData(recordId);
        ordItemList = getOrderItemData(order.Id);
        account = getOrderAccountData(order.AccountId);

        return JSON.serialize(new OrderSerialize(order, ordItemList, account));
    }

    @AuraEnabled
    public static String getAccount(String recordId) {
        OrderSerialize order;
        AccountSerialize account;
        List<ProductSerialize> ordItemList;
        
        account = getOrderAccountData(recordId);

        return JSON.serialize(new OrderSerialize(account));
    }

    public static HeaderSerialize getOrderData(Id orderId){
        Order order = [SELECT Id, Description, DescriptionBillingSale__c, AccountId, Type, ShippingAccount__c , ShippingAccount__r.Phone,  ShippingAccount__r.Name, 
        ShippingAccount__r.BillingCity, ShippingAccount__r.BillingState ,ShippingAccount__r.CPF__c, ShippingAccount__r.CNPJ__c , Pricebook2Id, Pricebook2.Name, PaymentDate__c,  CustomerOrderNumber__c,
        Crop__c , Crop__r.Name, Culture__c , Culture__r.Name, PaymentForm__c, StatusSF__c, SalesOrg__c, SalesOrg__r.Name, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c, SalesCTV__r.Name,
        PaymentCondition__c, PaymentCondition__r.Name, ShippingDate__c, Incoterms__c
        FROM Order 
        WHERE Id = :orderId LIMIT 1];
        return new HeaderSerialize(order);
    }

    public static List<ProductSerialize> getOrderItemData(Id orderId) {
        List<ProductSerialize> prods = new List<ProductSerialize>();
        Integer counter = 0;
        for(OrderItem item : [
            SELECT Id,
                   Product2Id,
                   Product2.Name,
                   Product2.ExternalId__c,
                   Product2.PrincipleActive__c,
                   Product2.Multiplicity__c,
                   Product2.ProductGroup__c,
                   Product2.ProductGroup__r.Name,
                   InvoicedQuantity__c,
                   OrderId,
                   PricebookEntryId,
                   ServiceDate,
                   Quantity,
                   ListPrice,
                   UnitPrice,
                   FinalTotalValue__c,
                   Dosage__c,
                   toLabel(Status__c),
                   UnitMeasure__c,
                   DiscountPercent__c,
                   DiscountValue__c,
                   CommercialAdditionPercent__c,
                   CommercialAdditionValue__c,
                   FinancialAdditionPercent__c,
                   FinancialAdditionValue__c,
                   FinancialDiscountPercent__c,
                   FinancialDiscountValue__c,
                   ComissionValue__c,
                   CommercialMargin__c
              FROM OrderItem
             WHERE OrderId =: orderId
        ]){
            prods.add(new ProductSerialize(item, counter));
            counter++;
        }
        return prods;
    }

    public static AccountSerialize getOrderAccountData(Id accountId) {
        Account account = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE Id =: accountId LIMIT 1];
        return new AccountSerialize(account);
    }

    @AuraEnabled
    public static string getAccountDataChild(Id accountId){
        try {
            List<AccountSerialize> accountListSerialize = new List<AccountSerialize>();
            Account accountMom = [SELECT Id, Name, CNPJ__c, CPF__c, Phone, BillingCity, BillingState FROM Account WHERE Id =: accountId LIMIT 1];
            List<Account> accountList = [SELECT Id, Name, CNPJ__c, CPF__c, Phone, BillingCity, BillingState FROM Account WHERE ParentId =: accountId];
            accountList.add(accountMom);
            for(Account account : accountList)
                accountListSerialize.add(new AccountSerialize(account));
            return JSON.serialize(new AccountSerialize(accountListSerialize));
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String saveOrder(Id orderId, String data) {
        Savepoint sp = Database.setSavepoint();
        try{
            Order order;
            String msg;
            Boolean newOrder = true;
            OrderDeserialize orderData = (OrderDeserialize) JSON.deserialize(data, OrderDeserialize.class);
            
            if (orderId != NULL) {
                newOrder = false;
                order = [SELECT Id, Description, DescriptionBillingSale__c, AccountId, Type, ShippingAccount__c, Pricebook2Id, PaymentDate__c, ShippingDate__c, PaymentCondition__c, CustomerOrderNumber__c,
                Crop__c, Culture__c, PaymentForm__c, StatusSF__c, SalesOrg__c, DistributionChannel__c, ActivitySector__c, Currency__c, SalesCTV__c
                FROM Order WHERE Id =: orderId LIMIT 1];
            } else {
                order = new Order();
            }
            System.debug('order: ' + order);

            Account acc = [SELECT Id FROM Account WHERE Id =: orderData.accountData.Id LIMIT 1];
    
            Decimal orderTotalValue = 0;
            Set<Id> setOrderItemsIds = new Set<Id>();
            for (ProductDeserialize orderProduct : orderData.productData) {
                orderTotalValue += orderProduct.totalPrice;
                if (orderProduct.orderItemId != null) {
                    setOrderItemsIds.add(orderProduct.orderItemId);
                }
            }
            
            Map<Id, OrderItem> orderItemsById = new Map<Id, OrderItem>([
                SELECT Id
                  FROM OrderItem
                 WHERE Id IN: setOrderItemsIds
            ]);

            order.AccountId = acc.Id;
            order.Status = 'Draft';
            order.PriceBook2Id = orderData.headerData.lista_precos.Id;
            order.Type = orderData.headerData.tipo_venda ;
            order.ShippingAccount__c = orderData.headerData.cliente_entrega.Id ;
            order.PaymentDate__c = Date.valueOf(orderData.headerData.data_pagamento) ;
            order.CustomerOrderNumber__c = orderData.headerData.numero_pedido_cliente ;
            order.EffectiveDate = Date.today();
            order.Crop__c = orderData.headerData.safra.Id ;
            order.Culture__c = orderData.headerData.cultura.Id ;
            order.PaymentForm__c = orderData.headerData.forma_pagamento ;
            order.SalesOrg__c = orderData.headerData.organizacao_vendas == ' ' ? null :  orderData.headerData.organizacao_vendas;
            order.DistributionChannel__c = orderData.headerData.canal_distribuicao ;
            order.ActivitySector__c = orderData.headerData.setor_atividade ;
            order.Currency__c = orderData.headerData.moeda ;
            order.SalesCTV__c = orderData.headerData.ctv_venda.Id ;
            order.StatusSF__c = orderData.headerData.status_pedido;
            order.Incoterms__c = orderData.headerData.frete;
            order.Description = orderData.summaryData.observation;
            order.PaymentCondition__c = orderData.headerData.condicao_pagamento.Id;
            order.ShippingDate__c = Date.valueOf(orderData.headerData.data_entrega);
            order.DescriptionBillingSale__c = orderData.summaryData.billing_sale_observation;
            order.FinalTotalValue__c = orderTotalValue;

            Database.UpsertResult insResults = Database.upsert(order, false);
            if (insResults.isSuccess()) {
                msg = 'Pedido ' + (newOrder ? 'criado' : 'atualizado') + ' com sucesso';

                List<OrderItem> listOrderItems = new List<OrderItem>();
                Map<String, String> statusValueByLabel = new Map<String, String>{
                    'Concluído' => '5',
                    'Faturado Parcialmente' => '4',
                    'Crédito Liberado' => '3',
                    'Cancelado' => 'X'
                };
                for (ProductDeserialize orderProduct : orderData.productData) {
                    OrderItem orderItem;
                    if (!newOrder && orderItemsById.containsKey(orderProduct.orderItemId)) {
                        orderItem = orderItemsById.get(orderProduct.orderItemId);
                    } else {
                        orderItem = new OrderItem();
                        orderItem.OrderId = order.Id;
                        orderItem.PricebookEntryId = orderProduct.entryId;
                        orderItem.Product2Id = orderProduct.productId;
                        orderItem.ListPrice = orderProduct.listPrice;
                    }

                    orderItem.ServiceDate = System.today();
                    orderItem.Quantity = orderProduct.quantity;
                    orderItem.UnitPrice = orderProduct.unitPrice;
                    orderItem.Dosage__c = orderProduct.dosage;
                    orderItem.Status__c = orderProduct.sapStatus != null ? statusValueByLabel.get(orderProduct.sapStatus) : null;
                    orderItem.UnitMeasure__c = orderProduct.unity;
                    orderItem.FinalTotalValue__c = orderProduct.totalPrice;
                    orderItem.DiscountPercent__c = stringToDecimal(orderProduct.commercialDiscountPercentage);
                    orderItem.DiscountValue__c = orderProduct.commercialDiscountValue;
                    orderItem.CommercialAdditionPercent__c = stringToDecimal(orderProduct.commercialAdditionPercentage);
                    orderItem.CommercialAdditionValue__c = orderProduct.commercialAdditionValue;
                    orderItem.FinancialAdditionPercent__c = stringToDecimal(orderProduct.financialAdditionPercentage);
                    orderItem.FinancialAdditionValue__c = orderProduct.financialAdditionValue;
                    orderItem.FinancialDiscountPercent__c = stringToDecimal(orderProduct.financialDecreasePercentage);
                    orderItem.FinancialDiscountValue__c = orderProduct.financialDecreaseValue;
                    orderItem.ComissionValue__c = orderProduct.comissionValue;
                    orderItem.CommercialMargin__c = orderProduct.commercialMarginPercentage;
                    System.debug('orderItem: ' + orderItem);
                    listOrderItems.add(orderItem);
                }

                String orderItemErrors = '';
                List<Database.UpsertResult> insOrderItemResults = Database.upsert(listOrderItems, false);
                for (Database.UpsertResult result : insOrderItemResults){
                    if(!result.isSuccess()){
                        for (Database.error error: insResults.getErrors()){
                            orderItemErrors += '\n' + error.getMessage();
                            msg = 'Pedido não pôde ser ' + (newOrder ? 'criado' : 'atualizado');
                            return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg + orderItemErrors));
                        }
                    }
                }
                return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg));
            }

            String errors = '';
            for (Database.error error: insResults.getErrors()) {
                 errors += '\n' + error.getMessage();
            }
            msg = 'Pedido não pôde ser ' + (newOrder ? 'criado' : 'atualizado');
            return JSON.serializePretty(new AGRO_RemotingResult(false, '200', msg + errors));
        } catch (Exception ex) {
            Database.rollback(sp);
            System.debug('Erro: ' + ex.getMessage() + '   -   ' + ex.getStackTraceString());
			throw new AuraHandledException('Exception occured:\r\n' + ex.getMessage() + '\r\n' + ex.getStackTraceString() + '\r\n');
		}
    }

    public static Decimal stringToDecimal(String value) {
        if (value.contains(',')) value = value.replaceAll(',', '.');
        if (value.contains('%')) value = value.replaceAll('%', '');
        return Decimal.valueOf(value);
    }

    //Classe para deserialização
    public class OrderDeserialize{
        public AccountDeserialize accountData;
        public HeaderDeserialize headerData;
        public List<ProductDeserialize> productData;
        public SummaryDeserialize summaryData;
    }

    public class AccountDeserialize {
        public String Id;
        public String Name;
    }

    public class HeaderDeserialize {
       

        public String Id;
        public String AccountId;
        public String tipo_venda;
        //public InformationFields filial;
        public String numero_pedido_cliente;
        public InformationFields safra;
        public InformationFields cultura;
        public InformationFields lista_precos;
        public InformationFields condicao_pagamento;
        public String data_pagamento;
        public String data_entrega;
        public String status_pedido;
        public AccountSerialize cliente_entrega;
        public String organizacao_vendas;
        public String canal_distribuicao;
        public String setor_atividade;
        public String forma_pagamento;
        public String moeda;
        public String frete;
        public InformationFields ctv_venda;
        public String observation;
        public String billing_sale_observation;
        //public String cliente_faturamento;
    }

    public class ProductDeserialize{
        public String orderItemId;
        public String productId;
        public String name;
        public String entryId;
        public String sapProductCode;
        public String sapStatus;
        public String unity;
        public String activePrinciple;
        public String productGroupId;
        public String productGroupName;
        public Integer position;
        public Integer invoicedQuantity;
        public Decimal quantity;
        public Decimal listPrice;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Decimal dosage;
        public String commercialDiscountPercentage;
        public Decimal commercialDiscountValue;
        public String commercialAdditionPercentage;
        public Decimal commercialAdditionValue;
        public String financialAdditionPercentage;
        public Decimal financialAdditionValue;
        public String financialDecreasePercentage;
        public Decimal financialDecreaseValue;
        public Decimal commercialMarginPercentage;
        public Decimal comissionValue;
    }

    public class SummaryDeserialize{
        public String observation;
        public String billing_sale_observation;
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
        public String CNPJ;
        public String CPF;
        public String City;
        public String UF;
        public String CodSap;
        public String Company;
        
        public List<AccountSerialize> accountList;
        AccountSerialize(){}
        AccountSerialize(Account account){
            this.Id = account.Id;
            this.Name = account.Name;
            this.Phone = account.Phone;
            this.CNPJ = account.CNPJ__c;
            this.CPF = account.CPF__c;
            this.City = account.BillingCity;
            this.UF = account.BillingState;
            this.CodSap = account.ExternalId__c;
            this.Company = account.Company__c;
        }

        AccountSerialize(List<AccountSerialize> accountList){
            this.accountList = accountList;
        }
    }
    
    public class HeaderSerialize {
        public String Id;
        public String AccountId;
        public String tipo_venda;
        public String filial;
        public String numero_pedido_cliente;
        public InformationFields safra;
        public InformationFields cultura;
        public InformationFields lista_precos;
        public InformationFields condicao_pagamento;
        public String data_pagamento;
        public String data_entrega;
        public String status_pedido;
        public String cliente_faturamento;
        public AccountSerialize cliente_entrega;
        public InformationFields organizacao_vendas;
        public String canal_distribuicao;
        public String setor_atividade;
        public String forma_pagamento;
        public String moeda;
        public String frete;
        public InformationFields ctv_venda;
        public String observation;
        public String billing_sale_observation;
        //public String data_entrega;
        //public String cliente_faturamento;
        HeaderSerialize(){}
        HeaderSerialize(Order order){
            this.Id = order.Id;
            this.AccountId = order.AccountId;
            this.tipo_venda = order.Type;

            this.cliente_entrega = new AccountSerialize();
            this.cliente_entrega.Id = order.ShippingAccount__c;
            this.cliente_entrega.Name = order.ShippingAccount__r.Name;
            this.cliente_entrega.CNPJ = order.ShippingAccount__r.CNPJ__c;
            this.cliente_entrega.City = order.ShippingAccount__r.BillingCity;
            this.cliente_entrega.UF = order.ShippingAccount__r.BillingState;
            this.cliente_entrega.CPF = order.ShippingAccount__r.CPF__c;
            this.cliente_entrega.Phone = order.ShippingAccount__r.Phone;

            this.lista_precos = new InformationFields(order.Pricebook2Id, order.Pricebook2.Name);
            this.data_pagamento = String.valueOf(order.PaymentDate__c);
            this.data_entrega = String.valueOf(order.ShippingDate__c);
            this.numero_pedido_cliente = order.CustomerOrderNumber__c;
            this.safra = new InformationFields(order.Crop__c, order.Crop__r.Name);
            this.cultura = new InformationFields(order.Culture__c, order.Culture__r.Name);
            this.forma_pagamento = order.PaymentForm__c;
            this.status_pedido = order.StatusSF__c;
            this.organizacao_vendas = new InformationFields(order.SalesOrg__c, order.SalesOrg__r.Name);
            this.canal_distribuicao = order.DistributionChannel__c;
            this.setor_atividade = order.ActivitySector__c;
            this.moeda = order.Currency__c;
            this.ctv_venda = new InformationFields(order.SalesCTV__c,  order.SalesCTV__r.Name);
            this.condicao_pagamento = new InformationFields(order.PaymentCondition__c, order.PaymentCondition__r.Name);
            this.frete = order.Incoterms__c;
            this.observation = order.Description;
            this.billing_sale_observation = order.DescriptionBillingSale__c;
        }
    }

    public class InformationFields{
        public String Id;
        public String Name;

        public InformationFields(String id, String name){
            this.Id = id;
            this.Name = name;
        }
    }
    
    public class ProductSerialize{
        public String orderId;
        public String orderItemId;
        public String productId;
        public String name;
        public String sapProductCode;
        public String entryId;
        public String sapStatus;
        public String unity;
        public String activePrinciple;
        public String productGroupId;
        public String productGroupName;
        public String productGroup;
        public Date serviceDate;
        public Integer position;
        public Decimal multiplicity;
        public Decimal invoicedQuantity;
        public Decimal quantity;
        public Decimal listPrice;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Decimal dosage;
        public String commercialDiscountPercentage;
        public Decimal commercialDiscountValue;
        public String commercialAdditionPercentage;
        public Decimal commercialAdditionValue;
        public String financialAdditionPercentage;
        public Decimal financialAdditionValue;
        public String financialDecreasePercentage;
        public Decimal financialDecreaseValue;
        public Decimal commercialMarginPercentage;
        public Decimal comissionValue;

        ProductSerialize(){}

        ProductSerialize(OrderItem orderItem, Integer position){
            this.position = position;
            this.orderItemId = orderItem.Id;
            this.productId = orderItem.Product2Id;
            this.name = orderItem.Product2.Name;
            this.sapProductCode = orderItem.Product2.ExternalId__c;
            this.multiplicity = orderItem.Product2.Multiplicity__c;
            this.activePrinciple = orderItem.Product2.PrincipleActive__c;
            this.productGroupId = orderItem.Product2.ProductGroup__c;
            this.productGroupName = orderItem.Product2.ProductGroup__r.Name;
            this.entryId = orderItem.PricebookEntryId;
            this.orderId = OrderId;
            this.serviceDate = ServiceDate;
            this.quantity = orderItem.Quantity;
            this.invoicedQuantity = orderItem.InvoicedQuantity__c;
            this.listPrice = orderItem.ListPrice;
            this.unitPrice = orderItem.UnitPrice;
            this.totalPrice = orderItem.FinalTotalValue__c;
            this.dosage = orderItem.Dosage__c;
            this.sapStatus = orderItem.Status__c;
            this.unity = orderItem.UnitMeasure__c;
            this.commercialDiscountPercentage = String.valueOf(orderItem.DiscountPercent__c) + '%';
            this.commercialDiscountValue = orderItem.DiscountValue__c;
            this.commercialAdditionPercentage = String.valueOf(orderItem.CommercialAdditionPercent__c) + '%';
            this.commercialAdditionValue = orderItem.CommercialAdditionValue__c;
            this.financialAdditionPercentage = String.valueOf(orderItem.FinancialAdditionPercent__c) + '%';
            this.financialAdditionValue = orderItem.FinancialAdditionValue__c;
            this.financialDecreasePercentage = String.valueOf(orderItem.FinancialDiscountPercent__c) + '%';
            this.financialDecreaseValue = orderItem.FinancialDiscountValue__c;
            this.comissionValue = orderItem.ComissionValue__c;
            this.commercialMarginPercentage = orderItem.CommercialMargin__c;
        }
    }
}
