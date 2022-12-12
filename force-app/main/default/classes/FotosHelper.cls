public without sharing class FotosHelper {
    
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
    
    public static void incrementItem(List<Fotos__c> fotosList){

        List<string> rtrList = new List<String>();

        for(Fotos__c fot: fotosList){
            rtrList.add(fot.RTR__c);
        }

        List<Fotos__c> fotsList = new List<Fotos__c>([SELECT Id, FotoControl__c, RTR__c FROM Fotos__c WHERE RTR__c IN: rtrList Order By FotoControl__c DESC LIMIT 1]);
        List<TechnicalReport__c> techReportList = new List<TechnicalReport__c>([SELECT Id, ExternalId__c FROM TechnicalReport__c WHERE Id IN: rtrList]);

        Map<String, String> mapTechnicalReport = new Map<String, String>();

        for(TechnicalReport__c fotosControl:  techReportList){
            mapTechnicalReport.put(fotosControl.Id, fotosControl.ExternalId__c);
        }

        Map<String, Fotos__c> fotosMap = new Map <String, Fotos__c>();

        for(Fotos__c fotosIncrement: fotsList){
            fotosMap.put(fotosIncrement.RTR__c, fotosIncrement);
        }

        for(Fotos__c fotosIncrement: fotosList){
            String rtr = mapTechnicalReport.get(fotosIncrement.RTR__c);
            
            if(!fotosMap.containsKey(fotosIncrement.RTR__c)){
                fotosIncrement.fotosControl__c = 10;
                fotosIncrement.ExternalId__c = rtr+fotosIncrement.fotosControl__c;
            }
            else{
                Fotos__c fotosNew = fotosMap.get(fotosIncrement.RTR__c);
                fotosIncrement.fotosControl__c = (fotosNew.fotosControl__c + 10);
                fotosIncrement.ExternalId__c = rtr + fotosIncrement.fotosControl__c;
            }
        }
    }
}
