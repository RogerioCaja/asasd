public with sharing class CustomAccountLookupController {
    @AuraEnabled
    public static List<SObject> fetchAccountRecords(String searchString, Integer offSet, String salesOrg) {
        try {
			if(offSet == null){
				offSet = 0;
			}

			String query = '';

            List<SObject> recordsData = new List<SObject>();
			String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
			Boolean bpAccount = salesOrg != null;
			if (profileName == 'Balcão' || bpAccount) {
				query = 'SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Supplier__c, Phone, BillingCity, BillingState, Parent.Name, StateRegistration__c FROM Account WHERE Status__c = \'' + 'Ativo' + '\' AND ExternalId__c LIKE \'' + '0001' + '%\' AND (Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Name LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\')' +
				(bpAccount ? ' AND Supplier__c =: bpAccount' : '') +
				' ORDER BY Name' +
				(bpAccount ? ' LIMIT 50' : ' LIMIT 100') + 
				' OFFSET :offSet';
			} else {
				Set<Id> relatedAccounts = OrderScreenController.getTerritoryAccounts();
				query = 'SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Supplier__c, Phone, BillingCity, BillingState, Parent.Name, StateRegistration__c FROM Account WHERE Status__c = \'' + 'Ativo' + '\' AND Id IN: relatedAccounts AND ExternalId__c LIKE \'' + '0001' + '%\' AND (Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Name LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\')' +
				' ORDER BY Name' +
				' LIMIT 100' + 
				' OFFSET :offSet';
			}
            
			Set<String> accountIds = new Set<String>();
			List<SObject> accountResult = Database.query(query);
	        for (SObject s : accountResult) {
				accountIds.add((String) s.get('Id'));
	        }

			Set<String> salesOrgAccounts = new Set<String>();
			if (bpAccount) {
				for (Company__c accountCompany : [
					SELECT Id, Conta__c
					  FROM Company__c
					 WHERE Conta__c IN: accountIds
					   AND SalesOrg__c =: salesOrg
				]) {
					salesOrgAccounts.add(accountCompany.Conta__c);
				}
			}

			for (SObject s : accountResult) {
				if (bpAccount) {
					if (salesOrgAccounts.contains((String) s.get('Id'))) {
						recordsData.add(s);
					}
				} else {
					recordsData.add(s);
				}
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
	public static Integer getNumberOfAccounts(String searchString, String salesOrg){
		String query = '';
		String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
		Boolean bpAccount = salesOrg != null;
		
		if (bpAccount) {
			query = 'SELECT Id FROM Account WHERE ' + (bpAccount ? ' Supplier__c =: bpAccount' : '') + ' AND Status__c = \'' + 'Ativo' + '\' AND ExternalId__c LIKE \'' + '0001' + '%\' AND (Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Name LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\')';

			Set<String> accountIds = new Set<String>();
			List<SObject> accountResult = Database.query(query);
	        for (SObject s : accountResult) {
				accountIds.add((String) s.get('Id'));
	        }

			Set<String> salesOrgAccounts = new Set<String>();
			for (Company__c accountCompany : [
				SELECT Id, Conta__c
				  FROM Company__c
				 WHERE Conta__c IN: accountIds
				   AND SalesOrg__c =: salesOrg
			]) {
				salesOrgAccounts.add(accountCompany.Conta__c);
			}

			Integer accountNumber = 0;
			for (SObject s : accountResult) {
				if (salesOrgAccounts.contains((String) s.get('Id'))) {
					accountNumber++;
				}
			}

			Decimal value =  Math.mod(accountNumber, 50);
			Integer valueResult = (accountNumber/50) + (value > 0 ? 1 : 0);
			return valueResult;
		} else {
			if (profileName == 'Balcão') {
				query = 'SELECT COUNT() FROM Account WHERE Status__c = \'' + 'Ativo' + '\' AND ExternalId__c LIKE \'' + '0001' + '%\' AND (Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Name LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\')';           
			} else {
				Set<Id> relatedAccounts = OrderScreenController.getTerritoryAccounts();
				query = 'SELECT COUNT() FROM Account WHERE Status__c = \'' + 'Ativo' + '\' AND Id IN: relatedAccounts AND ExternalId__c LIKE \'' + '0001' + '%\' AND (Name LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Name LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR CPF__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\' OR Company__c LIKE \'' + String.escapeSingleQuotes(searchString.trim()) + '%\')';           
			}
			Integer result = Database.countQuery(query);
			Decimal value =  Math.mod(result, 100);
			Integer valueResult = (result/100) + (value > 0 ? 1 : 0);
			return valueResult;
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
}