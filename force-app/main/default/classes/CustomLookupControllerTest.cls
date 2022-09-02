@isTest
public class CustomLookupControllerTest {
    
    @TestSetup
    public static void makeData(){
        List<Account> accountList = new List<Account>();
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        accountList.add(parentAccount);

        Account childAccount = new Account(
            Name = 'Child Account',
            Company__c = 'Child Account',
            Phone = '11111111111',
            ExternalId__c = '123457'
        );
        accountList.add(childAccount);
        insert accountList;

        SalesCondition__c salesCondition = new SalesCondition__c(
            Name = 'Condição',
            ExternalId__c = '001'
        );
        insert salesCondition;

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
            ClientGroup__c = '01',
            Conta__c = parentAccount.Id,
            SalesOrg__c = salesOrg.Id,
            SalesOffice__c = salesOffice.Id,
            SalesTeam__c = salesTeam.Id,
            ExternalID__c = '001',
            SupplierCenter__c = '1010'
        );
        insert company;

        Order order = new Order(
            AccountId = parentAccount.Id,
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId(),
            Type = '1',
            ShippingAccount__c = parentAccount.Id,
            PaymentDate__c = Date.valueOf('2022-03-30'),
            CustomerOrderNumber__c = '65465',
            EffectiveDate = Date.today(),
            PaymentForm__c = 'A',
            Currency__c = 'BRL',
            StatusSF__c = 'Em digitação',
            Incoterms__c = 'CIF'
        );
        insert order;

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

        List<Product2> lstProducts = new List<Product2>();
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
        lstProducts.add(product);

        Product2 commodity = new Product2(
            Name = 'Soja',
            ExternalId__c = '002',
            ProductCode = '002',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            ProductType__c = 'ZCOM',
            PrincipleActive__c = 'Salicilina',
            ProductGroup__c = productGroup.Id,
            Multiplicity__c = 5,
            ClasseAvaliacao__c = 'chucrute',
            GrupoQuimico__c = 'Só o quimico',
            MarcadoEliminacao__c = 'S',
            NCM__c = 'S',
            NumeroRegistro__c = '0002',
            OrigemMaterial__c = 'Himalaia', 
            UnidadeMedida__c = 'KG',
            ProductHierarchy__c = productHierarchy.Id
        );
        lstProducts.add(commodity);

        Product2Helper.disableTrigger();
        insert lstProducts;
        Product2Helper.enableTrigger();

        List<JurosDescontoAntecipao__c> prices = new List<JurosDescontoAntecipao__c>();
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
        prices.add(productPrice);

        JurosDescontoAntecipao__c commodityPrice = new JurosDescontoAntecipao__c(
            RecordTypeId = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId(),
            Account__c = parentAccount.Id,
            Product__c = commodity.Id,
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
            ExternalId__c = '002'
        );
        prices.add(commodityPrice);
        insert prices;

        List<OrgVProduct__c> orgVList = new List<OrgVProduct__c>();
        OrgVProduct__c orgV = new OrgVProduct__c(
            Product__c = product.Id,
            SalesOrg__c = salesOrg.Id,
            Status__c = 'Adicionada',
            SupplierCenter__c = '1010'
        );
        orgVList.add(orgV);

        OrgVProduct__c commodityOrgV = new OrgVProduct__c(
            Product__c = commodity.Id,
            SalesOrg__c = salesOrg.Id,
            Status__c = 'Adicionada',
            SupplierCenter__c = '1010'
        );
        orgVList.add(commodityOrgV);
        insert orgVList;

        List<PricebookEntry> lstEntries = new List<PricebookEntry>();
        PricebookEntry productPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 150,
            CostPrice__c = 112,
            IsActive = true
        );
        lstEntries.add(productPricebookEntry);

        PricebookEntry commodityPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = commodity.Id,
            UnitPrice = 150,
            CostPrice__c = 112,
            IsActive = true
        );
        lstEntries.add(commodityPricebookEntry);
        insert lstEntries;

        Comissao__c comission = new Comissao__c(
            ProductHierarchy__c = productHierarchy.Id,
            CommissionPercentage__c = 3,
            SellerType__c = 'CTV',
            ProductGroup__c = productGroup.Id
        );
        insert comission;

      
        
        
    }

    @isTest
    public static void fetchRecordsTest(){

        Account acc = [SELECT Id FROM Account LIMIT 1];

        CustomLookupController.fetchRecords('Account', 'Name', 'Parent Account', null);
        CustomLookupController.fetchRecords('Account', 'Name', 'Child Account', acc.Id);
    }

    @isTest
    public static void fetchProductsRecordsTest(){
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        Id scId = [SELECT Id FROM SalesCondition__c LIMIT 1].Id;
        Id cropId = [SELECT Id FROM Safra__c LIMIT 1].Id;
        Id cultureId = [SELECT Id FROM Cultura__c LIMIT 1].Id;
        Id salesOrgId = [SELECT Id FROM SalesOrg__c LIMIT 1].Id;
        Id salesOfficeId = [SELECT Id FROM SalesOffice__c LIMIT 1].Id;
        Id salesTeamId = [SELECT Id FROM SalesTeam__c LIMIT 1].Id;

        CustomLookupController.fetchProductsRecords('Milho', '{"salesConditionId":"' + scId + '","accountId":"' + accountId + '","ctvId":"' + UserInfo.getUserId() + '","safra":"' + cropId +'","productCurrency":"BRL","culture":"' + cultureId + '","orderType":"Venda Normal","supplierCenter":"1010","salesOrgId":"' + salesOrgId + '","salesOfficeId":"' + salesOfficeId + '","salesTeamId":"' + salesTeamId + '","numberOfRowsToSkip":0}', false, new List<String>{});
    }

    @isTest
    public static void fetchCommodityRecordsTest(){
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        Id scId = [SELECT Id FROM SalesCondition__c LIMIT 1].Id;
        Id cropId = [SELECT Id FROM Safra__c LIMIT 1].Id;
        Id cultureId = [SELECT Id FROM Cultura__c LIMIT 1].Id;
        Id salesOrgId = [SELECT Id FROM SalesOrg__c LIMIT 1].Id;
        Id salesOfficeId = [SELECT Id FROM SalesOffice__c LIMIT 1].Id;
        Id salesTeamId = [SELECT Id FROM SalesTeam__c LIMIT 1].Id;

        CustomLookupController.fetchProductsRecords('Soja', '{"salesConditionId":"' + scId + '","accountId":"' + accountId + '","ctvId":"' + UserInfo.getUserId() + '","safra":"' + cropId +'","productCurrency":"BRL","culture":"' + cultureId + '","orderType":"Venda Normal","supplierCenter":"1010","salesOrgId":"' + salesOrgId + '","salesOfficeId":"' + salesOfficeId + '","salesTeamId":"' + salesTeamId + '","numberOfRowsToSkip":0}', true, new List<String>{});
    }

    @isTest
    public static void fetchAccountsWithTerritoriesTest(){
        Id terr;
        Id objAss;
        Id userAss;
        System.runAs(new User(Id = UserInfo.getUserId())){
            terr = createTerritory();
            objAss = createObjectAss(terr);
            userAss = createUserAss(terr);

            
        CustomLookupController.fetchAccountsWithTerritories('P','{"territory":"","ctv":"'+ UserInfo.getUserId()+ '","offSet":0,"option":"addRemove"}');
        CustomLookupController.fetchAccountsWithTerritories('p','{"territory":"'+ terr + '","ctv":"","offSet":0,"option":"addRemove"}');
        CustomLookupController.fetchAccountsWithTerritories('p','{"territory":"'+ terr + '","ctv":"'+ UserInfo.getUserId()+ '","offSet":0,"option":"addRemove"}');
        }

    }

    public static Id createObjectAss(Id terr){
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = accountId, Territory2Id =terr, AssociationCause='Territory2Manual' );
        insert objObjectTerritory2Association;
        return objObjectTerritory2Association.Id;
    }

    public static Id createTerritory(){
        Territory2Type terrModel = [SELECT Id FROM Territory2Type LIMIT 1];
        Territory2Model model = [SELECT Id FROM Territory2Model LIMIT 1];
        Territory2 objTerr = new Territory2(); 
            objTerr.Description = 'Description__c';
            objTerr.Name = 'Name';
            objTerr.DeveloperName = 'Name';
            objTerr.Territory2TypeId = terrModel.Id;
            objTerr.Territory2ModelId = model.Id;
        insert objTerr;
        return objTerr.Id;
    }

    public static Id createUserAss(Id terr){
        UserTerritory2Association userTerrAssociation = new UserTerritory2Association(Territory2Id= terr, UserId= UserInfo.getUserId(), RoleInTerritory2='Sales / Marketing Manager');
        insert userTerrAssociation;
        return userTerrAssociation.Id;
    }
}