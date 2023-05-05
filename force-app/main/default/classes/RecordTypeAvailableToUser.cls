public with sharing class RecordTypeAvailableToUser {
    @AuraEnabled(cacheable=true)
    public static String getRecordTypeData(){
        try {
            for(RecordTypeInfo info: Order.SObjectType.getDescribe().getRecordTypeInfos()){
                if (info.isAvailable()) {
                    return info.getName();
                }
            
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
