public with sharing class VisitController {
    public VisitDAO visit {get; set;}
    public List<PhotoDAO> photos {get;set;}
    
    public VisitController(ApexPages.StandardController stdController) {
        Id visitIdPageReference;
        if(ApexPages.currentPage().getParameters().get('Id') != null) {
            visitIdPageReference = Id.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('Id').escapeHtml4()));

            //Queries 
            List<Cadastro_ClientedaVisita__c> clientVisitList = getVisitById(visitIdPageReference, 
            new Set<String>{
                'Id', 'Name', 'Local_da_Visita__c', 'Tipo_da_Visita__c' , 'PlanejamentoVisita__r.Culture__r.Name' ,'PlanejamentoVisita__r.Safra__r.Name' , 'PlanejamentoVisita__r.CTVvisit__c', 'PlanejamentoVisita__r.SellOrg__r.Name' , 'Account__r.Name', 'Account__r.BillingStreet', 'Account__r.BillingState' , 'Account__r.Phone', 'Account__r.BillingCity', 'DataVisita__c'
            , 'Account__r.BillingLongitude', 'Account__r.BillingLatitude'
            });

            List<Fotos__c> photoList = getPhotoByClientId(visitIdPageReference,
            new Set<String>{
                'Id','Observation__c', 'ClienteVisita__c'
            });
        
            List<ContentVersion> contentVersionList = getFileByPhotoId(photoList);
            // ----------------------------------------------------------------------
            // Preparing Data to Photos
            this.photos = new List<PhotoDAO>();
            for(Integer i = 0; i< contentVersionList.size(); i++){
                if(photoList.size() == 1){
                    this.photos.add( new PhotoDAO(photoList.get(0), contentVersionList.get(i)));
                }
                else{
                    this.photos.add(new PhotoDAO(photoList.get(i), contentVersionList.get(i)));
                }
            }
            // ---------------------------------------------------------------------------------


            
            this.visit = new VisitDAO(clientVisitList.get(0));


            String downloadingFileName = 'VisitReport-' + this.visit.name + '.pdf';
            Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + downloadingFileName );
        }
        
    }

    public List<PhotoDAO> getPhotos(){
        return this.photos;
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

        String query = new Q(Cadastro_ClientedaVisita__c.SObjectType)
                        .selectFields(fieldsSet)
                        .add(Q.condition('Id').equalsTo(visitId)).build();

        return Database.query(query); 
    }

    public static List<Fotos__c> getPhotoByClientId(Id visitId, Set<String> fieldsSet){

        String query = new Q(Fotos__c.SObjectType)
                        .selectFields(fieldsSet)
                        .add(Q.condition('ClienteVisita__c').equalsTo(visitId)).build();
    
        //FirstPublishLocationId
        return Database.query(query);
    }

    public static List<ContentVersion> getFileByPhotoId(List<Fotos__c> photoList){
        List<String> photoIds = new List<String>();
        for(Fotos__c photo : photoList){
            photoIds.add(String.valueOf(photo.Id));
        }
        String query = new Q(ContentVersion.SObjectType)
        .selectFields(new Set<String>{'Id', 'FirstPublishLocationId'})
        .add(Q.condition('FirstPublishLocationId').isIn(photoIds)).build();

        return Database.query(query);
    }
    
    public class PhotoDAO{
        public String id {get; set;}
        public String observation {get; set;}
        public String image {get; set;}

        public PhotoDAO(Fotos__c photo, ContentVersion contentVersion){
            this.id = photo.Id;
            this.observation = photo.Observation__c;
            this.image = contentVersion.Id;
        }
    }

    public class VisitDAO{

        public String id {get; set;}
        public String name {get; set;}
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
        public String orgSales {get; set;}

        public VisitDAO(Cadastro_ClientedaVisita__c clientVisit){
            this.id = clientVisit.Id;
            this.name = clientVisit.Name;
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
            this.orgSales = clientVisit.PlanejamentoVisita__r.SellOrg__r.Name;
        }
    }

  
}