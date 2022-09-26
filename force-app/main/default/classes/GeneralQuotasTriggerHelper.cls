public without sharing class GeneralQuotasTriggerHelper {
    private static Boolean isEnabled;

    static {
        isEnabled = true;
    }

    public static Boolean isTriggerEnabled() {
        return isEnabled;
    }
    
    public static Boolean disableTrigger() {
        return isEnabled = false;
    }

    public static Boolean enableTrigger() {
        return isEnabled = true;
    }

    public static void verifyUsedQuantities(List<GeneralQuotas__c> newRecords, Map<Id, GeneralQuotas__c> newMap) {
        Map<Id, Decimal> distributedQuantitiesByGeneralQuota = new Map<Id, Decimal>();
        for (IndividualQuotas__c individualQuota : [
            SELECT Id,
                   Quantity__c,
                   GeneralQuotas__c
              FROM IndividualQuotas__c
             WHERE GeneralQuotas__c =: newMap.keySet()
        ]) {
            if (distributedQuantitiesByGeneralQuota.containsKey(individualQuota.GeneralQuotas__c)) {
                Decimal updateQuantity = distributedQuantitiesByGeneralQuota.get(individualQuota.GeneralQuotas__c) + individualQuota.Quantity__c;
                distributedQuantitiesByGeneralQuota.put(individualQuota.GeneralQuotas__c, updateQuantity);
            } else {
                distributedQuantitiesByGeneralQuota.put(individualQuota.GeneralQuotas__c, individualQuota.Quantity__c);
            }
        }

        for (GeneralQuotas__c currentQuota : newRecords) {
            System.debug(distributedQuantitiesByGeneralQuota.containsKey(currentQuota.Id));
            if (distributedQuantitiesByGeneralQuota.containsKey(currentQuota.Id)) {
                Decimal individualQuantities = distributedQuantitiesByGeneralQuota.get(currentQuota.Id);
                if (individualQuantities > currentQuota.Quantity__c) {
                    currentQuota.addError('A quantidade não pode ser inferior a já distribuida nas cotas individuais');
                } else {
                    individualQuantities = individualQuantities == null ? 0 : individualQuantities;
                    currentQuota.Balance__c = currentQuota.Quantity__c - individualQuantities;
                }
            }
        }
    }
}