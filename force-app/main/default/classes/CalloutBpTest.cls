@isTest
    public with sharing class CalloutBpTest {
    
    
        @isTest
        static void calloutBpSuccess(){

            Test.setMock(HttpCalloutMock.class, new CalloutBPMock(true));
            Test.startTest();
            CalloutBP.processIntegration();
            Test.stopTest();
        } 
    }