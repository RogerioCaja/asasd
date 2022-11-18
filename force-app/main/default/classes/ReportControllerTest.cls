@isTest
public with sharing class ReportControllerTest {
    public ReportControllerTest() {}

    @TestSetup
    static void makeData(){
         TemplateDefaultFields t = new TemplateDefaultFields();
        t.packageTest();
        List<Account> accountList = new List<Account>();
        Account parentAccount = new Account(
            Name = 'Parent Account',
            Company__c = 'Parent Account',
            Phone = '11111111111',
            ExternalId__c = '123456'
        );
        insert parentAccount;
    }

    @isTest
    public static void verifyDateFormat(){
        String dateTest = ReportController.getDatetime();

        System.assert((String.isNotBlank(dateTest) && String.isNotEmpty(dateTest)), 'Os dados resultaram em falha');
    }

    @isTest
    public static void verifyQueries(){
        List<TechnicalReport__c> cp = [SELECT Id FROM TechnicalReport__c LIMIT 1];
        List<Fotos__c> p = [SELECT Id FROM Fotos__c LIMIT 1];
        List<TechnicalReport__c> responseCadastro = ReportController.getReportById(Id.valueOf(cp.get(0).Id), new Set<String>{
            'Id', 'Name', 'toLabel(VisitPlanning__r.Objetivo__c)', 'VisitPlanning__r.MainBp__r.Name' , 'VisitPlanning__r.InitialDate__c'
                , 'Note__c', 'VisitPlanning__r.Name',
                'VisitPlanning__r.Culture__r.Name' ,'VisitPlanning__r.Safra__r.Name' , 
                'VisitPlanning__r.VisitSeller__c', 'VisitPlanning__r.SellOrg__r.Name' , 
                'VisitPlanning__r.BP_Property__r.Name', 'VisitPlanning__r.BP_Property__r.BillingStreet', 'VisitPlanning__r.BP_Property__r.BillingState' , 
                'VisitPlanning__r.BP_Property__r.Phone', 'VisitPlanning__r.BP_Property__r.BillingCity',    'VisitPlanning__r.BP_Property__r.BillingLongitude', 'VisitPlanning__r.BP_Property__r.BillingLatitude'
            });
        List<Fotos__c> responseFoto = ReportController.getPhotoByClientId(Id.valueOf(cp.get(0).Id), new Set<String>{
            'Id','Observation__c', 'ClienteVisita__c', 'RTR__c'
        });
        List<ContentDocumentLink> contentList = ReportController.getFileByPhotoId(p);
        
        System.assert(responseCadastro.size() != 0);
        System.assert(responseFoto.size() != 0);
        System.assert(contentList.size() == 0);

    }

    @isTest
    public static void verifyProcedureMain(){
        prepareTerritory();
        List<TechnicalReport__c> cp = [SELECT Id FROM TechnicalReport__c LIMIT 1];
        ReportController vc = new ReportController();
        System.assert(vc.generatePDF(cp.get(0).Id) == true, 'Houve algum erro no processo de gerar PDF'); 
    }
    public static void prepareTerritory(){
        Id terr;
        Id objAss;
        Id userAss;
        Id terr2;
        System.runAs(new User(Id = UserInfo.getUserId())){
            terr = createTerritory();
            terr2 = createTerritory2(terr);
            objAss = createObjectAss(terr2);
            userAss = createUserAss(terr2);
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
        Territory2Type terrModel = [SELECT Id FROM Territory2Type WHERE DeveloperName = 'SalesOrg' LIMIT 1];
        Territory2Model model = [SELECT Id FROM Territory2Model LIMIT 1];
        Territory2 objTerr = new Territory2(); 
            objTerr.Description = 'Description__c';
            objTerr.Name = 'Name';
            objTerr.DeveloperName = 'X1111';
            objTerr.Territory2TypeId = terrModel.Id;
            objTerr.Territory2ModelId = model.Id;
        insert objTerr;
        return objTerr.Id;
    }

    public static Id createTerritory2(Id Terr){
        Territory2Type terrModel = [SELECT Id FROM Territory2Type LIMIT 1];
        Territory2Model model = [SELECT Id FROM Territory2Model LIMIT 1];
        Territory2 objTerr = new Territory2(); 
            objTerr.Description = 'Description__c2';
            objTerr.Name = 'Name2';
            objTerr.DeveloperName = 'Name2';
        	objTerr.ParentTerritory2Id = Terr;
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