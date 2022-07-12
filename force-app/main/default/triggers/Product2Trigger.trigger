trigger Product2Trigger on Product2 (after insert) {
    if (Product2Helper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_INSERT {
                Product2Helper.createStandardEntries(Trigger.new);
            }
        }
    }
}