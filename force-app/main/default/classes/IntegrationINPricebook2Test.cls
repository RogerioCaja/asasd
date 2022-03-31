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

        Product2 prod = new Product2(
            Name = 'Laptop X200', 
            Family = 'Hardware',
            ExternalId__c = '0001'
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

      INSERT account;
      INSERT safra;
      INSERT cultura;
      INSERT so;
      INSERT prod;
      INSERT salesOffice;
      INSERT salesTeam;
      INSERT activitySector;
      INSERT productFamily;
      INSERT productGroup; 
    }

    @isTest
    static void verifyIntegrationPricebook2(){

        List<TemplateDataIntegrationFields.GenericINData> genericDataList = new List<TemplateDataIntegrationFields.GenericINData>();
        TemplateDataIntegrationFields.GenericINData genericData = new TemplateDataIntegrationFields.GenericINData();
        List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntryList = new  List<TemplateDataIntegrationFields.PricebookEntryINData>();
        TemplateDataIntegrationFields.PricebookEntryINData pricebookEntry = new TemplateDataIntegrationFields.PricebookEntryINData();
        pricebookEntry.productCode = '0001';
        pricebookEntry.unitPrice = 100.00;

        pricebookEntryList.add(pricebookEntry);
        genericData.name = 'Teste';
        genericData.codExternal = '112';
        genericData.typeCondition = 'PR00';
        genericData.description = 'Na classe de Teste';
        genericData.orgVendas = '1111';
        genericData.listPrice = 'Não sei por que isso existe';
        genericData.cropCode = '1223';
        genericData.cultureCode = '1234';
        genericData.accountCode = '11111';
        genericData.accountGroup = 'A';
        genericData.salesOffice = '1';
        genericData.salesTeam = '1';
        genericData.salesSector = '1';
        genericData.initialDate = '2022-03-30';
        genericData.endDate = '2022-04-30';
        genericData.effectiveDate = '2022-03-30';
        genericData.typeCurrency = 'BRL';
        genericData.active = true;
        genericData.productFamily = '1';
        genericData.pricebookEntries = pricebookEntryList;
        genericDataList.add(genericData);
        
        IntegrationINPricebook2.upsertPricebook2(genericDataList);
    } 

    @isTest
    static void verifyIntegrationInterestDiscount(){
        List<TemplateDataIntegrationFields.GenericINData> genericDataList = new List<TemplateDataIntegrationFields.GenericINData>();
        TemplateDataIntegrationFields.GenericINData genericData = new TemplateDataIntegrationFields.GenericINData();
   

        genericData.name = 'Teste';
        genericData.codExternal = '111';
        genericData.typeCondition = 'ZJ01';
        genericData.description = 'Na classe de Teste';
        genericData.orgVendas = '1111';
        genericData.listPrice = 'Não sei por que isso existe';
        genericData.cropCode = '1223';
        genericData.cultureCode = '1234';
        genericData.accountCode = '11111';
        genericData.accountGroup = 'A';
        genericData.salesOffice = '1';
        genericData.salesTeam = '1';
        genericData.salesSector = '1';
        genericData.initialDate = '2022-03-30';
        genericData.endDate = '2022-04-30';
        genericData.effectiveDate = '2022-03-30';
        genericData.typeCurrency = 'BRL';
        genericData.active = true;
        genericData.productFamily = '1';
        genericData.productGroup = '1';
        genericData.percentage = '30';
        genericData.priority = '30';
        genericData.product = '0001';
        genericDataList.add(genericData);
        
        IntegrationINPricebook2.upsertPricebook2(genericDataList);
    }

    @isTest 
    static void verifyIntegrationWithErrors(){
        List<TemplateDataIntegrationFields.GenericINData> genericDataList = new List<TemplateDataIntegrationFields.GenericINData>();
        TemplateDataIntegrationFields.GenericINData genericData = new TemplateDataIntegrationFields.GenericINData();
        List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntryList = new  List<TemplateDataIntegrationFields.PricebookEntryINData>();
        TemplateDataIntegrationFields.PricebookEntryINData pricebookEntry = new TemplateDataIntegrationFields.PricebookEntryINData();
        pricebookEntry.productCode = '0001';
        pricebookEntry.unitPrice = 100.00;

        pricebookEntryList.add(pricebookEntry);
        genericData.name = 'Teste';
        genericData.codExternal = '';
        genericData.typeCondition = 'PR00';
        genericData.description = 'Na classe de Teste';
        genericData.orgVendas = '1111';
        genericData.listPrice = 'Não sei por que isso existe';
        genericData.cropCode = '1223';
        genericData.cultureCode = '1234';
        genericData.accountCode = '11111';
        genericData.accountGroup = 'A';
        genericData.salesOffice = '1';
        genericData.salesTeam = '1';
        genericData.salesSector = '1';
        genericData.initialDate = '2022-03-30';
        genericData.endDate = '2022-04-30';
        genericData.effectiveDate = '2022-03-30';
        genericData.typeCurrency = 'BRL';
        genericData.active = true;
        genericData.productFamily = '1';
        genericData.pricebookEntries = pricebookEntryList;
        genericDataList.add(genericData);
        
        IntegrationINPricebook2.upsertPricebook2(genericDataList);
    }
}
