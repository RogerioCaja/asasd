@isTest
public with sharing class IntegrationINInvoiceTest {
    @TestSetup
    static void makeData(){
        
        NotaFiscal__c invoice = new NotaFiscal__c(
            Name = 'Invoice Agro',
            AccountCode__c = '020',
            OrderCode__c = '0100',
            Company__c = ' 001',
            ReceiverAccountCode__c = '030',
            invoiceNumber__c = '90001',
            Serie__c = '001',
            BranchOffice__c = 'São Paulo', 
            InvoiceStatus__c = 'Aprovado',
            AccessKey__c = '35220765651788000141550020000011611391381530',
            Invoice_CreationDate__c = System.today(),
            HoraCriacao__c = System.today(),
            Invoice_TotalAmount__c = 100.00,
            CFOP__c = '5.102'
        );
        insert invoice;
        Account account = new Account(
            Name = 'AgroGalaxy Conta',
            BillingStreet = '',
            BillingState = '' ,
            Phone= '0000011111', 
            BillingCity = ' ', 
            BillingLongitude = 01010101,
            BillingLatitude = 001100,
            BillingPostalCode = '',
            ExternalId__c = '020',
            Company__c = '00010018631001100010103511001'
        );
        insert account;

        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert parentAccount;

        Account account2 = new Account(
            Name = 'AgroGalaxy Propriedade',
            BillingStreet = '',
            BillingState = '' ,
            Phone= '000002222', 
            BillingCity = ' ', 
            BillingLongitude = 02020202,
            BillingLatitude = 002200,
            BillingPostalCode = '',
            ExternalId__c = '030',
            Company__c = '00010018631001100010103511001'
        );
        insert account2;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='tetedogas@testorg.com');

        INSERT u;

        SalesOrg__c salesOrg = new SalesOrg__c(
            Name = 'Sales Organization',
            SalesOrganizationCode__c = '001'
        );
        insert salesOrg;

        SalesOffice__c salesOffice = new SalesOffice__c(
            Name = 'Sales Office',
            Codigo__c = '001'
        );
        insert salesOffice;

        SalesTeam__c salesTeam = new SalesTeam__c(
            Name = 'Sales team'
        );
        insert salesTeam;
        DistributionChannel__c distributionChannel = new DistributionChannel__c(
            Name = 'Teste',
            Codigo__c = '0001'
        );
        insert distributionChannel;

        ActivitySector__c activitySector = new ActivitySector__c(
            Name = 'Teste Activity',
            Codigo__c = '003'
        );
        insert activitySector;

        Company__c company = new Company__c(
            Name = 'Company',
            Blocked__c = false,
            ClientGroup__c = 'NÃO SEGMENTADO',
            Conta__c = parentAccount.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            ExternalID__c = '001',
            SupplierCenter__c = '1010'
        );
        insert company;

        Safra__c crop = new Safra__c(
            Name = 'Safra 01',
            Code__c = '001',
            BillingStartDate__c = System.today(),
            StartDateOrderInsertion__c = System.today(),
            EndDateBilling__c = System.today().addDays(90),
            EndDateInsertionOrders__c = System.today().addDays(90),
            NumberOfDaysAfterPayment__c = System.today().addDays(10),
            ReleaseStatus__c = 'Ativo'
        );
        insert crop;

        Cultura__c culture = new Cultura__c(
            Name = 'Culture 01',
            Name__c = 'Culture 01',
            Codigo__c = '001'
        );
        insert culture;

        ProductGroup__c productGroup = new ProductGroup__c(
            Name = 'Grãos',
            ExternalId__c = '001'
        );
        insert productGroup;

        ProductHierarchy__c productHierarchy = new ProductHierarchy__c(
            Name = 'Hierarquia',
            External_Id__c = '001'
        );
        insert productHierarchy;

        SalesCondition__c salesCondition = new SalesCondition__c(
            Name = 'Condição',
            ExternalId__c = '001'
        );
        insert salesCondition;

        CondicaoPagamento__c paymentCondition = new CondicaoPagamento__c(
            Name = 'Condição à vista',
            Code__c = 'Z09'
        );
        insert paymentCondition;

        Product2 product = new Product2(
            Name = 'Milho',
            ExternalId__c = '001',
            ProductCode = '001',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            ProductType__c = 'HAWA',
            PrincipleActive__c = 'Salicilina',
            ProductGroup__c = productGroup.Id,
            Multiplicity__c = 5,
            ClasseAvaliacao__c = 'chucrute',
            GrupoQuimico__c = 'Só o quimico',
            MarcadoEliminacao__c = 'S',
            NCM__c = 'S',
            NumeroRegistro__c = '0001',
            OrigemMaterial__c = 'Himalaia', 
            UnidadeMedida__c = 'KG',
            ProductHierarchy__c = productHierarchy.Id
        );
        insert product;


        Map <String,Schema.RecordTypeInfo> recordTypeMap = Order.sObjectType.getDescribe().getRecordTypeInfosByName();

            Order order = new Order(
            CodigoSap__c = '0100',
            NumeroPedidoApp__c = '0600',
            Pricebook2Id = Test.getStandardPricebookId(),
            ShippingAccount__c = '020',
            AccountId = '030',
            Crop__c = '001',
            Culture__c = '001',
            SalesOrg__c = '001',
            SalesCTV__c =  u.Id,
            PaymentCondition__c = 'Z09',
            DistributionChannel__c = '0001',
            ActivitySector__c = '003',
            PaymentDate__c = Date.valueOf('2022-09-21'),
            EffectiveDate = Date.today(),
            ShippingDate__c = Date.valueOf('2022-09-30'),
            Status = '02',
            CustomerOrderNumber__c ='09001',
            PaymentForm__c = 'B',
            StatusSF__c = 'Aprovado',
            Currency__c = 'BRL',
            Incoterms__c = 'CIF',
            Incoterms2__c = 'CIF',
            Description = 'Teste de integração',
            DescriptionBillingSale__c = 'Teste de integração',
            FinalTotalValue__c = 1000,
            Hectare__c = 10,
            OrderMargin__c = 1200,
            SalesCondition__c =  '001',
            IsOrderMother__c = false,
            Company__c =  '001',
            RecordTypeId = recordTypeMap.get('Venda Normal').getRecordTypeId(),
            Type = 'Venda Normal',
            OrderType__c = 'Pedido Normal',
            OwnerId = u.Id
        );
        insert order;
    }

    @isTest
    static void verifyIntegrationInvoice(){
        List<TemplateDataINtegrationFields.NotaFiscalINData> listInvoiceList = new List<TemplateDataINtegrationFields.NotaFiscalINData>();
        TemplateDataIntegrationFields.NotaFiscalINData listInvoice = new TemplateDataIntegrationFields.NotaFiscalINData();
        listInvoice.invoiceName = 'Invoice AgroGalaxy';
        listInvoice.serie = '001';
        listInvoice.numeroNotaFiscal = '90001';
        listInvoice.chaveAcesso =  '35220765651788000141550020000011611391381530';
        listInvoice.localNegocios = 'São Paulo';
        listInvoice.codigoStatus = 'Aprovado';
        listInvoice.dataCriacao = Date.valueOf('2022-09-21');
        listInvoice.horaCriacao = System.today();
        listInvoice.codigoEmpresa = '001';
        listInvoice.cliente = '020';  
        listInvoice.propriedade =  '030';
        listInvoice.valorTotalNf = 100.00;
        listInvoice.naturezaOperacao = '5.102';  
        listInvoice.numeroPedido = '0100';
        TemplateDataIntegrationFields.ItensNotaFiscalINData listInvoiceItems = new TemplateDataIntegrationFields.ItensNotaFiscalINData();
        
        listInvoiceItems.notaFiscal = '90001';
        listInvoiceItems.codigoMaterial = '001';
        listInvoiceItems.quantidade = 12;
        listInvoiceItems.valorTotalItem = 100.00;
        listInvoiceItems.lote = '01';
        listInvoiceItems.unidadeMedida = 'L';
        listInvoiceItems.naturezaOperacao = '5.102'; 
        listInvoiceItems.descontoNF = 0;
        listInvoiceItems.valorUnitarioNF =  8.33;
        listInvoiceItems.NameProduct = 'Milho';
        listInvoice.itensNotaFiscal.add(listInvoiceItems);

        listInvoiceList.add(listInvoice);
        Test.startTest();
        IntegrationINInvoice.ResponseModel modelo = IntegrationINInvoice.upsertInvoice(listInvoiceList);
        Test.stopTest();
    }
}
