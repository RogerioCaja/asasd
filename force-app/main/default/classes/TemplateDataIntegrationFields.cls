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
                ConditionType__c = this.typeCondition == 'ZPR0' ||  this.typeCondition == 'ZPRS' ? 'Preço' : this.typeCondition == 'ZDAN'? 'Desconto' : 'Juros',
                RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName =: this.typeCondition == 'ZPRS' ? 'ZPR0' :  this.typeCondition ][0].Id,
                Culture__c = lookups.containsKey('Cultura__c'+this.cultureCode) ? lookups.get('Cultura__c'+this.cultureCode) : null,
                DistributionCenter__c =lookups.containsKey('DistributionCenter__c'+this.center) ? lookups.get('DistributionCenter__c'+this.center) : null,
                EndDate__c = this.endDate != null ? (Date.valueOf(this.endDate.contains('9999') ? this.endDate.replace('9999','2999') : this.endDate )) : null,
                // ExternalId__c = this.orgVendas + this.cropCode  + this.typeCurrency +  this.product + this.salesCondition  + this.productGroup + this.salesOffice  + this.cultureCode + this.accountGroup +  this.accountCode  + this.product + this.salesTeam  + this.product, // A estrutura está acima ^^^^
                ExternalId__c = this.externalId,
                IsActive__c = Date.valueOf(this.endDate) < Date.today() ? false : true,
                harvest__c = lookups.containsKey('Safra__c'+this.cropCode) ? lookups.get('Safra__c'+this.cropCode) : null,
                Product__c = lookups.containsKey('Product2'+this.product) ? lookups.get('Product2'+this.product) : null,
                ProductGroup__c = lookups.containsKey('ProductGroup__c'+this.productGroup) ? lookups.get('ProductGroup__c'+this.productGroup) : null,
                SalesOffice__c = lookups.containsKey('SalesOffice__c'+this.salesOffice) ? lookups.get('SalesOffice__c'+this.salesOffice) : null,
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.orgVendas) ? lookups.get('SalesOrg__c'+this.orgVendas) : null,
                SalesTeam__c = lookups.containsKey('SalesTeam__c'+this.salesTeam) ? lookups.get('SalesTeam__c'+this.salesTeam) : null,
                StartDate__c = this.initialDate != null ? (Date.valueOf(this.initialDate.contains('9999') ? this.initialDate.replace('9999','2999') : this.initialDate )) : null,
                Account__c = lookups.containsKey('Account'+this.accountCode) ? lookups.get('Account'+this.accountCode) : null,
                Currency__c = this.typeCurrency,
                SalesCondition__c = lookups.containsKey('SalesCondition__c'+this.salesCondition) ? lookups.get('SalesCondition__c'+this.salesCondition) : null, 
                ProductMultiplier__c = 1,
                UnitMeasurement__c = this.unitMeasurement != null ? this.unitMeasurement : null,
                UnitPrice__c = (this.typeCurrency == 'BRL' || this.typeCurrency == 'USD') ? Decimal.valueOf(this.unitPrice.trim()) : null,
                Percentage__c = this.typeCurrency == '%' ? Decimal.valueOf(this.unitPrice.trim()) : null,
                Cost__c = this.typeCondition == 'ZPRS' ?  Decimal.valueOf(this.unitPrice.trim()) : null
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
        public String ProductCode;
        public String TextoBreveMaterial;
        public String DescricaoMaterial;
        public String UnidadeMedida;
        public String UnidadeMedidaRemessa;
        public String Status;
        public String TipoMaterial;
        public String GrupoMercadoria;
        public String SubgrupoMercadoria;
        public String SubgrupoMercadoria2;
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
        public List<TemplateDataIntegrationFields.OrgVProductINData> orgVProductItems;
        //public List<TemplateDataIntegrationFields.ProductINData> product2Entries;

        public Product2 serialize(Map<String, Id> lookups){


            //Returning Object with Fields
            return new Product2(
                Name = this.TextoBreveMaterial,
                ProductCode = this.ProductCode,
                Description = this.DescricaoMaterial,
                UnidadeMedida__c = this.UnidadeMedida,
                GrossWeightUnitOfMeasure__c = this.UnidadeMedidaRemessa,
                ProductType__c = this.TipoMaterial,
                ProductGroup__c = lookups.containsKey('ProductGroup__c'+this.GrupoMercadoria) ? lookups.get('ProductGroup__c'+this.GrupoMercadoria) : null,
                ProductSubgroup__c = lookups.containsKey('ProductSubgroup__c'+this.SubgrupoMercadoria) ? lookups.get('ProductSubgroup__c'+this.SubgrupoMercadoria) : null,
                ProductSubgroup2__c = this.SubgrupoMercadoria2,
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

    global class OrgVProductINData implements FieldDataChild{
        
        //JSON fields Example
        public String OrgVId;
        public String OrganizacaoVendas;
        public String SetorAtividade;
        public String OrgProduct;
        public String Status;
        

        public OrgVProduct__c serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new OrgVProduct__c(
                OrgVExternal__c = this.OrgProduct + '|' + this.OrgVId,
                SalesOrg__c = lookups.containsKey('SalesOrg__c' + this.OrganizacaoVendas) ? lookups.get('SalesOrg__c' + this.OrganizacaoVendas) : null,
                Product__c = lookups.containsKey('Product2' + this.OrgProduct) ? lookups.get('Product2' + this.OrgProduct) : null,
                Department__c = this.SetorAtividade,
                Status__c = this.Status
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{
               //'Name',
               
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'Id';
        }

        public String getFieldExternal(){
            return 'Invoice__c';
        }
        
        public String getParentKey(){
            return 'Pricebook2Id';
        }
    }

    global class OrderINData implements FieldData{

        public String Status;
        public String pricebook2Id;
        public String CodigoSap;
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
        //public String clienteCode; 
        public List<TemplateDataIntegrationFields.OrderItemINData> orderItems;
        public List<TemplateDataIntegrationFields.ShippingDivisonINData> shippingDivison;
        public Order serialize(Map<String, Id> lookups){

            return new Order(

                CodigoSap__c = this.CodigoSap,
                Pricebook2Id = lookups.containsKey('Pricebook2Id'+this.pricebook2Id) ? lookups.get('Pricebook2Id'+this.pricebook2Id) : null,
                ShippingAccount__c = lookups.containsKey('ShippingAccount__c'+this.shippingAccount) ? lookups.get('ShippingAccount__c'+this.shippingAccount) : null,
                AccountId = lookups.containsKey('Account'+ this.PaymentAccount) ? lookups.get('Account'+this.PaymentAccount) : null,
                Crop__c = lookups.containsKey('Safra__c'+this.crop) ? lookups.get('Safra__c'+this.crop) : null,
                Culture__c = lookups.containsKey('Cultura__c'+this.culture) ? lookups.get('Cultura__c'+this.culture) : null,
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.salesOrg) ? lookups.get('SalesOrg__c'+this.salesOrg) : null,
                SalesCTV__c = lookups.containsKey('SalesCTV__c'+this.salesCTV) ? lookups.get('SalesCTV__c'+this.salesCTV) : null,
                PaymentCondition__c = lookups.containsKey('CondicaoPagamento__c'+this.paymentCondition) ? lookups.get('CondicaoPagamento__c'+this.paymentCondition) : null,
                OrderReference__c = lookups.containsKey('OrderReference__c'+this.orderReference) ? lookups.get('OrderReference__c'+this.orderReference) : null,
                DistributionChannel__c = lookups.containsKey('DistributionChannel__c' + this.distributionChannel)? lookups.get ('' + this.distributionChannel) : null,
                ActivitySector__c = lookups.containsKey('ActivitySector__c' + this.activitySector)? lookups.get ('' + this.activitySector) : null,
                PaymentDate__c = Date.valueOf(paymentDate),
                EffectiveDate = Date.valueOf(effectiveDate),
                ShippingDate__c = Date.valueOf(ShippingDate),
                Status = this.status,
                Type = this.type,
                CustomerOrderNumber__c = this.customerOrderNumber,
                PaymentForm__c = this.paymentForm,
                Currency__c = this.CurrencyOrder,
                Incoterms__c = this.incoterms,
                Incoterms2__c = this.incoterms,
                Description = this.description,
                DescriptionBillingSale__c = this.descriptionBillingSale
            );
        }

        public List<String> getRequiredFields(){
            return new List<String>{
                'CodigoSap__c',
                'AccountId'
     
            };
        }
        public String getFieldKey(){
            return 'CodigoSap__c';
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
        public String productCode;
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
                OrderId = lookups.containsKey('Order'+this.orderExternalId) ? lookups.get('Order'+this.orderExternalId) : null,
                Product2Id = lookups.containsKey('Product2'+this.material) ? lookups.get('Product2'+this.material) : null,
                PricebookEntryId = lookups.containsKey('PricebookEntry'+ this.material) ? lookups.get('PricebookEntry' + this.material) : null,
                ExternalId__c = this.orderExternalId + '|' + this.orderItemCode,
                Quantity = this.quantidade,
                UnitMeasure__c = this.unidadeMedida,
                UnitPrice = this.listaPreco,
                PercentComission__c = this.porcentagemComissao,
                DiscountPercent__c = this.porcentagemDesconto,
                ComissionValue__c = this.comissaoValor,
                CommercialMargin__c = this.margemComercial,
                DiscountValue__c = this.descontoValor,
                FinalTotalValue__c = this.valorTotal,
                FinancialDiscountPercent__c = this.porcentagemDescontoFin,
                FinancialDiscountValue__c = this.valorDescontoFin,
                FinancialAdditionPercent__c = this.porcentagemAcrescFin,
                FinancialAdditionValue__c = this.valorAcrescFin 
                 
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
            return 'ExternalId__c';
        }
        
        //Parent ExternalId field
        public String getParentKey(){
            return 'OrderId';
        }
    }

    global class ShippingDivisonINData implements FieldDataChild{
        //JSON fields Example
        public String OrderItemCode;    
        public String orderExternalId;
        public String DivisaoRemessa;
        public String NumeroDivisaoRemessa;
        public Date DataDivisao;
        public Decimal Quantidade;
        public Decimal QuantidadeConfirmada;
        public String ExternalId;

        public ShippingDivison__c serialize(Map<String, Id> lookups){

            return new ShippingDivison__c(
                OrderItem__c = lookups.containsKey('OrderItem__c'+this.OrderItemCode) ? lookups.get('OrderItem__c'+this.OrderItemCode) : null,
                // Como estava ----> ExternalId__c = this.orderExternalId + '|' + this.OrderItemCode,//Confirmar com Helder como deverá ser essa chave
                ExternalId__c = this.orderExternalId,//Confirmar com Helder como deverá ser essa chave
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
            return 'ExternalId__c';
        }
        
        //Parent ExternalId field
        public String getParentKey(){
            return 'OrderId';
        }
        
    }
    
    global class NotaFiscalINData implements FieldData{
        //JSON fields Example
        
        
        public String invoiceName;
        public String numeroNotaFiscal;
        public String serie;
        public String localNegocios;
        public String codigoStatus;
        public String chaveAcesso;
        public Date dataCriacao;
        public Datetime horaCriacao;
        public String codigoEmpresa;
        public String cliente;
        public String propriedade;
        public Decimal valorTotalNf;
        public String naturezaOperacao;
        public String numeroPedido;
        public List<TemplateDataIntegrationFields.ItensNotaFiscalINData> itensNotaFiscal; 
        public NotaFiscal__c serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new NotaFiscal__c(
               
                Name = this.invoiceName,
                ExternalID__c = this.invoiceName + '|' + this.numeroNotaFiscal,
                AccountCode__c = lookups.containsKey('Account'+this.cliente) ? lookups.get('Account' + this.cliente) : null,
                OrderCode__c = lookups.containsKey('Order'+this.numeroPedido) ? lookups.get('Order'+ this.numeroPedido) : null,
                Company__c = lookups.containsKey('SalesOrg__c'+this.codigoEmpresa) ? lookups.get('SalesOrg__c'+this.codigoEmpresa) : null,
                ReceiverAccountCode__c = lookups.containsKey('Account'+this.propriedade) ? lookups.get('Account'+this.propriedade) : null,
                invoiceNumber__c = this.numeroNotaFiscal,
                Serie__c = this.serie,
                BranchOffice__c = this.localNegocios,
                InvoiceStatus__c = this.codigoStatus,
                AccessKey__c = this.chaveAcesso,
                Invoice_CreationDate__c = this.dataCriacao,
                HoraCriacao__c = this.horaCriacao,
                Invoice_TotalAmount__c = this.valorTotalNf,
                CFOP__c = this.naturezaOperacao
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{
                'Name'
                //'numeroNotaFiscal'
       
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

    global class BoletosINData implements FieldData {

            public String CodigoParceiro;
            public Date VencimentoBoleto;
            public Date DataBoleto;
            public String Empresa;
            public Decimal ValorBoleto;
            public String LinhaDigitavel;
            public Boletos__c serialize(Map<String, Id> lookups){

                //Returning Object with Fields

            return new Boletos__c(
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.Empresa) ? lookups.get('SalesOrg__c'+this.Empresa) : null,
                AccountCode__c = lookups.containsKey('AccountCode__c'+this.CodigoParceiro) ? lookups.get('AccountCode__c'+this.CodigoParceiro) : null,
                ExpirationDate__c = Date.valueOf(VencimentoBoleto),
                IssueDate__c = Date.valueOf(DataBoleto),
                Value__c = this.ValorBoleto,
                WritableLine__c = this.LinhaDigitavel
            );
        }

        //Required fields for integration

        public List<String> getRequiredFields(){
            return new List<String>{

                'AccountCode__c',
                'ExpirationDate__c',
                'Value__c',
                'WritableLine__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return '';
        }
        //Id field

        public String getFieldId() {
            return 'Id';
        }
    }

    global class ItensNotaFiscalINData implements FieldDataChild{
        
        //JSON fields Example
        public String nfExternalId;
        public String notaFiscal;
        public String codigoMaterial;
        public Decimal quantidade;
        public Decimal valorTotalItem;
        public String lote;
        public String unidadeMedida;
        public String naturezaOperacao;
        public Decimal descontoNF;
        public Decimal valorUnitarioNF;

        public ItensNotaFiscal__c serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new ItensNotaFiscal__c(
                Name = 'Nota Fiscal' + ' - ' + this.notaFiscal, //Pegar descrição do produto e number NF
                ExternalID__c = this.codigoMaterial + '|' + this.notaFiscal + '|' + this.lote,
                Invoice__c = lookups.containsKey('NotaFiscal__c' + this.notaFiscal) ? lookups.get('NotaFiscal__c' + this.notaFiscal) : null,
                Productcode__c = lookups.containsKey('Product2'+this.codigoMaterial) ? lookups.get('Product2' + this.codigoMaterial) : null,
                Theamount__c = this.quantidade,
                Amount__c = this.valorTotalItem,
                Batch__c = this.lote,
                UnidadeMedida__C = this.unidadeMedida,
                CFOP__c = this.naturezaOperacao,
                Discount__c = this.descontoNF,
                Unitaryvalue__c = this.valorUnitarioNF
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            return new List<String>{
                'Name',
                'Invoice__c',
                'Productcode__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'Id';
        }

        public String getFieldExternal(){
            return 'Invoice__c';
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