public without sharing class CalloutVisits {

        public static void sendOrder(List<VisitPlanning__c> planningVisitsList) {
    
            List<RequestParameters> request = new List<RequestParameters>();
            List<String> visitIdList = new List<String>();
            List<String> technicalReportIdList = new List<String>();
            List<String> photoIdList = new List<String>();
            List<String> contentDocumentIdList = new List<String>();
            for (VisitPlanning__c visit : planningVisitsList) {
                visitIdList.add(visit.Id); 
            }
            List<TechnicalReport__c> technicalReportList  = new List<TechnicalReport__c>([SELECT id, ExternalId__c, Note__c, VisitPlanning__c, EndTime__c, EndDate__c, Status__c, CancellationReason__c FROM TechnicalReport__c WHERE VisitPlanning__c =: visitIdList]);
            Map<String, List<TechnicalReport__c>> technicalReportMap = new Map<String, List<TechnicalReport__c>>();
            for (VisitPlanning__c technical : technicalReportList) {
                technicalReportIdList.add(technical.Id); 

                if(technicalReportMap.containsKey(technical.VisitPlanning__c)){
                    List<VisitPlanning__c> technicalReportList = technicalReportMap.get(technical.VisitPlanning__c);
                    technicalReportList.add(technical);
                    technicalReportMap.put(comp.Conta__r.ExternalId__c,technicalReportList);
                }else{
                    List<VisitPlanning__c> newTechnicalReportList = new List<VisitPlanning__c>();
                    newTechnicalReportList.add(technical);
                    technicalReportMap.put(technical.VisitPlanning__c,newTechnicalReportList);
                }
            }
            List<Fotos__c> photoList  = new List<Fotos__c>([SELECT id, RTR__c, Observation__c, FotoControl__c, IsIntegrated__c FROM Fotos__c WHERE RTR__c =: technicalReportIdList AND IsIntegrated__c = false]);

            for(Fotos__c fotos : photoList){
                photoIdList.add(fotos.id);
            }
            List<ContentDocumentLink> contendLinkList = new List<ContentDocumentLink>([SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN: photoIdList]);
            for(ContentDocumentLink contendLink : contendLinkList){
                contentDocumentIdList.add(contendLink.ContentDocumentId);
            }
            Map<Id,ContentVersion> contendVersionList = new Map<Id,ContentVersion>([SELECT Id, VersionData FROM ContentVersion WHERE Id IN: contentDocumentIdList]);


            //para pegar o base64
            /* usando o VersionData
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v42.0/sobjects/ContentVersion/06890000003oTkqAAE/VersionData');
            req.setMethod('GET');
            req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            HttpResponse res = h.send(req);
            system.debug(res.getBody());
            */

            // por aqui

            for (VisitPlanning__c visit : planningVisitsList) {
                //criar map string,List technicalReport 
                List<VisitPlanning__c> technicalReportList = technicalReportMap.get(visit.Id); 
                request.add(new RequestParameters(visit,technicalReportList));
                
            }
            String code = (!Test.isRunningTest() ? getAcessCode() : 'acessToken');
            System.debug('AcessCode: '+ code);
            String payload = JSON.serialize(request);
            System.debug('PayloadCheck: '+ payload);
            /*
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
            } */
        }
        public static String getAcessCode(){
            /*
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
            */
            return null;
        }
    
        //! Preparing data to Callout
        public class RequestParameters{
            public Object header;
    
            public RequestParameters(VisitPlanning__c visit, List<TechnicalReport__c> technicalReportList){
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


                List<CalloutCTVCarteira.TechnicalReportsParameters> technicalReportList= new List<CalloutCTVCarteira.TechnicalReportsParameters>();
                
                for(TechnicalReport__c technical : technicalReportList){
                    technicalReportList.add(new CalloutCTVCarteira.TechnicalReportsParameters(technical));
                    System.debug('technicalReportList'+ technicalReportList);
                }
    
                header.TechnicalReports = technicalReportList;
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
            public PhotosParameters(Fotos__c photo,Map<String,String> base64PhotoMap){
                //this.Photo = base64PhotoMap.get;
                //this.Observation = photo;
                //this.FileLine = photo;
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
            public TechnicalReportsParameters(TechnicalReport__c technicalReport){
                CalloutVisits.TechnicalReportsParameters technical = new CalloutVisits.TechnicalReportsParameters();
    
                technical.Observation = technicalReport.Note__c;
                technical.EndTime = technicalReport.EndTime__c;
                technical.EndDate = technicalReport.EndDate__c;
                technical.Status = technicalReport.Status__c;
                technical.CancellationReason = technicalReport.CancellationReason__c;
                technical.RtrLine = technicalReport.rtrControl__c;
                technical.ExternalCodeTechnical = technicalReport.ExternalId__c;
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
    
}
