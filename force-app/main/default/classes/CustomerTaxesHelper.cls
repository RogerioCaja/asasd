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
        for(CustomerTaxes__c customerTaxes : customerTaxesList){
            String impostBarter;
            String salesOrg;
            if(customerTaxes.Tax__c != null) impostBarter = customerTaxes.Tax__r.ExternalId__c;
            if(customerTaxes.SalesOrg__c != null) salesOrg = customerTaxes.SalesOrg__r.SalesOrganizationCode__c;
            customerTaxes.ExternalId__c = customerTaxes.Account__r.ExternalId__c + '-' + impostBarter + '-' + salesOrg + '-' + customerTaxes.Name__c;
        }
    }
}