global class BatchDeleteIntegrationLogs implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts{
    
    global BatchDeleteIntegrationLogs() {}

    public static void run(){
        Database.executeBatch(new BatchDeleteIntegrationLogs(), 200);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Decimal numberMonths = Decimal.valueOf(TimeOfMonths__c.getInstance('Log de Integrações').numberMonths__c);
        return Database.getQueryLocator('SELECT id FROM IntegrationLog__c WHERE CreatedDate < LAST_N_MONTHS:numberMonths ORDER BY CreatedDate DESC');
    }

    global void execute(Database.BatchableContext BC, List<IntegrationLog__c> scope) {
        BatchDeleteIntegrationLogs.executeBatch(scope);
    }

    global void finish(Database.BatchableContext BC) {}

    global static void executeBatch(List<IntegrationLog__c> scope) {
        delete scope;
    }

    global void execute(SchedulableContext sc) {
        BatchDeleteIntegrationLogs.run();
    }

    global static void scheduleBatch() {
        System.schedule((Test.isRunningTest() ? 'Batch Delete Integration Logs Test' : 'Batch Delete Integration Log'), '0 0 0 1 * ?', new BatchDeleteIntegrationLogs());
    }
}