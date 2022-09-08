public with sharing class CalendarHelper {
    public CalendarHelper() {
            //
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
            Event event = new Event(OwnerId =  visitPlanning.VisitSeller__c, StartDateTime = DateTime.newInstance(visitPlanning.InitialDate__c.date(), visitPlanning.StartTime__c.time()), 	EndDateTime = visitPlanning.EndDate__c);
            eventList.add(event);
        }

        upsert eventList;
    }
}
