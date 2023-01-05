@isTest
public class GenerateIndividualQuotesControllerTest {
    @testSetup
    public static void makeData() {
        Safra__c crop = new Safra__c(
            Name = 'Safra 01',
            Name__c = 'Safra 1',
            Code__c = '001',
            BillingStartDate__c = System.today(),
            StartDateOrderInsertion__c = System.today(),
            EndDateBilling__c = System.today().addDays(90),
            EndDateInsertionOrders__c = System.today().addDays(90),
            NumberOfDaysAfterPayment__c = System.today().addDays(10),
            PaymentBaseDate__c = System.today().addDays(90),
            ReleaseStatus__c = 'Ativo'
        );
        insert crop;

        ProductHierarchy__c productHierarchy = new ProductHierarchy__c(
            Name = 'Hierarquia',
            External_Id__c = '001'
        );
        insert productHierarchy;

        ProductGroup__c productGroup = new ProductGroup__c(
            Name = 'Grãos',
            ExternalId__c ='001'
        );
        insert productGroup;

        Product2 product = new Product2(
            Name = 'Milho',
            ExternalId__c = '001',
            ProductCode = '001',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            PrincipleActive__c = 'Salicilina',
            ProductGroup__c = productGroup.Id,
            Multiplicity__c = 5,
            ClasseAvaliacao__c = 'A',
            GrupoQuimico__c = 'A',
            MarcadoEliminacao__c = 'A',
            NCM__c = 'A',
            NumeroRegistro__c = '2',
            OrigemMaterial__c = 'Ferro',
            UnidadeMedida__c = 'Quilos',
            ProductHierarchy__c = productHierarchy.Id
        );
        insert product;

        GeneralQuotas__c generalQuota = new GeneralQuotas__c(
            Quantity__c = 1000,
            Balance__c = 1000,
            Consumed__c = 0,
            Crop__c = crop.Id,
            Cultivate__c = product.Id
        );
        insert generalQuota;
    }

    @isTest
    public static void getQuoteDataTest() {
        GenerateIndividualQuotesController.getQuoteData([SELECT Id FROM GeneralQuotas__c LIMIT 1].Id);
    }

    @isTest
    public static void createIndividualQuoteTest() {
        GeneralQuotas__c generalQuota = [SELECT Id, Crop__c, Crop__r.Name, Cultivate__c, Cultivate__r.Name FROM GeneralQuotas__c LIMIT 1];
        GenerateIndividualQuotesController.QuoteData data = new GenerateIndividualQuotesController.QuoteData();
        data.quoteId = generalQuota.Id;
        data.cropId = generalQuota.Crop__c;
        data.cropName = generalQuota.Crop__r.Name;
        data.sellerId = UserInfo.getUserId();
        data.cultivateId = generalQuota.Cultivate__c;
        data.cultivateName = generalQuota.Cultivate__r.Name;
        data.balance = 100;
        data.consumed = 0;
        data.quantity = 100;
        GenerateIndividualQuotesController.createIndividualQuote(JSON.serialize(data));
    }
}