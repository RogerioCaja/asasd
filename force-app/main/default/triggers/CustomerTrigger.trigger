trigger CustomerTrigger on Customer (after insert, after delete) {
    if(CustomerHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_DELETE {
                CustomerHelper.calloutCTVIntegration();
            }
            when AFTER_INSERT {
                CustomerHelper.calloutCTVIntegration();
            }
        }
    }
}