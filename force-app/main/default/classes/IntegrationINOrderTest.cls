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
        SalesOrganizationCode__c = '1000'
    );

    DistributionChannel__c distributionChannel = new DistributionChannel__c(
        Name = 'Teste',
        Codigo__c = '0001'
    );

    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
    User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, CodigoSap__c='11111',
        TimeZoneSidKey='America/Los_Angeles', UserName='tetedogas@testorg.com');
      
    ActivitySector__c activitySector = new ActivitySector__c(
            Name = 'Teste Activity',
            Codigo__c = '003'
        );
    insert activitySector;
      
    CondicaoPagamento__c paymentCondition = new CondicaoPagamento__c(
            Name = 'Condição à vista',
            Code__c = 'Z09'
        );
        insert paymentCondition;
    SalesCondition__c salesCondition = new SalesCondition__c(
            Name = 'Condição',
            ExternalId__c = '01'
        );
        insert salesCondition;

    INSERT account;
    INSERT safra;
    INSERT cultura;
    INSERT so;
    INSERT distributionChannel;
    INSERT u;
       Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert parentAccount;
      
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
      
      Company__c company = new Company__c(
            Name = 'Company',
            Blocked__c = false,
            ClientGroup__c = '11',
            Conta__c = parentAccount.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            ExternalID__c = '001',
            SupplierCenter__c = '1010'
        );
        insert company;
      
      Order order2 = new Order(
        AccountId =  account.Id,
        NumeroPedidoApp__c = '686BB52',
        PaymentCondition__c = paymentCondition.Id,
        CodigoSap__c = '1007',
        Status = 'Draft',
        Type = 'Adicionada',
        FinalTotalValue__c = 1022,
        Description = 'Teste',
        OrderMargin__c = 09,
        OrderType__c = 'Pedido Normal',
        IsOrderMother__c = false,
        PriceBook2Id = Test.getStandardPricebookId(),
        ShippingAccount__c =   account.Id,
        PaymentDate__c =  Date.today(),
        CustomerOrderNumber__c = '0001',
        EffectiveDate = Date.today(),
        Crop__c =  safra.Id,
        Culture__c = cultura.Id,
        PaymentForm__c = 'B',
        SalesOrg__c =  so.Id,
        DistributionChannel__c =  distributionChannel.Id,
        ActivitySector__c =  activitySector.Id,
        Currency__c =  'BRL',
        SalesCTV__c =  u.Id,
        StatusSF__c = 'Em digitação',
        Incoterms2__c = 'CIF',
        Incoterms__c = 'CIF'
    );

    INSERT order2;

    Order order = new Order(
        AccountId =  account.Id,
        NumeroPedidoApp__c = '686BB',
        PaymentCondition__c = paymentCondition.Id,
        CodigoSap__c = '1002',
        Status = 'Draft',
        Type = 'Adicionada',
        FinalTotalValue__c = 1022,
        Description = 'Teste',
        OrderMargin__c = 09,
        OrderType__c = 'Pedido Normal',
        IsOrderMother__c = false,
        PriceBook2Id = Test.getStandardPricebookId(),
        ShippingAccount__c =   account.Id,
        PaymentDate__c =  Date.today(),
        CustomerOrderNumber__c = '0001',
        EffectiveDate = Date.today(),
        Crop__c =  safra.Id,
        Culture__c = cultura.Id,
        PaymentForm__c = 'B',
        SalesOrg__c =  so.Id,
        DistributionChannel__c =  distributionChannel.Id,
        ActivitySector__c =  activitySector.Id,
        Currency__c =  'BRL',
        SalesCTV__c =  u.Id,
        StatusSF__c = 'Em digitação',
        Incoterms2__c = 'CIF',
        OrderReference__c = order2.Id,
        Company__c = company.Id,
        Incoterms__c = 'CIF'
    );

    INSERT order;
  Order order3 = new order(
        AccountId =  account.Id,
        NumeroPedidoApp__c = null,
        PaymentCondition__c = paymentCondition.Id,
        CodigoSap__c = '1009',
        Status = 'Draft',
        Type = 'Adicionada',
        FinalTotalValue__c = 1022,
        Description = 'Teste',
        OrderMargin__c = 09,
        OrderType__c = 'Pedido Normal',
        IsOrderMother__c = false,
        PriceBook2Id = Test.getStandardPricebookId(),
        ShippingAccount__c =   account.Id,
        PaymentDate__c =  Date.today(),
        CustomerOrderNumber__c = '0001',
        EffectiveDate = Date.today(),
        Crop__c =  safra.Id,
        Culture__c = cultura.Id,
        PaymentForm__c = 'B',
        SalesOrg__c =  so.Id,
        DistributionChannel__c =  distributionChannel.Id,
        ActivitySector__c =  activitySector.Id,
        Currency__c =  'BRL',
        SalesCTV__c =  u.Id,
        StatusSF__c = 'Em digitação',
        Incoterms2__c = 'CIF',
        OrderReference__c = order2.Id,
        Company__c = company.Id,
        Incoterms__c = 'CIF'
    );

    INSERT order3;
    Product2 prod = new Product2(
        Name = 'Laptop X200', 
        Family = 'Hardware',
        ExternalId__c = '0001',
        ProductCode__c = '0001',
        ProductCode = '0001',
        ClasseAvaliacao__c = 'av01',
        UnidadeMedida__c = 'L',
        GrupoQuimico__c = 'bg1',
        MarcadoEliminacao__c = 'tes01',
        NCM__c = '85432000',
        NumeroRegistro__c = '2',
        OrigemMaterial__c = 'sp'
    );
    INSERT prod;

   
    OrderItem orderItem = new OrderItem(
        OrderId = order.Id,
        Product2Id = prod.Id,
        NumeroSap__c = '10',
        UnitMeasure__c = prod.UnidadeMedida__c,
        UnitPrice = 10000,
        Quantity = 1,
        ExternalId__c = order.Id + '|' + '10',
        PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id =: prod.Id LIMIT 1][0].Id
    );

    INSERT orderItem;
      
      OrderItem orderItem2 = new OrderItem(
        OrderId = order3.Id,
        Product2Id = prod.Id,
        NumeroSap__c = '10',
        UnitMeasure__c = '',
        UnitPrice = 10000,
        Quantity = 1,
        ExternalId__c = order3.Id + '|' + '10',
        PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id =: prod.Id LIMIT 1][0].Id
    );

    INSERT orderItem2;

    ShippingDivison__c shipping = new ShippingDivison__c(
        DeliveryDate__c = System.today().addDays(30),
        Quantity__c = 10,
        ExternalId__c = '001',
        ConfirmedQuantity__c = 0,
        OrderItem__c = orderItem.Id
    );
    insert shipping;
      
    ShippingDivison__c shipping2 = new ShippingDivison__c(
        DeliveryDate__c = System.today().addDays(30),
        Quantity__c = 10,
        ExternalId__c = '002',
        ConfirmedQuantity__c = 0,
        OrderItem__c = orderItem2.Id
    );
    insert shipping2;
}


@isTest 
static void verifyIntegrationOrder(){
    List<TemplateDataINtegrationFields.OrderINData> listOrderList = new List<TemplateDataINtegrationFields.OrderINData>();
    TemplateDataIntegrationFields.OrderINData listOrder = new TemplateDataIntegrationFields.OrderINData();
	listOrder.CodigoSap = '1002';
    listOrder.numeroPedidoApp = '686BB';
    listOrder.eCalendarizacao = false;
    listOrder.Status = null;
    listOrder.PriceBook2Id = null;
    listOrder.ShippingAccount = '11111';
    listOrder.paymentDate = null;
    listOrder.effectiveDate = null;
    listOrder.Crop = null;
    listOrder.Culture = null;
    listOrder.PaymentForm = null;
    listOrder.CurrencyOrder = 'BRL';
    //listOrder.SalesCTV = '0001004579';
    listOrder.Incoterms = 'CIF';
    listOrder.Incoterms2 = 'null';
    listOrder.Description = '';
    listOrder.PaymentCondition = null;
    listOrder.ShippingDate = Date.today();
    listOrder.DescriptionBillingSale = 'null';
    listOrder.OrderReference = null;
    listOrder.hectare = 10;
    listOrder.condicaoVenda = '01';
    listOrder.pedidoMae = false;
    listOrder.SalesOrg = null;
    //listOrder.CentroFornecedor = '1001';
    listOrder.DistributionChannel = null;
    //listOrder.EquipeVendas = '001';
    //listOrder.EscritorioVendas = '3511';
    listOrder.activitySector = null;
    listOrder.salesType = 'ZVNO';
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
    listOrderItem.motivoRecusa =  null;
    listOrderItem.material =  '0001';
    listOrderItem.margemComercial =  5.885115;
    listOrderItem.dosagem =  0.5;
    listOrderItem.descontoValor =  177.237795;
    listOrderItem.custoPreco =  189.05;
    listOrderItem.custoLista =  204.45;
    listOrderItem.comissaoValor =  0;
    listOrder.orderItems = new List<TemplateDataIntegrationFields.OrderItemINData>();
    listOrder.orderItems.add(listOrderItem);

    TemplateDataIntegrationFields.ShippingDivisonINData listShippingDivision = new TemplateDataIntegrationFields.ShippingDivisonINData();
    listShippingDivision.Quantidade =  5;
    listShippingDivision.OrderItemCode =  '10';
    listShippingDivision.NumeroDivisaoRemessa =  '1002';
    listShippingDivision.material =  '0001';
    listShippingDivision.DivisaoRemessa =  '001';
    listShippingDivision.DataDivisao =  Date.valueOf('2022-09-21');
    listOrder.shippingDivison = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
    listOrder.shippingDivison.add(listShippingDivision);

    List<TemplateDataINtegrationFields.PartnerInsert> listPartnersList = new List<TemplateDataINtegrationFields.PartnerInsert>();
    TemplateDataIntegrationFields.PartnerInsert listPartners1 = new TemplateDataIntegrationFields.PartnerInsert();
    TemplateDataIntegrationFields.PartnerInsert listPartners2 = new TemplateDataIntegrationFields.PartnerInsert();
    TemplateDataIntegrationFields.PartnerInsert listPartners3 = new TemplateDataIntegrationFields.PartnerInsert();
    TemplateDataIntegrationFields.PartnerInsert listPartners4 = new TemplateDataIntegrationFields.PartnerInsert();
    TemplateDataIntegrationFields.PartnerInsert listPartners5 = new TemplateDataIntegrationFields.PartnerInsert();
    
    listPartners1.PARVW = 'AG';
    listPartners1.KUNNR = '11111';
    listPartnersList.add(listPartners1);
    
    listPartners2.PARVW = 'RE';
    listPartners2.KUNNR = '11111';
    listPartnersList.add(listPartners2);
    
    listPartners3.PARVW = 'RG';
    listPartners3.KUNNR = '11111';
    listPartnersList.add(listPartners3);
    
    listPartners4.PARVW = 'WE';
    listPartners4.KUNNR = '11111';
    listPartnersList.add(listPartners4);
    
    listPartners5.PARVW = 'ZC';
    listPartners5.KUNNR = '11111';
    listPartnersList.add(listPartners5 );
    
    listOrder.partners = new List<TemplateDataINtegrationFields.PartnerInsert>();
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
    listOrder.conditions = new List<TemplateDataINtegrationFields.ConditionInsert>();
    listOrder.conditions.addAll(listConditionList);
    listOrderList.add(listOrder);
    Test.startTest();
    IntegrationINOrder.ResponseModel modelo = IntegrationINOrder.upsertOrderValidation(listOrderList);
    Test.stopTest();
}
    
    
    @isTest 
	static void verifyIntegrationOrderItem(){
        List<TemplateDataINtegrationFields.OrderINData> listOrderList = new List<TemplateDataINtegrationFields.OrderINData>();
        TemplateDataIntegrationFields.OrderINData listOrder = new TemplateDataIntegrationFields.OrderINData();
        listOrder.CodigoSap = '1002';
        listOrder.numeroPedidoApp = '686BB';
        listOrder.eCalendarizacao = false;
        listOrder.Status = null;
        listOrder.PriceBook2Id = null;
        listOrder.ShippingAccount = '11111';
        listOrder.paymentDate = null;
        listOrder.effectiveDate = null;
        listOrder.Crop = null;
        listOrder.Culture = null;
        listOrder.PaymentForm = null;
        listOrder.CurrencyOrder = 'BRL';
        //listOrder.SalesCTV = '0001004579';
        listOrder.Incoterms = 'CIF';
        listOrder.Incoterms2 = 'null';
        listOrder.Description = '';
        listOrder.PaymentCondition = null;
        listOrder.ShippingDate = Date.today();
        listOrder.DescriptionBillingSale = 'null';
        listOrder.OrderReference = null;
        listOrder.hectare = 10;
        listOrder.condicaoVenda = '01';
        listOrder.pedidoMae = false;
        listOrder.SalesOrg = null;
        //listOrder.CentroFornecedor = '1001';
        listOrder.DistributionChannel = null;
        //listOrder.EquipeVendas = '001';
        //listOrder.EscritorioVendas = '3511';
        listOrder.activitySector = null;
        listOrder.salesType = 'ZVNO';
        listOrder.valorFinalTotal = 1004.347505;
        listOrder.margemPedido = 5.885115;
        listOrder.orderType = 'Pedido Normal';
        
        TemplateDataIntegrationFields.OrderItemINData listOrderItem = new TemplateDataIntegrationFields.OrderItemINData();
        listOrderItem.valorTotal =  1004.347505;
        listOrderItem.valorDescontoFin =  96.2647;
        listOrderItem.valorAcrescFin =  null;
        listOrderItem.valorAcrescComercial =  null;
        listOrderItem.unidadeMedida =  null;
        listOrderItem.quantidade =  5;
        listOrderItem.precoUnitario =  255.57; 
        listOrderItem.precoPraticado =  200.869501;
        listOrderItem.porcentagemDescontoFin =  null;
        listOrderItem.porcentagemDesconto =  null;
        listOrderItem.porcentagemComissao =  null;
        listOrderItem.porcentagemAcrescFin =  0;
        listOrderItem.porcentagemAcrescComercial =  null;
        listOrderItem.orderItemECalendariazacao =  false;
        listOrderItem.orderItemCode =  '10';
        listOrderItem.motivoRecusa =  null;
        listOrderItem.material =  null;
        listOrderItem.margemComercial =  1;
        listOrderItem.dosagem =  null;
        listOrderItem.descontoValor =  177.237795;
        listOrderItem.custoPreco =  189.05;
        listOrderItem.custoLista =  204.45;
        listOrderItem.comissaoValor =  null;
        listOrder.orderItems = new List<TemplateDataIntegrationFields.OrderItemINData>();
        listOrder.orderItems.add(listOrderItem);
    
        TemplateDataIntegrationFields.ShippingDivisonINData listShippingDivision = new TemplateDataIntegrationFields.ShippingDivisonINData();
        listShippingDivision.Quantidade =  5;
        listShippingDivision.OrderItemCode =  '10';
        listShippingDivision.NumeroDivisaoRemessa =  '1002';
        listShippingDivision.material =  '0001';
        listShippingDivision.DivisaoRemessa =  '001';
        listShippingDivision.DataDivisao =  Date.valueOf('2022-09-21');
        listOrder.shippingDivison = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
        listOrder.shippingDivison.add(listShippingDivision);
    
        List<TemplateDataINtegrationFields.PartnerInsert> listPartnersList = new List<TemplateDataINtegrationFields.PartnerInsert>();
        TemplateDataIntegrationFields.PartnerInsert listPartners1 = new TemplateDataIntegrationFields.PartnerInsert();
        TemplateDataIntegrationFields.PartnerInsert listPartners2 = new TemplateDataIntegrationFields.PartnerInsert();
        TemplateDataIntegrationFields.PartnerInsert listPartners3 = new TemplateDataIntegrationFields.PartnerInsert();
        TemplateDataIntegrationFields.PartnerInsert listPartners4 = new TemplateDataIntegrationFields.PartnerInsert();
        TemplateDataIntegrationFields.PartnerInsert listPartners5 = new TemplateDataIntegrationFields.PartnerInsert();
        
        listPartners1.PARVW = 'AG';
        listPartners1.KUNNR = '11111';
        listPartnersList.add(listPartners1);
        
        listPartners2.PARVW = 'RE';
        listPartners2.KUNNR = '11111';
        listPartnersList.add(listPartners2);
        
        listPartners3.PARVW = 'RG';
        listPartners3.KUNNR = '11111';
        listPartnersList.add(listPartners3);
        
        listPartners4.PARVW = 'WE';
        listPartners4.KUNNR = '11111';
        listPartnersList.add(listPartners4);
        
        listPartners5.PARVW = 'ZC';
        listPartners5.KUNNR = '11111';
        listPartnersList.add(listPartners5 );
        
        listOrder.partners = new List<TemplateDataINtegrationFields.PartnerInsert>();
        listOrder.partners.addAll(listPartnersList);
    
        List<TemplateDataINtegrationFields.ConditionInsert> listConditionList = new List<TemplateDataINtegrationFields.ConditionInsert>();
        TemplateDataIntegrationFields.ConditionInsert listCondition1 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition2 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition3 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition4 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition5 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition6 = new TemplateDataIntegrationFields.ConditionInsert();
        listCondition1.KSCHL = 'ZPR0';
        listCondition1.KPOSN = '10';
        listCondition1.KPEIN = '1';
        listCondition1.KNUMV = '0000001665';
        listCondition1.KBETR = '10500.0';
        listConditionList.add(listCondition1);
        
        listCondition2.KSCHL = 'ZDAC';
        listCondition2.KPOSN = '10';
        listCondition2.KPEIN = '0';
        listCondition2.KNUMV = '0000001665';
        listCondition2.KBETR = '8.933333';
        listConditionList.add(listCondition2);
        
        listCondition3.KSCHL = 'ZJUC';
        listCondition3.KPOSN = '10';
        listCondition3.KPEIN = '0';
        listCondition3.KNUMV = '0000001665';
        listCondition3.KBETR = '0';
        listConditionList.add(listCondition3);
        
        listCondition4.KSCHL = 'ZDEC';
        listCondition4.KPOSN = '10';
        listCondition4.KPEIN = '0';
        listCondition4.KNUMV = '0000001665';
        listCondition4.KBETR = '-10';
        listConditionList.add(listCondition4);
        
        listCondition5.KSCHL = 'ZMAR';
        listCondition5.KPOSN = '10';
        listCondition5.KPEIN = '0';
        listCondition5.KNUMV = '0000001665';
        listCondition5.KBETR = '109';
        listConditionList.add(listCondition5);
        
        listCondition6.KSCHL = 'ZCP0';
        listCondition6.KPOSN = '10';
        listCondition6.KPEIN = '0';
        listCondition6.KNUMV = '0000001665';
        listCondition6.KBETR = '1200';
        listConditionList.add(listCondition6);
        
        listOrder.conditions = new List<TemplateDataINtegrationFields.ConditionInsert>();
        listOrder.conditions.addAll(listConditionList);
        listOrderList.add(listOrder);
        Test.startTest();
        IntegrationINOrder.ResponseModel modelo = IntegrationINOrder.upsertOrderValidation(listOrderList);
        Test.stopTest();
    }
    
    @isTest 
	static void verifyIntegrationOrderInsert(){
        List<TemplateDataINtegrationFields.OrderINData> listOrderList = new List<TemplateDataINtegrationFields.OrderINData>();
        TemplateDataIntegrationFields.OrderINData listOrder = new TemplateDataIntegrationFields.OrderINData();
        listOrder.CodigoSap = '1003';
        listOrder.numeroPedidoApp = null;
        listOrder.eCalendarizacao = false;
        listOrder.Status = '2';
        listOrder.PriceBook2Id = null;
        listOrder.ShippingAccount = '11111';
        listOrder.paymentDate = Date.today();
        listOrder.effectiveDate = Date.today();
        listOrder.Crop = '1223' ;
        listOrder.Culture = '1234' ;
        listOrder.PaymentForm = 'B';
        listOrder.CurrencyOrder = 'BRL';
        //listOrder.SalesCTV = '0001004579';
        listOrder.Incoterms = 'CIF';
        listOrder.Incoterms2 = 'null';
        listOrder.Description = '';
        listOrder.PaymentCondition = 'Z09' ;
        listOrder.ShippingDate = Date.today();
        listOrder.DescriptionBillingSale = 'null';
        listOrder.OrderReference = null;
        listOrder.hectare = 10;
        listOrder.condicaoVenda = '01';
        listOrder.pedidoMae = false;
        listOrder.SalesOrg = null;
        //listOrder.CentroFornecedor = '1001';
        listOrder.DistributionChannel = '0001';
        //listOrder.EquipeVendas = '001';
        //listOrder.EscritorioVendas = '3511';
        listOrder.activitySector = '003' ;
        listOrder.salesType = 'ZVNO';
        listOrder.valorFinalTotal = 1004.347505;
        listOrder.margemPedido = 5.885115;
        listOrder.orderType = 'Pedido Normal';
        
        TemplateDataIntegrationFields.OrderItemINData listOrderItem = new TemplateDataIntegrationFields.OrderItemINData();
        listOrderItem.valorTotal =  1004.347505;
        listOrderItem.valorDescontoFin =  96.2647;
        listOrderItem.valorAcrescFin =  null;
        listOrderItem.valorAcrescComercial =  null;
        listOrderItem.unidadeMedida =  null;
        listOrderItem.quantidade =  5;
        listOrderItem.precoUnitario =  255.57; 
        listOrderItem.precoPraticado =  200.869501;
        listOrderItem.porcentagemDescontoFin =  null;
        listOrderItem.porcentagemDesconto =  null;
        listOrderItem.porcentagemComissao =  null;
        listOrderItem.porcentagemAcrescFin =  0;
        listOrderItem.porcentagemAcrescComercial =  null;
        listOrderItem.orderItemECalendariazacao =  false;
        listOrderItem.orderItemCode =  '10';
        listOrderItem.motivoRecusa =  null;
        listOrderItem.material =  null;
        listOrderItem.margemComercial =  1;
        listOrderItem.dosagem =  null;
        listOrderItem.descontoValor =  177.237795;
        listOrderItem.custoPreco =  189.05;
        listOrderItem.custoLista =  204.45;
        listOrderItem.comissaoValor =  null;
        listOrder.orderItems = new List<TemplateDataIntegrationFields.OrderItemINData>();
        listOrder.orderItems.add(listOrderItem);
    
        TemplateDataIntegrationFields.ShippingDivisonINData listShippingDivision = new TemplateDataIntegrationFields.ShippingDivisonINData();
        listShippingDivision.Quantidade =  5;
        listShippingDivision.OrderItemCode =  '10';
        listShippingDivision.NumeroDivisaoRemessa =  '1002';
        listShippingDivision.material =  '0001';
        listShippingDivision.DivisaoRemessa =  '001';
        listShippingDivision.DataDivisao =  Date.valueOf('2022-09-21');
        listOrder.shippingDivison = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
        listOrder.shippingDivison.add(listShippingDivision);
    
        List<TemplateDataINtegrationFields.PartnerInsert> listPartnersList = new List<TemplateDataINtegrationFields.PartnerInsert>();
        TemplateDataIntegrationFields.PartnerInsert listPartners1 = new TemplateDataIntegrationFields.PartnerInsert();
        TemplateDataIntegrationFields.PartnerInsert listPartners2 = new TemplateDataIntegrationFields.PartnerInsert();
        TemplateDataIntegrationFields.PartnerInsert listPartners3 = new TemplateDataIntegrationFields.PartnerInsert();
        TemplateDataIntegrationFields.PartnerInsert listPartners4 = new TemplateDataIntegrationFields.PartnerInsert();
        TemplateDataIntegrationFields.PartnerInsert listPartners5 = new TemplateDataIntegrationFields.PartnerInsert();
        
        listPartners1.PARVW = 'AG';
        listPartners1.KUNNR = '11111';
        listPartnersList.add(listPartners1);
        
        listPartners2.PARVW = 'RE';
        listPartners2.KUNNR = '11111';
        listPartnersList.add(listPartners2);
        
        listPartners3.PARVW = 'RG';
        listPartners3.KUNNR = '11111';
        listPartnersList.add(listPartners3);
        
        listPartners4.PARVW = 'WE';
        listPartners4.KUNNR = '11111';
        listPartnersList.add(listPartners4);
        
        listPartners5.PARVW = 'ZC';
        listPartners5.KUNNR = '11111';
        listPartnersList.add(listPartners5 );
        
        listOrder.partners = new List<TemplateDataINtegrationFields.PartnerInsert>();
        listOrder.partners.addAll(listPartnersList);
    
        List<TemplateDataINtegrationFields.ConditionInsert> listConditionList = new List<TemplateDataINtegrationFields.ConditionInsert>();
        TemplateDataIntegrationFields.ConditionInsert listCondition1 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition2 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition3 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition4 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition5 = new TemplateDataIntegrationFields.ConditionInsert();
        TemplateDataIntegrationFields.ConditionInsert listCondition6 = new TemplateDataIntegrationFields.ConditionInsert();
        listCondition1.KSCHL = 'ZPR0';
        listCondition1.KPOSN = '10';
        listCondition1.KPEIN = '1';
        listCondition1.KNUMV = '0000001665';
        listCondition1.KBETR = '10500.0';
        listConditionList.add(listCondition1);
        
        listCondition2.KSCHL = 'ZDAC';
        listCondition2.KPOSN = '10';
        listCondition2.KPEIN = '0';
        listCondition2.KNUMV = '0000001665';
        listCondition2.KBETR = '8.933333';
        listConditionList.add(listCondition2);
        
        listCondition3.KSCHL = 'ZJUC';
        listCondition3.KPOSN = '10';
        listCondition3.KPEIN = '0';
        listCondition3.KNUMV = '0000001665';
        listCondition3.KBETR = '0';
        listConditionList.add(listCondition3);
        
        listCondition4.KSCHL = 'ZDEC';
        listCondition4.KPOSN = '10';
        listCondition4.KPEIN = '0';
        listCondition4.KNUMV = '0000001665';
        listCondition4.KBETR = '-10';
        listConditionList.add(listCondition4);
        
        listCondition5.KSCHL = 'ZMAR';
        listCondition5.KPOSN = '10';
        listCondition5.KPEIN = '0';
        listCondition5.KNUMV = '0000001665';
        listCondition5.KBETR = '109';
        listConditionList.add(listCondition5);
        
        listCondition6.KSCHL = 'ZCP0';
        listCondition6.KPOSN = '10';
        listCondition6.KPEIN = '0';
        listCondition6.KNUMV = '0000001665';
        listCondition6.KBETR = '1200';
        listConditionList.add(listCondition6);
        
        listOrder.conditions = new List<TemplateDataINtegrationFields.ConditionInsert>();
        listOrder.conditions.addAll(listConditionList);
        listOrderList.add(listOrder);
        Test.startTest();
        IntegrationINOrder.ResponseModel modelo = IntegrationINOrder.upsertOrderValidation(listOrderList);
        Test.stopTest();
    }
    
    @isTest 
	static void verifyIntegrationOrderAppDigital(){
        List<TemplateDataINtegrationFields.OrderINData> listOrderList = new List<TemplateDataINtegrationFields.OrderINData>();
        TemplateDataIntegrationFields.OrderINData listOrder = new TemplateDataIntegrationFields.OrderINData();
        listOrder.CodigoSap = null;
        listOrder.numeroPedidoApp = '007';
        listOrder.eCalendarizacao = false;
        listOrder.Status = '2';
        listOrder.PriceBook2Id = null;
        listOrder.ShippingAccount = '11111';
        listOrder.paymentDate = Date.today();
        listOrder.effectiveDate = Date.today();
        listOrder.Crop = '1223' ;
        listOrder.Culture = '1234' ;
        listOrder.PaymentForm = 'B';
        listOrder.CurrencyOrder = 'BRL';
        //listOrder.SalesCTV = '0001004579';
        listOrder.Incoterms = 'CIF';
        listOrder.Incoterms2 = 'null';
        listOrder.Description = '';
        listOrder.PaymentCondition = 'Z09' ;
        listOrder.ShippingDate = Date.today();
        listOrder.DescriptionBillingSale = 'null';
        listOrder.OrderReference = null;
        listOrder.hectare = 10;
        listOrder.condicaoVenda = '01';
        listOrder.pedidoMae = false;
        listOrder.SalesOrg = null;
        //listOrder.CentroFornecedor = '1001';
        listOrder.DistributionChannel = '0001';
        //listOrder.EquipeVendas = '001';
        //listOrder.EscritorioVendas = '3511';
        listOrder.activitySector = '003' ;
        listOrder.salesType = 'ZVNO';
        listOrder.valorFinalTotal = 1004.347505;
        listOrder.margemPedido = 5.885115;
        listOrder.orderType = 'Pedido Normal';
        
        TemplateDataIntegrationFields.OrderItemINData listOrderItem = new TemplateDataIntegrationFields.OrderItemINData();
        listOrderItem.valorTotal =  1004.347505;
        listOrderItem.valorDescontoFin =  96.2647;
        listOrderItem.valorAcrescFin =  1;
        listOrderItem.valorAcrescComercial =  4;
        listOrderItem.unidadeMedida =  'l';
        listOrderItem.quantidade =  5;
        listOrderItem.precoUnitario =  255.57; 
        listOrderItem.precoPraticado =  200.869501;
        listOrderItem.porcentagemDescontoFin =  1;
        listOrderItem.porcentagemDesconto =  2;
        listOrderItem.porcentagemComissao =  3;
        listOrderItem.porcentagemAcrescFin =  0;
        listOrderItem.porcentagemAcrescComercial =  4;
        listOrderItem.orderItemECalendariazacao =  false;
        listOrderItem.orderItemCode =  '10';
        listOrderItem.motivoRecusa =  null;
        listOrderItem.material =  '0001';
        listOrderItem.margemComercial =  1;
        listOrderItem.dosagem =  12;
        listOrderItem.descontoValor =  177.237795;
        listOrderItem.custoPreco =  189.05;
        listOrderItem.custoLista =  204.45;
        listOrderItem.comissaoValor =  2;
        listOrder.orderItems = new List<TemplateDataIntegrationFields.OrderItemINData>();
        listOrder.orderItems.add(listOrderItem);
    
        TemplateDataIntegrationFields.ShippingDivisonINData listShippingDivision = new TemplateDataIntegrationFields.ShippingDivisonINData();
        listShippingDivision.Quantidade =  5;
        listShippingDivision.OrderItemCode =  '10';
        listShippingDivision.NumeroDivisaoRemessa =  '1002';
        listShippingDivision.material =  '0001';
        listShippingDivision.DivisaoRemessa =  '001';
        listShippingDivision.DataDivisao =  Date.valueOf('2022-09-21');
        listOrder.shippingDivison = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
        listOrder.shippingDivison.add(listShippingDivision);
  
        listOrderList.add(listOrder);
        Test.startTest();
        IntegrationINOrderAppdigital.ResponseModel modelo = IntegrationINOrderAppdigital.upsertOrder(listOrderList);
        Test.stopTest();
    }
    
     @isTest 
	static void verifyIntegrationOrderAppDigitalUpdate(){
        List<TemplateDataINtegrationFields.OrderINData> listOrderList = new List<TemplateDataINtegrationFields.OrderINData>();
        TemplateDataIntegrationFields.OrderINData listOrder = new TemplateDataIntegrationFields.OrderINData();
        listOrder.CodigoSap = '1009';
        listOrder.numeroPedidoApp = null;
        listOrder.eCalendarizacao = true;
        listOrder.Status = null;
        listOrder.PriceBook2Id = null;
        listOrder.ShippingAccount = null;
        listOrder.paymentDate = null;
        listOrder.effectiveDate = null;
        listOrder.Crop = null ;
        listOrder.Culture = null ;
        listOrder.PaymentForm = null;
        listOrder.CurrencyOrder = 'BRL';
        //listOrder.SalesCTV = '0001004579';
        listOrder.Incoterms = null;
        listOrder.Incoterms2 = null;
        listOrder.Description = '';
        listOrder.PaymentCondition = null ;
        listOrder.ShippingDate = null;
        listOrder.DescriptionBillingSale = null;
        listOrder.OrderReference = null;
        listOrder.hectare = null;
        listOrder.condicaoVenda = null;
        listOrder.pedidoMae = false;
        listOrder.SalesOrg = null;
        //listOrder.CentroFornecedor = '1001';
        listOrder.DistributionChannel = null;
        //listOrder.EquipeVendas = '001';
        //listOrder.EscritorioVendas = '3511';
        listOrder.activitySector = '003' ;
        listOrder.salesType = 'ZVNO';
        listOrder.valorFinalTotal = 1004.347505;
        listOrder.margemPedido = 5.885115;
        listOrder.orderType = 'Pedido Normal';
        
        TemplateDataIntegrationFields.OrderItemINData listOrderItem = new TemplateDataIntegrationFields.OrderItemINData();
        listOrderItem.valorTotal =  1004.347505;
        listOrderItem.valorDescontoFin =  96.2647;
        listOrderItem.valorAcrescFin =  null;
        listOrderItem.valorAcrescComercial =  null;
        listOrderItem.unidadeMedida =  null;
        listOrderItem.quantidade =  5;
        listOrderItem.precoUnitario =  255.57; 
        listOrderItem.precoPraticado =  200.869501;
        listOrderItem.porcentagemDescontoFin =  null;
        listOrderItem.porcentagemDesconto =  null;
        listOrderItem.porcentagemComissao =  null;
        listOrderItem.porcentagemAcrescFin =  0;
        listOrderItem.porcentagemAcrescComercial =  null;
        listOrderItem.orderItemECalendariazacao =  false;
        listOrderItem.orderItemCode =  '10';
        listOrderItem.motivoRecusa =  null;
        listOrderItem.material =  '0001';
        listOrderItem.margemComercial =  1;
        listOrderItem.dosagem =  null;
        listOrderItem.descontoValor =  177.237795;
        listOrderItem.custoPreco =  189.05;
        listOrderItem.custoLista =  204.45;
        listOrderItem.comissaoValor =  null;
        listOrder.orderItems = new List<TemplateDataIntegrationFields.OrderItemINData>();
        listOrder.orderItems.add(listOrderItem);
    
        TemplateDataIntegrationFields.ShippingDivisonINData listShippingDivision = new TemplateDataIntegrationFields.ShippingDivisonINData();
        listShippingDivision.Quantidade =  5;
        listShippingDivision.OrderItemCode =  '10';
        listShippingDivision.NumeroDivisaoRemessa =  '1002';
        listShippingDivision.material =  '0001';
        listShippingDivision.DivisaoRemessa =  '001';
        listShippingDivision.DataDivisao =  Date.valueOf('2022-09-21');
        listOrder.shippingDivison = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
        listOrder.shippingDivison.add(listShippingDivision);
   		
        listOrderList.add(listOrder);
        Test.startTest();
        IntegrationINOrderAppdigital.ResponseModel modelo = IntegrationINOrderAppdigital.upsertOrder(listOrderList);
        Test.stopTest();
    }
}