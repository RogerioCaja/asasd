public with sharing class CalendarTriggerHandler {
    List<VisitPlanning__c> oldRecords {get; set;} // Trigger.old 
        List<VisitPlanning__c> newRecords {get; set;} // Trigger.new
        Map<Id, VisitPlanning__c> oldMap {get; set;} // Trigger.oldMap
        Map<Id, VisitPlanning__c> newMap {get; set;} // Trigger.newMap

    public CalendarTriggerHandler(List<VisitPlanning__c> oldRecords, List<VisitPlanning__c> newRecords, Map<Id, VisitPlanning__c> oldMap, Map<Id, VisitPlanning__c> newMap) {
            this.oldRecords = oldRecords;
            this.newRecords = newRecords;
            this.oldMap = oldMap;
            this.newMap = newMap;
    }

    public void OnBeforeInsert(){
        CalendarHelper.createCalendarEvent(this.newRecords);

    }
    
    public void OnAfterInsert(){
        
    }
    
    public void OnBeforeUpdate(){
    }
    
    public void OnAfterUpdate(){
        calendarHelper.updateCalendarEvent(this.newMap);
    }
    
    public void OnBeforeDelete(){}
    
    public void OnAfterDelete(){}
    
    public void OnUndelete(){}
}