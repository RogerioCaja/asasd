public with sharing class VisitController {
    public VisitDAO visit {get; set;}
    public PhotoDAO photo {get;set;}
    

    public VisitController(ApexPages.StandardController stdController) {
        Id visitIdPageReference;
        if(ApexPages.currentPage().getParameters().get('Id') != null) {
            visitIdPageReference = Id.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('Id').escapeHtml4()));
        }
        
        List<Cadastro_ClientedaVisita__c> ClientVisitList = getVisitById(visitIdPageReference, 
        new Set<String>{
            'PlanejamentoVisita__r.CTVvisit__c', 'Account__r.Name', 'Account__r.BillingStreet', 'Account__r.BillingState' , 'Account__r.Phone', 'Account__r.BillingCity', 'DataVisita__c'
           });

        List<Fotos__c> photoList = getPhotoByClientId(visitIdPageReference);

        this.visit = new VisitDAO(ClientVisitList.get(0));
    }

    public VisitDAO getVisit(){
        return this.visit;
    }
    public static String getDatetime(){
        Datetime  dt = DateTime.now();
        String dateFormat = dt.format('dd/MM/yyyy HH:mm:ss', 
        'America/Sao_Paulo');

        return dateFormat;
    }

    public static List<Cadastro_ClientedaVisita__c> getVisitById(Id visitId, Set<String> fieldsSet){

        Boolean isNotBlank = String.isNotBlank(String.valueOf(visitId));
        
        List<Cadastro_ClientedaVisita__c> visitList = [SELECT Id, Local_da_Visita__c, Tipo_da_Visita__c , PlanejamentoVisita__r.Culture__r.Name ,PlanejamentoVisita__r.Safra__r.Name , PlanejamentoVisita__r.CTVvisit__c, Account__r.Name, Account__r.BillingStreet, Account__r.BillingState , Account__r.Phone, Account__r.BillingCity, DataVisita__c
        , Account__r.BillingLongitude, Account__r.BillingLatitude
                                                        FROM Cadastro_ClientedaVisita__c
                                                        WHERE Id =: visitId ];
        return visitList;
         
    }

    public static List<Fotos__c> getPhotoByClientId(Id visitId){
        List<Fotos__c> photoList = [SELECT Observation__c, ClienteVisita__c
                                    FROM Fotos__c
                                    WHERE ClienteVisita__c =: visitId];

        return photoList;
    }
    public class PhotoDAO{
        public String observation {get; set;}
        public String image {get; set;}

        public PhotoDAO(Fotos__c photo){

        }
    }

    public class VisitDAO{

        // CTV da Visita, Data de Início e Fim do Plano de visitas; Nome do Plano, Organização de Vendas, Safra, Cultura
        // Cliente, Tipo da visita, Local da visita, Base check in, Data e hora da visita, status da visita
        
        //  , 'Account__r.Phone', 'Account__r.BillingCity', 
        public String id {get; set;}
        public String visitCTV {get; set;}
        public String dateVisit {get; set;}
        public String accountName {get; set;}
        public String accountStreet {get; set;}
        public String accountState {get; set;}
        public String accountPhone {get; set;}
        public String accountCity {get; set;}

        public String service {get; set;}
        public String localeVisit {get; set;}
        public String culture {get; set;}
        public String crop {get; set;}

        public String accountLatitude {get; set;}
        public String accountLongitude {get; set;}

        //Local_da_Visita__c, Tipo_da_Visita__c PlanejamentoVisita__r.Cultura__r.Name ,PlanejamentoVisita__r.Safra__r.Name

        public VisitDAO(){}
        public VisitDAO(Cadastro_ClientedaVisita__c clientVisit){
            this.id = clientVisit.Id;
            //Bloco 1
            this.visitCTV = clientVisit.PlanejamentoVisita__r.CTVvisit__c;
            this.dateVisit = String.valueOf(clientVisit.DataVisita__c);
            this.accountName = clientVisit.Account__r.Name;
            this.accountStreet = clientVisit.Account__r.BillingStreet;
            this.accountState = clientVisit.Account__r.BillingState;
            this.accountPhone = clientVisit.Account__r.Phone;
            this.accountCity = clientVisit.Account__r.BillingCity;

            //Bloco 2
            this.service = clientVisit.Tipo_da_Visita__c;
            this.localeVisit = clientVisit.Local_da_Visita__c;
            this.culture = clientVisit.PlanejamentoVisita__r.Culture__r.Name;
            this.crop = clientVisit.PlanejamentoVisita__r.Safra__r.Name;

            //Bloco 3
            this.accountLatitude = String.valueOf(clientVisit.Account__r.BillingLatitude);
            this.accountLongitude =String.valueOf(clientVisit.Account__r.BillingLongitude);

        }

    }

  
}