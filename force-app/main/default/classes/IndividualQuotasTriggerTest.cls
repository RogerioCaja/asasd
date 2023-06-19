@isTest
public class IndividualQuotasTriggerTest {
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
    public static void individualQuotaTest() {
        IndividualQuotas__c individualQuota = new IndividualQuotas__c(
            Quantity__c = 1000,
            Balance__c = 1000,
            Consumed__c = 0,
            Cultivate__c = [SELECT Id FROM Product2 LIMIT 1].Id,
            GeneralQuotas__c = [SELECT Id FROM GeneralQuotas__c LIMIT 1].Id,
            Crop__c = [SELECT Id FROM Safra__c LIMIT 1].Id,
            Seller__c = UserInfo.getUserId()
        );
        insert individualQuota;
        update individualQuota;
    }
}