global class BatchImplementationCTV  implements Database.Batchable<sObject>, Database.AllowsCallouts{
    String query;
    public static void run(){
        Database.executeBatch(new BatchImplementationCTV(), 1);
    }
    public BatchImplementationCTV() {}

    global Database.QueryLocator start(Database.BatchableContext BC){
        //Na query é realizado o filtro de dados onde só buscará o Territory2
        query = 'SELECT id, DeveloperName, lastmodifieddate, ParentTerritory2.DeveloperName, name, Territory2Type.DeveloperName FROM territory2';
        return Database.getQueryLocator(query);
    } 
    global void execute(Database.BatchableContext BC, List<Territory2> territoryList){
        System.debug('territoryList: '+territoryList);
        CalloutCTVCarteira.sendOrder(territoryList);

    }
    global void finish(Database.BatchableContext BC) {} 
}

