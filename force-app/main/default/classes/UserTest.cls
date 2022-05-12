@isTest
    public with sharing class UserTest {

        @TestSetup
        public static void makeData() {
        }
        @isTest 
        static void calloutUserIntegration(){
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='tetedogas@testorg.com');
                
            Test.startTest();
                insert u;
            Test.stopTest();
        }
    }
    