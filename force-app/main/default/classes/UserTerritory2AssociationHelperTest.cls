@isTest
    public with sharing class UserTerritory2AssociationHelperTest {

    
        @isTest 
        static void userTerritory2Test(){
            List<UserTerritory2Association> userTerritoryList = new List<UserTerritory2Association>([SELECT Territory2Id  FROM UserTerritory2Association WHERE RoleInTerritory2 =:'Sales / Marketing Manager' LIMIT 1]);
            

            Test.startTest();
                UserTerritory2AssociationHelper.sendTerritoryCTV(userTerritoryList);
            Test.stopTest();
        }
    }
    