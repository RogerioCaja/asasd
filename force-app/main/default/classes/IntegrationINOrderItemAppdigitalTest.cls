@isTest
public with sharing class IntegrationINOrderItemAppdigitalTest {

    @TestSetup
    static void makeData(){


        Account account = new Account (
            Name = 'Teste 12',
            BillingStreet = ' ',
            BillingState = '' ,
            Phone= '00000000000', 
            BillingCity = ' ', 
            BillingLongitude = 000000,
            BillingLatitude = 00000,
            BillingPostalCode = '',
            ExternalId__c = '2884',
            Company__c = 'Empresa 012'
        );
        insert account;

        Safra__c safra = new Safra__c(
            Code__c = '12234',
            Name = 'Safra Teste',
            Name__c = 'Safra Teste',
            BillingStartDate__c = System.today(),
            EndDateBilling__c = System.today(),
            EndDateInsertionOrders__c = System.today(),
            NumberOfDaysAfterPayment__c = System.today(),
            ReleaseStatus__c = 'Ativo',
            StartDateOrderInsertion__c = System.today()
        );
        insert safra;

        Cultura__c cultura = new Cultura__c(
            Name = 'Safrinha',
            Name__c = 'Safrinha',
            Codigo__c = '12344'
        );
        insert cultura;

        SalesOrg__c salesOrg = new SalesOrg__c(
            Name = 'AgroGalaxy',
            SalesOrganizationCode__c = '2222'
        );
        insert salesOrg;

        ActivitySector__c activitySector = new ActivitySector__c(
            Name = 'Setor Teste',
            Codigo__c = '2'
        );
        insert activitySector;

        SalesCondition__c sales = new SalesCondition__c(
            Name = 'Condição',
            ExternalId__c = '2'
        );
        insert sales;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='tetedogas@testorg.com');
            insert u;


            Order order = new Order(
                AccountId =  account.Id,
                Status = 'Draft',
                Type =  'Venda Normal',
                PriceBook2Id = Test.getStandardPricebookId(),
                ShippingAccount__c = account.Id,
                PaymentDate__c =  Date.today(),
                CustomerOrderNumber__c = '0002',
                EffectiveDate = Date.today(),
                Crop__c =  safra.Id,
                Culture__c = cultura.Id,
                PaymentForm__c =  'Bonificação',
                SalesOrg__c =  salesOrg.Id,
                DistributionChannel__c =  'Venda Direta',
                ActivitySector__c =  '',
                Currency__c =  'BRL',
                SalesCTV__c =  u.Id,
                StatusSF__c = 'Em digitação',
                Incoterms__c = 'CIF'
            );
            insert order;

            Product2 prod = new Product2(
                Name = 'Laptop X2020', 
                Family = 'Hardware',
                ExternalId__c = '0002',
                ClasseAvaliacao__c = 'chucrute2',
                GrupoQuimico__c = 'Só pó quimico',
                MarcadoEliminacao__c = 'S',
                NCM__c = 'S',
                NumeroRegistro__c = '0002',
                OrigemMaterial__c = 'Himalaia',
                UnidadeMedida__c = 'KG'
            );
            insert prod;
            
            PricebookEntry standardPricebookEntry = [SELECT Id, Name FROM PricebookEntry LIMIT 1];
            

            OrderItem orderItem = new OrderItem(
                OrderId = order.Id,
                Product2Id = prod.Id,
                NumeroSap__c = '124',
                UnitMeasure__c = 'L',
                UnitPrice = 100000,
                Quantity = 1,
                ExternalId__c = 'texto2',
                PricebookEntryId = standardPricebookEntry.Id
            );
            insert orderItem;

            ShippingDivison__c shippingDivison = new ShippingDivison__c(
                OrderItem__c = orderItem.Id,
                DeliveryDate__c = System.today().addDays(30),
                Quantity__c = 10,
                ExternalId__c = '001',
                ConfirmedQuantity__c = 0
            );
            insert shippingDivison;
          }

    @isTest 
    
    static void verifyIntegrationOrder(){
  
        List<TemplateDataIntegrationFields.OrderItemINData> listOrderItemList = new List<TemplateDataIntegrationFields.OrderItemINData>();
        TemplateDataIntegrationFields.OrderItemINData listOrderItem = new TemplateDataIntegrationFields.OrderItemINData();
        listOrderItem.orderItemCode = '100';
        listOrderItem.orderExternalId = '100';
        listOrderItem.material = '100';
        listOrderItem.productCode = '100';
        listOrderItem.quantidade = 1;
        listOrderItem.unidadeMedida = '1';
        listOrderItem.listaPreco = 2;
        listOrderItem.porcentagemComissao = 2;
        listOrderItem.porcentagemDesconto = 2;
        listOrderItem.comissaoValor = 4;
        listOrderItem.margemComercial = 5;
        listOrderItem.descontoValor = 5;
        listOrderItem.valorTotal = 5;
        listOrderItem.porcentagemDescontoFin = 5;
        listOrderItem.valorDescontoFin = 5;
        listOrderItem.porcentagemAcrescFin = 5;
        listOrderItem.valorAcrescFin = 5;
        listOrderItemList.add(listOrderItem);

        List<TemplateDataIntegrationFields.ShippingDivisonINData> listShippingDivisonList = new List<TemplateDataIntegrationFields.ShippingDivisonINData>();
        TemplateDataIntegrationFields.ShippingDivisonINData listShippingDivison = new TemplateDataIntegrationFields.ShippingDivisonINData();
        listShippingDivison.OrderItemCode = '';
        listShippingDivison.DivisaoRemessa = 'Texto20';
        listShippingDivison.NumeroDivisaoRemessa = 'Texto21';
        listShippingDivison.Quantidade = 10.00;
        listShippingDivison.QuantidadeConfirmada = 20.00;
        listShippingDivisonList.add(listShippingDivison);
        
  
        List<TemplateDataIntegrationFields.OrderINData> listOrderList = new List<TemplateDataIntegrationFields.OrderINData>();
        TemplateDataIntegrationFields.OrderINData listOrder = new TemplateDataIntegrationFields.OrderINData();
        listOrder.Status = 'Draft';
        listOrder.pricebook2Id = 'Standard Price Book';
        listOrder.CodigoSap = '100';
        listOrder.Type = 'Adicionada';
        listOrder.ShippingAccount = '020';
        listOrder.PaymentAccount = '020';
        listOrder.PaymentDate = System.today();
        listOrder.CustomerOrderNumber = 'Teste';
        listOrder.EffectiveDate = System.today();
        listOrder.Crop = 'Teste 5';
        listOrder.Culture = 'Teste';
        listOrder.PaymentForm = 'Bonificação';
        listOrder.DistributionChannel = 'Venda Direta';
        listOrder.ActivitySector = 'Teste';
        listOrder.CurrencyOrder = 'BRL';
        listOrder.SalesOrg = '1';
        listOrder.SalesCTV = 'Jurema';
        listOrder.Incoterms = 'CIF';
        listOrder.Incoterms2 = 'Teste';
        listOrder.Description = 'LT';
        listOrder.PaymentCondition = 'LT';
        listOrder.ShippingDate = System.today();
        listOrder.DescriptionBillingSale = 'LT';
        listOrder.OrderReference = 'LT';
        listOrder.orderItems = listOrderItemList;
        listOrder.shippingDivison = listShippingDivisonList;
        listOrderList.add(listOrder);
        
        IntegrationINOrderAppdigital.ResponseModel modelo = IntegrationINOrderAppdigital.upsertOrder(listOrderList);
        //IntegrationINOrderAppdigital.ResponseModel toPass = new IntegrationINOrderAppdigital.ResponseModel(modelo.response);
        System.debug(modelo);
        //System.assertEquals(true, modelo.response[0].status, 'O status nesta situação deveria vir verdadeiro');
        //System.assertEquals(null, modelo.response[0].errorMessage, 'O erro nesta situação deveria vir nulo');
//System.assertEquals(null, modelo.response[0].idSalesforce, 'O idSalesforce nesta situação deveria vir um Id');
        //System.assertNotEquals('null', modelo.response[0].externalCode, 'O externalCode nesta situação deveria vir codExternal');
       // System.assertNotEquals();
    }
        
    }
