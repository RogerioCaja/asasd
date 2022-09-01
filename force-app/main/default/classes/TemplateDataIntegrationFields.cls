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
        public String multiplicationFactor;
        // Chave(ExternalId__c): (orgVendas) | (safra) | (moeda) | (Material)(Lista de preço) | (Grupo de produtos)(Escritório de vendas)(Equipe de Vendas)(Cultura)(Segmento do Cliente)(Cliente) | (Material)(Equipe de vendas) | (Material)
        public JurosDescontoAntecipao__c serialize(Map<String, Id> lookups){
            JurosDescontoAntecipao__c lists = new JurosDescontoAntecipao__c(
                ClientGroup__c = this.accountGroup,
                ConditionType__c = this.typeCondition == 'ZPR0' ||  this.typeCondition == 'ZPRS' || this.typeCondition == 'ZCPE' ? 'Preço' : this.typeCondition == 'ZDAN'? 'Desconto' : 'Juros',
                RecordTypeId = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get(this.typeCondition == 'ZPRS' || this.typeCondition == 'ZCPE' ? 'ZPR0' :  this.typeCondition).getRecordTypeId(),
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
                ProductMultiplier__c = Decimal.valueOf(this.multiplicationFactor.trim()),
                UnitMeasurement__c = this.unitMeasurement != null ? this.unitMeasurement : null
            );
            if(this.typeCondition == 'ZPRS'){
                lists.Cost__c = Decimal.valueOf(this.unitPrice.trim());
            }
            else if(this.typeCondition == 'ZPR0' || this.typeCondition == 'ZCPE'){
                lists.UnitPrice__c = Decimal.valueOf(this.unitPrice.trim());
            }
            else{
                lists.Percentage__c = Decimal.valueOf(this.unitPrice.trim());
            }
            return lists;
            
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
        public Decimal multiplicidade;
        public String hierarquiaProduto;
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
                IsActive = true,
                ProductCode__c = this.ProductCode,
                ProductCode = this.ProductCode,
                Description = this.DescricaoMaterial,
                UnidadeMedida__c = this.UnidadeMedida,
                GrossWeightUnitOfMeasure__c = this.UnidadeMedidaRemessa,
                ProductType__c = this.TipoMaterial,
                ProductHierarchy__c = lookups.containsKey('ProductHierarchy__c'+this.hierarquiaProduto) ? lookups.get('ProductHierarchy__c'+this.hierarquiaProduto) : null,
                ProductGroup__c = lookups.containsKey('ProductGroup__c'+this.GrupoMercadoria) ? lookups.get('ProductGroup__c'+this.GrupoMercadoria) : null,
                ProductSubgroup__c = lookups.containsKey('ProductSubgroup__c'+this.SubgrupoMercadoria) ? lookups.get('ProductSubgroup__c'+this.SubgrupoMercadoria) : null,
                ProductSubgroup2__c = this.SubgrupoMercadoria2,
                MarcadoEliminacao__c = this.MarcadoEliminacao,
                QuantityUnitOfMeasure = this.UnidadePeso,
                ExternalId__c = this.ProductCode,
                ClasseAvaliacao__c = this.ClasseAvaliacao,
                OrigemMaterial__c = this.OrigemMaterial,
                Brand__c = this.Marca,
                NCM__c = this.NCM,
                GrupoQuimico__c = this.GrupoQuimico,
                PrincipleActive__c = this.IngredienteAtivo, 
                NumeroRegistro__c = this.NumeroRegistro,
                GrossWeight__c = this.PesoBruto,
                Multiplicity__c = this.multiplicidade

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
        public String productExternalId;
        public String OrgVId;
        public String centroFilial;
        public String OrganizacaoVendas;
        public String SetorAtividade;
        public String OrgProduct;
        public String Status;
        

        public OrgVProduct__c serialize(Map<String, Id> lookups){

            if(Status == '' || Status == null){
                Status = 'Adicionada';
            }
            else if (Status != null){
                Status = 'Removida';
            }
            //Returning Object with Fields.
            return new OrgVProduct__c(
                OrgVExternal__c = this.OrganizacaoVendas + '|' + this.OrgProduct + '|' + this.centroFilial,
                SalesOrg__c = lookups.containsKey('SalesOrg__c' + this.OrganizacaoVendas) ? lookups.get('SalesOrg__c' + this.OrganizacaoVendas) : null,
                Product__c = lookups.containsKey('Product2' + this.OrgProduct) ? lookups.get('Product2' + this.OrgProduct) : null,
                Department__c = this.SetorAtividade,
                SupplierCenter__c = this.centroFilial,
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

    public class PartnerInsert{
        public String PARVW;
	    public String KUNNR;
        public PartnerInsert(){}
    }

    global class ConditionInsert{
        public String KNUMV;
        public String KPOSN;
        public String KSCHL;
        public String KBETR;
        public String KPEIN;
        public ConditionInsert(){}
    }


    global class OrderINData implements FieldData{

        public String Status;
        //public String statusRecusa;
        public String numeroPedidoApp;
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
        public String condicaoVenda;
        public Boolean pedidoMae;
        public Decimal valorFinalTotal;
        public Decimal hectare;
        public Decimal margemPedido;
        public String orderType;
        public String centroFornecedor;
        public String escritorioVendas;
        public String equipeVendas;
        public String company;
        public Boolean eCalendarizacao;
        /*ATUALIZAÇÃO 05.07.22*/
        public String salesType;
        public String recordIdToUpdate;
        //public String clienteCode; 
        public List<TemplateDataIntegrationFields.OrderItemINData> orderItems;
        public List<TemplateDataIntegrationFields.ShippingDivisonINData> shippingDivison;
        public List<TemplateDataIntegrationFields.PartnerInsert> partners;
        public List<TemplateDataIntegrationFields.ConditionInsert> conditions;
        public Order serialize(Map<String, Id> lookups){

            if(pedidoMae == null){
                pedidoMae = false;
            }
            

            
            switch on salesType {
               // ---- Pedido mãe  ----
                when 'ZCCO' {
                    pedidoMae = true;
                }
                when 'ZCVF'{
                    pedidoMae = true;
                }
                when 'ZCVN'{
                    pedidoMae = true;
                }

               // --- Pedidos normais ---
                when 'ZSER'{
                    pedidoMae = false;
                }
                when 'ZVBA'{
                    pedidoMae = false;
                    
                }
                when 'ZVEF'{
                    pedidoMae = false;
                    
                }
                when 'ZVNO' {
                    pedidoMae = false;

                }
                when 'ZVVO'{
                    pedidoMae = false;
                    
                }
                when 'ZRCO'{
                    pedidoMae = false;

                }
            }

            
                    Map<String, String> codTypeOrder = new Map<String, String>();
                    if(!pedidoMae){
                        
                        codTypeOrder.put('ZRAG', 'Venda Amostra Grátis');
                        codTypeOrder.put('ZRBO', 'Venda Bonificação');
                        codTypeOrder.put('ZVBA', 'Venda Barter');
                        codTypeOrder.put('ZRCO', 'Venda Conta e Ordem');
                        codTypeOrder.put('ZSER', 'Venda de Serviço');
                        codTypeOrder.put('ZVEF', 'Venda Entrega Futura');
                        codTypeOrder.put('ZVNO', 'Venda Normal');
                        codTypeOrder.put('ZVVO', 'Venda Ordem Simples Faturamento');
                    }
                    else{
                        codTypeOrder.put('ZCCO', 'Venda Conta e Ordem');
                        codTypeOrder.put('ZCVF', 'Venda Entrega Futura');
                        codTypeOrder.put('ZCVN', 'Venda Normal');
                    }

                    salesType = codTypeOrder.containsKey(salesType) ? codTypeOrder.get(salesType) : salesType;
                
                    if(orderReference == null){
                        orderReference = '';
                    }

                    
                    
            return new Order(

                CodigoSap__c = this.CodigoSap,
                NumeroPedidoApp__c = this.numeroPedidoApp,
                Pricebook2Id = lookups.containsKey('Pricebook2Id'+this.pricebook2Id) ? lookups.get('Pricebook2Id'+this.pricebook2Id) : null,
                ShippingAccount__c = lookups.containsKey('Account'+this.shippingAccount) ? lookups.get('Account'+this.shippingAccount) : null,
                AccountId = lookups.containsKey('Account'+ this.PaymentAccount) ? lookups.get('Account'+this.PaymentAccount) : null,
                Crop__c = lookups.containsKey('Safra__c'+this.crop) ? lookups.get('Safra__c'+this.crop) : null,
                Culture__c = lookups.containsKey('Cultura__c'+this.culture) ? lookups.get('Cultura__c'+this.culture) : null,
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.salesOrg) ? lookups.get('SalesOrg__c'+this.salesOrg) : null,
                SalesCTV__c = lookups.containsKey('User'+this.salesCTV) ? lookups.get('User'+this.salesCTV) : null,
                PaymentCondition__c = lookups.containsKey('CondicaoPagamento__c'+this.PaymentCondition) ? lookups.get('CondicaoPagamento__c'+this.PaymentCondition) : null,
                OrderReference__c = lookups.containsKey('Order'+this.orderReference) ? lookups.get('Order'+this.orderReference) : null,
                DistributionChannel__c = lookups.containsKey('DistributionChannel__c' + this.distributionChannel)? lookups.get ('DistributionChannel__c' + this.distributionChannel) : null,
                ActivitySector__c = lookups.containsKey('ActivitySector__c' + this.activitySector)? lookups.get ('ActivitySector__c' + this.activitySector) : null,
                PaymentDate__c = Date.valueOf(paymentDate),
                EffectiveDate = Date.valueOf(effectiveDate),
                ShippingDate__c = Date.valueOf(ShippingDate),
                Status = this.status,
                //StatusRecusa__c	= this.statusRecusa,
                CustomerOrderNumber__c = this.customerOrderNumber,
                PaymentForm__c = this.paymentForm,
                StatusSF__c = (this.CodigoSap != null && this.CodigoSap != '') ? 'Integrado' :'Em digitação',
                Currency__c = this.CurrencyOrder,
                Incoterms__c = this.incoterms,
                Incoterms2__c = this.incoterms,
                Description = this.description + '1n73gr4ção N3sc4r4 5F x 4PP',
                DescriptionBillingSale__c = this.descriptionBillingSale,
                FinalTotalValue__c = this.valorFinalTotal,
                Hectare__c = this.hectare,
                OrderMargin__c = this.margemPedido,
                SalesCondition__c = lookups.containsKey('SalesCondition__c'+this.condicaoVenda) ? lookups.get('SalesCondition__c'+this.condicaoVenda) : null,
                IsOrderMother__c = this.pedidoMae,
                Company__c = lookups.containsKey('Company__c' + this.company) ? lookups.get('Company__c' + this.company):null,
                
                /* ATUALIZAÇÃO 05.07.2022*/
                RecordTypeId = this.salesType != null ? Schema.SObjectType.Order.getRecordTypeInfosByName().get(this.salesType).getRecordTypeId() : this.recordIdToUpdate,//
                Type = this.salesType != null ? this.salesType : Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosById().get(this.recordIdToUpdate).getName(),
                OrderType__c = this.orderReference != '' ? 'Pedido Filho' : (this.pedidoMae ? 'Pedido Mãe' : 'Pedido Normal'),
                
                OwnerId = lookups.containsKey('User'+this.salesCTV) ? lookups.get('User'+this.salesCTV) : null

                
            );
        }

        public List<String> getRequiredFields(){
            return new List<String>{
                //'CodigoSap__c'
                //'AccountId'
     
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
        public Boolean orderItemECalendariazacao;
        //public String centro;
        public String unidadeMedida;
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
        public Decimal porcentagemAcrescComercial;
        public Decimal valorAcrescComercial;
        public Decimal dosagem;
        public Decimal custoLista;
        public Decimal custoPreco;
        public Decimal precoPraticado;
        public Decimal precoUnitario;
        public String motivoRecusa;
        public OrderItem serialize(Map<String, Id> lookups){

            
            orderItemCode = orderItemCode.replaceFirst('^0+','');
            
            return new OrderItem(
                OrderId = this.orderExternalId,
                Product2Id = lookups.containsKey('Product2'+this.material) ? lookups.get('Product2'+this.material) : null,
                PricebookEntryId = lookups.containsKey('PricebookEntry'+ this.material) ? lookups.get('PricebookEntry' + this.material) : null,
                //ProductCode = this.material,
                ExternalId__c = this.orderExternalId + '|' + this.orderItemCode,
                Quantity = this.quantidade,
                UnitMeasure__c = this.unidadeMedida,
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
                CommercialAdditionPercent__c = this.porcentagemAcrescComercial,
                CommercialAdditionValue__c = this.valorAcrescComercial,
                Dosage__c = this.dosagem,
                ListPrice__c = this.precoUnitario,
                ListCost__c = this.custoLista,
                NumeroSap__c = String.valueOf(Integer.valueOf(this.orderItemCode)),
                PracticedCost__c = this.custoPreco,
                PracticedPrice__c = this.precoPraticado,
                UnitPrice = this.precoPraticado,
                AmountUsed__c = 0,
                ReasonRefuse__c = this.motivoRecusa
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
        public String material;
        public String orderExternalId;
        public String DivisaoRemessa;
        public String NumeroDivisaoRemessa;
        public Date DataDivisao;
        public Decimal Quantidade;
        public Decimal QuantidadeConfirmada;
        public String ExternalId;

        public ShippingDivison__c serialize(Map<String, Id> lookups){
            orderItemCode = orderItemCode.replaceFirst('^0+','');
            return new ShippingDivison__c(
                OrderItem__c = lookups.containsKey('OrderItem__c'+this.material) ? lookups.get('OrderItem__c'+this.material) : null,
                ExternalId__c = this.orderExternalId + '|' + this.OrderItemCode + '|' + this.DivisaoRemessa,
                DeliveryDate__c = this.DataDivisao,
                Quantity__c = this.Quantidade
                // ConfirmedQuantity__c = this.QuantidadeConfirmada
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
        public String numeroPedido; //
        public List<TemplateDataIntegrationFields.ItensNotaFiscalINData> itensNotaFiscal; 
        public NotaFiscal__c serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new NotaFiscal__c(
               
                Name = this.invoiceName,
                ExternalID__c = this.invoiceName + '|' + this.numeroNotaFiscal,
                AccountCode__c = lookups.containsKey('Account'+this.cliente) ? lookups.get('Account' + this.cliente) : null,
                OrderCode__c = lookups.containsKey('Order'+this.numeroPedido) ? lookups.get('Order'+ this.numeroPedido) : null, //
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
            public String localNegocio;
            public String instrucoes;
            public String numeroBoleto;
            public String bancoEmpresa;
            public String boletoBasePdf;
            public Boletos__c serialize(Map<String, Id> lookups){

                //Returning Object with Fields

            return new Boletos__c(
                SalesOrg__c = lookups.containsKey('SalesOrg__c'+this.Empresa) ? lookups.get('SalesOrg__c'+this.Empresa) : null,
                AccountCode__c = lookups.containsKey('AccountCode__c'+this.CodigoParceiro) ? lookups.get('AccountCode__c'+this.CodigoParceiro) : null,
                ExpirationDate__c = Date.valueOf(VencimentoBoleto),
                IssueDate__c = Date.valueOf(DataBoleto),
                Value__c = this.ValorBoleto,
                WritableLine__c = this.LinhaDigitavel,
                BankName__c = this.bancoEmpresa,
                OurNumber__c = this.numeroBoleto,
                BusinessLocation__c = this.localNegocio, 
                Instructions__c = this.instrucoes,
                Base64__c = this.boletoBasePdf
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
        public String NameProduct;
        public ItensNotaFiscal__c serialize(Map<String, Id> lookups){
        
     
            //Returning Object with Fields.
            return new ItensNotaFiscal__c(
                Name = 'Nota Fiscal ' + this.notaFiscal + ' - ' + this.NameProduct, //Pegar descrição do produto e number NF
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