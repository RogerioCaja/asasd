@isTest
public class IntegrationINCropDelimitationTest {
  
    @TestSetup
    static void makeData(){

        Safra__c safra = new Safra__c(
            Code__c = '111',
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
        SalesOrg__c so = new SalesOrg__c(
            Name = 'SalesOrganization Teste',
            SalesOrganizationCode__c = '333'
        );
        insert so;
        salesCondition__c sales = new salesCondition__c(
            Name = 'SalesCondition Teste',
            ExternalId__c = '222'
        );
        insert sales;

    }
    
    @isTest
    static void verifyIntegrationINCropDelimitation(){
        List<TemplateDataIntegrationFields.DelimitadoresINData> delimitatorsList = new List<TemplateDataIntegrationFields.DelimitadoresINData>();
        TemplateDataIntegrationFields.DelimitadoresINData delimitators = new TemplateDataIntegrationFields.DelimitadoresINData();
        delimitators.SalesOrganization = '333';
        delimitators.Safra = '111';
        delimitators.PriceList = '222';
        delimitators.StartDateOV = Date.valueOf('2022-09-21');
        delimitators.EndDateOV = Date.valueOf('2022-09-21');
        delimitators.StartDateFaturalmente = Date.valueOf('2022-09-21');
        delimitators.EndDateFaturalmente = Date.valueOf('2022-09-21');
        delimitators.BaseDateFinancing = Date.valueOf('2022-09-21');
        delimitators.AfterPaymentDate = Date.valueOf('2022-09-22');
        delimitatorsList.add(delimitators);
        
        Test.startTest();
        IntegrationINCropDelimitation.ResponseModel model = IntegrationINCropDelimitation.upsertCropDelimitation(delimitatorsList);
        Test.stopTest();
        
        System.debug(model);
    }
}