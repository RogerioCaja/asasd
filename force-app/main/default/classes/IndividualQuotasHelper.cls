public without sharing class IndividualQuotasHelper {
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

    public static void changeGeneralValues(List<IndividualQuotas__c> newRecords, Map<Id, IndividualQuotas__c> oldMap) {
        Set<Id> generalQuotasIds = new Set<Id>();
        for (IndividualQuotas__c individualQuotes : newRecords) {
            generalQuotasIds.add(individualQuotes.GeneralQuotas__c);
        }

        Map<Id, GeneralQuotas__c> generalQuotasById = new Map<Id, GeneralQuotas__c>();
        for (GeneralQuotas__c generalQuota : [
            SELECT Id,
                   Balance__c,
                   Consumed__c,
                   Quantity__c
              FROM GeneralQuotas__c
             WHERE Id IN: generalQuotasIds
        ]) {
            generalQuotasById.put(generalQuota.Id, generalQuota);
        }

        Boolean quantityError = false;
        for (IndividualQuotas__c individualQuotes : newRecords) {
            individualQuotes.Balance__c = individualQuotes.Quantity__c - (individualQuotes.Consumed__c == null ? 0 : individualQuotes.Consumed__c);
            GeneralQuotas__c generalQuota = generalQuotasById.get(individualQuotes.GeneralQuotas__c);
            
            if (oldMap != null) {
                IndividualQuotas__c oldValues = oldMap.get(individualQuotes.Id);
                generalQuota.Consumed__c = (generalQuota.Consumed__c == null ? 0 : generalQuota.Consumed__c) + individualQuotes.Quantity__c - oldValues.Quantity__c;
                generalQuota.Balance__c = generalQuota.Balance__c - individualQuotes.Quantity__c + oldValues.Quantity__c;

                if (generalQuota.Consumed__c < 0 || generalQuota.Balance__c < 0) {
                    individualQuotes.addError('As quantidades da cota geral precisam ser respeitadas');
                    quantityError = true;
                }
            } else {
                generalQuota.Consumed__c = (generalQuota.Consumed__c == null ? 0 : generalQuota.Consumed__c) + individualQuotes.Quantity__c;
                generalQuota.Balance__c = generalQuota.Balance__c - individualQuotes.Quantity__c;
            }
            generalQuotasById.put(generalQuota.Id, generalQuota);
        }

        if (!quantityError) {
            GeneralQuotasTriggerHelper.disableTrigger();
            update generalQuotasById.values();
            GeneralQuotasTriggerHelper.enableTrigger();
        }
    }
}