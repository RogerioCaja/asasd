trigger AccountTrigger on Account (after insert, after delete) {
    if(AccountHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_DELETE {
                AccountHelper.calloutCTVIntegration();
            }
            when AFTER_INSERT {
                AccountHelper.calloutCTVIntegration();
            }
        }
    }
}