public without sharing class TechnicalReportHelper {
    public TechnicalReportHelper() {
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
    public static void incrementLineItem(List<TechnicalReport__c> tech){
        List<String> visitIds = new List<String>();
        for(TechnicalReport__c techRep : tech){
           visitIds.add(techRep.VisitPlanning__c);
        }
        List<TechnicalReport__c> technicalReportList = new List<TechnicalReport__c>([SELECT Id, rtrControl__c, VisitPlanning__c FROM TechnicalReport__c WHERE VisitPlanning__c IN: visitIds Order By rtrControl__c DESC LIMIT 1]);
        List<VisitPlanning__c> visitPlanningList = new List<VisitPlanning__c>([SELECT Id, ExternalId__c FROM VisitPlanning__c WHERE Id IN: visitIds]);
        Map<String, String> mapVisitPlanning = new Map<String, String>();
        for(VisitPlanning__c techRepControlVisit : visitPlanningList){
            mapVisitPlanning.put(techRepControlVisit.Id, techRepControlVisit.ExternalId__c);
            System.debug('Map ' + mapVisitPlanning);
        }
        System.debug('Lista ' + visitPlanningList);
        Map<String, TechnicalReport__c> mapTechnicalReport = new Map<String, TechnicalReport__c>();
        for(TechnicalReport__c techRepControl : technicalReportList){
            mapTechnicalReport.put(techRepControl.VisitPlanning__c, techRepControl);
        }
        for(TechnicalReport__c techRepIncrement : tech){
            String visit = mapVisitPlanning.get(techRepIncrement.VisitPlanning__c);
            System.debug('Visti ' + visit);
            if(!mapTechnicalReport.containsKey(techRepIncrement.VisitPlanning__c)){
                techRepIncrement.rtrControl__c = 10;
                System.debug('Teste ' + techRepIncrement.visitplanning__r.ExternalId__c);
                techRepIncrement.ExternalId__c = visit + techRepIncrement.rtrControl__c;
            }
            else {
                TechnicalReport__c techReportNew = mapTechnicalReport.get(techRepIncrement.VisitPlanning__c);
                techRepIncrement.rtrControl__c = (techReportNew.rtrControl__c + 10);
                techRepIncrement.ExternalId__c = visit + techRepIncrement.rtrControl__c;
            }
        }
    }
}