public without sharing class CalloutVisits {

    
    public static void callIntegration(List<String> visitPlanningIdList){
        updatePhoto(visitPlanningIdList);
        sendOrder(visitPlanningIdList);
    }
    public static void updatePhoto(List<String> visitIdList) {
        List<String> technicalReportIdList = new List<String>();

        List<VisitPlanning__c> visitUpdatedList = new List<VisitPlanning__c>([SELECT Id,Name, MainBP__r.ExternalId__c, BP_Property__r.ExternalId__c, InitialDate__c, EndDate__c, StartTime__c, EndTime__c, 
            Status__c, Objetivo__c, Safra__r.Code__c, Culture__r.Codigo__c, Email__c, Presential__c, Reminder__c, Displacement__c, VisitSeller__r.CodigoSap__c, Note__c, ReschedulingReason__c, 
            CancellationReason__c, ExternalId__c FROM VisitPlanning__c WHERE id IN: visitIdList]);

        List<TechnicalReport__c> technicalReportList  = new List<TechnicalReport__c>([SELECT id, ExternalId__c, Note__c, rtrControl__c, VisitPlanning__c, EndTime__c, EndDate__c, Status__c, CancellationReason__c FROM TechnicalReport__c WHERE VisitPlanning__c =: visitIdList]);
        for (TechnicalReport__c technical : technicalReportList) {
            technicalReportIdList.add(technical.Id); 
        }
        List<Fotos__c> photoList  = new List<Fotos__c>([SELECT id, RTR__c, Observation__c, ExternalId__c, FotoControl__c, IsIntegrated__c FROM Fotos__c WHERE RTR__c =: technicalReportIdList AND IsIntegrated__c = false]);
        for(Fotos__c fotos : photoList){
            fotos.IsIntegrated__c = true;
        }

        if(!photoList.isEmpty()){
            FotosHelper.disableTrigger();
            upsert photoList;
            FotosHelper.enableTrigger();
        }
    }
    @future(callout = true)
    public static void sendOrder(List<String> visitIdList) {

        List<RequestParameters> request = new List<RequestParameters>();
        List<String> technicalReportIdList = new List<String>();
        List<String> photoIdList = new List<String>();
        List<String> contentDocumentIdList = new List<String>();

        List<VisitPlanning__c> visitUpdatedList = new List<VisitPlanning__c>([SELECT Id,Name, MainBP__r.ExternalId__c, BP_Property__r.ExternalId__c, InitialDate__c, EndDate__c, StartTime__c, EndTime__c, 
            Status__c, Objetivo__c, Safra__r.Code__c, Culture__r.Codigo__c, Email__c, Presential__c, Reminder__c, Displacement__c, VisitSeller__r.CodigoSap__c, Note__c, ReschedulingReason__c, 
            CancellationReason__c, ExternalId__c FROM VisitPlanning__c WHERE id IN: visitIdList]);

        List<TechnicalReport__c> technicalReportList  = new List<TechnicalReport__c>([SELECT id, ExternalId__c, Note__c, rtrControl__c, VisitPlanning__c, EndTime__c, EndDate__c, Status__c, CancellationReason__c FROM TechnicalReport__c WHERE VisitPlanning__c =: visitIdList]);
        Map<String, List<TechnicalReport__c>> technicalReportMap = new Map<String, List<TechnicalReport__c>>();
        for (TechnicalReport__c technical : technicalReportList) {
            technicalReportIdList.add(technical.Id); 

            if(technicalReportMap.containsKey(technical.VisitPlanning__c)){
                List<TechnicalReport__c> newTechnicalReportList = technicalReportMap.get(technical.VisitPlanning__c);
                newTechnicalReportList.add(technical);
                technicalReportMap.put(technical.VisitPlanning__c,newTechnicalReportList);
            }else{
                List<TechnicalReport__c> newTechnicalReportList = new List<TechnicalReport__c>();
                newTechnicalReportList.add(technical);
                technicalReportMap.put(technical.VisitPlanning__c,newTechnicalReportList);
            }
        }
        List<Fotos__c> photoList  = new List<Fotos__c>([SELECT id, RTR__c, Observation__c, ExternalId__c, FotoControl__c, IsIntegrated__c FROM Fotos__c WHERE RTR__c =: technicalReportIdList AND IsIntegrated__c = false]);
        Map<String, List<Fotos__c>> fotoMap = new Map<String, List<Fotos__c>>();
        Map<String, Fotos__c> fotoIdMap = new Map<String, Fotos__c>();
        for(Fotos__c fotos : photoList){
            fotoIdMap.put(fotos.Id,fotos);
            photoIdList.add(fotos.id);
            if(fotoMap.containsKey(fotos.RTR__c)){
                List<Fotos__c> newFotoList = fotoMap.get(fotos.RTR__c);
                newFotoList.add(fotos);
                fotoMap.put(fotos.RTR__c,newFotoList);
            }else{
                List<Fotos__c> newfotoList = new List<Fotos__c>();
                newfotoList.add(fotos);
                fotoMap.put(fotos.RTR__c,newfotoList);
            }
        }
        List<ContentDocumentLink> contendLinkList = new List<ContentDocumentLink>();
        if(!photoIdList.isEmpty()){
            contendLinkList = [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersion.VersionData FROM ContentDocumentLink WHERE LinkedEntityId IN: photoIdList]; 
        }
        System.debug('photoIdList ' + photoIdList);
        System.debug('contendLinkList ' + contendLinkList);
        Map<String, String> photoBase64Map = new Map<String, String>();
        for(ContentDocumentLink contendLink : contendLinkList){
            Fotos__c photo = fotoIdMap.get(contendLink.LinkedEntityId);
            photoBase64Map.put(photo.Id,EncodingUtil.base64Encode(contendLink.ContentDocument.LatestPublishedVersion.VersionData));
        }
		System.debug('photoBase64Map ' + photoBase64Map);
        
        

        for (VisitPlanning__c visit : visitUpdatedList) {
            //criar map string,List technicalReport 
            List<TechnicalReport__c> newTechnicalReportList = technicalReportMap.get(visit.Id); 
            request.add(new RequestParameters(visit,newTechnicalReportList, fotoMap, photoBase64Map));

        }

        String code = (!Test.isRunningTest() ? getAcessCode() : 'acessToken');
        System.debug('AcessCode: '+ code);
        String payload = JSON.serialize(request);
        System.debug('PayloadCheck: '+ payload);
        
        //Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
        String accessToken = code;
        //Url mock: https://aabb2740-69b0-4737-925c-2c40367a3737.mock.pstmn.io//CalloutCTVCarteira
        //Path geralmente cadastrado dentro de ua customSettings 
        Integration__c data = Integration__c.getInstance('Visits OUT');
        String endpoint = (!Test.isRunningTest() ? data.Url__c : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-type', 'application/json');
        headersMap.put('Authorization', 'Bearer '+ accessToken);
        
        IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap);

        if (responseObject.success) {

            HttpResponse response = responseObject.response;

            IntegrationLog.createLog('Visits OUT', 'OUT', response.getBody(), payload, false);
            System.debug('response.getBody(): '+ response.getBody());
        } else {
            IntegrationLog.createLog('Visits OUT', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
        } 
    }
    public static String getAcessCode(){
        
        Integration__c data = Integration__c.getInstance('Visits OUT');
        String payloadToken = 'grant_type=client_credentials';
        String endpointToken = (!Test.isRunningTest() ? data.UrlToken__c : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMapToken = new Map<String, String>();
        headersMapToken.put('Content-type', 'application/x-www-form-urlencoded');
        headersMapToken.put('Authorization', data.Token__c);
        IntegrationUtils.RequestResponseObject responseObject2 = IntegrationUtils.executeCallout(endpointToken, payloadToken, headersMapToken);
        
        if (responseObject2.success) {
            HttpResponse response = responseObject2.response;
            ResponseParametersToken responses = (ResponseParametersToken) JSON.deserialize(response.getBody(), ResponseParametersToken.class);
            return responses.access_token;
        } else {
            return null;
        }
    }

    //! Preparing data to Callout
    public class RequestParameters{
        public Object header;

        public RequestParameters(VisitPlanning__c visit, List<TechnicalReport__c> technicalReportList, Map<String, List<Fotos__c>> fotoMap, Map<String, String> photoBase64Map){
            CalloutVisits.HeaderInsert header = new CalloutVisits.HeaderInsert();

            header.Name  = visit.Name;
            header.BpCode = visit.MainBP__r.ExternalId__c;
            header.BpPropertyCode = visit.BP_Property__r.ExternalId__c;
            header.PlanStartDate = visit.InitialDate__c;
            header.PlanEndDate = visit.EndDate__c;
            header.StartTime = visit.StartTime__c;
            header.EndTime = visit.EndTime__c;
            header.Status = visit.Status__c;
            header.Objective = visit.Objetivo__c;
            header.Crop = visit.Safra__r.Code__c;
            header.Culture = visit.Culture__r.Codigo__c;
            header.Email = visit.Email__c;
            header.Presential = visit.Presential__c;
            header.Reminder = visit.Reminder__c;
            header.Displacement = visit.Displacement__c;
            header.CtvVisit = visit.VisitSeller__r.CodigoSap__c;
            header.Observation = visit.Note__c;
            header.ReasonRescheduling = visit.ReschedulingReason__c;
            header.ExternalCodeVisits = visit.ExternalId__c;
            header.ReasonCancellation = visit.CancellationReason__c;


            List<CalloutVisits.TechnicalReportsParameters> newtechnicalReportList = new List<CalloutVisits.TechnicalReportsParameters>();
            if(technicalReportList != null){
                for(TechnicalReport__c technical : technicalReportList){
                    newtechnicalReportList.add(new CalloutVisits.TechnicalReportsParameters(technical, fotoMap, photoBase64Map));
                    System.debug('technicalReportList'+ technicalReportList);
                }
            }else{
                newtechnicalReportList.add(new CalloutVisits.TechnicalReportsParameters(null, fotoMap, photoBase64Map));
            }
            header.TechnicalReports = newtechnicalReportList;
            this.header = header;
        }
    }
    public class HeaderInsert{
        public String Name;
        public String BpCode;
        public String BpPropertyCode;
        public Date PlanStartDate;
        public Date PlanEndDate;
        public Time StartTime;
        public Time EndTime;
        public String Status;
        public String Objective;
        public String Crop;
        public String Culture;
        public String Email;
        public Boolean Presential;
        public Boolean Reminder;
        public String Displacement;
        public String CtvVisit;
        public String Observation;
        public String ReasonRescheduling;
        public String ExternalCodeVisits;
        public String ReasonCancellation;
        public List<CalloutVisits.TechnicalReportsParameters> TechnicalReports;

        public HeaderInsert(){}
    }
    public class PhotosParameters{
        public String Photo;
        public String Observation;
        public String FileLine;
        public String ExternalCodePhoto;
        public PhotosParameters(Fotos__c photo, Map<String, String> photoBase64Map){
            if(photoBase64Map.containsKey(photo.Id))
                this.Photo = photoBase64Map.get(photo.Id);
            this.Observation = photo.Observation__c;
            this.FileLine = String.valueOf(photo.FotoControl__c);
            this.ExternalCodePhoto = photo.ExternalId__c;
        }
    }

    public class TechnicalReportsParameters{
        public String Observation;
        public Time EndTime;
        public Date EndDate;
        public String Status;
        public String CancellationReason;
        public String RtrLine;
        public String ExternalCodeTechnical;

        public List<CalloutVisits.PhotosParameters> Photos;
        public TechnicalReportsParameters(TechnicalReport__c technicalReport,  Map<String, List<Fotos__c>> fotoMap, Map<String, String> photoBase64Map){
            if(technicalReport != null){
            this.Observation = technicalReport.Note__c;
            this.EndTime = technicalReport.EndTime__c;
            this.EndDate = technicalReport.EndDate__c;
            this.Status = technicalReport.Status__c;
            this.CancellationReason = technicalReport.CancellationReason__c;
            this.RtrLine = String.valueOf(technicalReport.rtrControl__c);
            this.ExternalCodeTechnical = technicalReport.ExternalId__c;

            if(fotoMap.containsKey(technicalReport.id)){
                List<CalloutVisits.PhotosParameters> newPhotoList= new List<CalloutVisits.PhotosParameters>();
                List<Fotos__c> photoList = fotoMap.get(technicalReport.id);
                for(Fotos__c photo : photoList){
                    newPhotoList.add(new CalloutVisits.PhotosParameters(photo, photoBase64Map));
                }
                this.Photos = newPhotoList;
            }
            }else{
                this.Observation = null;
                this.EndTime = null;
                this.EndDate = null;
                this.Status = null;
                this.CancellationReason = null;
                this.RtrLine = null;
                this.ExternalCodeTechnical = null;
                this.Photos = null;
            }
        }
    }

    //! Response part
    public class ResponseParameters {
        public List<ResponseParametersWrapper> responses;

        public ResponseParameters(List<ResponseParametersWrapper> responses) {
            this.responses = responses;
        }
    }

    public class ResponseParametersWrapper {
        public Boolean Status; 
        public List<OrderDetails> DetalhesPedido;
        public List<Messages> Mensagens; 
    }

    public class ResponseParametersToken {
        public String access_token; 
        public String scope; 
        public String token_type; 
        public Decimal expires_in; 
    }

    public class Messages{
        public String Tipo;
        public String Mensagem;
    }

    public class OrderDetails{
        public String StatusSap;
        public String NumeroOrdemVenda;
    }
}