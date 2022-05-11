
public class TemplateDefaultFields {
	
    public interface FieldDefaults { 
        Map<String, Object> getFieldDefaults();
    }

    public Account createAccount(){
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

        return account;
    }

    public Safra__c createSafra(){
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
        return safra; 
    }

    public Pricebook2 createPricebook2(){
        Pricebook2 pricebook = new Pricebook2(
            Name ='Price Book Test',
            Description = 'Teste',
            ExternalId__c = '0001',
            IsActive =true
        );

        return pricebook;
    }

    public Cultura__c createCultura(){
        Cultura__c cultura = new Cultura__c(
            Name = 'Cultura Teste',
            Name__c = 'Cultura Teste',
            Codigo__c = '1234'
        );

        return cultura;
    }

    public SalesOrg__c createOrgVendas(){
        SalesOrg__c so = new SalesOrg__c(
            Name = 'AgroGalaxy',
            SalesOrganizationCode__c = '1111'
        );

        return so;
    }

    public DistributionChannel__c createCanalDistribuicao(){
        DistributionChannel__c distributionChannel = new DistributionChannel__c(
            Name = 'Teste',
            Codigo__c = '0001'
        );
   
        return distributionChannel;
    }

    public Order createOrder(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='tetedogas@testorg.com');

        Account account = createAccount();
        Safra__c safra = createSafra();
        Cultura__c cultura = createCultura();
        SalesOrg__c so = createOrgVendas();
        DistributionChannel distributionChannel = createCanalDistribuicao();
        INSERT account;
        INSERT safra;
        INSERT cultura;
        INSERT so;
        INSERT distributionChannel;
        INSERT u;
        Map <String,Schema.RecordTypeInfo> recordTypeMap = Order.sObjectType.getDescribe().getRecordTypeInfosByName();

        Order order = new Order(
            AccountId =  account.Id,
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Sucata',
            RecordTypeId = recordTypeMap.get('Venda Sucata').getRecordTypeId(),
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
            EndDate = Date.today(),
            Incoterms__c = 'CIF'
        );
   
        return order;
    }

    public Product2 createProduct(){
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

        return prod;
    }

    public PricebookEntry createPricebookEntry(){
        Product2 prod = createProduct();
        INSERT prod;
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = prod.Id,
            UnitPrice = 10000,
            IsActive = true);
        
        return standardPrice;
    }

    public OrderItem createOrderItem(){
        Order order = createOrder();
        Product2 prod = createProduct();
        PricebookEntry standardPrice = createPricebookEntry();
        INSERT prod;
        INSERT order;
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

        return orderItem;
    }

    public ShippingDivison__c createDivisaoRemessa(){
        OrderItem orderItem = createOrderItem();
        INSERT orderItem;

        ShippingDivison__c shipping = new ShippingDivison__c(
            DeliveryDate__c = System.today().addDays(30),
            Quantity__c = 10,
            ExternalId__c = '001',
            ConfirmedQuantity__c = 0,
            OrderItem__c = orderItem.Id
        );
        

        return shipping;
    }
    

       
       

        

        

        
    

        

       

        

    

   

  

   
}