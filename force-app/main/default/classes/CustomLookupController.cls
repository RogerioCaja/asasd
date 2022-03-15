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
                		' LIKE ' + '\'' + String.escapeSingleQuotes(searchString.trim()) + '%\' LIMIT 49999';
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
            String query = 'SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' LIMIT 49999';
            
	        for(SObject s : Database.query(query)) {
	            recordsData.add(s);
	        }

            return recordsData;

	    } catch (Exception err) {

	    	if ( String.isNotBlank( err.getMessage() ) && err.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else {
                throw new AuraHandledException(err.getMessage());
            }
	    }
    }

    @AuraEnabled
    public static List<ProductData> fetchProductsRecords(String searchString, String pricebookListId) {
        try {
            Map<Id, PricebookEntry> productsPriceById = new Map<Id, PricebookEntry>();
            Set<String> pricebookEntryFields = new Set<String>{'Id', 'UnitPrice', 'CostPrice__c', 'Product2Id'};
            String pricebookEntryQuery = new Q(PricebookEntry.SObjectType)
                           .selectFields(pricebookEntryFields)
                           .add(Q.condition('Pricebook2Id').equalsTo(pricebookListId))
                           .add(Q.condition('IsActive').equalsTo(true))
                           .build();
            for(SObject pbe : Database.query(pricebookEntryQuery)) {
                productsPriceById.put((Id)pbe.get('Product2Id'), (PricebookEntry)pbe);
            }

            Set<Id> prodsId = productsPriceById.keySet();
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
                 WHERE Id IN:prodGroupIds
            ]);

            for(SObject s : queryResult) {
                PricebookEntry pbe = productsPriceById.get((Id) s.get('Id'));
                String productGroupId = (String)s.get('ProductGroup__c');
                String productGroupName = '';
                
                if (productGroupId != null) {
                    productGroupName = productsGroupById.get(productGroupId) != null ? productsGroupById.get(productGroupId).Name : '';
                }
                recordsDataList.add(new ProductData((String)s.get('Id'), (String)s.get('Name'), (String)s.get('ExternalId__c'), (String)s.get('QuantityUnitOfMeasure'), (String)s.get('PrincipleActive__c'), (Decimal)s.get('Multiplicity__c'), productGroupId, productGroupName, pbe.Id, pbe.UnitPrice, pbe.CostPrice__c));
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

    public class RecordsData {

        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public RecordsData(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class ProductData {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String sapProductCode;
        @AuraEnabled public String unity;
        @AuraEnabled public String productGroupId;
        @AuraEnabled public String productGroupName;
        @AuraEnabled public String activePrinciple;
        @AuraEnabled public Decimal multiplicity;
        @AuraEnabled public String entryId;
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
}