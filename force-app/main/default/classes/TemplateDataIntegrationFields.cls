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

    global class JurosDescontoAntecipaoINData implements FieldData{
        public String table;
        public String typeCondition;
        public String product;
        public String productGroup;
        public String unitPrice;
        public String center;

        public String salesCondition;

        public String cropCode;
        public String cultureCode;
        public String accountCode;
        public String accountGroup;

        public String orgVendas;
        public String salesOffice;
        public String salesTeam;

        public String initialDate;
        public String endDate;

        public String typeCurrency;
        public String externalId;
        public String unitMeasurement;
        // Chave(ExternalId__c): (orgVendas) | (safra) | (moeda) | (Material)(Lista de preço) | (Grupo de produtos)(Escritório de vendas)(Equipe de Vendas)(Cultura)(Segmento do Cliente)(Cliente) | (Material)(Equipe de vendas) | (Material)
        public JurosDescontoAntecipao__c serialize(Map<String, Id> lookups){
            return new JurosDescontoAntecipao__c(
                AccountType__c = this.accountGroup,
                ConditionType__c = this.typeCondition == 'ZPR0' ? 'Preço' : this.typeCondition == 'ZDAN'? 'Desconto' : 'Juros',
                RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName =: this.typeCondition][0].Id,
                Culture__c = lookups.containsKey('Cultura__c'+this.cultureCode) ? lookups.get('Cultura__c'+this.cultureCode) : null,
                DistributionCenter__c =lookups.containsKey('DistributionCenter__c'+this.center) ? lookups.get('DistributionCenter__c'+this.center) : null,
                EndDate__c = this.endDate != null ? Date.valueOf(this.endDate) : null,
                // ExternalId__c = this.orgVendas + this.cropCode  + this.typeCurrency +  this.product + this.salesCondition  + this.productGroup + this.salesOffice  + this.cultureCode + this.accountGroup +  this.accountCode  + this.product + this.salesTeam  + this.product, // A estrutura está acima ^^^^
                ExternalId__c = this.externalId,
                harvest__c = lookups.containsKey('Safra__c'+this.cropCode) ? lookups.get('Safra__c'+this.cropCode) : null,
                Product__c = lookups.containsKey('Product2'+this.product) ? lookups.get('Product2'+this.product) : null,
                ProductGroup__c = lookups.containsKey('ProductGroup__c'+this.productGroup) ? lookups.get('ProductGroup__c'+this.productGroup) : null,
                SalesOffice__c = lookups.containsKey('SalesOffice__c'+this.salesOffice) ? lookups.get('SalesOffice__c'+this.salesOffice) : null,
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.orgVendas) ? lookups.get('SalesOrg__c'+this.orgVendas) : null,
                SalesTeam__c = lookups.containsKey('SalesTeam__c'+this.salesTeam) ? lookups.get('SalesTeam__c'+this.salesTeam) : null,
                StartDate__c = this.initialDate != null ? Date.valueOf(this.initialDate) : null,
                Account__c = lookups.containsKey('Account'+this.accountCode) ? lookups.get('Account'+this.accountCode) : null,
                Currency__c = this.typeCurrency,
                SalesCondition__c = lookups.containsKey('SalesCondition__c'+this.salesCondition) ? lookups.get('SalesCondition__c'+this.salesCondition) : null, 
                ProductMultiplier__c = 1,
                UnitMeasurement__c = this.unitMeasurement != null ? this.unitMeasurement : null,
                UnitPrice__c = (this.typeCurrency == 'BRL' || this.typeCurrency == 'USD') ? Decimal.valueOf(this.unitPrice) : null,
                Percentage__c = this.typeCurrency == '%' ? Decimal.valueOf(this.unitPrice) : null
            );
            
        }
    
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{

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
    
    global class Product2INData implements FieldData {
        public String ProductName;
        public String TextoBreveMaterial;
        public String UnidadeMedida;
        public String UnidadeMedidaRemessa;
        public String Status;
        public String TipoMaterial;
        public String GrupoMercadoria;
        public String SubgrupoMercadoria;
        public String MarcadoEliminacao;
        public String UnidadePeso;
        public String CodigoControle;
        public String ClasseAvaliacao;
        public String OrigemMaterial;
        public String Marca;
        public String NCM;
        public String GrupoQuimico;
        public String IngredienteAtivo;
        public String NumeroRegistro;
        public Decimal PesoBruto;
        //public List<TemplateDataIntegrationFields.ProductINData> product2Entries;

        public Product2 serialize(Map<String, Id> lookups){


            //Returning Object with Fields
            return new Product2(
                Name = this.ProductName,
                Description = this.TextoBreveMaterial,
                UnidadeMedida__c = this.UnidadeMedida,
                GrossWeightUnitOfMeasure__c = this.UnidadeMedidaRemessa,
                SalesOrgStatus__c = this.Status,
                ProductType__c = this.TipoMaterial,
                ProductGroup__c = lookups.containsKey('ProductGroup__c'+this.GrupoMercadoria) ? lookups.get('ProductGroup__c'+this.GrupoMercadoria) : null,
                ProductSubgroup__c = lookups.containsKey('ProductSubgroup__c'+this.SubgrupoMercadoria) ? lookups.get('ProductSubgroup__c'+this.SubgrupoMercadoria) : null,
                MarcadoEliminacao__c = this.MarcadoEliminacao,
                QuantityUnitOfMeasure = this.UnidadePeso,
                ExternalId__c = this.CodigoControle,
                ClasseAvaliacao__c = this.ClasseAvaliacao,
                OrigemMaterial__c = this.OrigemMaterial,
                Brand__c = this.Marca,
                NCM__c = this.NCM,
                GrupoQuimico__c = this.GrupoQuimico,
                PrincipleActive__c = this.IngredienteAtivo, 
                NumeroRegistro__c = this.NumeroRegistro,
                GrossWeight__c = this.PesoBruto

            );
        }
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{
                //'ExternalId__c'
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
    global class IntegrationOrderINData implements FieldData{

        public String status;
        public String pricebook2Id;
        public String CodigoSap;
        public String codOrder;
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
        public String CurrencyOrder;
        public String SalesCTV;
        public String Incoterms;
        public String Incoterms2;
        public String Description;
        public String PaymentCondition;
        public Date ShippingDate;
        public String DescriptionBillingSale;
        public String OrderReference;
        public String orderMother;
        public List<TemplateDataIntegrationFields.OrderItemINData> orderItems;
        public List<TemplateDataIntegrationFields.ShippingDivisonData> shippingDivison;
        public Order serialize(Map<String, Id> lookups){

            return new Order(

                CodigoSap__c = this.CodigoSap,
                Pricebook2Id = lookups.containsKey('Pricebook2Id'+this.pricebook2Id) ? lookups.get('Pricebook2Id'+this.pricebook2Id) : null,
                ShippingAccount__c = lookups.containsKey('ShippingAccount__c'+this.shippingAccount) ? lookups.get('ShippingAccount__c'+this.shippingAccount) : null,
                AccountId = lookups.containsKey('AccountId'+this.paymentAccount) ? lookups.get('AccountId'+this.paymentAccount) : null,
                Crop__c = lookups.containsKey('Crop__c'+this.crop) ? lookups.get('Crop__c'+this.crop) : null,
                Culture__c = lookups.containsKey('Culture__c'+this.culture) ? lookups.get('Culture__c'+this.culture) : null,
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.salesOrg) ? lookups.get('SalesOrg__c'+this.salesOrg) : null,
                SalesCTV__c = lookups.containsKey('SalesCTV__c'+this.salesCTV) ? lookups.get('SalesCTV__c'+this.salesCTV) : null,
                PaymentCondition__c = lookups.containsKey('PaymentCondition__c'+this.paymentCondition) ? lookups.get('PaymentCondition__c'+this.paymentCondition) : null,
                PaymentDate__c = Date.valueOf(paymentDate),
                EffectiveDate = Date.valueOf(effectiveDate),
                ShippingDate__c = Date.valueOf(ShippingDate),
                Status = this.status,
                Type = this.type,
                CustomerOrderNumber__c = this.customerOrderNumber,
                PaymentForm__c = this.paymentForm,
                DistributionChannel__c = this.distributionChannel,
                ActivitySector__c = this.activitySector,
                Currency__c = this.CurrencyOrder,
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

    global class OrderItemINData implements FieldDataChild{
        //JSON fields Example
        public String orderItemCode;
        public String orderExternalId;
        public String material;
        public Decimal quantidade;
        //public String centro;
        public String unidadeMedida;
        public Decimal listaPreco;
        public Decimal porcentagemComissao;
        public Decimal porcentagemDesconto;
        public Decimal comissaoValor;
        public Decimal margemComercial;
        public Decimal descontoValor;
        public Decimal valorTotal;
        public Decimal porcentagemDescontoFin;
        public Decimal valorDescontoFin;
        public Decimal porcentagemAcrescFin;
        public Decimal valorAcrescFin;

        public OrderItem serialize(Map<String, Id> lookups){

            return new OrderItem(
                ExternalId__c = this.orderExternalId + '|' + this.orderItemCode, //Perguntar para o  Helder
                OrderId = lookups.containsKey('Order'+this.orderExternalId) ? lookups.get('Order'+this.orderExternalId) : null,
                Product2Id = this.material,
                Quantity = this.quantidade,
                //CentroDistribuicao__c = this.centro,
                UnitMeasure__c = this.unidadeMedida,
                ListPrice = this.listaPreco,
                PercentComission__c = this.porcentagemComissao,
                DiscountPercent__c = this.porcentagemDesconto,
                ComissionValue__c = this.comissaoValor,
                CommercialMargin__c = this.margemComercial,
                DiscountValue__c = this.descontoValor,
                FinalTotalValue__c = this.valorTotal,
                FinancialDiscountPercent__c = this.porcentagemDescontoFin,
                FinancialDiscountValue__c = this.valorDescontoFin,
                FinancialAdditionPercent__c = this.porcentagemAcrescFin,
                FinancialAdditionValue__c = this.valorAcrescFin, 
                PricebookEntryId = lookups.containsKey('PricebookEntry'+ this.material) ? lookups.get('PricebookEntry' + this.material) : null 
            );
        }
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'Product2Id'
    
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

    global class ShippingDivisonData implements FieldDataChild{
        //JSON fields Example
        public String orderExternalId;
        public String DivisaoRemessa;
        public String NumeroDivisaoRemessa;
        public Date DataDivisao;
        public Decimal Quantidade;
        public Decimal QuantidadeConfirmada;
        public String ExternalId;

        public ShippingDivison__c serialize(Map<String, Id> lookups){

            return new ShippingDivison__c(
                //ExternalId__c = this.NumeroDivisaoRemessa + '---'+ this.orderNumber,
                //Name = this.DivisaoRemessa,
                //OrderItem__c = this.NumeroDivisaoRemessa,
                DeliveryDate__c = this.DataDivisao,
                Quantity__c = this.Quantidade,
                ConfirmedQuantity__c = this.QuantidadeConfirmada
            );
        }
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'OrderItem__c'
    
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