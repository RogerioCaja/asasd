trigger UserTrigger on User (after insert, after delete) {
    if(UserHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_DELETE {
                UserHelper.calloutCTVIntegration();
            }
            when AFTER_INSERT {
                UserHelper.calloutCTVIntegration();
            }
        }
    }
}