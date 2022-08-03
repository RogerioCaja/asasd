@isTest
public with sharing class IntegrationINOrderTest {
  @TestSetup
  static void makeData(){
    Account account = new Account(
        Name = 'Teste 1',
        BillingStreet = ' ',
        BillingState = '' ,
        Phone= '', 
        BillingCity = ' ', 
        BillingLongitude = 000000,
        BillingLatitude = 00000,
        BillingPostalCode = '',
        ExternalId__c = '11111',
        Company__c = 'Empresa 01'
    );

    Safra__c safra = new Safra__c(
        Code__c = '1223',
        Name = 'Safra Teste',
        Name__c = 'Safra Teste',
        BillingStartDate__c = System.today(),
        EndDateBilling__c = System.today(),
        EndDateInsertionOrders__c = System.today(),
        NumberOfDaysAfterPayment__c = System.today(),
        ReleaseStatus__c = 'Ativo',
        StartDateOrderInsertion__c = System.today()
    );

    Pricebook2 pricebook = new Pricebook2(
        Name ='Price Book Test',
        Description = 'Furduncio',
        ExternalId__c = '0001',
        IsActive =true
    );

    Cultura__c cultura = new Cultura__c(
        Name = 'Safrinha',
        Name__c = 'Safrinha',
        Codigo__c = '1234'
    );

    SalesOrg__c so = new SalesOrg__c(
        Name = 'AgroGalaxy',
        SalesOrganizationCode__c = '1111'
    );

    DistributionChannel__c distributionChannel = new DistributionChannel__c(
        Name = 'Teste',
        Codigo__c = '0001'
    );

    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
    User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='tetedogas@testorg.com');

    INSERT account;
    INSERT safra;
    INSERT cultura;
    INSERT so;
    INSERT distributionChannel;
    INSERT u;

    Order order = new Order(
        AccountId =  account.Id,
        Status = 'Draft',
        PriceBook2Id = Test.getStandardPricebookId(),
        Type =  'Venda Normal',
        ShippingAccount__c =   account.Id,
        PaymentDate__c =  Date.today(),
        CustomerOrderNumber__c = '0001',
        EffectiveDate = Date.today(),
        Crop__c =  safra.Id,
        Culture__c = cultura.Id,
        PaymentForm__c =  'Bonificação',
        SalesOrg__c =  so.Id,
        DistributionChannel__c =  'Venda Direta',
        ActivitySector__c =  '',
        Currency__c =  'BRL',
        SalesCTV__c =  u.Id,
        StatusSF__c = 'Em digitação',
        Incoterms__c = 'CIF'
    );

    INSERT order;

    Product2 prod = new Product2(
        Name = 'Laptop X200', 
        Family = 'Hardware',
        ExternalId__c = '0001',
        ClasseAvaliacao__c = 'av01',
        GrupoQuimico__c = 'bg1',
        MarcadoEliminacao__c = 'tes01',
        NCM__c = '85432000',
        NumeroRegistro__c = '2',
        OrigemMaterial__c = 'sp',
        UnidadeMedida__c = 'un'
    );
    INSERT prod;

    PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(), 
        Product2Id = prod.Id,
        UnitPrice = 10000,
        IsActive = true);
    
    INSERT standardPrice;

    OrderItem orderItem = new OrderItem(
        OrderId = order.Id,
        Product2Id = prod.Id,
        NumeroSap__c = '123',
        UnitMeasure__c = 'L',
        UnitPrice = 10000,
        Quantity = 1,
        ExternalId__c = 'texto',
        PricebookEntryId = standardPrice.Id
    );

    INSERT orderItem;

    ShippingDivison__c shipping = new ShippingDivison__c(
        DeliveryDate__c = System.today().addDays(30),
        Quantity__c = 10,
        ExternalId__c = '001',
        ConfirmedQuantity__c = 0,
        OrderItem__c = orderItem.Id
    );
    insert shipping;
}


@isTest 
static void verifyIntegrationOrder(){
    List<TemplateDataINtegrationFields.OrderINData> listOrderList = new List<TemplateDataINtegrationFields.OrderINData>();
    TemplateDataIntegrationFields.OrderINData listOrder = new TemplateDataIntegrationFields.OrderINData();

    listOrder.NumeroPedidoApp = '686BB';
    listOrder.eCalendarizacao = false;
    listOrder.Status = '001';
    listOrder.PriceBook2Id = 'Standard Price Book';
    listOrder.ShippingAccount = '0002004568';
    listOrder.PaymentDate = Date.valueOf('2022-09-16');
    listOrder.EffectiveDate = Date.valueOf('2022-08-02');
    listOrder.Crop = '2022/2023';
    listOrder.Culture = '121';
    listOrder.PaymentForm = 'B';
    listOrder.CurrencyOrder = 'BRL';
    listOrder.SalesCTV = '0001004579';
    listOrder.Incoterms = 'CIF';
    listOrder.Incoterms2 = 'null';
    listOrder.Description = '';
    listOrder.PaymentCondition = 'Z030';
    listOrder.ShippingDate = Date.valueOf('2022-08-26');
    listOrder.DescriptionBillingSale = 'null';
    listOrder.OrderReference = '';
    listOrder.hectare = 10;
    listOrder.condicaoVenda = '01';
    listOrder.pedidoMae = false;
    listOrder.SalesOrg = '1000';
    listOrder.CentroFornecedor = '1001';
    listOrder.DistributionChannel = '10';
    listOrder.EquipeVendas = '001';
    listOrder.EscritorioVendas = '3511';
    listOrder.activitySector = '10';
    listOrder.salesType = 'Venda Normal';
    listOrder.valorFinalTotal = 1004.347505;
    listOrder.margemPedido = 5.885115;
    listOrder.orderType = 'Pedido Normal';
    
    TemplateDataIntegrationFields.OrderItemINData listOrderItem = new TemplateDataIntegrationFields.OrderItemINData();
    listOrderItem.valorTotal =  1004.347505;
    listOrderItem.valorDescontoFin =  96.2647;
    listOrderItem.valorAcrescFin =  0;
    listOrderItem.valorAcrescComercial =  0;
    listOrderItem.unidadeMedida =  'L';
    listOrderItem.quantidade =  5;
    listOrderItem.precoUnitario =  255.57;
    listOrderItem.precoPraticado =  200.869501;
    listOrderItem.porcentagemDescontoFin =  7.533333;
    listOrderItem.porcentagemDesconto =  15;
    listOrderItem.porcentagemComissao =  0;
    listOrderItem.porcentagemAcrescFin =  0;
    listOrderItem.porcentagemAcrescComercial =  0;
    listOrderItem.orderItemECalendariazacao =  false;
    listOrderItem.orderItemCode =  '10';
    listOrderItem.motivoRecusa =  'Reprovado';
    listOrderItem.material =  '000000000005002281';
    listOrderItem.margemComercial =  5.885115;
    listOrderItem.dosagem =  0.5;
    listOrderItem.descontoValor =  177.237795;
    listOrderItem.custoPreco =  189.05;
    listOrderItem.custoLista =  204.45;
    listOrderItem.comissaoValor =  0;
    listOrder.orderItems.add(listOrderItem);

    TemplateDataIntegrationFields.ShippingDivisonINData listShippingDivision = new TemplateDataIntegrationFields.ShippingDivisonINData();
    listShippingDivision.Quantidade =  5;
    listShippingDivision.OrderItemCode =  '10';
    listShippingDivision.NumeroDivisaoRemessa =  '686BB';
    listShippingDivision.material =  '000000000005002281';
    listShippingDivision.DivisaoRemessa =  '001';
    listShippingDivision.DataDivisao =  Date.valueOf('2022-09-21');
    listOrder.shippingDivison.add(listShippingDivision);

    List<TemplateDataINtegrationFields.PartnerInsert> listPartnersList = new List<TemplateDataINtegrationFields.PartnerInsert>();
    TemplateDataIntegrationFields.PartnerInsert listPartners = new TemplateDataIntegrationFields.PartnerInsert();
    listPartners.PARVW = 'AG';
    listPartners.KUNNR = '0001003675';
    listPartnersList.add(listPartners);
    listPartners.PARVW = 'RE';
    listPartners.KUNNR = '0001003675';
    listPartnersList.add(listPartners);
    listPartners.PARVW = 'RG';
    listPartners.KUNNR = '0001003675';
    listPartnersList.add(listPartners);
    listPartners.PARVW = 'WE';
    listPartners.KUNNR = '0002000509';
    listPartnersList.add(listPartners);
    listPartners.PARVW = 'ZC';
    listPartners.KUNNR = '0001004579';
    listPartnersList.add(listPartners);
    listOrder.partners.addAll(listPartnersList);

    List<TemplateDataINtegrationFields.ConditionInsert> listConditionList = new List<TemplateDataINtegrationFields.ConditionInsert>();
    TemplateDataIntegrationFields.ConditionInsert listCondition = new TemplateDataIntegrationFields.ConditionInsert();
    listCondition.KSCHL = 'ZPR0';
    listCondition.KPOSN = '10';
    listCondition.KPEIN = '1';
    listCondition.KNUMV = '0000001665';
    listCondition.KBETR = '10500.0';
    listConditionList.add(listCondition);
    listCondition.KSCHL = 'ZDAC';
    listCondition.KPOSN = '10';
    listCondition.KPEIN = '0';
    listCondition.KNUMV = '0000001665';
    listCondition.KBETR = '8.933333';
    listConditionList.add(listCondition);
    listCondition.KSCHL = 'ZJUC';
    listCondition.KPOSN = '10';
    listCondition.KPEIN = '0';
    listCondition.KNUMV = '0000001665';
    listCondition.KBETR = '0';
    listConditionList.add(listCondition);
    listCondition.KSCHL = 'ZDEC';
    listCondition.KPOSN = '10';
    listCondition.KPEIN = '0';
    listCondition.KNUMV = '0000001665';
    listCondition.KBETR = '-10';
    listConditionList.add(listCondition);
    listCondition.KSCHL = 'ZMAR';
    listCondition.KPOSN = '10';
    listCondition.KPEIN = '0';
    listCondition.KNUMV = '0000001665';
    listCondition.KBETR = '109';
    listConditionList.add(listCondition);
    listCondition.KSCHL = 'ZCP0';
    listCondition.KPOSN = '10';
    listCondition.KPEIN = '0';
    listCondition.KNUMV = '0000001665';
    listCondition.KBETR = '1200';
    listConditionList.add(listCondition);
    listOrder.conditions.addAll(listConditionList);
    listOrderList.add(listOrder);
    Test.startTest();
    IntegrationINOrder.ResponseModel modelo = IntegrationINOrder.upsertOrder(listOrderList);
    Test.stopTest();
}
}
