public without sharing class CustomLookupController {
    
    @AuraEnabled
    public static List<RecordsData> fetchRecords(String objectName, String filterField, String searchString, String value) {

        try {

            List<RecordsData> recordsDataList = new List<RecordsData>();
            String query = 'SELECT Id, ' + filterField + ' FROM '+objectName;

            if(String.isNotBlank(value)) {
                query += ' WHERE Id = \''+ value + '\' LIMIT 49999';
            } else {
                query += ' WHERE '+filterField+
                		' LIKE ' + '\'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR '+
                		filterField + ' LIKE ' + '\'' + String.escapeSingleQuotes(searchString.trim()) + '%\' LIMIT 49999';
            }
	        for(SObject s : Database.query(query)) {
	            recordsDataList.add( new RecordsData((String)s.get(filterField), (String)s.get('id')) );
	        }

            return recordsDataList;

	    } catch (Exception err) {

	    	if ( String.isNotBlank( err.getMessage() ) && err.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else {
                throw new AuraHandledException(err.getMessage());
            }
	    }
    }

    public static String removeAccents(String text) {
		String minmaj = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž& ';
		String maj    = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZze-e';
		String out    = '';
		for (Integer i = 0 ; i < text.length() ; i++) {
			String car = text.substring(i, i+1);
			Integer idx = minmaj.indexOf(car);
			if (idx != -1){
				out += maj.substring(idx, idx+1);
			} else {
				out += car;
			}
		}
		return out.toLowercase();
	}

    @AuraEnabled
    public static ProductDataResult fetchProductsRecords(String searchString, String data, Boolean isCommodity, List<String> productsIds, Boolean priceScreen) {
        try {
            ProductDataResult result = new ProductDataResult();
            ProductParams productParams = (ProductParams) JSON.deserialize(data, ProductParams.class);
            System.debug('productParams: ' + productParams);
            Id commodityRecType = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId();
            List<Account> lstAccount = new List<Account>();
            if (productParams.accountId != '') lstAccount = [SELECT Industry FROM Account WHERE Id =: productParams.accountId];

            SalesResult salesResult = new SalesResult();
            salesResult.salesOrgId = productParams.salesOrgId;
            salesResult.salesOfficeId = productParams.salesOfficeId;
            salesResult.salesTeamId = productParams.salesTeamId;
            salesResult.segmento = lstAccount.size() > 0 ? lstAccount[0].Industry : '';
            salesResult.searchString = searchString;
            result.salesResult = salesResult;

            Set<String> priceFields = new Set<String>{'Id', 'UnitPrice__c', 'Cost__c', 'Product__c', 'ProductGroup__c', 'Currency__c', 'SalesOrg__c', 'SalesTeam__c', 'SalesOffice__c', 'Account__c', 'Culture__c', 'ProductMultiplier__c', 'ExternalId__c', 'SalesCondition__r.Name'};
            Q priceQuery = new Q(JurosDescontoAntecipao__c.SObjectType)
                                .selectFields(priceFields)
                                .add(Q.condition('RecordTypeId').equalsTo(commodityRecType))
                                .add(Q.condition('harvest__c').equalsTo(productParams.safra))
                                .add(Q.condition('SalesOrg__c').equalsTo(salesResult.salesOrgId))
                                .add(Q.condition('IsActive__c').equalsTo(true))
                                .add(Q.condition('StartDate__c').isLessOrEquals(System.today()))
                                .add(Q.condition('EndDate__c').isGreaterOrEquals(System.today()));

            if (!priceScreen) {
                priceQuery.add(Q.condition('SalesCondition__c').equalsTo(productParams.salesConditionId))
                          .add(Q.condition('Currency__c').equalsTo(productParams.productCurrency));
            }
            if (productsIds.size() > 0) {
                priceQuery.add(Q.condition('Product__c').isIn(productsIds));
            }

            Map<Id, List<JurosDescontoAntecipao__c>> productsPriceById = new Map<Id, List<JurosDescontoAntecipao__c>>();
            Set<Id> accountIds = new Set<Id>();
            for(SObject jda : Database.query(priceQuery.build())) {
                System.debug('jda: ' + jda);
                if (!productsPriceById.containsKey((Id)jda.get('Product__c'))) {
                    productsPriceById.put((Id)jda.get('Product__c'), new List<JurosDescontoAntecipao__c>{(JurosDescontoAntecipao__c)jda});
                } else {
                    List<JurosDescontoAntecipao__c> jdaList = productsPriceById.get((Id)jda.get('Product__c'));
                    jdaList.add((JurosDescontoAntecipao__c)jda);
                    productsPriceById.put((Id)jda.get('Product__c'), jdaList);
                }
                accountIds.add((Id)jda.get('Account__c'));
            }

            Map<Id, Account> industryByAccountIds = new Map<Id, Account>([
                SELECT Id, Industry
                  FROM Account
                 WHERE Id IN: accountIds
            ]);

            List<Id> prodsId = new List<Id>();
            for (OrgVProduct__c orgVProduct : [
                SELECT Id,
                       Product__c
                  FROM OrgVProduct__c
                 WHERE Product__c IN: productsPriceById.keySet()
                   AND SalesOrg__c =: salesResult.salesOrgId
                   AND Status__c = 'Adicionada'
                   AND SupplierCenter__c =: productParams.supplierCenter
            ]) {
                prodsId.add(orgVProduct.Product__c);
            }

            String recTypeDevName = '';
            for (RecordType orderRecType : [
                SELECT Id,
                       DeveloperName
                  FROM RecordType
                 WHERE SobjectType = 'Order'
                   AND IsActive = true
                   AND Name =: productParams.orderType
            ]) {
                recTypeDevName = orderRecType.DeveloperName;
            }

            Set<String> normalSale = new Set<String>{'HAWA', 'FERT'};
            String productType = isCommodity ? 'ZCOM' : (recTypeDevName == 'VendaServico' ? 'DIEN' : (recTypeDevName == 'VendaBarter' ? 'HAWA' : ''));
            
            Integer numberOfRowsToSkip = productParams.numberOfRowsToSkip;
            String productQuery = 'SELECT Id, Name, ExternalId__c, UnidadeMedida__c, ProductGroup__c, ProductGroup__r.Name, ProductSubgroup__c, PrincipleActive__c, Multiplicity__c, ProductHierarchy__c' +
                                  '  FROM Product2' +
                                  ' WHERE Id IN:prodsId' +
                                  (
                                    productType == '' ? 
                                        ' AND ProductType__c IN: normalSale' :
                                        ' AND ProductType__c =: productType'
                                  ) +
                                  '   AND ('+
                                  '            Name LIKE \'%' + String.escapeSingleQuotes(searchString.trim()) + '%\'' +
                                  '         OR ProductGroup__r.Name LIKE \'%' + String.escapeSingleQuotes(searchString.trim()) + '%\'' +
                                  '         OR PrincipleActive__c LIKE \'%' + String.escapeSingleQuotes(searchString.trim()) + '%\'' +
                                  '       )' +
                                  ' ORDER BY Name' +
                                  ' LIMIT 9' +
                                  ' OFFSET :numberOfRowsToSkip';
            
            List<SObject> queryResult = Database.query(productQuery);
            Set<Id> prodGroupIds = new Set<Id>();
            Set<Id> prodSubgroupIds = new Set<Id>();
            Set<Id> prodHierarchyIds = new Set<Id>();
            for (SObject product : queryResult) {
                prodGroupIds.add((String)product.get('ProductGroup__c'));
                prodSubgroupIds.add((String)product.get('ProductSubgroup__c'));
                prodHierarchyIds.add((String)product.get('ProductHierarchy__c'));
            }

            Map<Id, ProductGroup__c> productsGroupById = new Map<Id, ProductGroup__c>([
                SELECT Id, Name
                  FROM ProductGroup__c
                 WHERE Id IN: prodGroupIds
            ]);

            Map<Id, ProductSubgroup__c> productsSubgroupById = new Map<Id, ProductSubgroup__c>([
                SELECT Id, Name
                  FROM ProductSubgroup__c
                 WHERE Id IN: prodSubgroupIds
            ]);

            
            Map<Id, Decimal> commissionByHierarchy = new Map<Id, Decimal>();
            if (isCommodity) {
                User user = [SELECT Id, SellerType__c FROM User WHERE Id =: productParams.ctvId];
                String sellerType = user.SellerType__c != null ? user.SellerType__c : '';
    
                if (sellerType != '') {
                    for (Comissao__c commission : [
                        SELECT Id,
                               ProductHierarchy__c,
                               CommissionPercentage__c 
                          FROM Comissao__c
                         WHERE ProductHierarchy__c IN: prodHierarchyIds
                           AND SellerType__c =: sellerType
                    ]) {
                        if (!commissionByHierarchy.containsKey(commission.ProductHierarchy__c)) {
                            commissionByHierarchy.put(commission.ProductHierarchy__c, commission.CommissionPercentage__c);
                        }
                    }
                }
            }
            
            Set<String> ptaFields = new Set<String>{'Id', 'PTAProduct__c', 'SalesOrg__c', 'Harvest__c'};
            String ptaQuery = new Q(PTAProducts__c.SObjectType)
                              .selectFields(ptaFields)
                              .add(Q.condition('PTAProduct__c').isIN(prodsId))
                              .add(Q.condition('SalesOrg__c').equalsTo(productParams.salesOrgId))
                              .add(Q.condition('Harvest__c').equalsTo(productParams.safra))
                              .build();

            Set<Id> ptaProducts = new Set<Id>();
            for(SObject pta : Database.query(ptaQuery)) {
                ptaProducts.add((Id)pta.get('PTAProduct__c'));
            }

            result.recordsDataList = new List<ProductData>();
            result.recordsDataMap = new Map<String, ProductData>();
            for(SObject s : queryResult) {
                List<JurosDescontoAntecipao__c> jdaList = productsPriceById.get((Id) s.get('Id'));
                Boolean productIncluded = false;
                for (JurosDescontoAntecipao__c jda : jdaList) {
                    if ((jda.SalesOrg__c == salesResult.salesOrgId || jda.SalesOrg__c == null) &&
                        (jda.SalesOffice__c == salesResult.salesOfficeId || jda.SalesOffice__c == null) &&
                        (jda.SalesTeam__c == salesResult.salesTeamId || jda.SalesTeam__c == null) &&
                        (productParams.accountId == '' || jda.Account__c == productParams.accountId || jda.Account__c == null))  {
                        String productGroupId = (String)s.get('ProductGroup__c');
                        String productSubgroupId = (String)s.get('ProductSubgroup__c');
                        String productHierarchyId = (String)s.get('ProductHierarchy__c');
                        String productGroupName = '';
                        String productSubgroupName = '';
                        Boolean isPtaProduct = false;
                        
                        if (productGroupId != null) {
                            productGroupName = productsGroupById.get(productGroupId) != null ? productsGroupById.get(productGroupId).Name : '';
                        }

                        if (productSubgroupId != null) {
                            productSubgroupName = productsSubgroupById.get(productSubgroupId) != null ? productsSubgroupById.get(productSubgroupId).Name : '';
                        }

                        if (ptaProducts.contains((String)s.get('Id'))) {
                            isPtaProduct = true;
                        }
        
                        Decimal commissionPercentage = commissionByHierarchy.get(productHierarchyId) != null ? commissionByHierarchy.get(productHierarchyId) : 0;
                        ProductData productData = new ProductData((String)s.get('Id'), (String)s.get('Name'), (String)s.get('ExternalId__c'), (String)s.get('UnidadeMedida__c'), (String)s.get('PrincipleActive__c'), (Decimal)s.get('Multiplicity__c'), productGroupId, productHierarchyId, productGroupName, productSubgroupId, productSubgroupName, jda.Currency__c, jda.Id, jda.UnitPrice__c, jda.Cost__c, commissionPercentage, jda.ProductMultiplier__c, isPtaProduct, jda.ExternalId__c, jda.SalesCondition__r.Name);
                        
                        Boolean priceIncluded = false;
                        String key = jda.Account__c + '-' + (String)s.get('Id');
                        if ((productParams.accountId == '' && jda.Account__c == null) || (productParams.accountId != '')) {
                            if (jda.Account__c != null && !result.recordsDataMap.containsKey(key)) {
                                result.recordsDataMap.put(key, productData);
                                priceIncluded = true;
                            }
            
                            String accountSegment = jda.Account__c != null ? industryByAccountIds.get(jda.Account__c).Industry : '';
                            key = accountSegment + '-' + (String)s.get('Id');
                            if (!priceIncluded && accountSegment != '' && !result.recordsDataMap.containsKey(key)) {
                                result.recordsDataMap.put(key, productData);
                                priceIncluded = true;
                            }
            
                            key = jda.Culture__c + '-' + jda.SalesTeam__c + '-' + (String)s.get('Id');
                            if (!priceIncluded && jda.Culture__c != null && jda.SalesTeam__c != null && !result.recordsDataMap.containsKey(key)) {
                                result.recordsDataMap.put(key, productData);
                                priceIncluded = true;
                            }
            
                            key = jda.SalesTeam__c + '-' + (String)s.get('Id');
                            if (!priceIncluded && jda.SalesTeam__c != null && !result.recordsDataMap.containsKey(key)) {
                                result.recordsDataMap.put(key, productData);
                                priceIncluded = true;
                            }
            
                            key = jda.SalesOffice__c + '-' + (String)s.get('Id');
                            if (!priceIncluded && jda.SalesOffice__c != null && !result.recordsDataMap.containsKey(key)) {
                                result.recordsDataMap.put(key, productData);
                                priceIncluded = true;
                            }
            
                            key = jda.ProductGroup__c;
                            if (!priceIncluded && jda.ProductGroup__c != null && !result.recordsDataMap.containsKey(key)) {
                                result.recordsDataMap.put(key, productData);
                                priceIncluded = true;
                            }
            
                            key = (String)s.get('Id');
                            if (!priceIncluded && !result.recordsDataMap.containsKey(key)) {
                                result.recordsDataMap.put(key, productData);
                                priceIncluded = true;
                            }
                            
                            if (!productIncluded && priceIncluded) {
                                result.recordsDataList.add(productData);
                                productIncluded = true;
                            }
                        }
                    }
                }
	        }

            return result;
	    } catch (Exception err) {
            System.debug('Erro: ' + err.getMessage() + '   -   ' + err.getStackTraceString());
	    	if ( String.isNotBlank( err.getMessage() ) && err.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else {
                throw new AuraHandledException(err.getMessage());
            }
	    }
    }

    @AuraEnabled
    public static TerritoryDataresult fetchAccountsWithTerritories(String searchString, String data){
        try {
            TerritoryDataresult result = new TerritoryDataresult();
            result.dataList = new List<InformationData>();
            TerritoryParams territoryParams = (TerritoryParams) JSON.deserialize(data, TerritoryParams.class);
            if(territoryParams.ctv != '' && territoryParams.territory == ''){
                List<UserTerritory2Association> territories = [SELECT User.Name, Territory2Id FROM UserTerritory2Association WHERE UserId =: territoryParams.ctv];
                if(territories.size() > 0){
                    UserTerritory2Association territory = territories[0];
                    Set<String> fieldsSet = new Set<String>{'Id', 'Name', 'ExternalId__c'};
                    Q accountQuery = new Q(Account.SObjectType)
                                .selectFields(fieldsSet)
                                .add(Q.condition('Name').isLike('%' + String.escapeSingleQuotes(searchString.trim()) + '%'));

                    List<Account> accountList = Database.query(accountQuery.build());
                    Map<Id, Account> accountMap = new Map<Id, Account>();
                    for(Account acc : accountList){
                        accountMap.put(acc.Id, acc);
                    }

                    Integer counter = [SELECT COUNT() FROM ObjectTerritory2Association
                                        WHERE ObjectId IN: accountMap.keySet() AND Territory2Id =: territory.Territory2Id];
                    result.counter = counter;
                    List<ObjectTerritory2Association> objectList = [SELECT ObjectId, Territory2Id, Territory2.Name, Territory2.ParentTerritory2.Name FROM ObjectTerritory2Association
                                                                    WHERE ObjectId IN: accountMap.keySet() AND Territory2Id =: territory.Territory2Id LIMIT 30 OFFSET : territoryParams.offSet];
                                                                    System.debug('objectList => ' + objectList);
                    for(ObjectTerritory2Association objectItem : objectList){
                        InformationData resultData = new InformationData();
                        if(accountMap.containsKey(objectItem.ObjectId)){
                            resultData.accountCode = accountMap.get(objectItem.ObjectId).ExternalId__c;
                            resultData.accountName = accountMap.get(objectItem.ObjectId).Name;
                            resultData.actualCTV = territory.User.Name;
                            resultData.territoryName = objectItem.Territory2.Name;
                            resultData.territoryFatherName = objectItem.Territory2.ParentTerritory2.Name;
                            result.dataList.add(resultData);
                        }
                    }
                }
                return result;
            }
            else if(territoryParams.ctv == '' && territoryParams.territory != ''){
                List<UserTerritory2Association> territories = [SELECT User.Name, Territory2Id FROM UserTerritory2Association WHERE Territory2Id =: territoryParams.territory LIMIT 1];
                if(territories.size() > 0){
                    UserTerritory2Association territory = territories[0];
                    
                    Set<String> fieldsSet = new Set<String>{'Id', 'Name', 'ExternalId__c'};
                    Q accountQuery = new Q(Account.SObjectType)
                    .selectFields(fieldsSet)
                    .add(Q.condition('Name').isLike('%' + String.escapeSingleQuotes(searchString.trim()) + '%'));
                    
                    List<Account> accountList = Database.query(accountQuery.build());
                    Map<Id, Account> accountMap = new Map<Id, Account>();
                    for(Account acc : accountList){
                        accountMap.put(acc.Id, acc);
                    }

                    Integer counter = [SELECT COUNT() FROM ObjectTerritory2Association
                                        WHERE ObjectId IN: accountMap.keySet() AND Territory2Id =: territory.Territory2Id];
                    result.counter = counter;

                    List<ObjectTerritory2Association> objectList = [SELECT ObjectId, Territory2Id, Territory2.Name, Territory2.ParentTerritory2.Name FROM ObjectTerritory2Association
                                                                    WHERE ObjectId IN: accountMap.keySet() AND Territory2Id =: territory.Territory2Id LIMIT 30 OFFSET : territoryParams.offSet];

                    for(ObjectTerritory2Association objectItem : objectList){
                        InformationData resultData = new InformationData();
                        if(accountMap.containsKey(objectItem.ObjectId)){
                            resultData.accountCode = accountMap.get(objectItem.ObjectId).ExternalId__c;
                            resultData.accountName = accountMap.get(objectItem.ObjectId).Name;
                            resultData.actualCTV = territory.User.Name;
                            resultData.territoryName = objectItem.Territory2.Name;
                            resultData.territoryFatherName = objectItem.Territory2.ParentTerritory2.Name;
                            result.dataList.add(resultData);
                        }
                    }
                }
                return result;
            }else{
                Map<Id, String> ctvToTerritory = new Map<Id, String>();
                List<UserTerritory2Association> territoryList = [SELECT User.Name, Territory2Id FROM UserTerritory2Association WHERE UserId =: territoryParams.ctv OR Territory2Id =: territoryParams.territory];
                if(territoryList != null && territoryList.size() > 0){
                        for(UserTerritory2Association userTerr : territoryList){
                            if(!ctvToTerritory.containsKey(userTerr.Territory2Id)){
                                ctvToTerritory.put(userTerr.Territory2Id, userTerr.User.Name);
                            }
                        }
                    
                    
                    Set<String> fieldsSet = new Set<String>{'Id', 'Name', 'ExternalId__c'};
                    Q accountQuery = new Q(Account.SObjectType)
                    .selectFields(fieldsSet)
                    .add(Q.condition('Name').isLike('%' + String.escapeSingleQuotes(searchString.trim()) + '%'));

                    List<Account> accountList = Database.query(accountQuery.build());
                    Map<Id, Account> accountMap = new Map<Id, Account>();
                    for(Account acc : accountList){
                        accountMap.put(acc.Id, acc);
                    }

                    Integer counter = [SELECT COUNT() FROM ObjectTerritory2Association
                                        WHERE ObjectId IN: accountMap.keySet() AND Territory2Id IN: ctvToTerritory.keySet()];
                    result.counter = counter;

                    List<ObjectTerritory2Association> objectList = [SELECT ObjectId, Territory2Id, Territory2.Name, Territory2.ParentTerritory2.Name FROM ObjectTerritory2Association
                                        WHERE ObjectId IN: accountMap.keySet() AND Territory2Id IN: ctvToTerritory.keySet() LIMIT 30 OFFSET : territoryParams.offSet];
                    Map<Id, ObjectTerritory2Association> objectMap = new Map<Id, ObjectTerritory2Association>();
                    for(ObjectTerritory2Association objectItem : objectList){
                        objectMap.put(objectItem.Territory2Id, objectItem);
                    }
                    for(ObjectTerritory2Association objectItem : objectList){
                        InformationData resultData = new InformationData();
                        if(accountMap.containsKey(objectItem.ObjectId)){
                            resultData.accountCode = accountMap.get(objectItem.ObjectId).ExternalId__c;
                            resultData.accountName = accountMap.get(objectItem.ObjectId).Name;
                            resultData.actualCTV = ctvToTerritory.get(objectItem.Territory2Id);
                            resultData.territoryName = objectMap.get(objectItem.Territory2Id).Territory2.Name;
                            resultData.territoryFatherName = objectMap.get(objectItem.Territory2Id).Territory2.ParentTerritory2.Name;
                            result.dataList.add(resultData);
                        }
                    }
                }
                return result;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class RecordsData {

        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public RecordsData(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class ProductData {
        @AuraEnabled public String  Id;
        @AuraEnabled public String  Name;
        @AuraEnabled public String  sapProductCode;
        @AuraEnabled public String  unity;
        @AuraEnabled public String  productGroupId;
        @AuraEnabled public String  productGroupName;
        @AuraEnabled public String  productSubgroupId;
        @AuraEnabled public String  productSubgroupName;
        @AuraEnabled public String  productHierarchyId;
        @AuraEnabled public String  activePrinciple;
        @AuraEnabled public String  entryId;
        @AuraEnabled public String  productCurrency;
        @AuraEnabled public String  priceListCode;
        @AuraEnabled public String  salesCondition;
        @AuraEnabled public Boolean ptaProduct;
        @AuraEnabled public Decimal multiplicity;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal costPrice;
        @AuraEnabled public Decimal commissionPercentage;
        
        public ProductData(String Id, String Name, String sapProductCode, String unity, String activePrinciple, Decimal multiplicity, String productGroup, String productHierarchy, String productGroupName, String productSubgroup, String productSubgroupName, String productCurrency, Id entryId, Decimal listPrice, Decimal costPrice, Decimal commissionPercentage, Decimal multiplier, Boolean ptaProduct, String priceListCode, String salesCondition) {
            multiplier = multiplier != null ? multiplier : 1;
            this.Id = Id;
            this.Name = Name;
            this.sapProductCode = sapProductCode != null ? String.valueOf(Integer.valueOf(sapProductCode) * 1) : '';
            this.unity = unity != null ? unity : '';
            this.productGroupId = productGroup != null ? productGroup : '';
            this.productHierarchyId = productHierarchy != null ? productHierarchy : '';
            this.productGroupName = productGroupName != null ? productGroupName : '';
            this.productSubgroupId = productSubgroup != null ? productSubgroup : '';
            this.productSubgroupName = productSubgroupName != null ? productSubgroupName : '';
            this.activePrinciple = activePrinciple != null ? activePrinciple : '';
            this.productCurrency = productCurrency != null ? productCurrency : '';
            this.ptaProduct = ptaProduct;
            this.multiplicity = multiplicity != null ? multiplicity : 1;
            this.entryId = entryId;
            this.listPrice = listPrice != null ? listPrice / multiplier : 0;
            this.costPrice = costPrice != null ? costPrice / multiplier : 0;
            this.commissionPercentage = commissionPercentage != null ? commissionPercentage : 0;
            this.priceListCode = priceListCode != null ? priceListCode : '';
            this.salesCondition = salesCondition != null ? salesCondition : '';
        }
    }

    public class ProductParams {
        public String  salesConditionId;
        public String  accountId;
        public String  ctvId;
        public String  safra;
        public String  productCurrency;
        public String  culture;
        public String  orderType;
        public String  supplierCenter;
        public String  salesOrgId;
        public String  salesOfficeId;
        public String  salesTeamId;
        public Integer numberOfRowsToSkip;
    }

    public class ProductDataResult {
        @AuraEnabled public List<ProductData> recordsDataList;
        @AuraEnabled public Map<String, ProductData> recordsDataMap;
        @AuraEnabled public SalesResult salesResult;
    }

    public class SalesResult {
        @AuraEnabled public Id salesOrgId;
        @AuraEnabled public Id salesOfficeId;
        @AuraEnabled public Id salesTeamId;
        @AuraEnabled public String segmento;
        @AuraEnabled public String searchString;
    }

    public class TerritoryParams{
        public String territory;
        public String ctv;
        public Integer offSet;
    }

    public class InformationData{
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountCode;
        @AuraEnabled public String actualCTV;
        @AuraEnabled public String territoryName;
        @AuraEnabled public String territoryFatherName;
    }


    public class TerritoryDataresult{
        @AuraEnabled public List<InformationData> dataList;
        @AuraEnabled public Integer counter = 0;
    }
}