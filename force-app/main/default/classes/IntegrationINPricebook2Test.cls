@isTest
public class IntegrationINPricebook2Test {
  
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
            Company__c = 'Empresa 1'
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

        Cultura__c cultura = new Cultura__c(
            Name = 'Safrinha',
            Name__c = 'Safrinha',
            Codigo__c = '1234'
        );

        SalesOrg__c so = new SalesOrg__c(
            Name = 'AgroGalaxy',
            SalesOrganizationCode__c = '1111'
        );

        // ClasseAvaliacao__c, GrupoQuimico__c, MarcadoEliminacao__c, NCM__c, NumeroRegistro__c, 
        // OrigemMaterial__c, UnidadeMedida__c]: 
        Product2 prod = new Product2(
            Name = 'Laptop X200', 
            Family = 'Hardware',
            ExternalId__c = '0001',
            ProductCode__c = '0002',
            ClasseAvaliacao__c = 'chucrute',
            GrupoQuimico__c = 'Só o quimico',
            MarcadoEliminacao__c = 'S',
            NCM__c = 'S',
            NumeroRegistro__c = '0001',
            OrigemMaterial__c = 'Himalaia',
            UnidadeMedida__c = 'KG'
        );
        
        SalesOffice__c salesOffice = new SalesOffice__c(
            Name = 'Escritório Teste',
            Codigo__c = '1'

        );
        SalesTeam__c salesTeam = new SalesTeam__c(
            Name = 'Equipe Teste',
            ExternalId__c = '1'
        );

        
        ActivitySector__c activitySector = new ActivitySector__c(
            Name = 'Setor Teste',
            Codigo__c = '1'
        );
        

        ProductFamily__c productFamily = new ProductFamily__c(
            Name = 'Família Teste',
            ExternalId__c = '1'
        );

        ProductGroup__c productGroup = new ProductGroup__c(
            Name = 'Grupo Teste',
            ExternalId__c = '1'
        );

        salesCondition__c sales = new salesCondition__c(
            Name = 'Condição',
            ExternalId__c = '1'
        );

        DistributionCenter__c dc = new DistributionCenter__c(
            Name = 'Teste Centro',
            Code__c = '1'
        );
        
        


      INSERT dc;
      INSERT sales;  
      INSERT account;
      INSERT safra;
      INSERT cultura;
      INSERT so;
      INSERT prod;
    //   INSERT prod2;
      INSERT salesOffice;
      INSERT salesTeam;
      INSERT activitySector;
      INSERT productFamily;
      INSERT productGroup; 
        
        JurosDescontoAntecipao__c ListPrice = new JurosDescontoAntecipao__c(
            RecordTypeId = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId(),
            SalesOrg__c = so.Id,
            Currency__c = 'BRL',
            harvest__c = safra.Id,
            SalesCondition__c = sales.Id,
            Account__c = account.Id,
            Product__c = prod.Id,
            StartDate__c = Date.valueOf('2022-03-30')
        );
        
        INSERT ListPrice;
    }

    @isTest
    static void verifyIntegrationPricebook2(){

        List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> listPriceList = new List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData>();
        TemplateDataIntegrationFields.JurosDescontoAntecipaoINData listPrice = new TemplateDataIntegrationFields.JurosDescontoAntecipaoINData();
        listPrice.table = 'A935';
        listPrice.accountCode = '11111';
        listPrice.typeCondition = 'ZPR0';
        listPrice.product = '0002';
        listPrice.productGroup = '1';
        listPrice.multiplicationFactor = '1';
        listPrice.unitPrice = '2.00';
        listPrice.center = '1';
        listPrice.salesCondition = '1';
        listPrice.cropCode = '1223';
        listPrice.cultureCode = '1234';
        listPrice.accountGroup = '04';
        listPrice.orgVendas = '1111';
        listPrice.salesOffice = '1';
        listPrice.salesTeam = '1';
        listPrice.initialDate = '2022-03-30';
        listPrice.endDate = '2022-03-30';
        listPrice.typeCurrency = 'BRL';
        listPrice.externalId = 'Jurema';
        listPrice.unitMeasurement = 'LT';
        
        TemplateDataIntegrationFields.JurosDescontoAntecipaoINData listPrice2 = new TemplateDataIntegrationFields.JurosDescontoAntecipaoINData();
        listPrice2.table = 'A935';
        listPrice2.accountCode = '11111';
        listPrice2.typeCondition = 'ZPRS';
        listPrice2.product = '0002';
        listPrice2.productGroup = '1';
        listPrice2.multiplicationFactor = '1';
        listPrice2.unitPrice = '1.99';
        listPrice2.center = '1';
        listPrice2.salesCondition = '1';
        listPrice2.cropCode = '1223';
        listPrice2.cultureCode = '1234';
        listPrice2.accountGroup = '04';
        listPrice2.orgVendas = '1111';
        listPrice2.salesOffice = '1';
        listPrice2.salesTeam = '1';
        listPrice2.initialDate = '2022-03-30';
        listPrice2.endDate = '2022-03-30';
        listPrice2.typeCurrency = 'BRL';
        listPrice2.externalId = 'Jurema2';
        listPrice2.unitMeasurement = 'LT';
        listPriceList.add(listPrice2);
        
        TemplateDataIntegrationFields.JurosDescontoAntecipaoINData listPrice3 = new TemplateDataIntegrationFields.JurosDescontoAntecipaoINData();
        listPrice3.table = 'A935';
        listPrice3.accountCode = '11111';
        listPrice3.typeCondition = 'ZCPE';
        listPrice3.product = '0002';
        listPrice3.productGroup = '1';
        listPrice3.multiplicationFactor = '1';
        listPrice3.unitPrice = '3.00';
        listPrice3.center = '1';
        listPrice3.salesCondition = '1';
        listPrice3.cropCode = '1223';
        listPrice3.cultureCode = '1234';
        listPrice3.accountGroup = '04';
        listPrice3.orgVendas = '1111';
        listPrice3.salesOffice = '1';
        listPrice3.salesTeam = '1';
        listPrice3.initialDate = '2022-03-30';
        listPrice3.endDate = '2022-03-30';
        listPrice3.typeCurrency = 'BRL';
        listPrice3.externalId = 'Jurema3';
        listPrice3.unitMeasurement = 'LT';
        listPriceList.add(listPrice3);
        
        TemplateDataIntegrationFields.JurosDescontoAntecipaoINData listPrice4 = new TemplateDataIntegrationFields.JurosDescontoAntecipaoINData();
        listPrice4.table = 'A934';
        listPrice4.accountCode = '11111';
        listPrice4.typeCondition = 'ZDAN';
        listPrice4.product = '0002';
        listPrice4.productGroup = '1';
        listPrice4.multiplicationFactor = '1';
        listPrice4.unitPrice = '3.00';
        listPrice4.center = '1';
        listPrice4.salesCondition = '1';
        listPrice4.cropCode = '1223';
        listPrice4.cultureCode = '1234';
        listPrice4.accountGroup = '04';
        listPrice4.orgVendas = '1111';
        listPrice4.salesOffice = '1';
        listPrice4.salesTeam = '1';
        listPrice4.initialDate = '2022-03-30';
        listPrice4.endDate = '2022-03-30';
        listPrice4.typeCurrency = '%';
        listPrice4.externalId = 'Jurema4';
        listPrice4.unitMeasurement = 'LT';
        listPriceList.add(listPrice4);

        Test.startTest();
        IntegrationINPricebook2.ResponseModel model = IntegrationINPricebook2.upsertPricebook2(listPriceList);
        IntegrationINPricebook2.ResponseModel toPass = new IntegrationINPricebook2.ResponseModel(model.response);
        model = IntegrationINPricebook2.upsertPricebook2(listPriceList);
        toPass = new IntegrationINPricebook2.ResponseModel(model.response);
        Test.stopTest();
        
        System.debug(model);
        System.assertEquals(true, model.response[0].status, 'O status nesta situação deveria vir verdadeiro');
        System.assertEquals('JurosDescontoAntecipao__c', model.response[0].sObjectType, 'O objeto nesta situação deveria vir JurosDescontoAntecipao__c');
        System.assertEquals(null, model.response[0].errorMessage, 'O erro nesta situação deveria vir nulo');
        System.assertNotEquals(null, model.response[0].idSalesforce, 'O idSalesforce nesta situação deveria vir um Id');
        System.assertNotEquals('null', model.response[0].externalCode, 'O externalCode nesta situação deveria vir codExternal');
    }
    
    @isTest
    static void verifyException(){
        List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> listPriceList = new List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData>();
        TemplateDataIntegrationFields.JurosDescontoAntecipaoINData listPrice = new TemplateDataIntegrationFields.JurosDescontoAntecipaoINData();
        listPrice.table = 'A935';
        listPrice.accountCode = '11111';
        listPrice.typeCondition = 'ZPR0';
        listPrice.product = '0002';
        listPrice.productGroup = '1';
        listPrice.multiplicationFactor = '1';
        listPrice.unitPrice = '2.00';
        listPrice.center = '1';
        listPrice.salesCondition = '1';
        listPrice.cropCode = '1223';
        listPrice.cultureCode = '1234';
        listPrice.accountGroup = '04';
        //listPrice.orgVendas = '1111';
        listPrice.salesOffice = '1';
        listPrice.salesTeam = '1';
        listPrice.initialDate = '2022-03-30';
        listPrice.endDate = '2022-03-30';
        listPrice.typeCurrency = 'BRL';
        listPrice.externalId = 'Jurema';
        listPrice.unitMeasurement = 'LT';
        listPriceList.add(listPrice);
        
        Test.startTest();
        IntegrationINPricebook2.ResponseModel model = IntegrationINPricebook2.upsertPricebook2(listPriceList);
        IntegrationINPricebook2.ResponseModel toPass = new IntegrationINPricebook2.ResponseModel(model.response);
        Test.stopTest();
        
        System.debug(model);
        System.assertEquals(false, model.response[0].status, 'O status nesta situação deveria vir falsa');
        System.assertEquals('JurosDescontoAntecipao__c', model.response[0].sObjectType, 'O objeto nesta situação deveria vir JurosDescontoAntecipao__c');
    }
}