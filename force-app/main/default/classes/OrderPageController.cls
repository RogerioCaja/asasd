public with sharing class OrderPageController {
    public OrderDAO orderToPage {get; set;}
  
    public OrderPageController(){}
    public OrderPageController(ApexPages.StandardController stdController) {
        try
        {
            Id OrderIdPageReference = Id.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('Id').escapeHtml4()));
            if(OrderIdPageReference != null) generatePDF(OrderIdPageReference);
        }
        catch(Exception e){
            System.debug('Sem ID encontrado');
        }
    }

    public OrderDAO generatePDF(Id orderId){
        Order order = getOrderById(orderId);
        List<OrderItem> orderItemList = getOrderItemByOrderId(orderId);

        this.orderToPage = new OrderDAO(order);

        for(OrderItem orderItem : orderItemList){
            this.orderToPage.orderItemList.add(new OrderItemDAO(orderItem, this.orderToPage.culture));
        }

       
        String downloadingFileName = 'Pedido de Venda-' + this.orderToPage.codeSap + '.pdf';
        Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + downloadingFileName );
       
        return this.orderToPage;

    }

    public static Order getOrderById(Id orderId){
  
        Set<String> fieldSet = new Set<String>{
            'Id', 'Account.ExternalId__c', 'Account.Name', 'Account.BillingStreet',
            'ShippingAccount__r.Name','Account.BillingCity', 'Account.StateRegistration__c',
            'Account.CPF__c', 'Account.CNPJ__c', 'TotalAmount', 'Description',
            'Account.BillingPostalCode', 'Crop__r.Name', 'PaymentForm__c', 'PaymentDate__c',
            'Currency__c', 'Culture__c', 'CodigoSap__c'
        };

        String query = new Q(Order.SObjectType)
                            .selectFields(fieldSet)
                            .add(Q.condition('Id').equalsTo(orderId))
                            .addLimit(1).build();

        return Database.query(query);
    }

    public static List<OrderItem> getOrderItemByOrderId(Id orderId){

        Set<String> fieldSet = new Set<String>{
            'Product2Id', 'Description', 'UnitMeasure__c', 
            'UnitPrice','Quantity','TotalPrice'
        };

        String query = new Q(OrderItem.SObjectType)
                            .selectFields(fieldSet)
                            .add(Q.condition('OrderId').equalsTo(orderId)).build();

        return Database.query(query);
    }

    public static String getDatetime(){

        Datetime  dt = DateTime.now();
        String dateFormat = dt.format('dd/MM/yyyy', 
        'America/Sao_Paulo');

        return dateFormat;
    }

    public class OrderDAO{
        //Cód. Pessoa, Pessoa, Local, Fazenda, municipio, CPF/CNPJ, I.E., CEP
        //safra, Cond. de Pagamento, Vencimento
        public String codeSap {get; set;}
        public String codeSapOrder {get; set;}
        public String account {get; set;}
        public String accountAddress {get; set;}
        public String ranch {get; set;}
        public String district {get; set;}
        public String CPF_CNPJ {get; set;}
        public String IE {get; set;}
        public String CEP{get; set;}
        public String safra {get; set;}
        public String paymentCondition {get; set;}
        public String dueDate {get; set;}
        public String currencyOrder {get; set;}
        public String culture {get; set;}
        public String totalAmount {get; set;}
        public String observation {get; set;}
        public List<OrderItemDAO> orderItemList {get; set;}

        public OrderDAO(Order order){
            this.codeSap = order.Account.ExternalId__c;
            this.codeSapOrder = order.CodigoSap__c;
            this.account = order.Account.Name;
            this.accountAddress = order.Account.BillingStreet;
            this.ranch = order.ShippingAccount__r.Name;
            this.district = order.Account.BillingCity;
            this.IE = order.Account.StateRegistration__c;
            this.CEP = order.Account.BillingPostalCode;
            this.CPF_CNPJ = order.Account.CNPJ__c == null ? order.Account.CPF__c : order.Account.CNPJ__c;
            this.safra = order.Crop__r.Name;
            this.paymentCondition = order.PaymentForm__c;
            this.currencyOrder = order.Currency__c;
            this.culture = order.Culture__c;
            this.dueDate = String.valueOf(order.PaymentDate__c);
            this.totalAmount = String.valueOf(order.TotalAmount);
            this.observation = order.Description;
            this.orderItemList = new List<OrderItemDAO>();
        }
    }

    public class OrderItemDAO{
        // Cód. Produto Descrição Cultura Unid. Medida Quant. Preço Unit. Valor Total
        public String productCode {get; set;}
        public String description {get; set;}
        public String culture {get;set;}
        public String unitOfMeasure {get; set;}
        public Decimal unitPrice {get; set;}
        public Decimal quantity {get; set;}
        public Decimal totalAmount {get; set;}

        public OrderItemDAO(OrderItem orderItem, String culture){
            this.productCode = orderItem.Product2Id;
            this.description = orderItem.Description;
            this.unitOfMeasure = orderItem.UnitMeasure__c;
            this.unitPrice = orderItem.UnitPrice;
            this.quantity = orderItem.Quantity;
            this.totalAmount = orderItem.TotalPrice;
            this.culture = culture;
        }
    }
}
