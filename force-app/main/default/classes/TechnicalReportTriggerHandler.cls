public without sharing class TechnicalReportTriggerHandler {
    /*
        List<TechnicalReport__c> oldRecords {get; set;} // Trigger.old 
        List<TechnicalReport__c> newRecords {get; set;} // Trigger.new
        Map<Id, TechnicalReport__c> oldMap {get; set;} // Trigger.oldMap
        Map<Id, TechnicalReport__c> newMap {get; set;} // Trigger.newMap
    
        public TechnicalReportTriggerHandler(List<TechnicalReport__c> oldRecords, List<TechnicalReport__c> newRecords, Map<Id, TechnicalReport__c> oldMap, Map<Id, TechnicalReport__c> newMap ) {
            this.oldRecords = oldRecords;
            this.newRecords = newRecords;
            this.oldMap = oldMap;
            this.newMap = newMap;
        }
    
        public void OnBeforeInsert(){
            TechnicalReportHelper.incrementLineItem(this.newRecords);
        }
        
        public void OnAfterInsert(){
            TechnicalReportHelper.callVisitsIntegration(this.newRecords);
        }
        
        public void OnBeforeUpdate(){
    
        }
        
        public void OnAfterUpdate(){
            TechnicalReportHelper.callVisitsIntegration(this.newRecords);
        }
        */
        // public void OnBeforeDelete(){}
        
        // public void OnAfterDelete(){}
        
        // public void OnUndelete(){}

    }