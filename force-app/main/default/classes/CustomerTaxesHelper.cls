public with sharing class CustomerTaxesHelper {
    private static Boolean isEnabled;

    static{
        isEnabled = true;
    }

    public static Boolean isTriggerEnabled(){
        return isEnabled;
    }
    
    public static Boolean disableTrigger(){
        return isEnabled = false;
    }

    public static Boolean enableTrigger(){
        return isEnabled = true;
    }

    public static void setExternalId(List<CustomerTaxes__c> customerTaxesList){
        List<String> accountIdList = new List<String>();
        List<String> taxIdList = new List<String>();
        List<String> salesOrgIdList = new List<String>();
        
        for(CustomerTaxes__c customerTaxes : customerTaxesList){
            accountIdList.add(customerTaxes.Account__c);
            taxIdList.add(customerTaxes.Tax__c);
            salesOrgIdList.add(customerTaxes.SalesOrg__c);
        }

        Map<String, String> accountIdMap = new Map<String, String>();
        Map<String, String> taxIdMap = new Map<String, String>();
        Map<String, String> salesOrgIdMap = new Map<String, String>();
        Map<String, String> customerMap = new Map<String, String>();

        for(Account acc : [SELECT Id, ExternalId__c FROM Account WHERE Id =: accountIdList]){
            accountIdMap.put(acc.Id, acc.ExternalId__c);
        }

        for(SalesOrg__c org : [SELECT Id, SalesOrganizationCode__c FROM SalesOrg__c WHERE Id =: salesOrgIdList]){
            salesOrgIdMap.put(org.Id, org.SalesOrganizationCode__c);
        }

        for(BarterTaxes__c bar : [SELECT Id, ExternalId__c FROM BarterTaxes__c WHERE Id =: taxIdList]){
            taxIdMap.put(bar.Id, bar.ExternalId__c);
        }
        List<String> checkExternalId = new List<String>();
        for(CustomerTaxes__c customerTaxes : customerTaxesList){
            System.debug('customerTaxes' + customerTaxes);
            String impostBarter;
            String salesOrg;
            String accoun;
            if(accountIdMap.containsKey(customerTaxes.Account__c)) accoun = accountIdMap.get(customerTaxes.Account__c);
            if(salesOrgIdMap.containsKey(customerTaxes.SalesOrg__c)) salesOrg = salesOrgIdMap.get(customerTaxes.SalesOrg__c);
            if(taxIdMap.containsKey(customerTaxes.Tax__c)) impostBarter = taxIdMap.get(customerTaxes.Tax__c);
            customerTaxes.ExternalId__c =accoun + '-' + impostBarter + '-' + salesOrg + '-' + customerTaxes.Name__c;
        	System.debug('customerTaxes.ExternalId__c' + customerTaxes.ExternalId__c);
            checkExternalId.add(customerTaxes.ExternalId__c);
        }
        for(CustomerTaxes__c customer : [SELECT Id, Name, ExternalId__c FROM CustomerTaxes__c WHERE ExternalId__c =: checkExternalId]){
            customerMap.put(customer.ExternalId__c, customer.Name);
        }
        for(CustomerTaxes__c customerTaxes : customerTaxesList){
            if(customerMap.containsKey(customerTaxes.ExternalId__c))customerTaxes.addError('Registro apresenta mesmo dados de outro registro: ' + customerMap.get(customerTaxes.ExternalId__c));
        }
    }
}