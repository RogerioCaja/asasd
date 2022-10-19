@isTest
public with sharing class ReportControllerTest {
    public ReportControllerTest() {}

    @TestSetup
    static void makeData(){
         TemplateDefaultFields t = new TemplateDefaultFields();
        t.packageTest();
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
    public static void verifyConstructor(){
        List<TechnicalReport__c> cp = [SELECT Id FROM TechnicalReport__c LIMIT 1];
        List<TechnicalReport__c> responseCadastro = ReportController.getReportById(Id.valueOf(cp.get(0).Id), new Set<String>{
            'Id', 'Name', 'toLabel(VisitPlanning__r.Objetivo__c)', 'VisitPlanning__r.MainBp__r.Name' , 'VisitPlanning__r.InitialDate__c'
                , 'Note__c', 'VisitPlanning__r.Name',
                'VisitPlanning__r.Culture__r.Name' ,'VisitPlanning__r.Safra__r.Name' , 
                'VisitPlanning__r.VisitSeller__c', 'VisitPlanning__r.SellOrg__r.Name' , 
                'VisitPlanning__r.BP_Property__r.Name', 'VisitPlanning__r.BP_Property__r.BillingStreet', 'VisitPlanning__r.BP_Property__r.BillingState' , 
                'VisitPlanning__r.BP_Property__r.Phone', 'VisitPlanning__r.BP_Property__r.BillingCity',    'VisitPlanning__r.BP_Property__r.BillingLongitude', 'VisitPlanning__r.BP_Property__r.BillingLatitude'
            });

        ReportController.ReportDTO visitTest = new ReportController.ReportDTO(responseCadastro.get(0));
        System.assert(cp.get(0).Id == visitTest.id);
    }

    @isTest
    public static void verifyProcedureMain(){
        List<TechnicalReport__c> cp = [SELECT Id FROM TechnicalReport__c LIMIT 1];
        ReportController vc = new ReportController();
        System.assert(vc.generatePDF(cp.get(0).Id) == true, 'Houve algum erro no processo de gerar PDF'); 
    }
}