public without sharing class NotaPdfController {

    public string base64 {get; set;}
    public string accessKey;
    public String Data;    
    public static String getAcessCode(){
        Integration__c data = Integration__c.getInstance('NFe GET');
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

    public NotaPdfController(ApexPages.StandardController stdController) {
        
        Id notasIdPgReference = Id.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('Id').escapeHtml4()));
        NotaFiscal__c notaFiscal = [SELECT Id, AccessKey__c FROM NotaFiscal__c WHERE Id =: notasIdPgReference LIMIT 1];
        
        this.accessKey = notaFiscal.AccessKey__c;
        System.debug('accessKey ' + accessKey);
        String code = (!Test.isRunningTest() ? getAcessCode() : 'acessToken');
        String accessToken = code;
        
        System.debug('code' + code);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Integration__c integrationOUT = Integration__c.getInstance('NFe GET');
        String endpoint = (!Test.isRunningTest() ? integrationOUT.Url__c+accessKey : 'http://callout.My_Named_Credential.com/some/path');
        System.debug('endpoint ' + endpoint);
        //request.setEndpoint('https://apim.agrogalaxy.com.br/gtw/app-invoice/v1/invoices-xml?chave_acesso='+accessKey);
        //request.setMethod('GET');
        
        Map<String, String> headersMap = new Map<String, String>();
        //headersMap.put('Content-type', 'application/json');
        headersMap.put('Authorization', 'Bearer '+ accessToken);
        
        IntegrationUtils.RequestResponseObject responseCallout = IntegrationUtils.executeCalloutGet(endpoint,null,headersMap);
        System.debug('setEndpoint ' + request);
        System.debug('setEndpoint ' + responseCallout);
        System.debug('responseCallout' + responseCallout);
        // If the request is successful, parse the JSON response.
        if(responseCallout.response.getStatusCode() == 200) {
        // Deserialize the JSON string into collections of primitive data types.
        HttpResponse response = responseCallout.response;
        System.debug('getBody' + response.getBody());
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Data = (String)results.get('data');
        
        System.debug('Data ' + Data);
        //Map<String, ResponseParameters> results = (Map<String, ResponseParameters>) JSON.deserialize(response.getBody(), Map<String, ResponseParameters>.class);
        // Cast the values in the 'animals' key as a list
        System.debug('results' + results);
        
            /*
        for(ResponseParameters base: results.values()) {
                base64 = base.data;
                System.debug('base 64 ' + base64);
            }
            */
        }
    } 
    
    public class ResponseParameters {
        
        public String data;

    }
}