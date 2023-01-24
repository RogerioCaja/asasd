public without sharing class BoletosPdfController {

        public string base64 {get; set;}
        public string writableLine;
        public String Data;    
        public static String getAcessCode(){
            Integration__c data = Integration__c.getInstance('Boletos Get');
            System.debug('Data ' + data);
            String payloadToken = 'grant_type=client_credentials';
            String endpointToken = (!Test.isRunningTest() ? data.UrlToken__c : 'http://callout.My_Named_Credential.com/some/path');
            Map<String, String> headersMapToken = new Map<String, String>();
            headersMapToken.put('Content-type', 'application/x-www-form-urlencoded');
            headersMapToken.put('Authorization', (!Test.isRunningTest() ? data.Token__c : 'basic 3123312312'));
            IntegrationUtils.RequestResponseObject responseObject2 = IntegrationUtils.executeCallout(endpointToken, payloadToken, headersMapToken);
            System.debug('responseObject2: '+ responseObject2);
            if (responseObject2.success) {
                HttpResponse response = responseObject2.response;
                ResponseParametersToken responses = (ResponseParametersToken) JSON.deserialize(response.getBody(), ResponseParametersToken.class);
                System.debug('responses: '+ responses);
                return responses.access_token;
            } else {
                return null;
            }
        }

        public class ResponseParametersToken {
            public String access_token;
            public String scope;
            public String token_type;
            public Decimal expires_in;
        }

        public BoletosPdfController(ApexPages.StandardController stdController) {
            
            Id boletosIdPgReference = Id.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('Id').escapeHtml4()));
            Boletos__c boleto = [SELECT Id, WritableLine__c FROM Boletos__c WHERE Id =: boletosIdPgReference LIMIT 1];
            
            this.writableLine = boleto.WritableLine__c;
            System.debug('writableLine ' + writableLine);
            String code = (!Test.isRunningTest() ? getAcessCode() : 'acesstoken');
            String accessToken = code;
            
            System.debug('code' + code);
            Http http = new Http();
            //HttpRequest request = new HttpRequest();
            Integration__c integrationOUT = Integration__c.getInstance('Boletos Get');
            String endpoint = (!Test.isRunningTest() ? integrationOUT.Url__c+writableLine : 'http://callout.My_Named_Credential.com/some/path');
            //String endpoint = 'https://apim.agrogalaxy.com.br/gtw/bank-slip/v1/billing-pdf?linha_digitavel=74891.10234 00002.808046 10927.251008 7 92710000737104';
           
            endpoint = endpoint.replace(' ','%20');
            System.debug('endpoint ' + endpoint);
            
            
            Map<String, String> headersMap = new Map<String, String>();
            //headersMap.put('Content-type', 'application/json');
            headersMap.put('Authorization', 'Bearer '+ accessToken);
            System.debug('accessToken ' + accessToken);
            
            IntegrationUtils.RequestResponseObject responseCallout = IntegrationUtils.executeCalloutGet(endpoint,null,headersMap);
               System.debug('responseCallout ' + responseCallout);
            // If the request is successful, parse the JSON response.
            if(responseCallout.response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            HttpResponse response = responseCallout.response;
            System.debug('getBody' + response.getBody());
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Data = (String)results.get('data');
            base64 = Data;
            System.debug('Data ' + Data);
          
            System.debug('results' + results);
            
        
            }
        } 
        
       
    }