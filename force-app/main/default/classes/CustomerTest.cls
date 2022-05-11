@isTest
    public with sharing class CustomerTest {

        @TestSetup
        public static void makeData() {
        }
        @isTest 
        static void calloutUserIntegration(){
                
            Test.startTest();
            
            Test.stopTest();
        }
    }