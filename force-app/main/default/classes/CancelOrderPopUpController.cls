public without sharing class CancelOrderPopUpController {

    @AuraEnabled(cacheable=true)
    public static List<CancelReasonWrapper> getCancelReasons(){
        try {
            List<CancelReason__c> cancelReasonList = [SELECT Id, Name, DescriptionMandatory__c FROM CancelReason__c WHERE IsActive__c = true];
            List<CancelReasonWrapper> responseList = new List<CancelReasonWrapper>();

            for(CancelReason__c reason : cancelReasonList){
                responseList.add(new CancelReasonWrapper(reason.Id, reason.Name, reason.DescriptionMandatory__c));
            }

            return responseList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string saveOrder(String data){
        Savepoint sp = Database.setSavepoint();
        try {
            CancelOrderWrapper dataToSave = (CancelOrderWrapper) JSON.deserialize(data, CancelOrderWrapper.class);

            Order order = [SELECT Id, CancelReason__c, OthersDescription__c FROM Order WHERE Id =: dataToSave.recordId LIMIT 1];
            order.CancelReason__c = dataToSave.reasonId;
            order.OthersDescription__c = dataToSave.description;
            
            Database.SaveResult upsResult = Database.update(order, Order.Id);

            if(upsResult.isSuccess()){
                return 'Pedido cancelado com sucesso!';
            }else{
                return 'Pedido não pode ser cancelado.';
            }

        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class CancelReasonWrapper{
        @AuraEnabled 
        public String id;
        @AuraEnabled 
        public String cancelName;
        @AuraEnabled 
        public Boolean shouldHasDescription;

        public CancelReasonWrapper(String id, String cancelName, Boolean shouldHasDescription){
            this.id = id;
            this.cancelName = cancelName;
            this.shouldHasDescription = shouldHasDescription;
        }
    }

    public class CancelOrderWrapper{
        @AuraEnabled 
        public String recordId;
        @AuraEnabled 
        public String reasonId;
        @AuraEnabled 
        public String description;
    }
}