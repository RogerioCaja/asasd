public with sharing class RecordTypeAvailableToUser {
    public RecordTypeAvailableToUser() {

    }

    @AuraEnabled(cacheable=true)
    public static String getRecordTypeData(){
        try {
            return [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Order' LIMIT 1]?.Name;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
