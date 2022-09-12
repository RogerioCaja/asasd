public without sharing class ClientTerritoryController {
    @AuraEnabled
    public static ResponseData realizeTransaction(string data){
        ParametersWrapper parameters = (ParametersWrapper)JSON.deserialize(data, ParametersWrapper.class);
        
        ResponseData response = new ResponseData(); 

        switch on parameters.action {
            when 'add' {
                response = actionAdd(parameters, false);
            }
            when 'remove' {
                response = actionRemove(parameters, false);                                             
            }
            when 'addRemove' {
                response = actionAddRemove(parameters);
            }
        }

        return response;
    }

    private static ResponseData actionAdd(ParametersWrapper parameters, Boolean isDoubleAction){
        ResponseData response = new ResponseData();  
        
        Boolean status = true;
        String message = '';

        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name, ParentId FROM Account WHERE ExternalId__c IN: parameters.accountCodes]);
        Set<Id> accountSet = accountMap.keySet().clone();
        if(isDoubleAction){
            for(Id id : accountMap.keySet()){
                if(accountMap.get(id).ParentId != null){
                    accountSet.add(accountMap.get(id).ParentId);
                }
            }
        }
        Map<Id, Territory2> territoryMap =  new Map<Id, Territory2>([SELECT Id, Name FROM Territory2 WHERE Name =: parameters.territoryName[0]]);
        List<ObjectTerritory2Association> objectsAssociationsList = new List<ObjectTerritory2Association>();
        List<ObjectTerritory2Association> objectsAssociationsRemoveList = new List<ObjectTerritory2Association>();
        List<Id> territoryIds = new List<Id>(territoryMap.keySet());
        List<ObjectTerritory2Association> objectList = [SELECT Id, ObjectId FROM ObjectTerritory2Association WHERE ObjectId IN: accountSet];
        Map<Id, ObjectTerritory2Association> accountObjMap = new Map<Id, ObjectTerritory2Association>();
        for(ObjectTerritory2Association obj : objectList){
            accountObjMap.put(obj.ObjectId, obj);
        }
        for(Id id : accountSet){
            ObjectTerritory2Association objectAss;
            if(accountObjMap.containsKey(id)) objectsAssociationsRemoveList.add(accountObjMap.get(id));
                
            objectAss = new ObjectTerritory2Association(ObjectId = id, Territory2Id = parameters.territoryToGo, AssociationCause='Territory2Manual');
            
            objectsAssociationsList.add(objectAss);
        }

        if(objectsAssociationsRemoveList.size() > 0) Database.DeleteResult[] deleteResults = Database.delete(objectsAssociationsRemoveList, true);
        Database.SaveResult[] upsResults = Database.insert(objectsAssociationsList, true);
        for(Database.SaveResult result : upsResults){
            if(!result.isSuccess()){
                status = false;
                message = 'Houve Falha ao inserir as contas';
            } 

        }  
        response.status = status;
        response.message = message;
        return response;  
    }

    private static ResponseData actionRemove(ParametersWrapper parameters, Boolean isDoubleAction){
        ResponseData response = new ResponseData();  
        
        Boolean status = true;
        String message = '';

        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name, ParentId FROM Account WHERE ExternalId__c IN: parameters.accountCodes]);
        Set<Id> accountSet = accountMap.keySet().clone();
        if(isDoubleAction){
            for(Id id : accountMap.keySet()){
                if(accountMap.get(id).ParentId != null){
                    accountSet.add(accountMap.get(id).ParentId);
                }
            }
        }

        Map<Id, Territory2> territoryMap =  new Map<Id, Territory2>([SELECT Id, Name FROM Territory2 WHERE Name IN: parameters.territoryName]);
        List<ObjectTerritory2Association> objectsAssociations = [SELECT Id 
                                                                    FROM ObjectTerritory2Association
                                                                    WHERE ObjectId IN: accountSet
                                                                    AND Territory2Id IN: territoryMap.keySet()];
        
        Database.DeleteResult[] deleteResults = Database.delete(objectsAssociations, true);
        for(Database.DeleteResult result : deleteResults){
            if(!result.isSuccess()){
                status = false;
                message = 'Houve Falha ao deletar as contas';
            } 

        }  
        response.status = status;
        response.message = message;
        return response; 
    }

    private static ResponseData actionAddRemove(ParametersWrapper parameters){
        ResponseData response = new ResponseData();  
        
        Boolean status = true;
        String message = '';
        Savepoint sp = Database.setSavePoint();
        response = actionRemove(parameters, true);

        if(response.status == true){
            response = actionAdd(parameters, true);
            if(response.status == false) Database.rollback(sp); 
        }

        return response;
    }

    public class ResponseData{
        @AuraEnabled public Boolean status;
        @AuraEnabled public String message;
    }

    public class ParametersWrapper{
        public List<String> accountCodes;
        public List<String> territoryName;
        public String territoryToGo;
        public String action;
    }
}
