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

    /* @AuraEnabled
    public static List<CommodityData> fetchCommoditiesRecords(String searchString) {
        try {
            Id commodityRecType = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('Preço').getRecordTypeId();
            String query = 'SELECT Id, Currency__c, UnitPrice__c, UnitMeasurement__c, Product__c FROM JurosDescontoAntecipao__c WHERE RecordTypeId = \'' + commodityRecType + '\' AND IsActive__c = true AND StartDate__c <=: \'' + System.today() + '\' AND EndDate__c >=: \'' + System.today() + '\'';
            
            List<CommodityData> recordsDataList = new List<CommodityData>();
	        for(SObject s : Database.query(query)) {
	            recordsDataList.add(new CommodityData((String)s.get('Currency__c'), (Decimal)s.get('UnitPrice__c'), (String)s.get('UnitMeasurement__c')));
	        }

            return recordsDataList;
	    } catch (Exception err) {
            System.debug('Erro: ' + err.getMessage() + '   -   ' + err.getStackTraceString());
	    	if ( String.isNotBlank( err.getMessage() ) && err.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else {
                throw new AuraHandledException(err.getMessage());
            }
	    }
    } */
    
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
    public static List<ProductData> fetchProductsRecords(String searchString, String pricebookListId, String accountId, String ctvId) {
        try {
            Id commodityRecType = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId();
            Map<Id, JurosDescontoAntecipao__c> productsPriceById = new Map<Id, JurosDescontoAntecipao__c>();
            Set<String> priceFields = new Set<String>{'Id', 'UnitPrice__c', 'Cost__c', 'Product__c'};
            String priceQuery = new Q(JurosDescontoAntecipao__c.SObjectType)
                                .selectFields(priceFields)
                                .add(Q.condition('RecordTypeId').equalsTo(commodityRecType))
                                .add(Q.condition('IsActive__c').equalsTo(true))
                                .build();

            for(SObject jda : Database.query(priceQuery)) {
                productsPriceById.put((Id)jda.get('Product__c'), (JurosDescontoAntecipao__c)jda);
            }

            Set<Id> prodsId = new Set<Id>();
            Id orgV = getSalesOrgId(accountId, ctvId) != null ? getSalesOrgId(accountId, ctvId) : 'a0T8A000003MhfPUAS';
            for (OrgVProduct__c orgVProduct : [
                SELECT Id,
                       Product__c
                  FROM OrgVProduct__c
                 WHERE Product__c IN: productsPriceById.keySet()
                  AND SalesOrg__c =: orgV
            ]) {
                prodsId.add(orgVProduct.Product__c);
            }

            List<ProductData> recordsDataList = new List<ProductData>();
            String productQuery = 'SELECT Id, Name, ExternalId__c, QuantityUnitOfMeasure, ProductGroup__c, ProductGroup__r.Name, PrincipleActive__c, Multiplicity__c' +
                                  '  FROM Product2' +
                                  ' WHERE Id IN:prodsId' +
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

            for(SObject s : queryResult) {
                JurosDescontoAntecipao__c jda = productsPriceById.get((Id) s.get('Id'));
                String productGroupId = (String)s.get('ProductGroup__c');
                String productGroupName = '';
                
                if (productGroupId != null) {
                    productGroupName = productsGroupById.get(productGroupId) != null ? productsGroupById.get(productGroupId).Name : '';
                }
                recordsDataList.add(new ProductData((String)s.get('Id'), (String)s.get('Name'), (String)s.get('ExternalId__c'), (String)s.get('QuantityUnitOfMeasure'), (String)s.get('PrincipleActive__c'), (Decimal)s.get('Multiplicity__c'), productGroupId, productGroupName, jda.Id, jda.UnitPrice__c, jda.Cost__c));
	        }

            return recordsDataList;
	    } catch (Exception err) {
            System.debug('Erro: ' + err.getMessage() + '   -   ' + err.getStackTraceString());
	    	if ( String.isNotBlank( err.getMessage() ) && err.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else {
                throw new AuraHandledException(err.getMessage());
            }
	    }
    }

    public static Id getSalesOrgId(Id accountId, Id ctvId) {
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

        Id salesOrgId;
        if (territoryAndParents != null && territoryAndParents.get(userTerritoryId) != null && territoryAndParents.get(territoryAndParents.get(userTerritoryId).ParentTerritory2Id) != null) {
            Territory2 salesTeamTerritory = territoryAndParents.get(territoryAndParents.get(userTerritoryId).ParentTerritory2Id);
            
            if (salesTeamTerritory != null && salesTeamTerritory.DeveloperName != null) {
                String salesTeamDevName = salesTeamTerritory.DeveloperName.substring(1, salesTeamTerritory.DeveloperName.length());
                for (Company__c salesTeamCompany : [
                    SELECT Id,
                           SalesOrg__c
                      FROM Company__c
                     WHERE Conta__c =: accountId
                       AND SalesTeam__r.ExternalId__c =: salesTeamDevName
                ]) {
                    salesOrgId = salesTeamCompany.SalesOrg__c;
                }
            }
        }

        return salesOrgId;
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
        @AuraEnabled public Decimal multiplicity;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal costPrice;
        
        public ProductData(String Id, String Name, String sapProductCode, String unity, String activePrinciple, Decimal multiplicity, String productGroup, String productGroupName, String entryId, Decimal listPrice, Decimal costPrice) {
            this.Id = Id;
            this.Name = Name;
            this.sapProductCode = sapProductCode != null ? sapProductCode : '';
            this.unity = unity != null ? unity : '';
            this.productGroupId = productGroup != null ? productGroup : '';
            this.productGroupName = productGroupName != null ? productGroupName : '';
            this.activePrinciple = activePrinciple != null ? activePrinciple : '';
            this.multiplicity = multiplicity;
            this.entryId = entryId;
            this.listPrice = listPrice != null ? listPrice : 0;
            this.costPrice = costPrice != null ? costPrice : 0;
        }
    }

    /* public class ProductData {
        @AuraEnabled public String  commodityCurrency;
        @AuraEnabled public String  unitMeasurement;
        @AuraEnabled public Decimal unitPrice;
        
        public ProductData(Boolean isCommodity, String commodityCurrency, Decimal unitPrice, String unitMeasurement) {
            this.commodityCurrency = isCommodity ? commodityCurrency : null;
            this.unitMeasurement = isCommodity ? unitMeasurement : null;
            this.unitPrice = isCommodity ? unitPrice : null;
        }
    } */
}