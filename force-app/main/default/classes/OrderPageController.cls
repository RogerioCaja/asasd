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
        OrderCommodity__c commodity;
        if(this.orderToPage.currencyOrder == 'Barter'){
            commodity = getCommodityByOrderId(orderId)[0];
        }
        
        Map<Id, List<DivisonDAO>> divisonMap = getDivisonByList(orderItemList);

        for(OrderItem orderItem : orderItemList){
            this.orderToPage.orderItemList.add(new OrderItemDAO(orderItem, this.orderToPage.culture, this.orderToPage.currencyOrder, divisonMap.get(orderItem.Id), commodity));
        }
        Decimal totalValue = 0;
        for(OrderItemDAO orderItem : this.orderToPage.orderItemList){
            totalValue += Decimal.valueOf(orderItem.totalAmount.replace(' sacas', ''));
        }
        this.orderToPage.totalAmount = this.orderToPage.currencyOrder == 'Barter' ? String.valueOf(totalValue) + ' sacas' : String.valueOf(totalValue);
       
        String downloadingFileName = 'Pedido de Venda-' + this.orderToPage.codeSap + '.pdf';
        Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + downloadingFileName );
       
        return this.orderToPage;

    }

    public static Order getOrderById(Id orderId){
  
        Set<String> fieldSet = new Set<String>{
            'Id', 'Account.ExternalId__c', 'Account.Name', 'Account.BillingStreet',
            'ShippingAccount__r.Name','Account.BillingCity', 'Account.StateRegistration__c',
            'Account.CPF__c', 'Account.CNPJ__c', 'TotalAmount', 'Description',
            'Account.BillingPostalCode', 'Crop__r.Name', 'PaymentForm__c', 'PaymentDate__c', 'RecordTypeId',
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
            'Product2Id','Product2.ProductCode' ,'Description', 'UnitMeasure__c', 'FinalTotalValue__c',
            'UnitPrice','Quantity','TotalPrice' , 'Product2.Name', 'Product2.GrossWeightUnitOfMeasure__c'
        };

        String query = new Q(OrderItem.SObjectType)
                            .selectFields(fieldSet)
                            .add(Q.condition('OrderId').equalsTo(orderId)).build();

        return Database.query(query);
    }

    public static List<OrderCommodity__c> getCommodityByOrderId(Id orderId){

        Set<String> fieldSet = new Set<String>{
            'BagQuantity__c','CommodityPrice__c', 'Product__c'
            
        };

        String query = new Q(OrderCommodity__c.SObjectType)
                            .selectFields(fieldSet)
                            .add(Q.condition('Order__c').equalsTo(orderId)).build();

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
            this.currencyOrder = currencyLogic(order);
            this.culture = order.Culture__r.Name;
            this.dueDate = String.valueOf(order.PaymentDate__c);
            this.totalAmount = formatCurrency(order.TotalAmount, this.currencyOrder);
            this.observation = order.Description;
            this.codCTV = order.SalesCTV__r.CodigoSap__c;
            this.nameCTV = order.SalesCTV__r.Name;
            this.orderItemList = new List<OrderItemDAO>();
        }

        public String currencyLogic(Order order){
            Id recType = [SELECT Id, Name FROM RecordType WHERE Name = 'Venda Barter'].Id;
            String response = recType == order.RecordTypeId ? 'Barter' : order.Currency__c;
            return response;
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
        public String quantity {get; set;}
        public String totalAmount {get; set;}
        public List<DivisonDAO> divisonList {get; set;}

        public OrderItemDAO(OrderItem orderItem, String culture, String currencyCode, List<DivisonDAO> divisonList, OrderCommodity__c commodity){
            this.productCode = orderItem.Product2.ProductCode;
            this.description = orderItem.Product2.Name;
            this.unitOfMeasure = orderItem.Product2.GrossWeightUnitOfMeasure__c;
            this.unitPrice = commodity != null ? formatCurrency((orderItem.UnitPrice/commodity.CommodityPrice__c), currencyCode) + ' por saca': formatCurrency((orderItem.UnitPrice), currencyCode);
            this.quantity =  String.valueOf(orderItem.Quantity);
            this.totalAmount = commodity != null ? formatCurrency(Decimal.valueOf(this.unitPrice.replace(' por saca', '')) * orderItem.Quantity, currencyCode) + ' sacas' : formatCurrency(orderItem.FinalTotalValue__c, currencyCode) ;
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

    public class CommodityDAO{
        public String price {get; set;}
        public String quantity {get; set;}
        public String product {get; set;}

        public CommodityDAO(OrderCommodity__c commodity){
            this.quantity = String.valueOf(commodity.BagQuantity__c);
            this.price = String.valueOf(commodity.CommodityPrice__c) + ' por saca';
            this.product = commodity.Product__c;
        } 
    }
    
}
