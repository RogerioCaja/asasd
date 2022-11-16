public without sharing class ReportController {
    public ReportDTO report {get; set;}
    public List<PhotoDTO> photos {get;set;}
    public ReportController(){}
    public ReportController(ApexPages.StandardController stdController) {
        Id reportIdPageReference = Id.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('Id').escapeHtml4()));
        if(reportIdPageReference != null) generatePDF(reportIdPageReference);

    }

    @TestVisible
    public Boolean generatePDF(Id reportIdPageReference){

            //Queries 
            List<TechnicalReport__c> reportList = getReportById(reportIdPageReference, 
            new Set<String>{
                'Id', 'Name', 'toLabel(VisitPlanning__r.Objetivo__c)', 'VisitPlanning__r.MainBp__r.Name' , 'VisitPlanning__r.InitialDate__c'
                , 'Note__c', 'VisitPlanning__r.Name', 'VisitPlanning__c', 'VisitPlanning__r.Name',
                'VisitPlanning__r.Culture__r.Name' ,'VisitPlanning__r.Safra__r.Name' , 
                'VisitPlanning__r.VisitSeller__r.Name', 'VisitPlanning__r.SellOrg__r.Name' , 
                'VisitPlanning__r.BP_Property__r.Name', 'VisitPlanning__r.BP_Property__r.BillingStreet', 'VisitPlanning__r.BP_Property__r.BillingState' , 
                'VisitPlanning__r.BP_Property__r.Phone', 'VisitPlanning__r.BP_Property__r.BillingCity',    'VisitPlanning__r.BP_Property__r.BillingLongitude', 'VisitPlanning__r.BP_Property__r.BillingLatitude'
            });

            List<Fotos__c> photoList = getPhotoByClientId(reportIdPageReference,
            new Set<String>{
                'Id','Observation__c', 'ClienteVisita__c', 'RTR__c'
            });
            System.debug(photoList);
            if(photoList != null){
                List<ContentDocumentLink> contentVersionList = getFileByPhotoId(photoList);
                Map<Id, ContentDocumentLink> photoContentDocumentMap = new Map<Id, ContentDocumentLink>();

                for(ContentDocumentLink content : contentVersionList){
                    photoContentDocumentMap.put(content.LinkedEntityId, content);
                }
                // ----------------------------------------------------------------------
                // Preparing Data to Photos
                this.photos = new List<PhotoDTO>();
                
                for(Integer i = 0; i< contentVersionList.size(); i++){
                    if(photoList.size() == 1){
                        this.photos.add( new PhotoDTO(photoList.get(0), contentVersionList.get(i)));
                    }
                    else{
                        this.photos.add(new PhotoDTO(photoList.get(i), photoContentDocumentMap.get(photoList.get(i).Id)));
                    }
                }
                
            }
            // ---------------------------------------------------------------------------------
            this.report = new ReportDTO(reportList.get(0));
            String downloadingFileName = 'VisitReport-' + this.report.name + '.pdf';
            Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + downloadingFileName );
            if(this.report != null) return true;
            else return false;
        
    }
    public List<PhotoDTO> getPhotos(){
        return this.photos;
    }

    public ReportDTO getVisit(){
        return this.report;
    }

    public static String getDatetime(){

        Datetime  dt = DateTime.now();
        String dateFormat = dt.format('dd/MM/yyyy HH:mm:ss', 
        'America/Sao_Paulo');

        return dateFormat;
    }

    public static List<TechnicalReport__c> getReportById(Id reportId, Set<String> fieldsSet){

        String query = new Q(TechnicalReport__c.SObjectType)
                        .selectFields(fieldsSet)
                        .add(Q.condition('Id').equalsTo(reportId)).build();

        return Database.query(query); 
    }

    public static List<Fotos__c> getPhotoByClientId(Id reportId, Set<String> fieldsSet){

        String query = new Q(Fotos__c.SObjectType)
                        .selectFields(fieldsSet)
                        .add(Q.condition('RTR__c').equalsTo(reportId)).build();
    
        //FirstPublishLocationId
        System.debug(query);
        return Database.query(query);
    }

    public static List<ContentDocumentLink> getFileByPhotoId(List<Fotos__c> photoList){
        List<String> photoIds = new List<String>();
        for(Fotos__c photo : photoList){
            photoIds.add(String.valueOf(photo.Id));
        }
        String query = new Q(ContentDocumentLink.SObjectType)
        .selectFields(new Set<String>{'Id', 'ContentDocument.LatestPublishedVersionID', 'LinkedEntityId'})
        .add(Q.condition('LinkedEntityId').isIn(photoIds)).build();

        return Database.query(query);
    }
    
    public class PhotoDTO{
        public String id {get; set;}
        public String observation {get; set;}
        public String image {get; set;}

        public PhotoDTO(Fotos__c photo, ContentDocumentLink contentDocumentLink){
            this.id = photo.Id;
            this.observation = photo.Observation__c;
            this.image = contentDocumentLink.ContentDocument.LatestPublishedVersionID;
        }
    }

    public class ReportDTO{

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

        public String notes {get;set;}
        public String nextVisit {get;set;}
        public String nextVisitName {get;set;}

        public ReportDTO(TechnicalReport__c report){
            this.id = report.Id;
            this.name = report.Name;
            //Bloco 1
            this.visitCTV = report.VisitPlanning__r.VisitSeller__r.Name;
            this.dateVisit = getFormattedDate(String.valueOf(report.VisitPlanning__r.InitialDate__c));
            this.accountName = report.VisitPlanning__r.BP_Property__r.Name;
            this.accountStreet = report.VisitPlanning__r.BP_Property__r.BillingStreet;
            this.accountState = report.VisitPlanning__r.BP_Property__r.BillingState;
            this.accountPhone = getFormattedPhoneNum(report.VisitPlanning__r.BP_Property__r.Phone);
            this.accountCity = report.VisitPlanning__r.BP_Property__r.BillingCity;

            //Bloco 2
            this.service = report.VisitPlanning__r.Objetivo__c;
            this.localeVisit = report.VisitPlanning__r.MainBp__r.Name;
            this.culture = report.VisitPlanning__r.Culture__r.Name;
            this.crop = report.VisitPlanning__r.Safra__r.Name;

            //Bloco 3
            this.accountLatitude = String.valueOf(report.VisitPlanning__r.BP_Property__r.BillingLatitude);
            this.accountLongitude =String.valueOf(report.VisitPlanning__r.BP_Property__r.BillingLongitude);
            this.orgSales = report.VisitPlanning__r.SellOrg__r.Name;

            //Bloco 4
            this.notes = report.Note__c;
            this.nextVisit = URL.getSalesforceBaseUrl().toExternalForm() + '/' + report.VisitPlanning__c ;
            this.nextVisitName = report.VisitPlanning__r.Name;
        }

        
        public String getFormattedPhoneNum(String phone) {
            if(phone == null){
                return '';
            }
            else{
                String s = '(' + phone.substring(0, 2) + ') ' + phone.substring(2, 7) + '-' + phone.substring(7);
                return s;
            }
        }
        
        public String getFormattedDate(String dateToFormat){
            Date  dt = Date.valueOf(dateToFormat);
            String dateFormat = dt.format();
            return dateFormat;
        }

    }

  
}