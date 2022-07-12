trigger AccountTrigger on Account (after insert, after update, before update, before delete) {
    if(AccountHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_DELETE {
                AccountHelper.calloutCTVIntegration(Trigger.old);
            }
            when AFTER_INSERT {
                AccountHelper.calloutCTVIntegration(Trigger.new);
            }
            when AFTER_UPDATE {
                AccountHelper.calloutCTVIntegrationUpdateAfter(Trigger.new);
            }
            when BEFORE_UPDATE {
                AccountHelper.calloutCTVIntegrationUpdateBefore(Trigger.new);
            }
        }
    }
}