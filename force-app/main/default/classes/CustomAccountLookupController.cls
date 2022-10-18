public with sharing class CustomAccountLookupController {
    @AuraEnabled
    public static List<SObject> fetchAccountRecords(String searchString, Integer offSet) {
        try {
			if(offSet == null){
				offSet = 0;
			}

			String query = '';

            List<SObject> recordsData = new List<SObject>();
			String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
			if (profileName != 'Balcão') {
				Set<Id> relatedAccounts = OrderScreenController.getTerritoryAccounts();
				query = 'SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState, Parent.Name, StateRegistration__c FROM Account WHERE Status__c = \'' + 'Ativo' + '\' AND Id IN: relatedAccounts AND ExternalId__c LIKE \'' + '0001' + '%\' AND (Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Name LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\')' +
				' ORDER BY Name' +
				' LIMIT 30' + 
				' OFFSET :offSet';
				
			} else {
				query = 'SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState, Parent.Name, StateRegistration__c FROM Account WHERE Status__c = \'' + 'Ativo' + '\' AND ExternalId__c LIKE \'' + '0001' + '%\' AND (Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Name LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\')' +
				' ORDER BY Name' +
				' LIMIT 30' + 
				' OFFSET :offSet';
			}
            
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

	@AuraEnabled
	public static Integer getNumberOfAccounts(String searchString){
		String query = 'SELECT COUNT() FROM Account WHERE (Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Name LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\')';            
		Integer result = Database.countQuery(query);
		Decimal value =  Math.mod(result, 30);
		Integer valueResult = (result/30) + (value > 0 ? 1 : 0);
		return valueResult;
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
}