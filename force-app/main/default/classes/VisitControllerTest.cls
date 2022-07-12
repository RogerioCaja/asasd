@isTest
public with sharing class VisitControllerTest {
    public VisitControllerTest() {}

    @TestSetup
    static void makeData(){
         TemplateDefaultFields t = new TemplateDefaultFields();
        t.packageTest();
    }

    @isTest
    public static void verifyDateFormat(){
        String dateTest = VisitController.getDatetime();

        System.assert((String.isNotBlank(dateTest) && String.isNotEmpty(dateTest)), 'Os dados resultaram em falha');
    }

    @isTest
    public static void verifyQueries(){
        List<Cadastro_ClientedaVisita__c> cp = [SELECT Id FROM Cadastro_ClientedaVisita__c LIMIT 1];
        List<Fotos__c> p = [SELECT Id FROM Fotos__c LIMIT 1];
        List<Cadastro_ClientedaVisita__c> responseCadastro = VisitController.getVisitById(Id.valueOf(cp.get(0).Id), new Set<String>{
            'Id', 'Name', 'Local_da_Visita__c', 'Tipo_da_Visita__c' , 'PlanejamentoVisita__r.Culture__r.Name' ,'PlanejamentoVisita__r.Safra__r.Name' , 'PlanejamentoVisita__r.CTVvisit__c', 'PlanejamentoVisita__r.SellOrg__r.Name' , 'Account__r.Name', 'Account__r.BillingStreet', 'Account__r.BillingState' , 'Account__r.Phone', 'Account__r.BillingCity', 'DataVisita__c'
        , 'Account__r.BillingLongitude', 'Account__r.BillingLatitude'
        });
        List<Fotos__c> responseFoto = VisitController.getPhotoByClientId(Id.valueOf(cp.get(0).Id), new Set<String>{
            'Id','Observation__c', 'ClienteVisita__c'
        });
        List<ContentVersion> contentList = VisitController.getFileByPhotoId(p);
        
        System.assert(responseCadastro.size() != 0);
        System.assert(responseFoto.size() != 0);
        System.assert(contentList.size() == 0);

    }

    @isTest 
    public static void verifyConstructor(){
        List<Cadastro_ClientedaVisita__c> cp = [SELECT Id FROM Cadastro_ClientedaVisita__c LIMIT 1];
        List<Cadastro_ClientedaVisita__c> responseCadastro = VisitController.getVisitById(Id.valueOf(cp.get(0).Id), new Set<String>{
            'Id', 'Name', 'Local_da_Visita__c', 'Tipo_da_Visita__c' , 'PlanejamentoVisita__r.Culture__r.Name' ,'PlanejamentoVisita__r.Safra__r.Name' , 'PlanejamentoVisita__r.CTVvisit__c', 'PlanejamentoVisita__r.SellOrg__r.Name' , 'Account__r.Name', 'Account__r.BillingStreet', 'Account__r.BillingState' , 'Account__r.Phone', 'Account__r.BillingCity', 'DataVisita__c'
        , 'Account__r.BillingLongitude', 'Account__r.BillingLatitude'
        });

        VisitController.VisitDAO visitTest = new VisitController.VisitDAO(responseCadastro.get(0));
        System.assert(cp.get(0).Id == visitTest.id);
    }

    @isTest
    public static void verifyProcedureMain(){
        List<Cadastro_ClientedaVisita__c> cp = [SELECT Id, Name, Local_da_Visita__c, Tipo_da_Visita__c , PlanejamentoVisita__r.Culture__r.Name ,PlanejamentoVisita__r.Safra__r.Name , PlanejamentoVisita__r.CTVvisit__c, PlanejamentoVisita__r.SellOrg__r.Name , Account__r.Name, Account__r.BillingStreet, Account__r.BillingState , Account__r.Phone, Account__r.BillingCity, DataVisita__c
        , Account__r.BillingLongitude, Account__r.BillingLatitude FROM Cadastro_ClientedaVisita__c LIMIT 1];
        VisitController vc = new VisitController();
        System.assert(vc.generatePDF(cp.get(0).Id) == true, 'Houve algum erro no processo de gerar PDF'); 
    }
}