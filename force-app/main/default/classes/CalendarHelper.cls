public with sharing class CalendarHelper {
    public CalendarHelper() {

    }
  
private static Boolean isEnabled;

static{
    isEnabled = true;
}

public static Boolean isTriggerEnabled(){
    return isEnabled;
}

public static Boolean disableTrigger(){
    return isEnabled = false;
}

public static Boolean enableTrigger(){
    return isEnabled = true;
}


public static void createCalendarEvent(List<VisitPlanning__c> visitPlanningList) {
    //List<SObject_Visit> visitList = new List<SObject_Visit>();
    List<Event> eventList = new List<Event>();
    


    for(VisitPlanning__c visitPlanning : visitPlanningList){
        //if()//DateTime.newInstance(withDate.date(), withTime.time())
        Long dt1Long = DateTime.newInstance(visitPlanning.InitialDate__c, visitPlanning.StartTime__c).getTime();
        System.debug('dt1Long ' + dt1Long);
        Long dt2Long = DateTime.newInstance(visitPlanning.EndDate__c, visitPlanning.EndTime__c).getTime();
        System.debug('dt2Long ' + dt2Long);
        Long milliseconds = dt2Long - dt1Long;
        System.debug('milliseconds ' + milliseconds);
        Long seconds = milliseconds / 1000;
        System.debug('seconds ' + seconds);
        Long minutes = seconds / 60;
        System.debug('minutes ' + minutes);
        
        Event event = new Event(Subject = 'Meeting', IsReminderSet = true, ReminderDateTime = DateTime.newInstance(visitPlanning.InitialDate__c, visitPlanning.StartTime__c).addMinutes(-15), DurationInMinutes = integer.valueOf(minutes), OwnerId =  visitPlanning.VisitSeller__c, StartDateTime = DateTime.newInstance(visitPlanning.InitialDate__c, visitPlanning.StartTime__c), EndDateTime = DateTime.newInstance(visitPlanning.EndDate__c, visitPlanning.EndTime__c), Description = visitPlanning.Objetivo__c, WhatId = visitPlanning.MainBP__c);
        eventList.add(event);
    }

    upsert eventList;
}

public static void updateCalendarEvent(Map<Id, VisitPlanning__c> visitPlanningMap) {
    //List<SObject_Visit> visitList = new List<SObject_Visit>();
    
    List<String> visitId = new List<String>();
    
    

    for(VisitPlanning__c visitPlanning : visitPlanningMap.values()){
        //if()//DateTime.newInstance(withDate.date(), withTime.time())
        visitId.add(visitPlanning.Id);
    }

    
    List<Event> eventList = new List<Event>([SELECT Id, WhatId, Subject, DurationInMinutes, OwnerId, StartDateTime,ReminderDateTime, IsReminderSet,EndDateTime, Description FROM Event WHERE WhatId =: visitId]);

    for(Event event : eventList){
        VisitPlanning__c visitPlanning = visitPlanningMap.get(event.WhatId);

        Long dt1Long = DateTime.newInstance(visitPlanning.InitialDate__c, visitPlanning.StartTime__c).getTime();
        System.debug('dt1Long ' + dt1Long);
        Long dt2Long = DateTime.newInstance(visitPlanning.EndDate__c, visitPlanning.EndTime__c).getTime();
        System.debug('dt2Long ' + dt2Long);
        Long milliseconds = dt2Long - dt1Long;
        System.debug('milliseconds ' + milliseconds);
        Long seconds = milliseconds / 1000;
        System.debug('seconds ' + seconds);
        Long minutes = seconds / 60;
        System.debug('minutes ' + minutes);
        event.DurationInMinutes = integer.valueOf(minutes);
        event.OwnerId = visitPlanning.VisitSeller__c;
        event.StartDateTime = DateTime.newInstance(visitPlanning.InitialDate__c, visitPlanning.StartTime__c);
        event.EndDateTime = DateTime.newInstance(visitPlanning.EndDate__c, visitPlanning.EndTime__c);
        event.IsReminderSet = true;
        event.ReminderDateTime = DateTime.newInstance(visitPlanning.InitialDate__c, visitPlanning.StartTime__c).addMinutes(-15);
        event.Description = visitPlanning.Objetivo__c;
        event.WhatId = visitPlanning.MainBP__c;
    }
    upsert eventList;
}
}
