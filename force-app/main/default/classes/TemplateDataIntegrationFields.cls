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
    
    public abstract class ConditionsPrices implements FieldData{
        public String codExternal;
        public String typeCondition;
        public String cultureCode;
        public String orgVendas;
        public String salesOffice;
        public String salesTeam;
        public String productGroup;
        public String accountGroup;
        public String initialDate;
        public String endDate;
        public String numRegisterCondition;
    }

    global class Pricebook2INData extends ConditionsPrices{
        
        //JSON fields Example
        public String  name;
        public String  description;
        public String  listPrice;
        public String  cropCode;
        public String  accountCode;
        public String  salesSector;
        public String  effectiveDate;
        public String  typeCurrency;
        public Boolean active;
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
                'Name',
                'ExternalId__c'
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

    global class JurosDescontoAntecipaoINData extends ConditionsPrices{
       
        public String  cropCode;
        public String  product;
        public String  center;
        public Integer percentage;
        public String  priority;

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

global class AccountINData implements FieldData{
        
    //JSON fields Example
    public String CodigoExterno;
    public String RuaEntrega;
    public String CidadeEntrega;
    public String EstadoEntrega;
    public String PaisEntrega;
    public String CEPEntrega;
    public String RuaCobranca;
    public String CidadeCobranca;
    public String EstadoCobranca;
    public String PaisCobranca;
    public String CEPCobranca;
    public String ContaPai;
    public String CNPJ;
    public String CPF;
    public String InscricaoMunicipal;
    public String InscricaoEstadual;
    public String Email;
    public String Telefone;
    public String Status;
    public List<TemplateDataIntegrationFields.LimiteCreditoINData> creditoEntries;
    public List<TemplateDataIntegrationFields.CompanyINData> companyEntries;
    
    public Account serialize(Map<String, Id> lookups){

        Account ac = new Account(
            ExternalId__c = this.CodigoExterno,
            ParentId = lookups.containsKey('Account__c'+this.ContaPai) ? lookups.get('Account__c'+this.ContaPai) : null,
            CNPJ__c = this.CNPJ,
            CPF__c = this.CPF,
            MunicipalRegistration__c = this.InscricaoMunicipal,
            StateRegistration__c = this.InscricaoEstadual,
            Email__c = this.Email,
            Phone = this.Telefone,
            Status__c = this.Status
        );
        
        ac.ShippingStreet = this.RuaEntrega;
        ac.ShippingCity = this.CidadeEntrega;
        ac.ShippingState = this.EstadoEntrega;
        ac.ShippingCountry = this.PaisEntrega;
        ac.ShippingPostalCode = this.CEPEntrega;
        ac.BillingStreet = this.RuaCobranca;
        ac.BillingCity = this.CidadeCobranca;
        ac.BillingState = this.EstadoCobranca;
        ac.BillingCountry = this.PaisCobranca;
        ac.BillingPostalCode = this.CEPCobranca;

        //Returning Object with Fields.
        return ac;
    }
    
    //Required fields for integration
    public List<String> getRequiredFields(){
        return new List<String>{
            'ExternalId__c'
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

global class LimiteCreditoINData implements FieldDataChild{
    
    //JSON fields Example
    public String accountId;
    public String ExternalId;
    public String OrganizacaoVendas;
    public Decimal Valor;
    public String Bloqueado;
    public String Cultura;
    public String Garantia;
    public Decimal Saldo;
    public Date DataConcessao;
    public Date DataVencimento;
    public Date DataManutencao;
    public Decimal Safra;

    public LimiteCredito__c serialize(Map<String, Id> lookups){

        //Returning Object with Fields.
        return new LimiteCredito__c(
            Account__c = lookups.containsKey('Account__c'+this.accountId) ? lookups.get('Account__c'+this.accountId) : null,
            OrganizacaoVendas__c = lookups.containsKey('SalesOrg__c'+this.OrganizacaoVendas) ? lookups.get('SalesOrg__c'+this.OrganizacaoVendas) : null,
            Culture__c = lookups.containsKey('Culture__c'+this.Cultura) ? lookups.get('Culture__c'+this.Cultura) : null,
            Guarantee__c = this.Garantia,
            LimitValue__c = this.Valor,
            BlockedCredit__c = this.Bloqueado,
            LimitBalance__c = this.Saldo,
            ConcessionDate__c = this.DataConcessao,
            EndDate__c = this.DataVencimento,
            MaintenanceDate__c = this.DataManutencao,
            Safra__c = lookups.containsKey('Safra__c'+String.valueOf(this.Safra)) ? lookups.get('Safra__c'+String.valueOf(this.Safra)) : null,
            ExternalId__c = this.accountId + this.Safra + this.Cultura + this.Garantia 
        );
    }
    
    //Required fields for integration
    public List<String> getRequiredFields(){
        return new List<String>{
            'accountId'
        };
    }

    //ExternalId field
    public String getFieldKey(){
        return 'Id';
    }

    public String getFieldExternal(){
        return 'ExternalId__c';
    }
    
    public String getParentKey(){
        return 'AccountId';
    }
}

global class CompanyINData implements FieldDataChild{
    
    //JSON fields Example
    public String accountId;
    public String ExternalId;
    public String OrganizacaoVendas;
    public String SetorAtividade;
    public String CanalDistribuicao;
    public String DomicilioFiscal;
    public String EscritorioVendas;
    public String EquipeVendas;
    public String GrupoClientes;
    public Boolean Bloqueado;
    public String Status;
    public String SetorVendas;
    public Company__c serialize(Map<String, Id> lookups){

        //Returning Object with Fields.
        return new Company__c(
            Conta__c = lookups.containsKey('Account__c'+this.accountId) ? lookups.get('Account__c'+this.accountId) : null,
            SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.OrganizacaoVendas) ? lookups.get('SalesOrg__c'+this.OrganizacaoVendas) : null,
            ActivitySector__c = lookups.containsKey('ActivitySector__c'+this.SetorAtividade) ? lookups.get('ActivitySector__c'+this.SetorAtividade) : null,
            DistributionChannel__c = lookups.containsKey('DistributionChannel__c'+this.CanalDistribuicao) ? lookups.get('DistributionChannel__c'+this.CanalDistribuicao) : null,
            FiscalDomicile__c = this.DomicilioFiscal,
            SalesOffice__c = lookups.containsKey('SalesOffice__c'+this.EscritorioVendas) ? lookups.get('SalesOffice__c'+this.EscritorioVendas) : null,
            SalesTeam__c = lookups.containsKey('SalesTeam__c'+this.EquipeVendas) ? lookups.get('SalesTeam__c'+this.EquipeVendas) : null,
            ClientGroup__c = this.GrupoClientes,
            Blocked__c = this.Bloqueado,
            Status__c = this.Status,
            SalesSector__c = this.SetorVendas,
            ExternalId__c = this.accountId + this.OrganizacaoVendas + this.SetorAtividade + this.CanalDistribuicao + this.EscritorioVendas + this.EquipeVendas
        );
    }
    
    //Required fields for integration
    public List<String> getRequiredFields(){
        return new List<String>{
            'accountId'
        };
    }

    //ExternalId field
    public String getFieldKey(){
        return 'Id';
    }

    public String getFieldExternal(){
        return 'accountId';
    }
    
    public String getParentKey(){
        return 'AccountId';
    }
}

    global class GenericINData extends ConditionsPrices{
        public String  name;
        public String  description;
        public String  listPrice;
        public String  cropCode;
        public String  accountCode;
        public String  salesSector;
        public String  effectiveDate;
        public String  typeCurrency;
        public Boolean active;
        public String  priority;
        public String  center;
        public String  percentage;
        public String  product;
        public List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntries;

        public PricebookEntry serialize(Map<String, Id> lookups){
            //Returning Object with Fields.
            return new PricebookEntry(
            );
        }

         //Required fields for integration
         public List<String> getRequiredFields(){
            return new List<String>{
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return '';
        }
        
        //Id field
        public String getFieldId() {
            return '';
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
