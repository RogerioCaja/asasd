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

    public static void fillBalanceField(List<GeneralQuotas__c> newRecords) {
        for (GeneralQuotas__c currentQuota : newRecords) {
            currentQuota.Balance__c = currentQuota.Quantity__c;
        }
    }

    public static void verifyDuplicateGeneralQuota(List<GeneralQuotas__c> newRecords){
        Set<String> keysQuotas = new Set<String>();
        Map<String, GeneralQuotas__c> existsRecordsMap = new Map<String, GeneralQuotas__c>();

        for(GeneralQuotas__c generalQuotas : newRecords){
            keysQuotas.add(generalQuotas.Name);
        }

        List<GeneralQuotas__c> generalList = [SELECT Id, Name, Quantity__c, Balance__c, Consumed__c FROM GeneralQuotas__c WHERE Name IN: keysQuotas];
        
        for(GeneralQuotas__c generalQuotas : generalList){
            existsRecordsMap.put(generalQuotas.Name, generalQuotas);
        }

        for(GeneralQuotas__c key : newRecords){
            if(existsRecordsMap.containsKey(key.Name)){
                key.addError('Existe uma Cota Geral já cadastrada para esta Cultivar e Safra. Por favor, altere a Cota Geral existente ' + key.Name + '.');
            }
        }
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
            } else {
                currentQuota.Balance__c = currentQuota.Quantity__c;
            }
        }
    }
}