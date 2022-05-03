@isTest
public class IntegrationINPricebook2Test {
  
    @TestSetup
    static void makeData(){
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );

        update standardPricebook;

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

      PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = prod.Id, 
            UnitPrice = 100.00,
             IsActive = true);

    INSERT standardPBE;
    }

    @isTest
    static void verifyIntegrationPricebook2(){

        List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> listPriceList = new List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData>();
        TemplateDataIntegrationFields.JurosDescontoAntecipaoINData listPrice = new TemplateDataIntegrationFields.JurosDescontoAntecipaoINData();
        listPrice.accountCode = '11111';
        listPrice.typeCondition = 'ZPR0';
        listPrice.product = '0002';
        listPrice.productGroup = '1';
        listPrice.unitPrice = '2.00';
        listPrice.center = '1';
        listPrice.salesCondition = '1';
        listPrice.cropCode = '1223';
        listPrice.cultureCode = '1234';
        listPrice.accountGroup = 'A';
        listPrice.orgVendas = '1111';
        listPrice.salesOffice = '1';
        listPrice.salesTeam = '1';
        listPrice.initialDate = '2022-03-30';
        listPrice.endDate = '2022-03-30';
        listPrice.typeCurrency = 'BRL';
        listPrice.unitMeasurement = 'LT';
        listPriceList.add(listPrice);

        IntegrationINPricebook2.ResponseModel model = IntegrationINPricebook2.upsertPricebook2(listPriceList);
        IntegrationINPricebook2.ResponseModel toPass = new IntegrationINPricebook2.ResponseModel(model.response);
        System.debug(model);
        System.assertEquals(true, model.response[0].status, 'O status nesta situação deveria vir verdadeiro');
        System.assertEquals('JurosDescontoAntecipao__c', model.response[0].sObjectType, 'O objeto nesta situação deveria vir Pricebook2');
        System.assertEquals(null, model.response[0].errorMessage, 'O erro nesta situação deveria vir nulo');
        System.assertNotEquals(null, model.response[0].idSalesforce, 'O idSalesforce nesta situação deveria vir um Id');
        System.assertNotEquals('null', model.response[0].externalCode, 'O externalCode nesta situação deveria vir codExternal');
    } 

  


  

   
}
