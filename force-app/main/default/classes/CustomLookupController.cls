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

    @AuraEnabled
    public static List<SObject> fetchAccountRecords(String searchString) {
        try {
            List<SObject> recordsData = new List<SObject>();
            String query = 'SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Name LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' LIMIT 49999';
            
	        for(SObject s : Database.query(query)) {
	            recordsData.add(s);
	        }

            return recordsData;

	    } catch (Exception err) {
            System.debug('Erro: ' + err.getMessage() + '   -   ' + err.getStackTraceString());
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
    public static ProductDataResult fetchProductsRecords(String searchString, String data, Boolean isCommodity) {
        try {
            ProductDataResult result = new ProductDataResult();
            ProductParams productParams = (ProductParams) JSON.deserialize(data, ProductParams.class);
            System.debug('productParams: ' + productParams);
            Id commodityRecType = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId();

            SalesResult salesResult = getSalesOrgId(productParams.accountId, productParams.ctvId) != null ? getSalesOrgId(productParams.accountId, productParams.ctvId) : null;
            result.salesResult = salesResult;

            Set<String> priceFields = new Set<String>{'Id', 'UnitPrice__c', 'Cost__c', 'Product__c', 'Currency__c', 'SalesOrg__c', 'SalesTeam__c', 'SalesOffice__c', 'Account__c', 'Culture__c'};
            String priceQuery = new Q(JurosDescontoAntecipao__c.SObjectType)
                                .selectFields(priceFields)
                                .add(Q.condition('RecordTypeId').equalsTo(commodityRecType))
                                .add(Q.condition('SalesCondition__c').equalsTo(productParams.salesConditionId))
                                .add(Q.condition('harvest__c').equalsTo(productParams.safra))
                                .add(Q.condition('Currency__c').equalsTo(productParams.productCurrency))
                                .add(Q.condition('SalesOrg__c').equalsTo(salesResult.salesOrgId))
                                .add(Q.condition('IsActive__c').equalsTo(true))
                                .build();

            Map<Id, List<JurosDescontoAntecipao__c>> productsPriceById = new Map<Id, List<JurosDescontoAntecipao__c>>();
            Set<Id> accountIds = new Set<Id>();
            for(SObject jda : Database.query(priceQuery)) {
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

            Set<Id> prodsId = new Set<Id>();
            for (OrgVProduct__c orgVProduct : [
                SELECT Id,
                       Product__c
                  FROM OrgVProduct__c
                 WHERE Product__c IN: productsPriceById.keySet()
                   AND SalesOrg__c =: salesResult.salesOrgId
                   AND Status__c = 'Adicionada'
            ]) {
                prodsId.add(orgVProduct.Product__c);
            }

            Set<String> normalSale = new Set<String>{'HAWA', 'FERT'};
            String productType = isCommodity ? 'ZCOM' : (productParams.orderType == 'Venda de Serviço' ? 'DIEN' : (productParams.orderType == 'Venda Barter' ? 'HAWA' : ''));
            
            String productQuery = 'SELECT Id, Name, ExternalId__c, QuantityUnitOfMeasure, ProductGroup__c, ProductGroup__r.Name, PrincipleActive__c, Multiplicity__c' +
                                  '  FROM Product2' +
                                  ' WHERE Id IN:prodsId' +
                                  (
                                    productType == '' ? 
                                        ' AND ProductType__c IN: normalSale' :
                                        ' AND ProductType__c =: productType'
                                  ) +
                                  '   AND ('+
                                  '            Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\'' +
                                  '         OR ProductGroup__r.Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\'' +
                                  '         OR PrincipleActive__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\'' +
                                  '       )' +
                                  ' LIMIT 49999';
            
            List<SObject> queryResult = Database.query(productQuery);
            Set<Id> prodGroupIds = new Set<Id>();
            for (SObject product : queryResult) {
                prodGroupIds.add((String)product.get('ProductGroup__c'));
            }

            Map<Id, ProductGroup__c> productsGroupById = new Map<Id, ProductGroup__c>([
                SELECT Id, Name
                  FROM ProductGroup__c
                 WHERE Id IN: prodGroupIds
            ]);
            
            Map<Id, Decimal> commissionByGroup = new Map<Id, Decimal>();
            if (isCommodity) {
                User user = [SELECT Id, SellerType__c FROM User WHERE Id =: UserInfo.getUserId()];
                String sellerType = user.SellerType__c != null ? user.SellerType__c : '';
    
                if (sellerType != '') {
                    for (Comissao__c commission : [
                        SELECT Id,
                               ProductGroup__c,
                               CommissionPercentage__c 
                        FROM Comissao__c
                       WHERE ProductGroup__c IN: prodGroupIds
                         AND SellerType__c =: sellerType
                    ]) {
                        if (!commissionByGroup.containsKey(commission.ProductGroup__c)) {
                            commissionByGroup.put(commission.ProductGroup__c, commission.CommissionPercentage__c);
                        }
                    }
                }
            }

            result.recordsDataList = new List<ProductData>();
            result.recordsDataMap = new Map<String, ProductData>();
            for(SObject s : queryResult) {
                List<JurosDescontoAntecipao__c> jdaList = productsPriceById.get((Id) s.get('Id'));
                Boolean productIncluded = false;
                for (JurosDescontoAntecipao__c jda : jdaList) {
                    String productGroupId = (String)s.get('ProductGroup__c');
                    String productGroupName = '';
                    
                    if (productGroupId != null) {
                        productGroupName = productsGroupById.get(productGroupId) != null ? productsGroupById.get(productGroupId).Name : '';
                    }
    
                    Decimal commissionPercentage = commissionByGroup.get(productGroupId) != null ? commissionByGroup.get(productGroupId) : 0;
                    ProductData productData = new ProductData((String)s.get('Id'), (String)s.get('Name'), (String)s.get('ExternalId__c'), (String)s.get('QuantityUnitOfMeasure'), (String)s.get('PrincipleActive__c'), (Decimal)s.get('Multiplicity__c'), productGroupId, productGroupName, jda.Currency__c, jda.Id, jda.UnitPrice__c, jda.Cost__c, commissionPercentage);
                    if (!productIncluded) {
                        result.recordsDataList.add(productData);
                        productIncluded = true;
                    }
                    
                    String key = jda.Account__c + '-' + (String)s.get('Id');
                    if (!result.recordsDataMap.containsKey(key)) {
                        result.recordsDataMap.put(key, productData);
                    }
    
                    String accountSegment = jda.Account__c != null ? industryByAccountIds.get(jda.Account__c).Industry : '';
                    key = accountSegment + '-' + (String)s.get('Id');
                    if (!result.recordsDataMap.containsKey(key)) {
                        result.recordsDataMap.put(key, productData);
                    }
    
                    key = jda.Culture__c + '-' + jda.SalesTeam__c + '-' + (String)s.get('Id');
                    if (!result.recordsDataMap.containsKey(key)) {
                        result.recordsDataMap.put(key, productData);
                    }
    
                    key = jda.SalesTeam__c + '-' + (String)s.get('Id');
                    if (!result.recordsDataMap.containsKey(key)) {
                        result.recordsDataMap.put(key, productData);
                    }
    
                    key = jda.SalesOffice__c + '-' + (String)s.get('Id');
                    if (!result.recordsDataMap.containsKey(key)) {
                        result.recordsDataMap.put(key, productData);
                    }
    
                    key = productGroupId;
                    if (!result.recordsDataMap.containsKey(key)) {
                        result.recordsDataMap.put(key, productData);
                    }
    
                    key = (String)s.get('Id');
                    if (!result.recordsDataMap.containsKey(key)) {
                        result.recordsDataMap.put(key, productData);
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

    public static SalesResult getSalesOrgId(Id accountId, Id ctvId) {
        SalesResult result = new SalesResult();
        Id userTerritoryId;
        for (UserTerritory2Association userAssociation : [
            SELECT Id,
                   UserId,
                   Territory2Id
              FROM UserTerritory2Association
             WHERE UserId =: ctvId
             LIMIT 1
        ]) {
            userTerritoryId = userAssociation.Territory2Id;
        }

        Map<Id, Territory2> territoryAndParents = new Map<Id, Territory2>();
        for(Territory2 territory : [
            SELECT Id,
                   DeveloperName,
                   ParentTerritory2Id
              FROM Territory2
        ]){
            territoryAndParents.put(territory.Id, territory);
        }

        if (territoryAndParents != null && territoryAndParents.get(userTerritoryId) != null && territoryAndParents.get(territoryAndParents.get(userTerritoryId).ParentTerritory2Id) != null) {
            Territory2 salesTeamTerritory = territoryAndParents.get(territoryAndParents.get(userTerritoryId).ParentTerritory2Id);
            
            if (salesTeamTerritory != null && salesTeamTerritory.DeveloperName != null) {
                String salesTeamDevName = salesTeamTerritory.DeveloperName.substring(0, 1) == 'X' ? salesTeamTerritory.DeveloperName.substring(1, salesTeamTerritory.DeveloperName.length()) : salesTeamTerritory.DeveloperName;
                for (Company__c salesTeamCompany : [
                    SELECT Id,
                           SalesOrg__c,
                           SalesOffice__c,
                           SalesTeam__c
                      FROM Company__c
                     WHERE Conta__c =: accountId
                       AND SalesTeam__r.ExternalId__c =: salesTeamDevName
                ]) {
                    result.salesOrgId = salesTeamCompany.SalesOrg__c;
                    result.salesOfficeId = salesTeamCompany.SalesOffice__c;
                    result.salesTeamId = salesTeamCompany.SalesTeam__c;
                }
            }
        }
        result.segmento = [SELECT Industry FROM Account WHERE Id =: accountId].Industry;

        return result;
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
        @AuraEnabled public String  activePrinciple;
        @AuraEnabled public String  entryId;
        @AuraEnabled public String  productCurrency;
        @AuraEnabled public Decimal multiplicity;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal costPrice;
        @AuraEnabled public Decimal commissionPercentage;
        
        public ProductData(String Id, String Name, String sapProductCode, String unity, String activePrinciple, Decimal multiplicity, String productGroup, String productGroupName, String productCurrency, Id entryId, Decimal listPrice, Decimal costPrice, Decimal commissionPercentage) {
            this.Id = Id;
            this.Name = Name;
            this.sapProductCode = sapProductCode != null ? sapProductCode : '';
            this.unity = unity != null ? unity : '';
            this.productGroupId = productGroup != null ? productGroup : '';
            this.productGroupName = productGroupName != null ? productGroupName : '';
            this.activePrinciple = activePrinciple != null ? activePrinciple : '';
            this.productCurrency = productCurrency != null ? productCurrency : '';
            this.multiplicity = multiplicity != null ? multiplicity : 1;
            this.entryId = entryId;
            this.listPrice = listPrice != null ? listPrice : 0;
            this.costPrice = costPrice != null ? costPrice : 0;
            this.commissionPercentage = commissionPercentage != null ? commissionPercentage : 0;
        }
    }

    public class ProductParams {
        public String salesConditionId;
        public String accountId;
        public String ctvId;
        public String safra;
        public String productCurrency;
        public String culture;
        public String orderType;
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
    }
}