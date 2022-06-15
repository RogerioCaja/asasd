@isTest
    public with sharing class Territory2Test {

    
        @isTest 
        static void calloutCTVIntegration(){
            Territory2Type terrModel = [SELECT Id FROM Territory2Type LIMIT 1];
            Territory2Model model = [SELECT Id FROM Territory2Model LIMIT 1];
            Territory2 objTerr = new Territory2(); 
                objTerr.Description = 'Description__c';
                objTerr.Name = 'Territory Test';
                objTerr.DeveloperName = 'TerritoryTestName';
                objTerr.Territory2TypeId = terrModel.Id;
                objTerr.Territory2ModelId = model.Id;

            Test.startTest();
                insert objTerr;
                objTerr.Description = 'descricao test';
                update objTerr;
            Test.stopTest();
        }
    }
    