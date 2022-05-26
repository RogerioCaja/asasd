@isTest
    public with sharing class BatchCTVSchedulableTest {
        @isTest
        public static void testBatchDeliveryNotificationSchedulable(){
            String sch = '0 0 * * * ?';
            Test.startTest();
            system.schedule('Delivery Notification Schedule Job Test Class', sch, new BatchCTVSchedulable());
            Test.stopTest();
        }
    }