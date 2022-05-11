trigger Territory2Trigger on Territory2 (after update, after insert) {
    if(Territory2Helper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_UPDATE {
                Territory2Helper.checkUpdateFieldsCTV(Trigger.new);
            }
            when AFTER_INSERT {
                Territory2Helper.checkUpdateFieldsCTV(Trigger.new);
            }
        }
    }
}
    