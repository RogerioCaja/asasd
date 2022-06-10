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
            System.debug(e);
            System.debug('Sem ID encontrado');
        }
    }

    public OrderDAO generatePDF(Id orderId){
        Order order = getOrderById(orderId);
        this.orderToPage = new OrderDAO(order);
        List<OrderItem> orderItemList = getOrderItemByOrderId(orderId);
    
        Map<Id, List<DivisonDAO>> divisonMap = getDivisonByList(orderItemList);

        for(OrderItem orderItem : orderItemList){
            this.orderToPage.orderItemList.add(new OrderItemDAO(orderItem, this.orderToPage.culture, this.orderToPage.currencyOrder, divisonMap.get(orderItem.Id)));
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
            'Currency__c', 'Culture__r.Name', 'CodigoSap__c', 'SalesCTV__r.CodigoSap__c', 'SalesCTV__r.Name'
        };

        String query = new Q(Order.SObjectType)
                            .selectFields(fieldSet)
                            .add(Q.condition('Id').equalsTo(orderId))
                            .addLimit(1).build();

        return Database.query(query);
    }

    public static List<OrderItem> getOrderItemByOrderId(Id orderId){

        Set<String> fieldSet = new Set<String>{
            'Product2Id','Product2.ProductCode' ,'Description', 'UnitMeasure__c', 
            'UnitPrice','Quantity','TotalPrice' , 'Product2.Name', 'Product2.GrossWeightUnitOfMeasure__c'
        };

        String query = new Q(OrderItem.SObjectType)
                            .selectFields(fieldSet)
                            .add(Q.condition('OrderId').equalsTo(orderId)).build();

        return Database.query(query);
    }

    public static Map<Id, List<DivisonDAO>> getDivisonByList(List<OrderItem> orderItemList){
        
        List<String> orderItemIds = new List<String>();
        Map<Id, List<DivisonDAO>> divisonMap = new  Map<Id, List<DivisonDAO>>();

        for(OrderItem orderItem : orderItemList){
            orderItemIds.add(orderItem.Id);
        }
        Set<String> fieldSet = new Set<String>{
            'Id', 'DeliveryDate__c', 'Quantity__c', 'OrderItem__c'
        };

        String query = new Q(ShippingDivison__c.SObjectType)
                            .selectFields(fieldSet)
                            .add(Q.condition('OrderItem__c').isIn(orderItemIds))
                            .add(new QOrder('DeliveryDate__c').ascending())
                            .build();
    
        List<ShippingDivison__c> divisonList = Database.query(query);

        for(ShippingDivison__c divison : divisonList){
            if(!divisonMap.containsKey(divison.OrderItem__c)){
                divisonMap.put(divison.OrderItem__c, new List<DivisonDAO>());
            }
            divisonMap.get(divison.OrderItem__c).add(new DivisonDAO(divison));
        }
        return divisonMap;
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
        public String codCTV {get; set;}
        public String nameCTV {get; set;}
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
            this.culture = order.Culture__r.Name;
            this.dueDate = String.valueOf(order.PaymentDate__c);
            this.totalAmount = formatCurrency(order.TotalAmount, this.currencyOrder);
            this.observation = order.Description;
            this.codCTV = order.SalesCTV__r.CodigoSap__c;
            this.nameCTV = order.SalesCTV__r.Name;
            this.orderItemList = new List<OrderItemDAO>();
        }

        public String formatCurrency(Decimal value, String currencyCode){
            String valueToFormat = String.valueOf(value);
            if(currencyCode == 'BRL'){
                valueToFormat = valueToFormat.replace('.', ',');
                valueToFormat = 'R$ ' + valueToFormat;
            }
            else if(currencyCode == 'USD'){
                valueToFormat = '$ ' + valueToFormat;
            }
    
            return valueToFormat;
        }
    }

    public class OrderItemDAO{
        // Cód. Produto Descrição Cultura Unid. Medida Quant. Preço Unit. Valor Total
        public String productCode {get; set;}
        public String description {get; set;}
        public String culture {get;set;}
        public String unitOfMeasure {get; set;}
        public String unitPrice {get; set;}
        public Decimal quantity {get; set;}
        public String totalAmount {get; set;}
        public List<DivisonDAO> divisonList {get; set;}

        public OrderItemDAO(OrderItem orderItem, String culture, String currencyCode, List<DivisonDAO> divisonList){
            this.productCode = orderItem.Product2.ProductCode;
            this.description = orderItem.Product2.Name;
            this.unitOfMeasure = orderItem.Product2.GrossWeightUnitOfMeasure__c;
            this.unitPrice = formatCurrency(orderItem.UnitPrice, currencyCode);
            this.quantity = orderItem.Quantity;
            this.totalAmount = formatCurrency(orderItem.TotalPrice, currencyCode) ;
            this.culture = culture;
            this.divisonList = divisonList;
        }

        public String formatCurrency(Decimal value, String currencyCode){
            String valueToFormat = String.valueOf(value);
            if(currencyCode == 'BRL'){
                valueToFormat = valueToFormat.replace('.', ',');
                valueToFormat = 'R$ ' + valueToFormat;
            }
            else if(currencyCode == 'USD'){
                valueToFormat = '$ ' + valueToFormat;
            }
    
            return valueToFormat;
        }
    }

    public class DivisonDAO{
        public String deliveryDate {get; set;}
        public String quantity {get; set;}

        public DivisonDAO(ShippingDivison__c divison){
            this.deliveryDate =  divison.DeliveryDate__c.format();
            this.quantity = String.valueOf(divison.Quantity__c);
        }
    }
    
}
