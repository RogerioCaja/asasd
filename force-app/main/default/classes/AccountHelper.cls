public with sharing class AccountHelper {
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

    public static void calloutCTVIntegrationUpdateBefore(List<Account> accountList){
        List<String> accountIdList = new List<String>();
        for(Account acc : accountList){
            accountIdList.add(acc.Id);
        }
        List<ObjectTerritory2Association> terrytoryObjectList = new List<ObjectTerritory2Association>([SELECT Id, Territory2Id, ObjectId  FROM ObjectTerritory2Association WHERE ObjectId =: accountIdList]);
        System.debug('terrytoryObjectList: '+ terrytoryObjectList);
        List<RequestedAssociation> request = new List<RequestedAssociation>();
        for(ObjectTerritory2Association terrytory : terrytoryObjectList){
            request.add(new RequestedAssociation(terrytory));
        }
        System.debug('request: '+ request);
        String payload = JSON.serialize(request);
        for(Account acc : accountList){
            acc.AssosiationTerritories__c = payload;
        }
    }

    public static void calloutCTVIntegrationUpdateAfter(List<Account> accountList){
        Decimal goToIntregration = 0;
        String payload;
        List<String> accountIdList = new List<String>();
        for(Account acc : accountList){
            accountIdList.add(acc.Id);
            payload = acc.AssosiationTerritories__c;
        }
        List<RequestedAssociation> oldrequestedAssociationList = (List<RequestedAssociation>) JSON.deserialize(payload, List<RequestedAssociation>.class);
        System.debug('oldrequestedAssociationList: '+ oldrequestedAssociationList);
        Map<Id,ObjectTerritory2Association> terrytoryObjectMap = new Map<Id,ObjectTerritory2Association>([SELECT Id, Territory2Id, ObjectId  FROM ObjectTerritory2Association WHERE ObjectId =: accountIdList]);
        System.debug('terrytoryObjectMap: '+ terrytoryObjectMap);
        for(RequestedAssociation associantionOld : oldrequestedAssociationList){
            System.debug('associantionOld: '+ associantionOld);
            ObjectTerritory2Association associantionNew = terrytoryObjectMap.get(associantionOld.Id);
            System.debug('associantionNew: '+ associantionNew);
            if(associantionNew == null){
                //CalloutCTVCarteira.processIntegration();
                break;
            }else if(associantionNew.ObjectId != associantionOld.ObjectId){
                //CalloutCTVCarteira.processIntegration();
                break;
            }
        }
    }

    public static void calloutCTVIntegration(List<Account> accountList){
        List<String> accountIdList = new List<String>();
        for(Account acc : accountList){
            accountIdList.add(acc.Id);
        }
        List<ObjectTerritory2Association> terrytoryObject = new List<ObjectTerritory2Association>([SELECT Id, Territory2Id, ObjectId  FROM ObjectTerritory2Association WHERE ObjectId =: accountIdList]);
        //if(!terrytoryObject.isEmpty())
            //CalloutCTVCarteira.processIntegration();
    }

    public class RequestedAssociation { 
        public Id Id;
        public Id Territory2Id;
        public Id ObjectId;
        
        public RequestedAssociation(ObjectTerritory2Association objectAssociation){
            this.Id = objectAssociation.Id;
            this.Territory2Id = objectAssociation.Territory2Id;
            this.ObjectId = objectAssociation.ObjectId;
        }
    }
}
    