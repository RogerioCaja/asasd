global class BatchImplementationCTV  implements Database.Batchable<sObject>, Database.AllowsCallouts{
    String query;
    public static void run(){
        Database.executeBatch(new BatchImplementationCTV(), 5);
    }
    public BatchImplementationCTV() {}

    global Database.QueryLocator start(Database.BatchableContext BC){
        //Na query é realizado o filtro de dados onde só buscará o Territory2
        query = 'SELECT id, DeveloperName, LastModifiedDate, ParentTerritory2.DeveloperName, name, Territory2Type.DeveloperName FROM territory2';
        return Database.getQueryLocator(query);
    } 
    global void execute(Database.BatchableContext BC, List<Territory2> territoryList){
        List<String> territoryIdList = new List<String>();
        for(Territory2 territory : territoryList){
            territoryIdList.add(territory.id);
        }
        Map<String,UserTerritory2Association> userTerritoryMap = new Map<String,UserTerritory2Association>(); 
        List<UserTerritory2Association> territoryUserList  = new List<UserTerritory2Association>([SELECT id, Territory2Id, User.CodigoSAP__c, LastModifiedDate FROM UserTerritory2Association WHERE Territory2Id =: territoryIdList]);
        for(UserTerritory2Association territory : territoryUserList){
            if(territory.LastModifiedDate >= System.now().addMinutes(-30)){
                userTerritoryMap.put(territory.Territory2Id,territory);
            }
        }
        Map<String,ObjectTerritory2Association> objectTerritoryMap = new Map<String,ObjectTerritory2Association>(); 
        List<ObjectTerritory2Association> terrytoryObjectList = new List<ObjectTerritory2Association>([SELECT Id, Territory2Id, ObjectId, LastModifiedDate  FROM ObjectTerritory2Association WHERE Territory2Id =: territoryIdList All ROWS]);
        for(ObjectTerritory2Association territory : terrytoryObjectList){
            if(territory.LastModifiedDate >= System.now().addMinutes(-30)){
                objectTerritoryMap.put(territory.Territory2Id,territory);
            }
        }
        List<Territory2> territoryToSendList = new List<Territory2>();
        for(Territory2 territory : territoryList){
            if(objectTerritoryMap.containsKey(territory.Id) || userTerritoryMap.containsKey(territory.Id) || territory.LastModifiedDate >= System.now().addMinutes(-30)){
                territoryToSendList.add(territory);
            }
        }
        System.debug('territoryList: '+territoryList);
        if(!territoryToSendList.isEmpty()){
            if(!Test.isRunningTest()){
                System.debug('territoryToSendList: '+territoryToSendList);
                CalloutCTVCarteira.sendOrder(territoryToSendList);
            }
        }
    }
    global void finish(Database.BatchableContext BC) {} 
}

