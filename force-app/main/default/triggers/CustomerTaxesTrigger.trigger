trigger CustomerTaxesTrigger on CustomerTaxes__c (before insert) {

    
    if (CustomerTaxesHelper.isTriggerEnabled()){
        switch on Trigger.operationType {
            // when AFTER_INSERT {
                
            // }
            when BEFORE_INSERT{
                CustomerTaxesHelper.setExternalId(Trigger.new);
            }
            // when AFTER_UPDATE{
            //     //handler.OnAfterUpdate();
            // }
            // when BEFORE_UPDATE{
            //     //handler.OnBeforeUpdate();
            // }
            // when AFTER_DELETE{
            //     //BEFORE DELETE Method
            // }
            // when BEFORE_DELETE{
            //     //BEFORE DELETE Method
            // }
        }
    }
}