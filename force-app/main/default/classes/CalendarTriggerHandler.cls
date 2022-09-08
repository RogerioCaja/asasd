public with sharing class CalendarTriggerHandler {

        List<Event> oldRecords {get; set;} // Trigger.old 
        List<Event> newRecords {get; set;} // Trigger.new
        Map<Id, Event> oldMap {get; set;} // Trigger.oldMap
        Map<Id, Event> newMap {get; set;} // Trigger.newMap

    public CalendarTriggerHandler(List<Event> oldRecords, List<Event> newRecords, Map<Id, Event> oldMap, Map<Id, Event> newMap) {
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
