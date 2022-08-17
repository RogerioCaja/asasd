@isTest
public with sharing class CalloutOrderDatalakeTest {
    public CalloutOrderDatalakeTest() {

    }
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
            PaymentBaseDate__c = System.today(),
            ReleaseStatus__c = 'Ativo',
            StartDateOrderInsertion__c = System.today()

        );
        ActivitySector__c activitySector = new ActivitySector__c(
            Name = 'Teste Activity',
            Codigo__c = '003'
        );
        insert activitySector;
        
        salesCondition__c sales = new salesCondition__c(
            Name = 'Condição',
            ExternalId__c = '1'
        );
        INSERT sales;

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
            Name = 'Sales team',
            ExternalId__c = '001'
        );
        insert salesTeam;
        
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert parentAccount;
        
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

        Order order = new Order(
            AccountId =  account.Id,
            Status = '2',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Normal',
            ShippingAccount__c =   account.Id,
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  safra.Id,
            Culture__c = cultura.Id,
            PaymentForm__c =  'B',
            SalesOrg__c =  so.Id,
            DistributionChannel__c =  distributionChannel.Id,
            ActivitySector__c =  activitySector.Id,
            Currency__c =  'BRL',
            SalesCTV__c =  u.Id,
            StatusSF__c = 'Em digitação',
            Incoterms__c = 'CIF',
            Company__c = company.Id,
            SalesCondition__c = sales.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Venda Normal').getRecordTypeId()
        );

        INSERT order;
        
          Order order2 = new Order(
            AccountId =  account.Id,
            CodigoSap__c = '1002',
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Normal',
            ShippingAccount__c =   account.Id,
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  safra.Id,
            Culture__c = cultura.Id,
            PaymentForm__c =  'B',
            SalesOrg__c =  so.Id,
            DistributionChannel__c =  distributionChannel.Id,
            ActivitySector__c =  activitySector.Id,
            Currency__c =  'BRL',
            SalesCTV__c =  u.Id,
            StatusSF__c = 'Em digitação',
            Incoterms__c = 'CIF',
            Company__c = company.Id,
            SalesCondition__c = sales.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Venda Normal').getRecordTypeId()
        );

        INSERT order2;

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
            ExternalId__c = order.Id + '|001'
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
    static void calloutOrderSuccess(){
        CalloutOrderDatalake calloutTest = new CalloutOrderDatalake();
        Order ord = [SELECT Id, OrderNumber, StatusSF__c, StatusSAP__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class, new CalloutOrderMockDatalake(true, String.valueOf(ord.OrderNumber), false));
        Test.startTest();
        IntegrationUtils.CalloutDatalakeResponse response = CalloutOrderDatalake.processIntegration(ord.Id);
        Test.stopTest();
        System.debug(response);
        System.assertEquals(true, response.success, 'O status era para vir Verdadeiro');
        System.assertEquals(null, response.errorMessage, 'A mensagem de Erro deveria vir vazia');
        
    } 
    
    @isTest
    static void calloutOrderSuccessUpdate(){
        CalloutOrderDatalake calloutTest = new CalloutOrderDatalake();
        Order ord = [SELECT Id, OrderNumber, StatusSF__c, StatusSAP__c FROM Order WHERE CodigoSap__c = '1002' LIMIT 1 ][0];
        Test.setMock(HttpCalloutMock.class, new CalloutOrderMockDatalake(true, String.valueOf(ord.OrderNumber), false));
        Test.startTest();
        IntegrationUtils.CalloutDatalakeResponse response = CalloutOrderDatalake.processIntegration(ord.Id);
        Test.stopTest();
        System.debug(response);
        System.assertEquals(true, response.success, 'O status era para vir Verdadeiro');
        System.assertEquals(null, response.errorMessage, 'A mensagem de Erro deveria vir vazia');
        
    } 

    @isTest 
    static void calloutOrderFail(){
        Order ord = [SELECT Id, OrderNumber, StatusSF__c, StatusSAP__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class,new CalloutOrderMockDatalake(false, String.valueOf(ord.OrderNumber), false));
        Test.startTest();
        IntegrationUtils.CalloutDatalakeResponse response = CalloutOrderDatalake.processIntegration(ord.Id);
        Test.stopTest();
        System.debug(response);
        System.assertEquals(false, response.success, 'O status era para vir falso');
    }

    @isTest 
    static void calloutOrderException(){
        Order ord = [SELECT Id, OrderNumber, StatusSF__c, StatusSAP__c FROM Order LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class, new ExceptionCallouts());
        Test.startTest();
        IntegrationUtils.CalloutDatalakeResponse response = CalloutOrderDatalake.processIntegration(ord.Id);
        Test.stopTest();
        System.assertEquals('Error', response.errorMessage, 'Deveria ter falhado');
    }
    
    @isTest
    static void calloutOrderToken(){
        Test.setMock(HttpCalloutMock.class, new CalloutOrderMockDatalake(true, '0000023', true));
        Test.startTest();
        String response = CalloutOrderDatalake.getAcessCode();
        Test.stopTest();
    }
}