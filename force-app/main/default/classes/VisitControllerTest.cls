
@isTest
public with sharing class VisitControllerTest {
    public VisitControllerTest() {}

    @TestSetup
    static void makeData(){
        //Requisitos: Account, Planejamento de visita
        Account ac = new Account(
            Name = 'Teste 1'
        );
        

        Safra__c s = new Safra__c(
            Code__c = '1223',
            Name = 'Safra Teste',
            Name__c = 'Safra Teste',
            BillingStartDate__c = System.today(),
            EndDateBilling__c = System.today(),
            EndDateInsertionOrders__c = System.today(),
            NumberOfDaysAfterPayment__c = System.today(),
            ReleaseStatus__c = 'Ativo',
            StartDateOrderInsertion__c = System.today()

        );

        Cultura__c cultura = new Cultura__c(
            Name = 'Safrinha',
            Name__c = 'Safrinha',
            Codigo__c = '1234'
        );

        insert ac;
        insert s;
        insert cultura;

        SalesOrg__c so = new SalesOrg__c(
            Name = 'AgroGalaxy'
        );

        insert so;
        List<Cultura__c> clist = [SELECT Id FROM Cultura__c LIMIT 1];
        List<Safra__c> sList = [SELECT Id FROM Safra__c LIMIT 1];
        List<SalesOrg__c> salesList = [SELECT Id FROM SalesOrg__c LIMIT 1];
        VisitPlanning__c vp = new VisitPlanning__c(
            CTVvisit__c = 'Teste',
            Culture__c = clist.get(0).Id,
            EndDate__c = System.today(),
            InitialDate__c = System.today(),
            Safra__c = sList.get(0).Id,
            SellOrg__c = salesList.get(0).Id
        );
        insert vp;

        List<Account> accList = [SELECT Id FROM ACCOUNT LIMIT 1];
        List<VisitPlanning__c> vpList = [SELECT Id FROM VisitPlanning__c LIMIT 1];
        Cadastro_ClientedaVisita__c ccv = new Cadastro_ClientedaVisita__c(
            Account__c = accList.get(0).Id,
            ChekIn__c = true,
            DataVisita__c = Datetime.now(),
            Local_da_Visita__c = 'Local teste',
            PlanejamentoVisita__c = vpList.get(0).Id,
            Status_da_Visita__c = 'Planejada',
            Tipo_da_Visita__c = 'Serviço Técnico'
        );

        insert ccv;
        List<Cadastro_ClientedaVisita__c> cvList = [SELECT Id FROM Cadastro_ClientedaVisita__c LIMIT 1];
        Fotos__c photo = new Fotos__c(
            ClienteVisita__c = cvList.get(0).Id,
            Observation__c = 'Teste'
        );
        insert photo;

        //Requisito para as fotos e Cadastro do Cliente
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
}
