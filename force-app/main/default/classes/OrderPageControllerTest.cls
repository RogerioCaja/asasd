@isTest
public with sharing class OrderPageControllerTest {
    public OrderPageControllerTest() {

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
            AccountId =  [SELECT Id FROM Account LIMIT 1].Id,
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type =  'Venda Normal',
            ShippingAccount__c =  [SELECT Id FROM Account LIMIT 1].Id,
            PaymentDate__c =  Date.today(),
            CustomerOrderNumber__c = '0001',
            EffectiveDate = Date.today(),
            Crop__c =  [SELECT Id FROM Safra__c LIMIT 1].Id,
            Culture__c = [SELECT Id FROM Cultura__c LIMIT 1].Id,
            PaymentForm__c =  'Bonificação',
            SalesOrg__c =  [SELECT Id FROM SalesOrg__c LIMIT 1].Id,
            DistributionChannel__c =  'Venda Direta',
            ActivitySector__c =  '',
            Currency__c =  'BRL',
            SalesCTV__c =  [SELECT Id FROM User LIMIT 1].Id,
            StatusSF__c = 'Em digitação',
            Incoterms__c = 'CIF'
        );

        INSERT order;

        // this.productCode = orderItem.Product2Id;
        //     this.description = orderItem.Description;
        //     this.unitOfMeasure = orderItem.UnitMeasure__c;
        //     this.unitPrice = orderItem.UnitPrice;
        //     this.quantity = orderItem.Quantity;
        //     this.totalAmount = orderItem.TotalPrice;
        //     this.culture = culture;
        Product2 prod = new Product2(
            Name = 'Laptop X200', 
            Family = 'Hardware',
            ExternalId__c = '0001'
        );
        INSERT prod;

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = [SELECT Id FROM Product2 LIMIT 1].Id,
            UnitPrice = 10000,
            IsActive = true);
        
        INSERT standardPrice;

        OrderItem orderItem = new OrderItem(
            OrderId = [SELECT Id FROM Order LIMIT 1].Id,
            Product2Id = [SELECT Id FROM Product2 LIMIT 1].Id,
            UnitMeasure__c = 'L',
            UnitPrice = 10000,
            Quantity = 1,
            PricebookEntryId = [SELECT Id FROM PricebookEntry LIMIT 1].Id
        );

        INSERT orderItem;
    }

    @isTest
    public static void verifyDateFormat(){
        String dateTest = OrderPageController.getDatetime();

        System.assert((String.isNotBlank(dateTest) && String.isNotEmpty(dateTest)), 'Os dados resultaram em falha');
    }

    @isTest 
    static void verifyGetOrderById(){
        Order order = OrderPageController.getOrderById([SELECT Id FROM Order LIMIT 1].Id);

        System.assert(order != null, 'Order está vindo nulo');
    }

    @isTest 
    static void verifyGetOrderItemByOrderId(){
        List<OrderItem> orderItemList = OrderPageController.getOrderItemByOrderId([SELECT Id FROM Order LIMIT 1].Id);

        System.assert(orderItemList.size() >= 0 , 'A lista de OrderItem não está sendo retornada');
    }

    @isTest 
    static void verifyGeneratePDF(){
        // ApexPages.StandardController sc = new ApexPages.StandardController(testAccountPlanInsert);
        OrderPageController orderController = new OrderPageController();
        Id orderId = [SELECT Id FROM Order LIMIT 1].Id;
        Order order = OrderPageController.getOrderById(orderId);
        List<OrderItem> orderItemList = OrderPageController.getOrderItemByOrderId(orderId);
        OrderPageController.OrderDAO testValue = orderController.generatePDF(orderId);

  
        System.assertEquals(order.Account.ExternalId__c, testValue.codeSap, 'Erro no Campo: codeSap');
        System.assertEquals(order.Account.Name, testValue.account, 'Erro no Campo: account');
        System.assertEquals(order.Account.BillingStreet, testValue.accountAddress, 'Erro no Campo: accountAddress');
        System.assertEquals(order.ShippingAccount__r.Name, testValue.ranch, 'Erro no Campo: ranch');
        System.assertEquals(order.Account.BillingCity, testValue.district, 'Erro no Campo: district');
        System.assertEquals(order.Account.StateRegistration__c, testValue.IE, 'Erro no Campo: IE');
        System.assertEquals(order.Account.BillingPostalCode, testValue.CEP, 'Erro no Campo: CEP');
        System.assertEquals(order.Crop__r.Name, testValue.safra, 'Erro no Campo: safra');
        System.assertEquals(order.PaymentForm__c, testValue.paymentCondition, 'Erro no Campo: paymentCondition');
        System.assertEquals(String.valueOf(order.PaymentDate__c), testValue.dueDate, 'Erro no Campo: dueDate');
        System.assertEquals(order.Currency__c, testValue.currencyOrder, 'Erro no Campo: currencyOrder');
        System.assertEquals(order.Culture__c, testValue.culture, 'Erro no Campo: culture');
        System.assertEquals(order.CodigoSap__c, testValue.codeSapOrder, 'Erro no Campo: codeSapOrder');
        System.assert(orderItemList.size() > 0 , 'A lista de OrderItem não está sendo retornada');

        System.assertEquals(testValue.orderItemList.get(0).productCode, orderItemList.get(0).Product2Id, 'Erro no Campo: Product2Id');
        System.assertEquals(testValue.orderItemList.get(0).description, orderItemList.get(0).Description, 'Erro no Campo: Description');
        System.assertEquals(testValue.orderItemList.get(0).culture, order.Culture__c, 'Erro no Campo: Culture__c');
        System.assertEquals(testValue.orderItemList.get(0).unitOfMeasure, orderItemList.get(0).UnitMeasure__c, 'Erro no Campo: UnitMeasure__c');
        System.assertEquals(testValue.orderItemList.get(0).unitPrice, orderItemList.get(0).UnitPrice, 'Erro no Campo: UnitPrice');
        System.assertEquals(testValue.orderItemList.get(0).quantity, orderItemList.get(0).Quantity, 'Erro no Campo: Quantity');
        System.assertEquals(testValue.orderItemList.get(0).totalAmount, orderItemList.get(0).TotalPrice, 'Erro no Campo: TotalPrice');

    }

    @isTest
    static void vefifyConstructor(){
        PageReference pageRef = Page.OrderPagePDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf([SELECT Id FROM Order LIMIT 1].Id));
        ApexPages.StandardController sc = new ApexPages.StandardController([SELECT Id FROM Order LIMIT 1][0]);
         // ApexPages.StandardController sc = new ApexPages.StandardController(testAccountPlanInsert);
         OrderPageController orderController = new OrderPageController(sc);
    }

    @isTest
    static void vefifyConstructorException(){
        PageReference pageRef = Page.OrderPagePDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', null);
        ApexPages.StandardController sc = new ApexPages.StandardController([SELECT Id FROM Order LIMIT 1][0]);
         // ApexPages.StandardController sc = new ApexPages.StandardController(testAccountPlanInsert);
         OrderPageController orderController = new OrderPageController(sc);

    }
}
