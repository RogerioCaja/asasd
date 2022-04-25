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

    global class IntegrationINOrder implements FieldData{

        public String status;
        public String pricebook2Id;
        public String Type;
        public String ShippingAccount;
        public String PaymentAccount;
        public Date PaymentDate;
        public String CustomerOrderNumber;
        public Date EffectiveDate;
        public String Crop;
        public String Culture;
        public String PaymentForm;
        public String SalesOrg;
        public String DistributionChannel;
        public String ActivitySector;
        public String Currency;
        public String SalesCTV;
        public String Incoterms;
        public String Incoterms2;
        public String Description;
        public String PaymentCondition;
        public Date ShippingDate;
        public String DescriptionBillingSale;
        public String OrderReference;

        public Order serialize(Map<String, Id> lookups){

            return new Order(

                ExternalId__c = this.codExternal,
                Pricebook2Id = lookups.containsKey('Pricebook2Id'+this.pricebook2Id) ? lookups.get('Pricebook2Id'+this.pricebook2Id) : null,
                ShippingAccount__c = lookups.containsKey('ShippingAccount__c'+this.shippingAccount) ? lookups.get('ShippingAccount__c'+this.shippingAccount) : null,
                AccountId = lookups.containsKey('AccountId'+this.paymentAccount) ? lookups.get('AccountId'+this.paymentAccount) : null,
                Crop__c = lookups.containsKey('Crop__c'+this.cropCode) ? lookups.get('Crop__c'+this.cropCode) : null,
                Culture__c = lookups.containsKey('Culture__c'+this.cultureCode) ? lookups.get('Culture__c'+this.cultureCode) : null,
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.salesOrg) ? lookups.get('SalesOrg__c'+this.salesOrg) : null,
                SalesCTV__c = lookups.containsKey('SalesCTV__c'+this.salesCTV) ? lookups.get('SalesCTV__c'+this.salesCTV) : null,
                PaymentCondition__c = lookups.containsKey('PaymentCondition__c'+this.paymentCondition) ? lookups.get('PaymentCondition__c'+this.paymentCondition) : null,
                PaymentDate__c = Date.valueOf(paymentDate),
                EffectiveDate = Date.valueOf(effectiveDate),
                ShippingDate__c = Date.valueOf(ShippingDate),
                Status = this.status,
                Type = this.type,
                CustomerOrderNumber__c = this.orderNumber,
                PaymentForm__c = this.paymentForm,
                DistributionChannel__c = this.distributionChannel,
                ActivitySector__c = this.activitySector,
                Currency__c = this.currency,
                Incoterms__c = this.incoterms,
                Incoterms2__c = this.incoterms,
                Description = this.description,
                DescriptionBillingSale__c = this.descriptionBillingSale,
                OrderReference__c = this.OrderReference
            );
        }

        public List<String> getRequiredFields(){
            return new List<String>{
                'ExternalId__c',
                'Currency__c',
                'PaymentCondition__c',
                'PaymentDate__c',
                'PaymentForm__c',
                'CustomerOrderNumber__c'
     
            };
        }
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        public String getFieldId() {
            return 'Id';
        }
    }
}