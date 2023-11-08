public without sharing class FactoryBuilder {
    public FactoryBuilder() {}

    public interface Builder{
        void setOrder(Order order);
        void setRefMap();
        void setOrderItemMap();
        void setType();
        void setHeader();
        void setPartners();
        void setOrderItems();
        void setConditions();
        void setShippingDivision();
        Object getResult();
    }

    public class Director{
        public void constructRequestBasic(Builder builder, Order order){
            builder.setOrder(order);
            builder.setRefMap();
            builder.setOrderItemMap();
            builder.setType();
            builder.setHeader();
            builder.setPartners();
            builder.setOrderItems();
            builder.setConditions();
            builder.setShippingDivision();
        }

        public void constructRequestSeed(Builder builder, Order order){
            builder.setOrder(order);
            builder.setRefMap();
            builder.setOrderItemMap();
            builder.setType();
            builder.setHeader();
            builder.setPartners();
            builder.setOrderItems();
            builder.setConditions();
            builder.setShippingDivision();
        }

        public void constructRequestBarter(Builder builder, Order order){
            builder.setOrder(order);
            builder.setRefMap();
            builder.setOrderItemMap();
            builder.setType();
            builder.setHeader();
            builder.setPartners();
            builder.setOrderItems();
            builder.setConditions();
            builder.setShippingDivision();
        }

        public void constructRequestBarterSeeds(Builder builder, Order order){
            builder.setOrder(order);
            builder.setRefMap();
            builder.setOrderItemMap();
            builder.setType();
            builder.setHeader();
            builder.setPartners();
            builder.setOrderItems();
            builder.setConditions();
            builder.setShippingDivision();
        }
    }

    //builders
    public class RequestBuilder implements Builder{
        //parameters to builder
        private String IV_TYPE;
        private Header IS_HEADER_IN;
        private List<PartnerParameters> IT_PARTNERS;
        private List<ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        private List<ConditionParameters> IT_CONDITIONS_IN;
        private List<OrderItemParameters> IT_ITEMS_IN;

        //parameters to aux builder
        private Order order;
        private Delimitadores__c delimiter;
        private Map<String, String> referenceItemMotherMap;
        private Map<Id, OrderItem> orderItemMap;
        private Map<Id, Decimal> orderItemComboDiscountMap;

        public void setOrder(Order order){
            this.order = order;
            this.delimiter = getDelimiterByKey(this.order);
        }

        public void setRefMap(){
            this.referenceItemMotherMap = generateRefMapOrderItem(this.order);
        }

        public void setOrderItemMap(){
            this.orderItemMap = generateOrderItemMap(this.order);
            this.orderItemComboDiscountMap = generateOrderItemComboMap(this.orderItemMap);
        }

        public void setType(){
            this.IV_TYPE = getTypeContract(this.order);
        }

        public void setHeader(){
            this.IS_HEADER_IN = new Header(this.order, this.delimiter);
        }

        public void setPartners(){
            this.IT_PARTNERS = generatePartnerParametersList(this.order);
        }

        public void setOrderItems(){
            this.IT_ITEMS_IN = generateOrderItemParameterList(this.orderItemMap, this.referenceItemMotherMap, this.order);
        }

        public void setConditions(){
            this.IT_CONDITIONS_IN = generateConditionParametersList(this.orderItemMap, this.orderItemComboDiscountMap, this.order);
        }

        public void setShippingDivision(){
            this.IT_ORDER_SCHEDULES_IN = generateScheduleParametersList(this.orderItemMap);
        }

        public Request getResult(){
            return new Request(this.IS_HEADER_IN, this.IT_PARTNERS, this.IT_ORDER_SCHEDULES_IN, this.IT_CONDITIONS_IN, this.IT_ITEMS_IN, this.IV_TYPE);
        }
    }

    public class RequestSeedsBuilder implements Builder{
        //parameters to builder
        private String IV_TYPE;
        private HeaderSeeds IS_HEADER_IN;
        private List<PartnerParameters> IT_PARTNERS;
        private List<ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        private List<ConditionParameters> IT_CONDITIONS_IN;
        private List<OrderItemParametersSeeds> IT_ITEMS_IN;

        //parameters to aux builder
        private Order order;
        private Delimitadores__c delimiter;
        private Map<String, String> referenceItemMotherMap;
        private Map<Id, OrderItem> orderItemMap;
        private Map<Id, Decimal> orderItemComboDiscountMap;
        private Boolean hasSeed;

        public void setOrder(Order order){
            this.order = order;
            this.delimiter = getDelimiterByKey(this.order);
        }

        public void setRefMap(){
            this.referenceItemMotherMap = generateRefMapOrderItem(this.order);
        }

        public void setOrderItemMap(){
            this.orderItemMap = generateOrderItemMap(this.order);
            this.hasSeed = hasSeedGroup(this.orderItemMap);
            this.orderItemComboDiscountMap = generateOrderItemComboMap(this.orderItemMap);
        }

        public void setType(){
            this.IV_TYPE = getTypeContract(this.order);
        }

        public void setHeader(){
            this.IS_HEADER_IN = new HeaderSeeds(this.order, this.hasSeed, this.delimiter);
        }

        public void setPartners(){
            this.IT_PARTNERS = generatePartnerParametersList(this.order);
        }

        public void setOrderItems(){
            this.IT_ITEMS_IN = generateOrderItemParameterSeedList(this.orderItemMap, this.referenceItemMotherMap, this.order);
        }

        public void setConditions(){
            this.IT_CONDITIONS_IN = generateConditionParametersSeedList(this.orderItemMap, this.orderItemComboDiscountMap, this.order);
        }

        public void setShippingDivision(){
            this.IT_ORDER_SCHEDULES_IN = generateScheduleParametersList(this.orderItemMap);
        }

        public void setFormPayment(){
            this.IS_HEADER_IN = addPaymentForm(this.order, this.IS_HEADER_IN);
        }

        public RequestSeeds getResult(){
            setFormPayment();
            return new RequestSeeds(this.IS_HEADER_IN, this.IT_PARTNERS, this.IT_ORDER_SCHEDULES_IN, this.IT_CONDITIONS_IN, this.IT_ITEMS_IN, this.IV_TYPE);
        }
    }

    public class RequestBarterBuilder implements Builder{
        //parameters to builder
        private String IV_TYPE;
        private HeaderBarter IS_HEADER_IN;
        private List<PartnerParameters> IT_PARTNERS;
        private List<ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        private List<ConditionParameters> IT_CONDITIONS_IN;
        private List<OrderItemParametersBarter> IT_ITEMS_IN;

        //parameters to aux builder
        private Order order;
        private Delimitadores__c delimiter;
        private OrderCommodity__c commodity;
        private Map<String, String> referenceItemMotherMap;
        private Map<Id, OrderItem> orderItemMap;

        public void setOrder(Order order){
            this.order = order;
            this.delimiter = getDelimiterByKey(this.order);
            this.commodity = getCommodityPriceByOrder(this.order);
        }

        public void setRefMap(){
            this.referenceItemMotherMap = generateRefMapOrderItem(this.order);
        }

        public void setOrderItemMap(){
            this.orderItemMap = generateOrderItemMap(this.order);
        }

        public void setType(){
            this.IV_TYPE = getTypeContract(this.order);
        }

        public void setHeader(){
            this.IS_HEADER_IN = new HeaderBarter(this.order, this.delimiter, this.commodity);
        }

        public void setPartners(){
            this.IT_PARTNERS = generatePartnerParametersList(this.order);
        }

        public void setOrderItems(){
            this.IT_ITEMS_IN = generateOrderItemParameterBarterList(this.order);
        }

        public void setConditions(){
            this.IT_CONDITIONS_IN = generateConditionParametersBarterList(this.commodity, this.order);
        }

        public void setShippingDivision(){
            this.IT_ORDER_SCHEDULES_IN = generateScheduleParametersList(this.orderItemMap);
        }

        public RequestBarter getResult(){
            return new RequestBarter(this.IS_HEADER_IN, this.IT_PARTNERS, this.IT_ORDER_SCHEDULES_IN, this.IT_CONDITIONS_IN, this.IT_ITEMS_IN, this.IV_TYPE);
        }
    }

    public class RequestBarterSeedsBuilder implements Builder{
        //parameters to builder
        private String IV_TYPE;
        private HeaderBarterSeeds IS_HEADER_IN;
        private List<PartnerParameters> IT_PARTNERS;
        private List<ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        private List<ConditionParameters> IT_CONDITIONS_IN;
        private List<OrderItemParametersBarter> IT_ITEMS_IN;

        //parameters to aux builder
        private Order order;
        private Delimitadores__c delimiter;
        private OrderCommodity__c commodity;
        private Map<String, String> referenceItemMotherMap;
        private Map<Id, OrderItem> orderItemMap;
        private Boolean hasSeed;

        public void setOrder(Order order){
            this.order = order;
            this.delimiter = getDelimiterByKey(this.order);
            this.commodity = getCommodityPriceByOrder(this.order);
        }

        public void setRefMap(){
            this.referenceItemMotherMap = generateRefMapOrderItem(this.order);
        }

        public void setOrderItemMap(){
            this.orderItemMap = generateOrderItemMap(this.order);
            this.hasSeed = hasSeedGroup(this.orderItemMap);
        }

        public void setType(){
            this.IV_TYPE = getTypeContract(this.order);
        }

        public void setHeader(){
            this.IS_HEADER_IN = new HeaderBarterSeeds(this.order, this.hasSeed, this.delimiter, this.commodity);
        }

        public void setPartners(){
            this.IT_PARTNERS = generatePartnerParametersList(this.order);
        }

        public void setOrderItems(){
            this.IT_ITEMS_IN = generateOrderItemParameterBarterList(this.order);
        }

        public void setConditions(){
            this.IT_CONDITIONS_IN = generateConditionParametersBarterList(this.commodity, this.order);
        }

        public void setShippingDivision(){
            this.IT_ORDER_SCHEDULES_IN = generateScheduleParametersList(this.orderItemMap);
        }

        public void setFormPayment(){
            this.IS_HEADER_IN = addPaymentForm(this.order, this.IS_HEADER_IN);
        }

        public RequestBarterSeeds getResult(){
            setFormPayment();
            return new RequestBarterSeeds(this.IS_HEADER_IN, this.IT_PARTNERS, this.IT_ORDER_SCHEDULES_IN, this.IT_CONDITIONS_IN, this.IT_ITEMS_IN, this.IV_TYPE);
        }
    }

    //product
    private class Request{
        private final String IV_TYPE;
        private final Header IS_HEADER_IN;
        private final List<PartnerParameters> IT_PARTNERS;
        private final List<ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        private final List<ConditionParameters> IT_CONDITIONS_IN;
        private final List<OrderItemParameters> IT_ITEMS_IN;

        public Request(Header IS_HEADER_IN, List<PartnerParameters> IT_PARTNERS, List<ScheduleParameters> IT_ORDER_SCHEDULES_IN,
                        List<ConditionParameters> IT_CONDITIONS_IN, List<OrderItemParameters> IT_ITEMS_IN, String IV_TYPE){
            this.IV_TYPE = IV_TYPE;
            this.IS_HEADER_IN = IS_HEADER_IN;
            this.IT_PARTNERS = IT_PARTNERS;
            this.IT_ORDER_SCHEDULES_IN = IT_ORDER_SCHEDULES_IN;
            this.IT_CONDITIONS_IN = IT_CONDITIONS_IN;
            this.IT_ITEMS_IN = IT_ITEMS_IN;
        }
    }

    private class RequestSeeds{
        private final String IV_TYPE;
        private final HeaderSeeds IS_HEADER_IN;
        private final List<PartnerParameters> IT_PARTNERS;
        private final List<ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        private final List<ConditionParameters> IT_CONDITIONS_IN;
        private final List<OrderItemParametersSeeds> IT_ITEMS_IN;

        public RequestSeeds(HeaderSeeds IS_HEADER_IN, List<PartnerParameters> IT_PARTNERS, List<ScheduleParameters> IT_ORDER_SCHEDULES_IN,
                        List<ConditionParameters> IT_CONDITIONS_IN, List<OrderItemParametersSeeds> IT_ITEMS_IN, String IV_TYPE){
            this.IV_TYPE = IV_TYPE;
            this.IS_HEADER_IN = IS_HEADER_IN;
            this.IT_PARTNERS = IT_PARTNERS;
            this.IT_ORDER_SCHEDULES_IN = IT_ORDER_SCHEDULES_IN;
            this.IT_CONDITIONS_IN = IT_CONDITIONS_IN;
            this.IT_ITEMS_IN = IT_ITEMS_IN;
        }
    }

    private class RequestBarter{
        private final String IV_TYPE;
        private final HeaderBarter IS_HEADER_IN;
        private final List<PartnerParameters> IT_PARTNERS;
        private final List<ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        private final List<ConditionParameters> IT_CONDITIONS_IN;
        private final List<OrderItemParametersBarter> IT_ITEMS_IN;

        public RequestBarter(HeaderBarter IS_HEADER_IN, List<PartnerParameters> IT_PARTNERS, List<ScheduleParameters> IT_ORDER_SCHEDULES_IN,
                        List<ConditionParameters> IT_CONDITIONS_IN, List<OrderItemParametersBarter> IT_ITEMS_IN, String IV_TYPE){
            this.IV_TYPE = IV_TYPE;
            this.IS_HEADER_IN = IS_HEADER_IN;
            this.IT_PARTNERS = IT_PARTNERS;
            this.IT_ORDER_SCHEDULES_IN = IT_ORDER_SCHEDULES_IN;
            this.IT_CONDITIONS_IN = IT_CONDITIONS_IN;
            this.IT_ITEMS_IN = IT_ITEMS_IN;
        }
    }
    
    private class RequestBarterSeeds{
        private final String IV_TYPE;
        private final HeaderBarterSeeds IS_HEADER_IN;
        private final List<PartnerParameters> IT_PARTNERS;
        private final List<ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        private final List<ConditionParameters> IT_CONDITIONS_IN;
        private final List<OrderItemParametersBarter> IT_ITEMS_IN;

        public RequestBarterSeeds(HeaderBarterSeeds IS_HEADER_IN, List<PartnerParameters> IT_PARTNERS, List<ScheduleParameters> IT_ORDER_SCHEDULES_IN,
                        List<ConditionParameters> IT_CONDITIONS_IN, List<OrderItemParametersBarter> IT_ITEMS_IN, String IV_TYPE){
            this.IV_TYPE = IV_TYPE;
            this.IS_HEADER_IN = IS_HEADER_IN;
            this.IT_PARTNERS = IT_PARTNERS;
            this.IT_ORDER_SCHEDULES_IN = IT_ORDER_SCHEDULES_IN;
            this.IT_CONDITIONS_IN = IT_CONDITIONS_IN;
            this.IT_ITEMS_IN = IT_ITEMS_IN;
        } 
    }
   
    
    //product features
    private class Header{
        public String DOC_TYPE; // orderSalesType;
        public String SALES_ORG; //salesOrg;
        public String DISTR_CHAN;// distributionChannel;
        public String DIVISION; // activitySector;
        public String INCOTERMS1;
        public String INCOTERMS2;
        public String PMNTTRMS; // paymentCondition;
        public String PYMT_METH; //forma de pagamento
        public String CT_VALID_F; // Data inicio(Pedido Mãe)
        public String CT_VALID_T; // Data inicio(Pedido Mãe)
        public String ORD_REASON; //orderReason;
        public String PURCH_NO_C; // Customer;
        public String ZZSAFRA; //crop;
        public String ZZCOD_CULTURA; //culture;
        public String ZZPED_CRM; //orderType;
        public String ZZDATA_CARENCIA;
        public String ZZDATA_VENCTO;
        public String ZZDATA_ENTREGA;
        public String REF_DOC;
        public String PRICE_LIST;
        public String PRICE_DATE;
        public String CSTCNDGRP1;
        public String PO_METHOD;
        public String TEXT_ADICIONAL;
        public String TEXT_DANFE;
        public String STWAE;

        public Header(Order order, Delimitadores__c delimiter){
            Map<String, String> statusSeller = new Map<String, String>();
            statusSeller.put('CTV', 'CT');
            statusSeller.put('Franqueado', 'FR');

            String dateF;
            if(delimiter.StartDateOV__c < System.today() && order.IsOrderMother__c){
                dateF = String.valueOf(order.EffectiveDate).replace('-', '');
            }
            else{
                dateF = String.valueOf(delimiter.StartDateOV__c).replace('-', '');
            }
            
            this.DOC_TYPE = getCodeTypeOrder(String.valueOf(order.RecordType.DeveloperName), order.IsOrderMother__c, order.MTO__c); 
            if(this.DOC_TYPE == 'ZVNO' && order.PaymentCondition__r.CashPayment__c) this.DOC_TYPE = 'ZVAB';
            this.SALES_ORG = order.SalesOrg__r.SalesOrganizationCode__c;
            this.DISTR_CHAN =order.DistributionChannel__r.Codigo__c;
            this.DIVISION = order.ActivitySector__r.Codigo__c;
            this.INCOTERMS1 = order.Incoterms__c;
            this.INCOTERMS2 = order.Incoterms2__c;
            this.PMNTTRMS = order.PaymentCondition__r.Code__c;
            this.PYMT_METH = order.PaymentForm__c;
            
            this.CT_VALID_F = order.IsOrderMother__c ? dateF :  '';
            this.CT_VALID_T = order.IsOrderMother__c ? String.valueOf(delimiter.EndDateOV__c).replace('-', '') : '';

            this.PURCH_NO_C = order.CustomerOrderNumber__c;
            this.ORD_REASON = order.OrderReason__c;
            this.ZZSAFRA = order.Crop__r.Code__c;
            this.ZZCOD_CULTURA = order.Culture__r.Codigo__c;
            this.ZZPED_CRM = order.OrderNumber;
            this.ZZDATA_CARENCIA = String.valueOf(delimiter.FinancialBaseDate__c).replace('-', '');
            this.ZZDATA_ENTREGA = String.valueOf(order.ShippingDate__c).replace('-', '');
            this.PRICE_LIST = String.valueOf(order.SalesCondition__r.ExternalId__c).leftPad(2, '0');
            if(order.OrderReference__c != null){
                Order orderReference = [SELECT EffectiveOrderDate__c, EffectiveDate, PaymentDate__c FROM Order WHERE Id =: order.OrderReference__c LIMIT 1];
                if(orderReference != null){
                    this.PRICE_DATE = orderReference.EffectiveOrderDate__c == null ? String.valueOf(orderReference.EffectiveDate).replace('-', '') : String.valueOf(orderReference.EffectiveOrderDate__c).replace('-', '');
                    this.ZZDATA_VENCTO = String.valueOf(orderReference.PaymentDate__c).replace('-', '');
                }
            }
            else{
                this.ZZDATA_VENCTO = String.valueOf(order.PaymentDate__c).replace('-', '');
                this.PRICE_DATE = order.EffectiveOrderDate__c == null ? String.valueOf(order.EffectiveDate).replace('-', '') : String.valueOf(order.EffectiveOrderDate__c).replace('-', '');
            }
            this.REF_DOC = order.OrderReference__c != null ? order.OrderReference__r.CodigoSap__c : '';
            this.CSTCNDGRP1 = statusSeller.get(order.SalesCTV__r.SellerType__c);

            this.PO_METHOD = order.NumeroPedidoApp__c != null ? 'APP' : 'SFOR';
            
            //Add fields to descriptions
            if(order.Description != null) order.Description = order.Description.replace('1n73gr4ção N3sc4r4 5F x 4PP', '');
            this.TEXT_ADICIONAL = order.Description != null ? order.Description : '';
            this.TEXT_DANFE = order.DescriptionBillingSale__c != null ? order.DescriptionBillingSale__c : '';
            this.STWAE = order.Currency__c;
        }
    }

    private class HeaderSeeds{
        public String DOC_TYPE; // orderSalesType;
        public String SALES_ORG; //salesOrg;
        public String DISTR_CHAN;// distributionChannel;
        public String DIVISION; // activitySector;
        public String INCOTERMS1;
        public String INCOTERMS2;
        public String PMNTTRMS; // paymentCondition;
        public String PYMT_METH; //forma de pagamento
        public String CT_VALID_F; // Data inicio(Pedido Mãe)
        public String CT_VALID_T; // Data inicio(Pedido Mãe)
        public String ORD_REASON; //orderReason;
        public String PURCH_NO_C; // Customer;
        public String ZZSAFRA; //crop;
        public String ZZCOD_CULTURA; //culture;
        public String ZZPED_CRM; //orderType;
        public String ZZDATA_CARENCIA;
        public String ZZDATA_VENCTO;
        public String ZZDATA_ENTREGA;
        public String REF_DOC;
        public String PRICE_LIST;
        public String PRICE_DATE;
        public String CSTCNDGRP1;
        public String PO_METHOD;
        public String TEXT_ADICIONAL;
        public String TEXT_DANFE;
        public String STWAE;

        public String ZZDTAPAG0;
        public String ZZVLRPAG0;
        public String ZZITMPAG0;
        public String ZZDTAPAG1;
        public String ZZVLRPAG1;
        public String ZZITMPAG1;
        public String ZZDTAPAG2;
        public String ZZVLRPAG2;
        public String ZZITMPAG2;
        public String ZZDTAPAG3;
        public String ZZVLRPAG3;
        public String ZZITMPAG3;
        public String ZZDTAPAG4;
        public String ZZVLRPAG4;
        public String ZZITMPAG4;
        public String ZZDTAPAG5;
        public String ZZVLRPAG5;
        public String ZZITMPAG5;
        public String ZZDTAPAG6;
        public String ZZVLRPAG6;
        public String ZZITMPAG6;
        public String ZZDTAPAG7;
        public String ZZVLRPAG7;
        public String ZZITMPAG7;
        public String ZZDTAPAG8;
        public String ZZVLRPAG8;
        public String ZZITMPAG8;
        public String ZZDTAPAG9;
        public String ZZVLRPAG9;
        public String ZZITMPAG9;

        public HeaderSeeds(Order order, Boolean hasSeed, Delimitadores__c delimiter){
            Map<String, String> statusSeller = new Map<String, String>();
            statusSeller.put('CTV', 'CT');
            statusSeller.put('Franqueado', 'FR');

            String dateF;
            if(delimiter.StartDateOV__c < System.today() && order.IsOrderMother__c){
                dateF = String.valueOf(order.EffectiveDate).replace('-', '');
            }
            else{
                dateF = String.valueOf(delimiter.StartDateOV__c).replace('-', '');
            }
            
            this.DOC_TYPE = getCodeTypeOrder(String.valueOf(order.RecordType.DeveloperName), order.IsOrderMother__c, order.MTO__c); 
            if(this.DOC_TYPE == 'ZVNO' && order.PaymentCondition__r.CashPayment__c) this.DOC_TYPE = 'ZVAB';
            this.SALES_ORG = order.SalesOrg__r.SalesOrganizationCode__c;
            this.DISTR_CHAN =order.DistributionChannel__r.Codigo__c;
            this.DIVISION = order.ActivitySector__r.Codigo__c;
            this.INCOTERMS1 = order.Incoterms__c;
            this.INCOTERMS2 = order.Incoterms2__c;
            this.PMNTTRMS = order.PaymentCondition__r.Code__c;
            this.PYMT_METH = order.PaymentForm__c;
            
            this.CT_VALID_F = order.IsOrderMother__c ? dateF :  '';
            this.CT_VALID_T = order.IsOrderMother__c ? String.valueOf(delimiter.EndDateOV__c).replace('-', '') : '';

            this.PURCH_NO_C = order.CustomerOrderNumber__c;
            this.ORD_REASON = order.OrderReason__c;
            this.ZZSAFRA = order.Crop__r.Code__c;
            this.ZZCOD_CULTURA = order.Culture__r.Codigo__c;
            this.ZZPED_CRM = order.OrderNumber;
            this.ZZDATA_CARENCIA = String.valueOf(delimiter.FinancialBaseDate__c).replace('-', '');
            this.ZZDATA_ENTREGA = String.valueOf(order.ShippingDate__c).replace('-', '');
            this.PRICE_LIST = String.valueOf(order.SalesCondition__r.ExternalId__c).leftPad(2, '0');

            if(order.OrderReference__c != null){
                Order orderReference = [SELECT EffectiveOrderDate__c, EffectiveDate, PaymentDate__c FROM Order WHERE Id =: order.OrderReference__c LIMIT 1];
                if(orderReference != null){
                    this.PRICE_DATE = orderReference.EffectiveOrderDate__c == null ? String.valueOf(orderReference.EffectiveDate).replace('-', '') : String.valueOf(orderReference.EffectiveOrderDate__c).replace('-', '');
                    if(hasSeed){
                        this.PRICE_DATE = String.valueOf(orderReference.PaymentDate__c).replace('-', '');
                    }
                    this.ZZDATA_VENCTO = String.valueOf(orderReference.PaymentDate__c).replace('-', '');
                }
            }
            else{
                this.PRICE_DATE = order.EffectiveOrderDate__c == null ? String.valueOf(order.EffectiveDate).replace('-', '') : String.valueOf(order.EffectiveOrderDate__c).replace('-', '');
                if(hasSeed){
                    this.PRICE_DATE = String.valueOf(order.PaymentDate__c).replace('-', '');
                }
                this.ZZDATA_VENCTO = String.valueOf(order.PaymentDate__c).replace('-', '');
            }
            this.REF_DOC = order.OrderReference__c != null ? order.OrderReference__r.CodigoSap__c : '';
            this.CSTCNDGRP1 = statusSeller.get(order.SalesCTV__r.SellerType__c);

            this.PO_METHOD = order.NumeroPedidoApp__c != null ? 'APP' : 'SFOR';
            
            //Add fields to descriptions
            if(order.Description != null) order.Description = order.Description.replace('1n73gr4ção N3sc4r4 5F x 4PP', '');
            this.TEXT_ADICIONAL = order.Description != null ? order.Description : '';
            this.TEXT_DANFE = order.DescriptionBillingSale__c != null ? order.DescriptionBillingSale__c : '';
            this.STWAE = order.Currency__c;
        }   
    }

    private class HeaderBarter{
        public String DOC_TYPE; // orderSalesType;
        public String SALES_ORG; //salesOrg;
        public String DISTR_CHAN;// distributionChannel;
        public String DIVISION; // activitySector;
        public String INCOTERMS1;
        public String INCOTERMS2;
        public String PMNTTRMS; // paymentCondition;
        public String PYMT_METH; //forma de pagamento
        public String CT_VALID_F; // Data inicio(Pedido Mãe)
        public String CT_VALID_T; // Data inicio(Pedido Mãe)
        public String ORD_REASON; //orderReason;
        public String PURCH_NO_C; // Customer;
        public String ZZSAFRA; //crop;
        public String ZZCOD_CULTURA; //culture;
        public String ZZPED_CRM; //orderType;
        public String ZZDATA_CARENCIA;
        public String ZZDATA_VENCTO;
        public String ZZDATA_ENTREGA;
        public String REF_DOC;
        public String ZZREFBARTER;
        public String PRICE_LIST;
        public String PRICE_DATE;
        public String CSTCNDGRP1;
        public String PO_METHOD;
        public String TEXT_ADICIONAL;
        public String TEXT_DANFE;
        public String KURSK;
        public String STWAE;
        public String VKGRP;
        public String VKBUR;
        public String EKORG;
        public String EKGRP;
        public String OPTN_VAL;

        public HeaderBarter(Order order, Delimitadores__c delimiter, OrderCommodity__c commodity){
            Map<String, String> statusSeller = new Map<String, String>();
            statusSeller.put('CTV', 'CT');
            statusSeller.put('Franqueado', 'FR');

            String dateF;
            if(delimiter.StartDateOV__c < System.today() && order.IsOrderMother__c){
                dateF = String.valueOf(order.EffectiveDate).replace('-', '');
            }
            else{
                dateF = String.valueOf(delimiter.StartDateOV__c).replace('-', '');
            }
            
            this.DOC_TYPE = getCodeTypeOrder(String.valueOf(order.RecordType.DeveloperName), order.IsOrderMother__c, order.MTO__c); 
            if(this.DOC_TYPE == 'ZVNO' && order.PaymentCondition__r.CashPayment__c) this.DOC_TYPE = 'ZVAB';
            this.SALES_ORG = order.SalesOrg__r.SalesOrganizationCode__c;
            this.DISTR_CHAN =order.DistributionChannel__r.Codigo__c;
            this.DIVISION = order.ActivitySector__r.Codigo__c;
            this.INCOTERMS1 = order.Incoterms__c;
            this.INCOTERMS2 = order.Incoterms2__c;
            this.PMNTTRMS = order.PaymentCondition__r.Code__c;
            this.PYMT_METH = order.PaymentForm__c;
            
            this.CT_VALID_F = String.valueOf(commodity.StartDate__c).replace('-', '');
            this.CT_VALID_T = String.valueOf(commodity.EndDate__c).replace('-', '');

            this.PURCH_NO_C = order.CustomerOrderNumber__c;
            this.ORD_REASON = order.OrderReason__c;
            this.ZZSAFRA = order.Crop__r.Code__c;
            this.ZZCOD_CULTURA = order.Culture__r.Codigo__c;
            this.ZZPED_CRM = order.OrderNumber;
            this.ZZDATA_CARENCIA = String.valueOf(delimiter.FinancialBaseDate__c).replace('-', '');
            this.ZZDATA_ENTREGA = String.valueOf(order.ShippingDate__c).replace('-', '');
            this.PRICE_LIST = String.valueOf(order.SalesCondition__r.ExternalId__c).leftPad(2, '0');
            if(order.OrderReference__c != null){
                Order orderReference = [SELECT EffectiveOrderDate__c, EffectiveDate, PaymentDate__c FROM Order WHERE Id =: order.OrderReference__c LIMIT 1];
                if(orderReference != null){
                    this.PRICE_DATE = orderReference.EffectiveOrderDate__c == null ? String.valueOf(orderReference.EffectiveDate).replace('-', '') : String.valueOf(orderReference.EffectiveOrderDate__c).replace('-', '');
                    this.ZZDATA_VENCTO = String.valueOf(orderReference.PaymentDate__c).replace('-', '');
                }
            }
            else{
                this.ZZDATA_VENCTO = String.valueOf(order.PaymentDate__c).replace('-', '');
                this.PRICE_DATE = order.EffectiveOrderDate__c == null ? String.valueOf(order.EffectiveDate).replace('-', '') : String.valueOf(order.EffectiveOrderDate__c).replace('-', '');
            }
            this.REF_DOC = order.OrderReference__c != null ? order.OrderReference__r.CodigoSap__c : '';
            this.ZZREFBARTER = order.CodigoSap__c;
            this.CSTCNDGRP1 = statusSeller.get(order.SalesCTV__r.SellerType__c);

            this.PO_METHOD = order.NumeroPedidoApp__c != null ? 'APP' : 'SFOR';
            
            //Add fields to descriptions
            if(order.Description != null) order.Description = order.Description.replace('1n73gr4ção N3sc4r4 5F x 4PP', '');
            this.TEXT_ADICIONAL = order.Description != null ? order.Description : '';
            this.TEXT_DANFE = order.DescriptionBillingSale__c != null ? order.DescriptionBillingSale__c : '';

            this.STWAE = order.Currency__c;
            this.VKGRP = order.Company__r.salesOffice__r.Codigo__c;
            this.VKBUR = order.Company__r.salesTeam__r.ExternalId__c;
            this.OPTN_VAL = order.BPStorage__r.ExternalId__c != null ? order.BPStorage__r.ExternalId__c : '';
        }
    }

    private class HeaderBarterSeeds{
        public String DOC_TYPE; // orderSalesType;
        public String SALES_ORG; //salesOrg;
        public String DISTR_CHAN;// distributionChannel;
        public String DIVISION; // activitySector;
        public String INCOTERMS1;
        public String INCOTERMS2;
        public String PMNTTRMS; // paymentCondition;
        public String PYMT_METH; //forma de pagamento
        public String CT_VALID_F; // Data inicio(Pedido Mãe)
        public String CT_VALID_T; // Data inicio(Pedido Mãe)
        public String ORD_REASON; //orderReason;
        public String PURCH_NO_C; // Customer;
        public String ZZSAFRA; //crop;
        public String ZZCOD_CULTURA; //culture;
        public String ZZPED_CRM; //orderType;
        public String ZZDATA_CARENCIA;
        public String ZZDATA_VENCTO;
        public String ZZDATA_ENTREGA;
        public String REF_DOC;
        public String ZZREFBARTER;
        public String PRICE_LIST;
        public String PRICE_DATE;
        public String CSTCNDGRP1;
        public String PO_METHOD;
        public String TEXT_ADICIONAL;
        public String TEXT_DANFE;
        public String KURSK;
        public String STWAE;
        public String VKGRP;
        public String VKBUR;
        public String EKORG;
        public String EKGRP;
        public String OPTN_VAL;

        public String ZZDTAPAG0;
        public String ZZVLRPAG0;
        public String ZZITMPAG0;
        public String ZZDTAPAG1;
        public String ZZVLRPAG1;
        public String ZZITMPAG1;
        public String ZZDTAPAG2;
        public String ZZVLRPAG2;
        public String ZZITMPAG2;
        public String ZZDTAPAG3;
        public String ZZVLRPAG3;
        public String ZZITMPAG3;
        public String ZZDTAPAG4;
        public String ZZVLRPAG4;
        public String ZZITMPAG4;
        public String ZZDTAPAG5;
        public String ZZVLRPAG5;
        public String ZZITMPAG5;
        public String ZZDTAPAG6;
        public String ZZVLRPAG6;
        public String ZZITMPAG6;
        public String ZZDTAPAG7;
        public String ZZVLRPAG7;
        public String ZZITMPAG7;
        public String ZZDTAPAG8;
        public String ZZVLRPAG8;
        public String ZZITMPAG8;
        public String ZZDTAPAG9;
        public String ZZVLRPAG9;
        public String ZZITMPAG9;

        public HeaderBarterSeeds(Order order, Boolean hasSeed, Delimitadores__c delimiter, OrderCommodity__c commodity){
            Map<String, String> statusSeller = new Map<String, String>();
            statusSeller.put('CTV', 'CT');
            statusSeller.put('Franqueado', 'FR');

            String dateF;
            if(delimiter.StartDateOV__c < System.today() && order.IsOrderMother__c){
                dateF = String.valueOf(order.EffectiveDate).replace('-', '');
            }
            else{
                dateF = String.valueOf(delimiter.StartDateOV__c).replace('-', '');
            }
            
            this.DOC_TYPE = getCodeTypeOrder(String.valueOf(order.RecordType.DeveloperName), order.IsOrderMother__c, order.MTO__c); 
            if(this.DOC_TYPE == 'ZVNO' && order.PaymentCondition__r.CashPayment__c) this.DOC_TYPE = 'ZVAB';
            this.SALES_ORG = order.SalesOrg__r.SalesOrganizationCode__c;
            this.DISTR_CHAN =order.DistributionChannel__r.Codigo__c;
            this.DIVISION = order.ActivitySector__r.Codigo__c;
            this.INCOTERMS1 = order.Incoterms__c;
            this.INCOTERMS2 = order.Incoterms2__c;
            this.PMNTTRMS = order.PaymentCondition__r.Code__c;
            this.PYMT_METH = order.PaymentForm__c;
            
            this.CT_VALID_F = String.valueOf(commodity.StartDate__c).replace('-', '');
            this.CT_VALID_T = String.valueOf(commodity.EndDate__c).replace('-', '');

            this.PURCH_NO_C = order.CustomerOrderNumber__c;
            this.ORD_REASON = order.OrderReason__c;
            this.ZZSAFRA = order.Crop__r.Code__c;
            this.ZZCOD_CULTURA = order.Culture__r.Codigo__c;
            this.ZZPED_CRM = order.OrderNumber;
            this.ZZDATA_CARENCIA = String.valueOf(delimiter.FinancialBaseDate__c).replace('-', '');
            this.ZZDATA_ENTREGA = String.valueOf(order.ShippingDate__c).replace('-', '');
            this.PRICE_LIST = String.valueOf(order.SalesCondition__r.ExternalId__c).leftPad(2, '0');
            if(order.OrderReference__c != null){
                Order orderReference = [SELECT EffectiveOrderDate__c, EffectiveDate, PaymentDate__c FROM Order WHERE Id =: order.OrderReference__c LIMIT 1];
                if(orderReference != null){
                    this.PRICE_DATE = orderReference.EffectiveOrderDate__c == null ? String.valueOf(orderReference.EffectiveDate).replace('-', '') : String.valueOf(orderReference.EffectiveOrderDate__c).replace('-', '');
                    if(hasSeed){
                        this.PRICE_DATE = String.valueOf(orderReference.PaymentDate__c).replace('-', '');
                    }
                    this.ZZDATA_VENCTO = String.valueOf(orderReference.PaymentDate__c).replace('-', '');
                }
            }
            else{
                this.PRICE_DATE = order.EffectiveOrderDate__c == null ? String.valueOf(order.EffectiveDate).replace('-', '') : String.valueOf(order.EffectiveOrderDate__c).replace('-', '');
                if(hasSeed){
                    this.PRICE_DATE = String.valueOf(order.PaymentDate__c).replace('-', '');
                }
                this.ZZDATA_VENCTO = String.valueOf(order.PaymentDate__c).replace('-', '');
            }
            this.REF_DOC = order.OrderReference__c != null ? order.OrderReference__r.CodigoSap__c : '';
            this.ZZREFBARTER = order.CodigoSap__c;
            this.CSTCNDGRP1 = statusSeller.get(order.SalesCTV__r.SellerType__c);

            this.PO_METHOD = order.NumeroPedidoApp__c != null ? 'APP' : 'SFOR';
            
            //Add fields to descriptions
            if(order.Description != null) order.Description = order.Description.replace('1n73gr4ção N3sc4r4 5F x 4PP', '');
            this.TEXT_ADICIONAL = order.Description != null ? order.Description : '';
            this.TEXT_DANFE = order.DescriptionBillingSale__c != null ? order.DescriptionBillingSale__c : '';

            this.STWAE = order.Currency__c;
            this.VKGRP = order.Company__r.salesOffice__r.Codigo__c;
            this.VKBUR = order.Company__r.salesTeam__r.ExternalId__c;
            this.OPTN_VAL = order.BPStorage__r.ExternalId__c != null ? order.BPStorage__r.ExternalId__c : '';
        }
    }

    private class PartnerParameters{
        public String PARTN_ROLE;
        public String PARTN_NUMB;

        public PartnerParameters(String partnerCode, String partnerFunc){
            this.PARTN_ROLE = partnerFunc;
            this.PARTN_NUMB = partnerCode;
        }
    }

    private class ScheduleParameters{
        public String ITM_NUMBER;
        public String REQ_QTY;
        public String REQ_DATE;

        public ScheduleParameters(String incrementItem, String quantityItem, String deliveryDate){
            this.ITM_NUMBER = incrementItem;
            this.REQ_QTY = quantityItem;
            this.REQ_DATE = deliveryDate.replace('-', '');
        }
    }

    private class ConditionParameters{
        public String ITM_NUMBER;
        public String COND_TYPE;
        public String COND_VALUE;
        public String TYPE_CURRENCY;

        public ConditionParameters(String incrementItem, String conditionType, String conditionValue, String conditionCurrency){
            this.ITM_NUMBER = incrementItem;
            this.COND_TYPE = conditionType;
            this.COND_VALUE = conditionValue;
            this.TYPE_CURRENCY = conditionCurrency;
        }
    }

    private class OrderItemParameters{
        public String ITM_NUMBER;
        public String MATERIAL;
        public String PLANT;
        public String TARGET_QTY;
        public String REF_DOC_IT;


        public OrderItemParameters(OrderItem orderItem, String numReference, String plant){
            this.ITM_NUMBER = String.valueOf(orderItem.NumeroSap__c).leftPad(6, '0');
            this.MATERIAL = orderItem.Product2.ExternalId__c;
            this.PLANT = plant;
            this.TARGET_QTY =  String.valueOf(orderItem.Quantity);
            this.REF_DOC_IT = numReference != '' ? numReference.leftPad(6, '0') : '';
        }

        public OrderItemParameters(OrderCommodity__c orderCommodity, String plant){
            this.ITM_NUMBER = '10';
            this.MATERIAL = orderCommodity.Product__r.ExternalId__c;
            this.PLANT = plant;
            this.TARGET_QTY =  String.valueOf(orderCommodity.BagQuantity__c);
        }
    }

     private class OrderItemParametersBarter{
        public String ITM_NUMBER;
        public String MATERIAL;
        public String PLANT;
        public String TARGET_QTY;
        public String REF_DOC_IT;
        public String VALOR_MAT;

        public OrderItemParametersBarter(OrderCommodity__c orderCommodity, String plant){
            this.ITM_NUMBER = '000010';
            this.MATERIAL = orderCommodity.Product__r.ExternalId__c;
            this.PLANT = plant;
            this.TARGET_QTY =  String.valueOf(orderCommodity.BagQuantity__c);
            this.VALOR_MAT = String.valueOf(orderCommodity.CommodityPrice__c.setScale(2));
        }
    }

    private class OrderItemParametersSeeds{
        public String ITM_NUMBER;
        public String MATERIAL;
        public String PLANT;
        public String TARGET_QTY;
        public String REF_DOC_IT;
        public String ZZPENEIRA;
        public String ZZCLAS_CAT;


        public OrderItemParametersSeeds(OrderItem orderItem, String numReference, String plant){
            this.ITM_NUMBER = String.valueOf(orderItem.NumeroSap__c).leftPad(6, '0');
            this.MATERIAL = orderItem.Product2.ExternalId__c;
            this.PLANT = plant;
            this.TARGET_QTY =  String.valueOf(orderItem.Quantity);
            this.REF_DOC_IT = numReference != '' ? numReference.leftPad(6, '0') : '';
            this.ZZPENEIRA = orderItem.Sieve__c;
            this.ZZCLAS_CAT = orderItem.Class__c;
        }
    }
    

    private static String getCodeTypeOrder(String typeOrder, Boolean isOrderMother, String apiNameMTO){

        if(apiNameMTO != null) return apiNameMTO;
        
        String orderType = typeOrder + (isOrderMother ? 'PedidoMae' : '');

        RecordTypes__mdt recordType = RecordTypes__mdt.getInstance(orderType);

        if(recordType != null) return recordType.Code__c;
        else return '';
    }

    private static HeaderSeeds addPaymentForm(Order order, HeaderSeeds payload){
        Map<String, String> nameToCodePaymentFormMap = new Map<String, String>();
        nameToCodePaymentFormMap.put('Germoplasma', '01');
        nameToCodePaymentFormMap.put('TSI', '02');
        nameToCodePaymentFormMap.put('Royalties', '03');
        List<FormPayment__c> formPaymentList = [SELECT Amount__c, PaymentDate__c, PaymentType__c FROM FormPayment__c WHERE Order__c =: order.Id LIMIT 10];
        Map<String, Object> mapStringHeader = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payload));
        for(Integer i = 0; i<formPaymentList.size(); i++){
            mapStringHeader.put(('ZZDTAPAG' + i), String.valueOf(formPaymentList[i].PaymentDate__c).replace('-', '')  == null ? '' : String.valueOf(formPaymentList[i].PaymentDate__c).replace('-', ''));
            mapStringHeader.put(('ZZVLRPAG' + i), String.valueOf(formPaymentList[i].Amount__c) == null ? '' : String.valueOf(formPaymentList[i].Amount__c));
            mapStringHeader.put(('ZZITMPAG' + i), String.valueOf(formPaymentList[i].PaymentType__c)  == null ? '' : nameToCodePaymentFormMap.get(String.valueOf(formPaymentList[i].PaymentType__c)));
        }
        String header = JSON.serialize(mapStringHeader);
        payload = (HeaderSeeds)JSON.deserialize(header, HeaderSeeds.class);
        return payload;
    }

    private static HeaderBarterSeeds addPaymentForm(Order order, HeaderBarterSeeds payload){
        Map<String, String> nameToCodePaymentFormMap = new Map<String, String>();
        nameToCodePaymentFormMap.put('Germoplasma', '01');
        nameToCodePaymentFormMap.put('TSI', '02');
        nameToCodePaymentFormMap.put('Royalties', '03');
        List<FormPayment__c> formPaymentList = [SELECT Amount__c, PaymentDate__c, PaymentType__c FROM FormPayment__c WHERE Order__c =: order.Id LIMIT 10];
        Map<String, Object> mapStringHeader = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payload));
        for(Integer i = 0; i<formPaymentList.size(); i++){
            mapStringHeader.put(('ZZDTAPAG' + i), String.valueOf(formPaymentList[i].PaymentDate__c).replace('-', '')  == null ? '' : String.valueOf(formPaymentList[i].PaymentDate__c).replace('-', ''));
            mapStringHeader.put(('ZZVLRPAG' + i), String.valueOf(formPaymentList[i].Amount__c) == null ? '' : String.valueOf(formPaymentList[i].Amount__c));
            mapStringHeader.put(('ZZITMPAG' + i), String.valueOf(formPaymentList[i].PaymentType__c)  == null ? '' : nameToCodePaymentFormMap.get(String.valueOf(formPaymentList[i].PaymentType__c)));
        }
        String header = JSON.serialize(mapStringHeader);
        payload = (HeaderBarterSeeds)JSON.deserialize(header, HeaderBarterSeeds.class);
        return payload;
    }

    private static Decimal isNotation(Decimal value){
        if(value == 0) return 0;
        else return value;
    }

    private static Map<String, String> generateRefMapOrderItem(Order order){
        Map<String, String> referenceItemMotherMap = new Map<String, String>();
        if(order.OrderReference__c != null){
            List<OrderItem> orderItemReferenceList = [SELECT Product2.ExternalId__c, NumeroSap__c FROM OrderItem WHERE OrderId =:  order.OrderReference__c AND (ReasonRefuse__c = null OR ReasonRefuse__c = '')];
            for(OrderItem orderItem : orderItemReferenceList){
                referenceItemMotherMap.put(orderItem.Product2.ExternalId__c, orderItem.NumeroSap__c);
            }
        }

        return referenceItemMotherMap;
    }

    private static Map<Id, OrderItem> generateOrderItemMap(Order order){
        Set<Id> orderItemSetIds = new Set<Id>();
        for(OrderItem orderItem : order.OrderItems){
            orderItemSetIds.add(orderItem.Id);
        }

        Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>([
            SELECT Id, NumeroSap__c, Product2.ExternalId__c, Product2.DistributionCenter__r.Code__c, Quantity, UnitPrice, ListCost__c, DiscountValue__c, FinancialAdditionValue__c, FinancialDiscountValue__c, CommercialAdditionValue__c,
            FinancialAdditionPercent__c, FinancialDiscountPercent__c, CommercialMargin__c, DiscountPercent__c, CommercialAdditionPercent__c, ListPrice__c, Class__c, Sieve__c, Product2.ProductGroup__r.ExternalId__c, Brokerage__c, ComboPromotion__c, 
            ComboPromotion__r.RecordType.Name, ComboPromotion__r.DiscountPercentage__c, AgrogalaxyComboDiscount__c, IndustryComboDiscount__c, Product2.Id
            FROM OrderItem
            WHERE Id IN: orderItemSetIds
        ]);

        return orderItemMap;
    }

    private static Map<Id, Decimal> generateOrderItemComboMap(Map<Id,OrderItem> orderItemMap){
        Map<Id, Decimal> orderItemDiscountMap = new Map<Id, Decimal>();
        try{
            Map<Id, OrderItem> orderItemHasComboAndValueMap = orderItemMap.deepClone();
            Map<String, Id> orderItemProductAndComboKey = new Map<String, Id>();
            Set<Id> comboIds = new Set<Id>();
            Set<Id> orderItemIds = orderItemMap.keySet();
            
            for(Id orderItemId : orderItemIds){
                OrderItem orderItem = orderItemMap.get(orderItemId);
                if(orderItem.ComboPromotion__c == null && orderItem.AgrogalaxyComboDiscount__c == null && orderItem.IndustryComboDiscount__c == null){
                    orderItemHasComboAndValueMap.remove(orderItemId);
                }
            }

            if(orderItemHasComboAndValueMap.size() > 0){
                for(OrderItem ordIt : orderItemHasComboAndValueMap.values()){
                    if(ordIt.ComboPromotion__r.DiscountPercentage__c != null){
                        orderItemDiscountMap.put(ordIt.Id, ordIt.ComboPromotion__r.DiscountPercentage__c);
                    }else{
                        orderItemProductAndComboKey.put(String.valueOf(ordIt.Product2.Id) +'|'+ String.valueOf(ordIt.ComboPromotion__c), ordIt.Id);
                        comboIds.add(ordIt.ComboPromotion__c);
                    }
                }
            }

            if(comboIds.size() > 0){
                List<BenefitProduct__c> benefitProductsList = [SELECT Product__c, DiscountPercentage__c, ComboPromotion__c FROM BenefitProduct__c WHERE ComboPromotion__c IN: comboIds];
                for(BenefitProduct__c product : benefitProductsList){
                    String key = String.valueOf(product.Product__c) +'|'+ String.valueOf(product.ComboPromotion__c);
                    if(orderItemProductAndComboKey.containsKey(key)){
                        orderItemDiscountMap.put(orderItemProductAndComboKey.get(key), product.DiscountPercentage__c);
                    }
                }
            }

        }catch(Exception err){
            System.debug(err.getMessage());
            System.debug(err.getStackTraceString());
        }
        return orderItemDiscountMap;
    }

    private static Boolean hasSeedGroup(Map<Id, OrderItem> orderItemMap){
        Boolean hasSeed = false;

        for(OrderItem orderItem : orderItemMap.values()){
            if('SEM001' == orderItem.Product2.ProductGroup__r.ExternalId__c){
                hasSeed = true;
            }
        }

        return hasSeed;
    }

    private static List<OrderItemParameters> generateOrderItemParameterList(Map<Id, OrderItem> orderItemMap, Map<String, String> referenceItemMotherMap,Order order){
       List<OrderItemParameters> orderItemParametersList = new List<OrderItemParameters>();
       for(OrderItem ordIt : orderItemMap.values()){
            String refItem = referenceItemMotherMap.containsKey(ordIt.Product2.ExternalId__c) ?  referenceItemMotherMap.get(ordIt.Product2.ExternalId__c) : '';
            String plant = order.DistributionCenter__r.Code__c == null ? ( order.CompanyReceiver__r.SupplierCenter__c == null ? order.Company__r.SupplierCenter__c : order.CompanyReceiver__r.SupplierCenter__c) : order.DistributionCenter__r.Code__c;
            orderItemParametersList.add(new OrderItemParameters(ordIt, refItem, plant));
       }

       return orderItemParametersList;
    }

    private static List<OrderItemParametersSeeds> generateOrderItemParameterSeedList(Map<Id, OrderItem> orderItemMap, Map<String, String> referenceItemMotherMap,Order order){
        List<OrderItemParametersSeeds> orderItemParametersList = new List<OrderItemParametersSeeds>();
        for(OrderItem ordIt : orderItemMap.values()){
             String refItem = referenceItemMotherMap.containsKey(ordIt.Product2.ExternalId__c) ?  referenceItemMotherMap.get(ordIt.Product2.ExternalId__c) : '';
             String plant = order.DistributionCenter__r.Code__c == null ? ( order.CompanyReceiver__r.SupplierCenter__c == null ? order.Company__r.SupplierCenter__c : order.CompanyReceiver__r.SupplierCenter__c) : order.DistributionCenter__r.Code__c;
             orderItemParametersList.add(new OrderItemParametersSeeds(ordIt, refItem, plant));
        }
 
        return orderItemParametersList;
     }

     private static List<OrderItemParametersBarter> generateOrderItemParameterBarterList(Order order){
        List<OrderItemParametersBarter> orderItemParametersList = new List<OrderItemParametersBarter>();
        OrderCommodity__c orderCommodity = [SELECT CommodityPrice__c, Product__r.ExternalId__c, BagQuantity__c FROM OrderCommodity__c WHERE Order__c =: order.Id LIMIT 1];
        String plant = order.DistributionCenter__r.Code__c == null ? ( order.CompanyReceiver__r.SupplierCenter__c == null ? order.Company__r.SupplierCenter__c : order.CompanyReceiver__r.SupplierCenter__c) : order.DistributionCenter__r.Code__c;
        orderItemParametersList.add(new OrderItemParametersBarter(orderCommodity, plant));
        return orderItemParametersList;
     }

    private static List<ConditionParameters> generateConditionParametersList(Map<Id, OrderItem> orderItemMap, Map<Id, Decimal> orderItemComboMap, Order order){
        List<ConditionParameters> conditionParametersList = new List<ConditionParameters>();
        String salesCondition = String.valueOf(order.SalesCondition__r.ExternalId__c).leftPad(2, '0');
        for(OrderItem ordIt : orderItemMap.values()){
            if(ordIt.CommercialAdditionPercent__c > 0){
                conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZDEC', (isNotation(ordIt.CommercialAdditionPercent__c)).toPlainString(), ''));
            }else {
                conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZDEC', (isNotation(ordIt.DiscountPercent__c)*-1).toPlainString(), ''));
            }
            conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZMAR', String.valueOf(isNotation(ordIt.CommercialMargin__c)), ''));

            if(orderItemComboMap.containsKey(ordIt.Id)){
                if(ordIt.AgrogalaxyComboDiscount__c > 0){
                    conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZCBA', (isNotation(orderItemComboMap.get(ordIt.Id)*-1)).toPlainString(), ''));
                }else{
                    conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZCBI', (isNotation(orderItemComboMap.get(ordIt.Id)*-1)).toPlainString(), ''));
                }
            }

            if(salesCondition == '99'){
                conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZPR0', String.valueOf(isNotation(ordIt.ListPrice__c)), ''));
            }
        }
 
        return conditionParametersList;
    }

    private static List<ConditionParameters> generateConditionParametersSeedList(Map<Id, OrderItem> orderItemMap, Map<Id, Decimal> orderItemComboMap, Order order){
        List<ConditionParameters> conditionParametersList = new List<ConditionParameters>();
        String salesCondition = String.valueOf(order.SalesCondition__r.ExternalId__c).leftPad(2, '0');
        for(OrderItem ordIt : orderItemMap.values()){
            if(ordIt.CommercialAdditionPercent__c > 0){
                conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZDEC', (isNotation(ordIt.CommercialAdditionPercent__c)).toPlainString(), ''));
            }else {
                conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZDEC', (isNotation(ordIt.DiscountPercent__c)*-1).toPlainString(), ''));
            }
            conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZMAR', String.valueOf(isNotation(ordIt.CommercialMargin__c)), ''));
            conditionParametersList.add(new conditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZCOR', String.valueOf(isNotation(ordIt.Brokerage__c)), ''));
            
            if(orderItemComboMap.containsKey(ordIt.Id)){
                if(ordIt.AgrogalaxyComboDiscount__c > 0){
                    conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZCBA', (isNotation(orderItemComboMap.get(ordIt.Id)*-1)).toPlainString(), ''));
                }else{
                    conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZCBI', (isNotation(orderItemComboMap.get(ordIt.Id)*-1)).toPlainString(), ''));
                }
            }

            if(salesCondition == '99'){
                conditionParametersList.add(new ConditionParameters(ordIt.NumeroSap__c.leftPad(6, '0'), 'ZPR0', String.valueOf(isNotation(ordIt.ListPrice__c)), ''));
            }
        }
        conditionParametersList.add(new ConditionParameters('0', 'ZFRE', String.valueOf(isNotation(order.FreightValue__c)), 'BRL'));
        return conditionParametersList;
    }

    private static List<ConditionParameters> generateConditionParametersBarterList(OrderCommodity__c orderCommodity, Order order){
        List<ConditionParameters> conditionParametersList = new List<ConditionParameters>();
        conditionParametersList.add(new ConditionParameters('000010', 'ACBS', String.valueOf(isNotation(orderCommodity.CommodityPrice__c)), String.valueOf(order.Currency__c)));
        return conditionParametersList;
    }

    private static OrderCommodity__c getCommodityPriceByOrder(Order order){
        return [SELECT CommodityPrice__c, StartDate__c, EndDate__c FROM OrderCommodity__c WHERE Order__c =: order.Id LIMIT 1];
    }


    private static List<ScheduleParameters> generateScheduleParametersList(Map<Id, OrderItem> orderItemMap){
        List<ScheduleParameters> scheduleParametersList = new List<ScheduleParameters>();
        List<ShippingDivison__c> divisonList = [SELECT Id,Name, DeliveryDate__c, Quantity__c, OrderItem__c FROM ShippingDivison__c WHERE OrderItem__c IN: orderItemMap.keySet()];
        Map<Id, List<ShippingDivison__c>> divisionMap = new  Map<Id, List<ShippingDivison__c>>();

        for(ShippingDivison__c sd : divisonList){
            if(!divisionMap.containsKey(sd.OrderItem__c)){
                divisionMap.put(sd.OrderItem__c, new List<ShippingDivison__c>());
            }
            divisionMap.get(sd.OrderItem__c).add(sd);
        }
        
        for(OrderItem ordIt : orderItemMap.values()){
            
            if(!divisionMap.isEmpty())
            {
                if(divisionMap.containsKey(ordIt.Id)){
                    for(ShippingDivison__c sd : divisionMap.get(ordIt.Id)){
                        String numSap = String.valueOf(ordIt.NumeroSap__c).leftPad(6, '0');
                        String quantity = String.valueOf(sd.Quantity__c);
                        String deliveryDate = String.valueOf(sd.DeliveryDate__c);
                        scheduleParametersList.add(new ScheduleParameters(numSap, quantity, deliveryDate));
                    }
                }
            }
        }
 
        return scheduleParametersList;
    }

    

    private static List<PartnerParameters> generatePartnerParametersList(Order order){
        List<PartnerParameters> partnerParametersList = new List<PartnerParameters>();

        partnerParametersList.add(new PartnerParameters(order.Account.ExternalId__c, 'AG'));
        partnerParametersList.add(new PartnerParameters(order.ShippingAccount__r.ExternalId__c, 'RM'));
        partnerParametersList.add(new PartnerParameters(order.SalesCTV__r.CodigoSap__c, order.SalesCTV__r.SellerType__c == 'Franqueado' ? 'ZF' : 'ZC'));

        return partnerParametersList;
    }

    private static String getTypeContract(Order order){
        String typeContract = order.IsOrderMother__c != false ? 'G' : 'C';
        if(order.CodigoSap__c != null && Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosById().get(order.RecordTypeId).getName() == 'Venda Barter'){
            typeContract = 'B';
        }
        return typeContract;
    }

    private static Delimitadores__c getDelimiterByKey(Order order){
        String keyDelimiter = order.Crop__r.Name +' '+ order.SalesCondition__r.ExternalId__c +' '+  order.SalesOrg__r.Name;
        
        Delimitadores__c delimiter = [
            SELECT Id,
                StartDateBilling__c,
                StartDateOV__c,
                EndDateOV__c,
                LimitDateAfterPayment__c,
                EndDateBilling__c,
                FinancialBaseDate__c
            FROM Delimitadores__c
            WHERE Name =: keyDelimiter
        ];

        return delimiter;
    }

     
     
}
