@isTest
public with sharing class CalloutOrderTest {

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
            ExternalId__c = '11111'
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
            ExternalId__c = '0001'
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
            UnitMeasure__c = 'L',
            UnitPrice = 10000,
            Quantity = 1,
            PricebookEntryId = standardPrice.Id
        );

        INSERT orderItem;
    }
    public CalloutOrderTest() {}

    @isTest
    static void CalloutOrderSuccess(){

    } 

    @isTest 
    static void CalloutOrderFail(){

    }

    @isTest 
    static void CalloutOrderTimeout(){

    }
}
