global with sharing class TemplateDataIntegrationFields {
    public interface FieldData {
        List<String> getRequiredFields();
        String getFieldKey();
        String getFieldId();
        SObject serialize(Map<String, Id> lookups);
    }
    
    public interface FieldDataChild {
        List<String> getRequiredFields();
        String getFieldKey();
        String getFieldExternal();
        SObject serialize(Map<String, String> lookups);
        String getParentKey();
    }

    
    global class Pricebook2INData implements FieldData{
        
        //JSON fields Example
        public String name;
        public String codExternal;
        public String typeCondition;
        public String description;
        public String orgVendas;
        public String cultureCode;
        public String listPrice;
        public String cropCode;
        public String accountCode;
        public String accountGroup;
        public String salesOffice;
        public String salesTeam;
        public String salesSector;
        public String initialDate;
        public String endDate;
        public String effectiveDate;
        public String typeCurrency;
        public String numRegisterCondition;
        public Boolean active;
        public String productGroup;
        public List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntries;

        public Pricebook2 serialize(Map<String, Id> lookups){

            
            //Returning Object with Fields.
            return new Pricebook2(
                Name = this.name,
                ExternalId__c =  (String.isEmpty(this.codExternal) || String.isBlank(this.codExternal)) ? null : this.codExternal,
                // RecordTypeId = [select Id from RecordType where sObjectType='Pricebook2' AND Name='Tipo de Condição'][0].Id,
                Description = description,
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.orgVendas) ? lookups.get('SalesOrg__c'+this.orgVendas) : null,
                PriceList__c = listPrice,
                Crop__c = lookups.containsKey('Safra__c'+this.cropCode) ? lookups.get('Safra__c'+this.cropCode) : null,
                Culture__c = lookups.containsKey('Cultura__c'+this.cultureCode) ? lookups.get('Cultura__c'+this.cultureCode) : null,
                Account__c = lookups.containsKey('Account'+this.accountCode) ? lookups.get('Account'+this.accountCode) : null,
                AccountType__c = accountGroup,
                SalesOffice__c = lookups.containsKey('SalesOffice__c'+this.salesOffice) ? lookups.get('SalesOffice__c'+this.salesOffice) : null,
                SalesTeam__c = lookups.containsKey('SalesTeam__c'+this.salesTeam) ? lookups.get('SalesTeam__c'+this.salesTeam) : null,
                SalesSection__c = lookups.containsKey('ActivitySector__c'+this.salesSector) ? lookups.get('ActivitySector__c'+this.salesSector) : null,
                InitialDate__c = Date.valueOf(initialDate),
                EndDate__c = Date.valueOf(endDate),
                EffectiveDate__c = Date.valueOf(effectiveDate),
                Currency__c = typeCurrency,
                ConditionNumberRegister__c = this.numRegisterCondition,
                IsActive = active,
                ProductGroup__c = lookups.containsKey('ProductGroup__c'+this.productGroup) ? lookups.get('ProductGroup__c'+this.productGroup) : null
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{
                'ExternalId__c',
                'SalesOrg__c',
                'PriceList__c',
                'InitialDate__c',
                'EndDate__c',
                'Currency__c',
                'EffectiveDate__c',
                'ProductGroup__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class PricebookEntryINData implements FieldDataChild{
        
        //JSON fields Example
        public String pricebook2Id;
        public String productCode;
        public Decimal unitPrice;

        public PricebookEntry serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new PricebookEntry(
                UnitPrice      = unitPrice,
                CostPrice__c  =  unitPrice,
                IsActive = true,
                Code__c = this.Pricebook2Id + '|' + this.ProductCode,
                Pricebook2Id  = lookups.containsKey('Pricebook2'+this.pricebook2Id) ? lookups.get('Pricebook2'+this.pricebook2Id) : null,
                Product2Id  = lookups.containsKey('Product2'+this.productCode) ? lookups.get('Product2'+this.productCode) : null
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{
                'Product2Id',
                'UnitPrice'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'Id';
        }

        public String getFieldExternal(){
            return 'Code__c';
        }
        
        public String getParentKey(){
            return 'Pricebook2Id';
        }
    }

    global class JurosDescontoAntecipaoINData implements FieldData{
        //JSON fields Example
       
        public String codExternal;
        public String cropCode;
        public String cultureCode;
        public String orgVendas;
        public String salesOffice;
        public String salesTeam;
        public String productGroup;
        public String accountGroup;
        public String initialDate;
        public String endDate;
        public String product;
        public String center;
        public String numRegisterCondition;
        public Integer percentage;
        public String typeCondition;
        public String priority;

        public JurosDescontoAntecipao__c serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new JurosDescontoAntecipao__c(
               
                ExternalId__c = this.codExternal,
                harvest__c = lookups.containsKey('Safra__c'+this.cropCode) ? lookups.get('Safra__c'+this.cropCode) : null,
                Culture__c = lookups.containsKey('Cultura__c'+this.cultureCode) ? lookups.get('Cultura__c'+this.cultureCode) : null,
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.orgVendas) ? lookups.get('SalesOrg__c'+this.orgVendas) : null,
                SalesOffice__c = lookups.containsKey('SalesOffice__c'+this.salesOffice) ? lookups.get('SalesOffice__c'+this.salesOffice) : null,
                SalesTeam__c = lookups.containsKey('SalesTeam__c'+this.salesTeam) ? lookups.get('SalesTeam__c'+this.salesTeam) : null,
                ProductGroup__c = lookups.containsKey('ProductGroup__c'+this.productGroup) ? lookups.get('ProductGroup__c'+this.productGroup) : null,
                AccountType__c = this.accountGroup,
                StartDate__c = Date.valueOf(initialDate),
                EndDate__c = Date.valueOf(endDate),
                Product__c = lookups.containsKey('Product2'+this.product) ? lookups.get('Product2'+this.product) : null,
                Percentage__c = this.percentage,
                ConditionType__c = typeCondition == 'ZJUR' ? 'ZJUR - Juros' : 'ZDAN - Desconto de antecipação' ,
                PriorityLevel__c = this.priority,
                DistributionCenter__c = lookups.containsKey('DistributionCenter__c'+this.center) ? lookups.get('DistributionCenter__c'+this.center) : null,
                ConditionNumberRegister__c = this.numRegisterCondition
               
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{
                'ExternalId__c',
                'harvest__c',
                'Culture__c',
                'SalesOrg__c',
                'SalesOffice__c',
                'SalesTeam__c',
                'ProductGroup__c',
                'AccountType__c',
                'StartDate__c',
                'EndDate__c',
                'Product__c',
                'Percentage__c',
                'ConditionType__c',
                'PriorityLevel__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class GenericINData{
        public String name;
        public String codExternal;
        public String typeCondition;
        public String description;
        public String orgVendas;
        public String cultureCode;
        public String listPrice;
        public String cropCode;
        public String accountCode;
        public String accountGroup;
        public String salesOffice;
        public String salesTeam;
        public String salesSector;
        public String initialDate;
        public String endDate;
        public String effectiveDate;
        public String typeCurrency;
        public Boolean active;
        public String productGroup;
        public String priority;
        public String center;
        public String numRegisterCondition;
        public String percentage;
        public String product;
        public List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntries;
    }


    // novas implantações, qualquer erro é daqui pra baixo 
    global class OrderINData implements FieldData{
        
        public String account;
        public String shippingAccount;
        public String codPricebook;
        public String type;
        public Date   paymentDate;
        public String codOrder;
        public Date   effectiveDate;
        public String codCrop;
        public String codCulture;
        public String paymentForm;
        public String codSalesOrg;
        public String codSalesActivity;
        public String codSalesCTV;
        public String codCurrency;
        public String statusSAP;
        public String incoterms1;
        public String incoterms2;
        public String observation;
        public String observationBillingSale;
        public String orderMother;
        public String totalAmount;
        // public List<TemplateDataIntegrationFields.PartnerParameters> partner;
        public List<TemplateDataIntegrationFields.OrderItemINData> orderItems;

        public Order serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new order(
                AccountId                 = null,
                ShippingAccount__c        = null,
                Pricebook2Id              = null,
                Type                      = null,
                PaymentDate__c            = null,
                CustomerOrderNumber__c    = null,
                CodigoSap__c              = null,
                EffectiveDate             = null,
                Crop__c                   = null,
                Culture__c                = null,
                PaymentForm__c            = null,
                SalesOrg__c               = null,
                ActivitySector__c         = null,
                SalesCTV__c               = null,
                Currency__c               = null,
                StatusSAP__c              = null,
                StatusSF__c               = null,
                Incoterms__c              = null,
                Incoterms2__c             = null,
                Description               = null,
                DescriptionBillingSale__c = null,
                OrderReference__c         = null,
                FinalTotalValue__c        = null
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'AccountId',
                'EXTERNALID__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'EXTERNALID__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    //OrderItem input structure -> Implementing FieldDataChild
    global class OrderItemINData implements FieldDataChild{
        
        public String  codExternalOrder;
        public String  itemCode;
        public String  material;
        public Decimal quantity;
        public String  codCenter;
        public String  billedQuantity;
        public String  status;
        public String  unitMeasure;
        public String  reasonRefuse;
        public String  percentageComission;
        public String  percentageDiscount;
        public String  comissionValue;
        public String  comercialValue;
        public String  discountValue;
        public List<TemplateDataIntegrationFields.ScheduleParameters> schedules;

        public OrderItem serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new OrderItem(
                OrderId                      = null,
                Product2Id                   = null,
                Quantity                     = 0,
                AmountUsed__c                = 0,
                Status__c                    = null,
                UnitMeasure__c               = null,
                ReasonRefuse__c              = null,
                DiscountPercent__c           = 0,
                PercentComission__c          = 0,
                ComissionValue__c            = 0,
                CommercialAdditionPercent__c = 0,
                DiscountValue__c             = 0,
                PricebookEntryId             = null
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'OrderId',
                'Product2Id',
                'Quantity'
            };
        }

        //Key field
        public String getFieldKey(){
            return 'Id';
        }

        //ExternalId field
        public String getFieldExternal(){
            return 'EXTERNALID__c';
        }
        
        //Parent ExternalId field
        public String getParentKey(){
            return 'OrderId';
        }
    }

    global class PartnerParameters{
        public String partnerFunc;
        public String partnerCode;

        public PartnerParameters(String partnerFunc, String partnerCode){
            this.partnerFunc = partnerFunc;
            this.partnerCode = partnerCode;
        }
    }
    
    global class ScheduleParameters{
        public Date deliveryDate;
        public String codSchedule;
        public Decimal quantity;
        public Decimal confirmedQuantity;
        public String itemCode;

        public ScheduleParameters(Date deliveryDate, String codSchedule, Decimal quantity, Decimal confirmedQuantity, String itemCode){
            this.deliveryDate = deliveryDate;
            this.codSchedule = codSchedule;
            this.quantity = quantity;
            this.confirmedQuantity = confirmedQuantity;
            this.itemCode = itemCode;
        }
        
        public ShippingDivison__c serialize(ScheduleParameters sP, Id orderItem){
            return new ShippingDivison__c(
                DeliveryDate__c      = sP.deliveryDate,
                ExternalId__c        = sP.codSchedule,
                OrderItem__c         = orderItem,
                Quantity__c          = sP.quantity,
                ConfirmedQuantity__c = sP.confirmedQuantity
            );
        }
    }

    global virtual class Response {
        public String  idSalesforce;
        public String  externalCode;
        public String  errorMessage;
        public Boolean status;
        public String  sObjectType;
        
        public void success(String idSalesforce, String externalCode, String sObjectType){
            this.idSalesforce = idSalesforce;
            this.externalCode = externalCode;
            this.status       = true;
            this.SObjectType  = sObjectType;
        }
        
        public void error(String externalCode, String errorMessage, String sObjectType){
            this.externalCode = externalCode;
            this.status       = false;
            this.errorMessage = errorMessage;
            this.SObjectType  = sObjectType;
        }

        public void error(String idSalesforce, String externalCode, String errorMessage, String sObjectType){
            this.idSalesforce = idSalesforce;
            this.externalCode = externalCode;
            this.status       = false;
            this.errorMessage = errorMessage;
            this.SObjectType  = sObjectType;
        }
    }
    
    //Response structure for integration of parent and child objects
    global class ResponseParent extends Response {
        public List<TemplateDataIntegrationFields.Response> items;
    }
}
