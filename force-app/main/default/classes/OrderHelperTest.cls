@isTest
public with sharing class OrderHelperTest {

    @TestSetup
    static void makeData(){
        Account account = new Account(
            Name = 'Teste 1',
            BillingStreet = ' ',
            BpType__c = 'Proprietario',
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
            PaymentBaseDate__c = System.today(),
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

        SalesOrg__c so1 = new SalesOrg__c(
            Name = 'Sementes',
            SalesOrganizationCode__c = '1700'
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
        salesCondition__c sales = new salesCondition__c(
            Name = 'Condição',
            ExternalId__c = '1'
        );

        INSERT sales;
        INSERT so1;
        INSERT account;
        INSERT safra;
        INSERT cultura;
        INSERT so;
        INSERT distributionChannel;
        INSERT u;
        

        Account account3 = new Account(
            Name = 'Teste 3',
            BillingStreet = ' ',
            BillingState = '' ,
            BpType__c = 'Propriedade',
            Phone= '', 
            BillingCity = ' ', 
            BillingLongitude = 000000,
            BillingLatitude = 00000,
            BillingPostalCode = '',
            ExternalId__c = '113123',
            Company__c = 'Empresa 02'
        );
        INSERT account3;

        Account account2 = new Account(
            Name = 'Teste 2',
            BillingStreet = ' ',
            ParentId = account.Id,
            BillingState = '' ,
            BpType__c = 'Propriedade',
            Phone= '', 
            BillingCity = ' ', 
            BillingLongitude = 000000,
            BillingLatitude = 00000,
            BillingPostalCode = '',
            ExternalId__c = '11122',
            Company__c = 'Empresa 02'
        );
        INSERT account2;
        Map <String,Schema.RecordTypeInfo> recordTypeMap = Order.sObjectType.getDescribe().getRecordTypeInfosByName();
 		Delimitadores__c delimiter = new Delimitadores__c(
            Name = '',
            EndDateBilling__c = System.today().addDays(30),
            EndDateOV__c = System.today().addDays(30),
            ExternalId__c = '' ,
            FinancialBaseDate__c = System.today().addDays(15),
            Safra__c= safra.Id, 
            SalesCondition__c = sales.Id, 
            SalesOrg__c = so.Id,
            StartDateBilling__c = System.today(),
            StartDateOV__c = System.today()
        );

        INSERT delimiter;

        Delimitadores__c delimiter2 = new Delimitadores__c(
            Name = '',
            EndDateBilling__c = System.today().addDays(30),
            EndDateOV__c = System.today().addDays(30),
            ExternalId__c = '' ,
            FinancialBaseDate__c = System.today().addDays(15),
            Safra__c= safra.Id, 
            SalesCondition__c = sales.Id, 
            SalesOrg__c = so1.Id,
            StartDateBilling__c = System.today(),
            StartDateOV__c = System.today()
        );

        INSERT delimiter2;
        Order order = new Order(
            AccountId =  account.Id,
            CodigoSap__c = '001',
            Status = '3',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Normal',
            RecordTypeId = recordTypeMap.get('Venda Normal').getRecordTypeId(),
            ShippingAccount__c =   account.Id,
            ShippingDate__c =  Date.today(),
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  safra.Id,
            Culture__c = cultura.Id,
            PaymentForm__c =  'B',
            SalesOrg__c =  so.Id,
            FinalTotalValue__c = 1000.00,
            SalesCondition__c = sales.Id,
            DistributionChannel__c =  distributionChannel.Id,
            Currency__c =  'BRL',
            SalesCTV__c =  u.Id,
            StatusSF__c = 'Em digitação',
            EndDate = Date.today(),
            Incoterms__c = 'CIF'
        );

        Order order1 = new Order(
            AccountId =  account.Id,
            CodigoSap__c = '002',
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Normal',
            RecordTypeId = recordTypeMap.get('Venda Normal').getRecordTypeId(),
            ShippingAccount__c =   account.Id,
            ShippingDate__c =  Date.today(),
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  safra.Id,
            Culture__c = cultura.Id,
            PaymentForm__c =  'B',
            SalesOrg__c =  so1.Id,
            FinalTotalValue__c = 1000.00,
            SalesCondition__c = sales.Id,
            DistributionChannel__c =  distributionChannel.Id,
            Currency__c =  'BRL',
            SalesCTV__c =  u.Id,
            StatusSF__c = 'Em digitação',
            EndDate = Date.today(),
            Incoterms__c = 'CIF'
        );
        
        Order order2 = new Order(
            AccountId =  account.Id,
            CodigoSap__c = '003',
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Barter',
            RecordTypeId = recordTypeMap.get('Venda Barter').getRecordTypeId(),
            ShippingAccount__c =   account.Id,
            ShippingDate__c =  Date.today(),
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  safra.Id,
            Culture__c = cultura.Id,
            PaymentForm__c =  'B',
            SalesOrg__c =  so.Id,
            FinalTotalValue__c = 1000.00,
            SalesCondition__c = sales.Id,
            DistributionChannel__c =  distributionChannel.Id,
            Currency__c =  'BRL',
            SalesCTV__c =  u.Id,
            StatusSF__c = 'Em digitação',
            EndDate = Date.today(),
            Incoterms__c = 'CIF',
            MarginCommittee__c = true,
            Manager_BranchOffice__c = false,
            Gerente_Regional__c = false,
            Director__c = false,
            Aprovador_ComiteMargem__c = u.Id
        );

        Order order3 = new Order(
            AccountId =  account.Id,
            CodigoSap__c = '004',
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Barter',
            RecordTypeId = recordTypeMap.get('Venda Barter').getRecordTypeId(),
            ShippingAccount__c =   account.Id,
            ShippingDate__c =  Date.today(),
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  safra.Id,
            Culture__c = cultura.Id,
            PaymentForm__c =  'B',
            SalesOrg__c =  so1.Id,
            FinalTotalValue__c = 1000.00,
            SalesCondition__c = sales.Id,
            DistributionChannel__c =  distributionChannel.Id,
            Currency__c =  'BRL',
            SalesCTV__c =  u.Id,
            StatusSF__c = 'Em digitação',
            EndDate = Date.today(),
            Incoterms__c = 'CIF'
        );

        Order order4 = new Order(
            AccountId =  account.Id,
            CodigoSap__c = '005',
            Status = '0',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Normal',
            RecordTypeId = recordTypeMap.get('Venda Normal').getRecordTypeId(),
            ShippingAccount__c =   account.Id,
            ShippingDate__c =  Date.today(),
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  safra.Id,
            Culture__c = cultura.Id,
            PaymentForm__c =  'B',
            SalesOrg__c =  so.Id,
            FinalTotalValue__c = 1000.00,
            SalesCondition__c = sales.Id,
            DistributionChannel__c =  distributionChannel.Id,
            Currency__c =  'BRL',
            SalesCTV__c =  u.Id,
            StatusSF__c = 'Em digitação',
            EndDate = Date.today(),
            Incoterms__c = 'CIF',
            StageStatusApproval__c = '',
            MarginCommittee__c = true,
            Manager_BranchOffice__c = false,
            Gerente_Regional__c = false,
            Director__c = false,
            Aprovador_ComiteMargem__c = u.Id
        );

        Order order5 = new Order(
            AccountId =  account.Id,
            CodigoSap__c = '006',
            Status = '0',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Normal',
            RecordTypeId = recordTypeMap.get('Venda Normal').getRecordTypeId(),
            ShippingAccount__c =   account.Id,
            ShippingDate__c =  Date.today(),
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  safra.Id,
            Culture__c = cultura.Id,
            PaymentForm__c =  'B',
            SalesOrg__c =  so.Id,
            FinalTotalValue__c = 1000.00,
            SalesCondition__c = sales.Id,
            Description = '1n73gr4ção N3sc4r4 5F x 4PP',
            DistributionChannel__c =  distributionChannel.Id,
            Currency__c =  'BRL',
            SalesCTV__c =  u.Id,
            StatusSF__c = 'Integrado',
            EndDate = Date.today(),
            Incoterms__c = 'CIF',
            MarginCommittee__c = false,
            Manager_BranchOffice__c = false,
            Gerente_Regional__c = false,
            Director__c = false
        );

        Order order6 = new Order(
            AccountId =  account.Id,
            Status = '001',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Normal',
            RecordTypeId = recordTypeMap.get('Venda Normal').getRecordTypeId(),
            ShippingAccount__c =   account.Id,
            ShippingDate__c =  Date.today(),
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  safra.Id,
            Culture__c = cultura.Id,
            PaymentForm__c =  'B',
            SalesOrg__c =  so.Id,
            FinalTotalValue__c = 1000.00,
            SalesCondition__c = sales.Id,
            Description = '1n73gr4ção N3sc4r4 5F x 4PP',
            DistributionChannel__c =  distributionChannel.Id,
            Currency__c =  'BRL',
            SalesCTV__c =  u.Id,
            StatusSF__c = 'Em digitação',
            EndDate = Date.today(),
            Incoterms__c = 'CIF',
            MarginCommittee__c = false,
            Manager_BranchOffice__c = false,
            Gerente_Regional__c = false,
            Director__c = false
        );

        INSERT order;
        INSERT order1;
        INSERT order2;
        INSERT order3;
        INSERT order4;
        INSERT order5;
        INSERT order6;
        
        OrderCommodity__c orderCommodity_1 = new OrderCommodity__c(
        	CommodityPrice__c = 19.00,
            StartDate__c = System.today(),
            EndDate__c = System.today().addDays(5),
            Order__c = order2.Id
        );

        OrderCommodity__c orderCommodity_2 = new OrderCommodity__c(
        	CommodityPrice__c = 20.00,
            StartDate__c = System.today(),
            EndDate__c = System.today().addDays(5),
            Order__c = order3.Id
        );
        
        OrderCommodity__c orderCommodity_3 = new OrderCommodity__c(
        	CommodityPrice__c = 20.00,
            StartDate__c = System.today(),
            EndDate__c = System.today().addDays(5),
            Order__c = order4.Id
        );

        INSERT orderCommodity_1;
        INSERT orderCommodity_2;
        INSERT orderCommodity_3;

        FormPayment__c pF = new FormPayment__c(
            Amount__c = 5.00,
            PaymentDate__c = System.today(),
            PaymentType__c = 'Germoplasma',
            Order__c = order.Id
        );

        INSERT pF;

        Product2 prod = new Product2(
            Name = 'Laptop X200', 
            Family = 'Hardware',
            ExternalId__c = '0001',
            ClasseAvaliacao__c = 'chucrute',
            GrupoQuimico__c = 'Só o quimico',
            MarcadoEliminacao__c = 'S',
            NCM__c = 'S',
            NumeroRegistro__c = '0001',
            OrigemMaterial__c = 'Himalaia',
            UnidadeMedida__c = 'KG'
        );

        INSERT prod;

        ComboPromotion__c combo = new ComboPromotion__c(
            CombosQuantity__c = 10
        );

        INSERT combo;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = prod.Id,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id =: prod.Id LIMIT 1][0].Id,
            ListPrice__c = 150,
            ServiceDate = System.today(),
            Quantity = 10,
            UnitPrice = 160,
            PracticedCost__c = 130,
            PracticedPrice__c = 160,
            Status__c = '5',
            UnitMeasure__c = 'Each',
            FinalTotalValue__c = 1600,
            DiscountPercent__c = 0,
            DiscountValue__c = 0,
            CommercialAdditionPercent__c = 6.6666,
            CommercialAdditionValue__c = 100,
            FinancialAdditionPercent__c = 0,
            FinancialAdditionValue__c = 0,
            FinancialDiscountPercent__c = 0,
            FinancialDiscountValue__c = 0,
            ComissionValue__c = 0,
            CommercialMargin__c = 2,
            Dosage__c = 5,
            InvoicedQuantity__c = 0,
            NumeroSap__c = '001',
            ExternalId__c = order.Id + '|001',
            ComboPromotion__c = combo.Id
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

        VisitPlanning__c vp = new VisitPlanning__c(
            Name = 'test Visit',
            MainBP__c = account.Id,
            BP_Property__c = account2.Id,
            CTVvisit__c = 'Teste',
            VisitSeller__c = u.Id,
            Status__c = 'Agendado',
            Objetivo__c = 'Evento',
            EndTime__c  = Time.newInstance(1, 2, 3, 6),  
			StartTime__c = Time.newInstance(1, 2, 3, 1),
            Culture__c = cultura.Id,
            EndDate__c = System.today(),
            InitialDate__c = System.today(),
            Safra__c = safra.id,
            SellOrg__c = so.Id
        );
        insert vp;

        Cadastro_ClientedaVisita__c ccv = new Cadastro_ClientedaVisita__c(
            Account__c = account.Id,
            ChekIn__c = true,
            DataVisita__c = Datetime.now(),
            Local_da_Visita__c = 'Local teste',
            PlanejamentoVisita__c = vp.Id,
            Status_da_Visita__c = 'Planejada',
            Tipo_da_Visita__c = 'Serviço Técnico'
        );

        insert ccv;
        TechnicalReport__c technicalReport = new TechnicalReport__c(
            EndDate__c  = System.today(),
            EndTime__c = Time.newInstance(1, 2, 3, 1),
            CancellationReason__c = '',
            Note__c = 'test',
            Status__c = 'Gerado',
            VisitPlanning__c = vp.Id
        );
        insert technicalReport;
        List<Cadastro_ClientedaVisita__c> cvList = [SELECT Id FROM Cadastro_ClientedaVisita__c LIMIT 1];
        Fotos__c photo = new Fotos__c(
            ClienteVisita__c = ccv.Id,
            Observation__c = 'Teste',
            RTR__c = technicalReport.Id
        );
        insert photo;

       
        
    }

    public OrderHelperTest() {}

    @isTest
    public static void verifySendApprovalUpdate(){
        Order order = [SELECT Id, Status, StageStatusApproval__c, Description  FROM Order WHERE CodigoSap__c = '005' LIMIT 1];
        order.Status = '001';
        Test.startTest();
        UPDATE order;
        
        Test.stopTest();
        order = [SELECT Id, Status, StageStatusApproval__c FROM Order WHERE CodigoSap__c = '005' LIMIT 1];
        
        System.assertEquals('Aprovação Comitê de Margem / Pendente', order.StageStatusApproval__c, 'Deveria ser Aprovação Comitê de Margem / Pendente');
    }

    @isTest
    public static void verifySendApprovalUpdateWithoutSendApprovalProccess(){
        Order order = [SELECT Id, Status FROM Order WHERE CodigoSap__c = '006' LIMIT 1];
        order.Status = '001';
        UPDATE order;
    }

    @IsTest
    public static void sendToIntegrationTest(){
        List<Order> newRecords = [SELECT Id, OrderNumber, OrderReference__c, Status, StatusSF__c, CodigoSap__c, IsDisableSendIntegration__c, RecordTypeId  FROM Order LIMIT 10];
        OrderHelper.calloutOrderToSAPTest(newRecords);
    }

    @isTest
    public static void verifyActionAura(){
        Order order = [SELECT Id FROM Order LIMIT 1];
        OrderHelper.sendToIntegrationTest(order.Id);
    }

    @isTest
    public static void verifyCombos(){
        Map<Id, Order> oldMap = new Map<Id, Order>([SELECT Id, Status FROM Order]);
        Order order = [SELECT Id, Status FROM Order WHERE CodigoSap__c = '001' LIMIT 1];
        order.Status = 'X';
        Test.startTest();
   		UPDATE order;
        Test.stopTest();
        ComboPromotion__c combo = [SELECT CombosQuantity__c FROM ComboPromotion__c LIMIT 1];
        System.assertEquals(11, combo.CombosQuantity__c, 'Deveria vir 11');
    }

    @isTest
    public static void verifyEnqueueJobsBarter(){
        Order order = [SELECT Id FROM Order LIMIT 1];
        System.enqueueJob(new OrderHelper.calloutsQueueBarter(order.Id));
    }

    @isTest
    public static void verifyEnqueueJobsDataLake(){
        Order order = [SELECT Id FROM Order LIMIT 1];
        System.enqueueJob(new OrderHelper.calloutDatalakeQueue(order.Id));
    }

    @isTest 
    public static void verifyCancelOrder(){
        List<Order> newRecords = [SELECT Id, StatusSF__c, CodigoSap__c FROM Order LIMIT 10];
        OrderHelper.verifyStatus(newRecords);
    }
}