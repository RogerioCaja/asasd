@isTest
public class LookupTest {
    @testSetup public static void makeData() {
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert parentAccount;

        Account childAccount = new Account(
            Name = 'Child Account',
            Company__c = 'Child Account',
            Phone = '11111111111',
            ExternalId__c = '123457'
        );
        insert childAccount;

        SalesOrg__c salesOrg = new SalesOrg__c(
            Name = 'Sales Organization',
            SalesOrganizationCode__c = '001'
        );
        insert salesOrg;

        SalesOffice__c salesOffice = new SalesOffice__c(
            Name = 'Sales Office',
            Codigo__c = '001'
        );
        insert salesOffice;

        SalesTeam__c salesTeam = new SalesTeam__c(
            Name = 'Sales team'
        );
        insert salesTeam;

        Company__c company = new Company__c(
            Name = 'Company',
            Blocked__c = false,
            ClientGroup__c = 'NÃO SEGMENTADO',
            Conta__c = parentAccount.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            ExternalID__c = '001',
            SupplierCenter__c = '1010'
        );
        insert company;

        Safra__c crop = new Safra__c(
            Name = 'Safra 01',
            Code__c = '001',
            BillingStartDate__c = System.today(),
            StartDateOrderInsertion__c = System.today(),
            EndDateBilling__c = System.today().addDays(90),
            EndDateInsertionOrders__c = System.today().addDays(90),
            NumberOfDaysAfterPayment__c = System.today().addDays(10),
            ReleaseStatus__c = 'Ativo'
        );
        insert crop;

        Cultura__c culture = new Cultura__c(
            Name = 'Culture 01',
            Name__c = 'Culture 01',
            Codigo__c = '001'
        );
        insert culture;

        ProductGroup__c productGroup = new ProductGroup__c(
            Name = 'Grãos',
            ExternalId__c = '001'
        );
        insert productGroup;

        ProductHierarchy__c productHierarchy = new ProductHierarchy__c(
            Name = 'Hierarquia',
            External_Id__c = '001'
        );
        insert productHierarchy;

        SalesCondition__c salesCondition = new SalesCondition__c(
            Name = 'Condição',
            ExternalId__c = '001'
        );
        insert salesCondition;

        Product2 product = new Product2(
            Name = 'Milho',
            ExternalId__c = '001',
            ProductCode = '001',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            ProductType__c = 'HAWA',
            PrincipleActive__c = 'Salicilina',
            ProductGroup__c = productGroup.Id,
            Multiplicity__c = 5,
            ClasseAvaliacao__c = 'chucrute',
            GrupoQuimico__c = 'Só o quimico',
            MarcadoEliminacao__c = 'S',
            NCM__c = 'S',
            NumeroRegistro__c = '0001',
            OrigemMaterial__c = 'Himalaia', 
            UnidadeMedida__c = 'KG',
            ProductHierarchy__c = productHierarchy.Id
        );
        insert product;

        JurosDescontoAntecipao__c productPrice = new JurosDescontoAntecipao__c(
            RecordTypeId = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId(),
            Account__c = parentAccount.Id,
            Product__c = product.Id,
            ProductGroup__c = productGroup.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            Culture__c = culture.Id,
            harvest__c = crop.Id,
            SalesCondition__c = salesCondition.Id,
            Currency__c = 'BRL',
            IsActive__c = true,
            StartDate__c = System.today().addDays(-5),
            EndDate__c = System.today().addDays(5),
            ExternalId__c = '001'
        );
        insert productPrice;
    }
    @isTest public static void getRecordsTest() {
        Id parentAccountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        Id childAccountId = [SELECT Id FROM Account WHERE Name != 'Parent Account' LIMIT 1].Id;
        Id salesOrgId = [SELECT Id FROM SalesOrg__c LIMIT 1].Id;

        Lookup.SalesConditionDTO conditionData = new Lookup.SalesConditionDTO();
        conditionData.safraName = 'Safra 01';
        conditionData.SalesOrgId = salesOrgId;
        conditionData.currencyGet = 'BRL';
        conditionData.typeOrder = 'Venda Barter';
        
        Lookup.getRecords('{"targetObject":"Company__c","searchFields":["Name"],"searchValue":"Empresa","moreFields":[], "relations": [{"parentRelationField": "Conta__c", "parentRecord": "' + parentAccountId + '"}], "differentRelations": [{"parentRelationField": "Conta__c", "parentRecord": "' + childAccountId + '"}], "accountId":"' + parentAccountId + '"}', false, JSON.serialize(conditionData));
    }

    @isTest public static void getSalesConditionTest() {
        Id parentAccountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        Id salesOrgId = [SELECT Id FROM SalesOrg__c LIMIT 1].Id;

        Lookup.SalesConditionDTO conditionData = new Lookup.SalesConditionDTO();
        conditionData.safraName = 'Safra 01';
        conditionData.SalesOrgId = salesOrgId;
        conditionData.currencyGet = 'BRL';
        conditionData.typeOrder = 'Venda Barter';
        
        Lookup.getRecords('{"targetObject":"SalesCondition__c","searchFields":["Name"],"searchValue":"Condição","moreFields":[], "relations": [], "differentRelations": [], "accountId":"' + parentAccountId + '"}', false, JSON.serialize(conditionData));
    }

    @isTest public static void getUserTest() {
        Id parentAccountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        Id salesOrgId = [SELECT Id FROM SalesOrg__c LIMIT 1].Id;

        Lookup.SalesConditionDTO conditionData = new Lookup.SalesConditionDTO();
        conditionData.safraName = 'Safra 01';
        conditionData.SalesOrgId = salesOrgId;
        conditionData.currencyGet = 'BRL';
        conditionData.typeOrder = 'Venda Barter';
        
        Lookup.getRecords('{"targetObject":"User","searchFields":["Name"],"searchValue":"User","moreFields":[], "relations": [], "differentRelations": [], "accountId":"' + parentAccountId + '"}', false, JSON.serialize(conditionData));
    }
}