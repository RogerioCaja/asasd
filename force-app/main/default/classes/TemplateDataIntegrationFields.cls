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
        public Boolean active;
        public String productFamily;
        public List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntries;

        public Pricebook2 serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new Pricebook2(
                Name = this.name,
                ExternalId__c = codExternal,
                RecordTypeId = 	'0127e0000003FkIAAU',
                Description = description,
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.orgVendas) ? lookups.get('SalesOrg__c'+this.orgVendas) : null,
                PriceList__c = listPrice,
                Crop__c = lookups.containsKey('Crop__c'+this.cropCode) ? lookups.get('Crop__c'+this.cropCode) : null,
                Culture__c = lookups.containsKey('Culture__c'+this.cultureCode) ? lookups.get('Culture__c'+this.cultureCode) : null,
                Account__c = lookups.containsKey('Account__c'+this.accountCode) ? lookups.get('Account__c'+this.accountCode) : null,
                AccountType__c = accountGroup,
                SalesOffice__c = lookups.containsKey('SalesOffice__c'+this.salesOffice) ? lookups.get('SalesOffice__c'+this.salesOffice) : null,
                SalesTeam__c = lookups.containsKey('SalesTeam__c'+this.salesTeam) ? lookups.get('SalesTeam__c'+this.salesTeam) : null,
                SalesSection__c = lookups.containsKey('SalesSection__c'+this.salesSector) ? lookups.get('SalesSection__c'+this.salesSector) : null,
                InitialDate__c = Date.valueOf(initialDate),
                EndDate__c = Date.valueOf(endDate),
                EffectiveDate__c = Date.valueOf(effectiveDate),
                Currency__c = typeCurrency,
                IsActive = active,
                ProductFamily__c = lookups.containsKey('ProductFamily__c'+this.productFamily) ? lookups.get('ProductFamily__c'+this.productFamily) : null
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{
                'ExternalId__c',
                // 'RecordTypeId',
                'SalesOrg__c',
                'PriceList__c',
                'InitialDate__c',
                'EndDate__c',
                'Currency__c',
                'EffectiveDate__c',
                'ProductFamily__c'
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
                Product2Id  = lookups.containsKey('Product2Id'+this.productCode) ? lookups.get('Product2Id'+this.productCode) : null
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{
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
