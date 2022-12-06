@isTest
public with sharing class BatchDeleteIntegrationLogsTest {
    public BatchDeleteIntegrationLogsTest() {}

    @TestSetup
    public static void testSetup() {
        TimeOfMonths__c time = new TimeOfMonths__c(
            Name = 'Log de Integrações',
            NumberOfMonths__c = '3'
        );

        INSERT time;
            
        //Creating integration log
        IntegrationLog.createLog('Teste', 'OUT', '', 'Integração para Batch', true);

            
    }
    @isTest
    public static void testMethod1(){
        IntegrationLog__c log = [SELECT Id FROM IntegrationLog__c LIMIT 1];
        Datetime lastMonths = Datetime.now().addMonths(-5);
        Test.setCreatedDate(log.Id, lastMonths);

        Test.startTest();
        BatchDeleteIntegrationLogs.run();
        Test.stopTest();
    }
    @isTest
    public static void testQueryIntegrationSchedulable(){
        BatchDeleteIntegrationLogs.scheduleBatch();
    }
}