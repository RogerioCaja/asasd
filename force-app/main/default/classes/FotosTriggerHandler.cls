public without sharing class FotosTriggerHandler {
    
    List<Fotos__c> oldRecords {get; set;} // Trigger.old 
        List<Fotos__c> newRecords {get; set;} // Trigger.new
        Map<Id, Fotos__c> oldMap {get; set;} // Trigger.oldMap
        Map<Id, Fotos__c> newMap {get; set;} // Trigger.newMap
    
        public FotosTriggerHandler(List<Fotos__c> oldRecords, List<Fotos__c> newRecords, Map<Id, Fotos__c> oldMap, Map<Id, Fotos__c> newMap ) {
            this.oldRecords = oldRecords;
            this.newRecords = newRecords;
            this.oldMap = oldMap;
            this.newMap = newMap;
        }
    
        public void OnBeforeInsert(){
            FotosHelper.incrementItem(this.newRecords);
        }
        
        public void OnAfterInsert(){
        
        }
        
        public void OnBeforeUpdate(){
    
        }
        
        public void OnAfterUpdate(){
        }
        
        public void OnBeforeDelete(){}
        
        public void OnAfterDelete(){}
        
        public void OnUndelete(){}

}