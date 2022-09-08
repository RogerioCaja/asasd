public with sharing class CalendarTriggerHandler {

        List<Event> oldRecords {get; set;} // Trigger.old 
        List<Event> newRecords {get; set;} // Trigger.new
        Map<Id, Event> oldMap {get; set;} // Trigger.oldMap
        Map<Id, Event> newMap {get; set;} // Trigger.newMap

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
        //calendarHelper.createCalendarEvent(this.newRecords);
    }
    
    public void OnBeforeUpdate(){
    }
    
    public void OnAfterUpdate(){
    
    }
    
    public void OnBeforeDelete(){}
    
    public void OnAfterDelete(){}
    
    public void OnUndelete(){}
    
}
