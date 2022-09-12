@isTest
public with sharing class ClientTerritoryControllerTest {
    public ClientTerritoryControllerTest() {

    }

    @TestSetup
    public static void makeData(){
        List<Account> accountList = new List<Account>();
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert parentAccount;
    }

    public List<String> accountCodes;
    public List<String> territoryName;
    public String territoryToGo;
    public String action;
    @isTest
    public static void testLogic(){
        Id terr;
        Id objAss;
        Id userAss;
        Id terr2;
        String accountExternal = [SELECT Id, ExternalId__c FROM Account WHERE Name = 'Parent Account' LIMIT 1].ExternalId__c;
        System.runAs(new User(Id = UserInfo.getUserId())){
            terr = createTerritory();
            objAss = createObjectAss(terr);
            userAss = createUserAss(terr);
            terr2 = createTerritory2();
            
            ClientTerritoryController.realizeTransaction('{"accountCodes":["'+ accountExternal +'"], "territoryName": ["'+ terr + '"], "territoryToGo": "'+terr2+'", "action": "add"}');
            ClientTerritoryController.realizeTransaction('{"accountCodes":["'+ accountExternal +'"], "territoryName": ["'+ terr + '"], "territoryToGo": null, "action": "remove"}');
        }
    }

    @isTest
    public static void addRemoveLogicTest(){
        Id terr;
        Id objAss;
        Id userAss;
        Id terr2;
        String accountExternal = [SELECT Id, ExternalId__c FROM Account WHERE Name = 'Parent Account' LIMIT 1].ExternalId__c;
        System.runAs(new User(Id = UserInfo.getUserId())){
            terr = createTerritory();
            objAss = createObjectAss(terr);
            userAss = createUserAss(terr);
            terr2 = createTerritory2();
            createObjectAss2(terr2);
            
            ClientTerritoryController.realizeTransaction('{"accountCodes":["'+ accountExternal +'"], "territoryName": ["'+ terr + '"], "territoryToGo": "'+terr2+'", "action": "addRemove"}');
        }
    }

    public static Id createObjectAss(Id terr){
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = accountId, Territory2Id =terr, AssociationCause='Territory2Manual' );
        insert objObjectTerritory2Association;
        return objObjectTerritory2Association.Id;
    }

    public static Id createObjectAss2(Id terr){
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;
        ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = accountId, Territory2Id =terr, AssociationCause='Territory2Manual' );
        insert objObjectTerritory2Association;
        return objObjectTerritory2Association.Id;
    }

    public static Id createTerritory(){
        Territory2Type terrModel = [SELECT Id FROM Territory2Type LIMIT 1];
        Territory2Model model = [SELECT Id FROM Territory2Model LIMIT 1];
        Territory2 objTerr = new Territory2(); 
            objTerr.Description = 'Description__c';
            objTerr.Name = 'Name';
            objTerr.DeveloperName = 'Name';
            objTerr.Territory2TypeId = terrModel.Id;
            objTerr.Territory2ModelId = model.Id;
        insert objTerr;
        return objTerr.Id;
    }

    public static Id createTerritory2(){
        Territory2Type terrModel = [SELECT Id FROM Territory2Type LIMIT 1];
        Territory2Model model = [SELECT Id FROM Territory2Model LIMIT 1];
        Territory2 objTerr = new Territory2(); 
            objTerr.Description = 'Description__c2';
            objTerr.Name = 'Name2';
            objTerr.DeveloperName = 'Name2';
            objTerr.Territory2TypeId = terrModel.Id;
            objTerr.Territory2ModelId = model.Id;
        insert objTerr;
        return objTerr.Id;
    }

    public static Id createUserAss(Id terr){
        UserTerritory2Association userTerrAssociation = new UserTerritory2Association(Territory2Id= terr, UserId= UserInfo.getUserId(), RoleInTerritory2='Sales / Marketing Manager');
        insert userTerrAssociation;
        return userTerrAssociation.Id;
    }
}
