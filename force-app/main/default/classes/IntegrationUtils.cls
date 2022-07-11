public class IntegrationUtils {
    
    //String check
    public static Boolean convertEmptyString(String str) {
        return ((String.isBlank(str) || str == 'null' || str == null || str == '') ? true : false); 
    }
    
    //Records upsert validation, adding results to the response list
    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, List<TemplateDataIntegrationFields.ResponseParent> responseList, List<SObject> sObjectListToUpsert, Schema.SObjectField field){
        TemplateDataIntegrationFields.ResponseParent responseData;
        Boolean hasError = false;
        for (TemplateDataIntegrationFields.Response response : responseList) {
            if(response.status == false)
                hasError = true;                
        }

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new TemplateDataIntegrationFields.ResponseParent();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if (upsResult.isSuccess()) {
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            }
            else {
                responseData.error(
                    String.valueOf(objResult.get(field)),
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
                hasError = true;
            }
            responseList.add(responseData);
        }
        return hasError;
    }

    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, List<TemplateDataIntegrationFields.Response> responseList, List<SObject> sObjectListToUpsert, Schema.SObjectField field){
        TemplateDataIntegrationFields.Response responseData;
        Boolean hasError = false;

        for (TemplateDataIntegrationFields.Response response : responseList) {
            if(response.status == false)
				hasError = true;                
        }

        for (Integer i = 0; i < upsResults.size(); i++) {
            responseData = new TemplateDataIntegrationFields.Response();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if (upsResult.isSuccess()) {
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            }
            else {
                responseData.error(String.valueOf(objResult.get(field)),
                                   upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                                   String.valueOf(objResult.getSObjectType())
                );
                hasError = true;
            }
            responseList.add(responseData);
        }
        return hasError;
    }

    //Child records upsert validation, adding results to the response list
    public static void upsertChildRecords(List<Database.UpsertResult> upsResults, Map<String, List<TemplateDataIntegrationFields.Response>> responseMap, List<SObject> sObjectListToUpsert, Schema.SObjectField field){
        TemplateDataIntegrationFields.Response responseData;

        System.debug('upsResults=>'+upsResults);

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new TemplateDataIntegrationFields.Response();

            SObject objResult = sObjectListToUpsert[i];

            Database.UpsertResult upsResult = upsResults[i];
            
            if(upsResult.isSuccess()){
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                ); 
            }
            else {
                responseData.error(
                    String.valueOf(objResult.get(field)), 
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
            }
            
            //Associating child object's response with object response
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if (objResult.getSObjectType() == globalDescribe.get('PricebookEntry')) {
                PricebookEntry aux = (PricebookEntry)objResult;
                if(responseMap.keySet().contains(aux.Pricebook2Id)){
                    responseMap.get(aux.Pricebook2Id).add(responseData);
                }
                else{
                    responseMap.put(aux.Pricebook2Id, new List<TemplateDataIntegrationFields.Response>{responseData});
                }
            }

            if (objResult.getSObjectType() == globalDescribe.get('OrderItem')) {
                OrderItem aux = (OrderItem)objResult;
                if(responseMap.keySet().contains(aux.OrderId)){
                    responseMap.get(aux.OrderId).add(responseData);
                }
                else{
                    responseMap.put(aux.OrderId, new List<TemplateDataIntegrationFields.Response>{responseData});
                }
            }

            if (objResult.getSObjectType() == globalDescribe.get('ShippingDivison__c')) {
                ShippingDivison__c aux = (ShippingDivison__c)objResult;
                if(responseMap.keySet().contains(aux.OrderItem__c)){
                    responseMap.get(aux.OrderItem__c).add(responseData);
                }
                else{
                    responseMap.put(aux.OrderItem__c, new List<TemplateDataIntegrationFields.Response>{responseData});
                }
            }

            if (objResult.getSObjectType() == globalDescribe.get('ItensNotaFiscal__c')){
                ItensNotaFiscal__c aux = (ItensNotaFiscal__c)objResult;
                if(responseMap.KeySet().contains(aux.Invoice__c)){
                    responseMap.get(aux.Invoice__c).add(responseData);
                }
                else{
                    responseMap.put(aux.Invoice__c, new List<TemplateDataINtegrationFields.Response>{responseData});
                }
            }
        }
    }
    
    public static Boolean SYSTEM_DEBUG_ENABLED   = true;

    // Standard Http Request response
    public class RequestResponseObject {
        // Response object, in case the callout was successful.
        public HttpResponse response;
        // Boolean that determines if there is an exception or a HttpResponse.
        public Boolean success;
        // Exception object, in case there is any.
        public Exception exceptionObject;

        public RequestResponseObject(HttpResponse response){
            this.success = true;
            this.response = response;
            this.exceptionObject = null;
        }

        public RequestResponseObject(Exception ex){
            this.success = false;
            this.response = null;
            this.exceptionObject = ex;
        }
    }

    
    // CALLOUT STANDARD RESPONSE OUTTER CLASS
    public class CalloutResponse{
        public CalloutOrder.ResponseParameters parsedResponse;
        public Boolean success;
        public String errorMessage;

        public CalloutResponse(CalloutOrder.ResponseParameters response){
            this.success = true;
            this.errorMessage = '';
            this.parsedResponse = response;
        }

        public CalloutResponse(String errorMessage){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = null;
        }

        public CalloutResponse(String errorMessage, CalloutOrder.ResponseParameters response){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = response;
        }
    }

    public class CalloutUpdateResponse{
        public CalloutOrderUpdate.ResponseParameters parsedResponse;
        public Boolean success;
        public String errorMessage;

        public CalloutUpdateResponse(CalloutOrderUpdate.ResponseParameters response){
            this.success = true;
            this.errorMessage = '';
            this.parsedResponse = response;
        }

        public CalloutUpdateResponse(String errorMessage){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = null;
        }

        public CalloutUpdateResponse(String errorMessage, CalloutOrderUpdate.ResponseParameters response){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = response;
        }
    }
    // CALLOUT STANDARD RESPONSE OUTTER CLASS
    public class CalloutBpResponse{
        public CalloutBP.ResponseParameters parsedResponse;
        public Boolean success;
        public String errorMessage;

        public CalloutBpResponse(CalloutBP.ResponseParameters response){
            this.success = true;
            this.errorMessage = '';
            this.parsedResponse = response;
        }

        public CalloutBpResponse(String errorMessage){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = null;
        }

        public CalloutBpResponse(String errorMessage, CalloutBP.ResponseParameters response){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = response;
        }
    }

    // CALLOUT STANDARD RESPONSE OUTTER CLASS
    public class CalloutCTVResponse{
        public CalloutCTVCarteira.ResponseParameters parsedResponse;
        public Boolean success;
        public String errorMessage;

        public CalloutCTVResponse(CalloutCTVCarteira.ResponseParameters response){
            this.success = true;
            this.errorMessage = '';
            this.parsedResponse = response;
        }

        public CalloutCTVResponse(String errorMessage){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = null;
        }

        public CalloutCTVResponse(String errorMessage, CalloutCTVCarteira.ResponseParameters response){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = response;
        }
    }

    public class CalloutDatalakeResponse{
        public CalloutOrderDatalake.ResponseParameters parsedResponse;
        public Boolean success;
        public String errorMessage;

        public CalloutDatalakeResponse(CalloutOrderDatalake.ResponseParameters response){
            this.success = true;
            this.errorMessage = errorMessage;
            this.parsedResponse = response;
        }
        
        public CalloutDatalakeResponse(String errorMessage){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = null;
        }

        public CalloutDatalakeResponse(String errorMessage, CalloutOrderDatalake.ResponseParameters response){
            this.success = false;
            this.errorMessage = errorMessage;
            this.parsedResponse = response;
        }
    }
    // CALLOUT PARSING INNER INTERFACE
    public interface CalloutResponseParsedData{}

    public static RequestResponseObject executeCallout(String namedCredential, String payload, Map<String, String> requestHeaders){
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        // Timeout reduced in 10000 miliseconds in order to avoid timeouts in invoke actions through javascript.
        request.setTimeout(110000);
        request.setEndpoint(namedCredential);
        request.setBody(payload);

        
        if (requestHeaders != null && requestHeaders.size() > 0){
            for (String headerKey : requestHeaders.keySet()){
                request.setHeader(headerKey, requestHeaders.get(headerKey));
            }
        }

        Long microtime = (Datetime.now()).getTime();
        if (SYSTEM_DEBUG_ENABLED){
            System.debug('EXECUTING WITH NAMED CREDENTIAL: '+namedCredential);
            System.debug('METHOD USED: '+request.getMethod());
            System.debug('SENT PAYLOAD: '+payload);
            System.debug('SENT HEADERS: '+JSON.serializePretty(requestHeaders));
        }

        HttpResponse response;
        try {
            response = (new Http()).send(request);

            if (SYSTEM_DEBUG_ENABLED){
                System.debug('RESPONSE IN '+((Datetime.now()).getTime() - microtime));
                System.debug('RESPONSE STATUS: '+response.getStatus()+' - '+String.valueOf(response.getStatusCode()));
                for (String headerKey : response.getHeaderKeys()){
                    if (String.isNotBlank(headerKey)) System.debug('HEADER KEY: '+headerKey+' | VALUE: '+response.getHeader(headerKey));
                }

                System.debug('RESPONSE BODY: '+response.getBody());
            }

            return new RequestResponseObject(response);
        } catch (Exception ex) {
            if (SYSTEM_DEBUG_ENABLED) System.debug('CALLOUT EXCEPTION: '+ex.getMessage());

            return new RequestResponseObject(ex);
        }
    }
    public static RequestResponseObject executeCalloutGet(String namedCredential, String payload, Map<String, String> requestHeaders){
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        // Timeout reduced in 10000 miliseconds in order to avoid timeouts in invoke actions through javascript.
        request.setTimeout(110000);
        request.setEndpoint(namedCredential);
        request.setBody(payload);

        
        if (requestHeaders != null && requestHeaders.size() > 0){
            for (String headerKey : requestHeaders.keySet()){
                request.setHeader(headerKey, requestHeaders.get(headerKey));
            }
        }

        Long microtime = (Datetime.now()).getTime();
        if (SYSTEM_DEBUG_ENABLED){
            System.debug('EXECUTING WITH NAMED CREDENTIAL: '+namedCredential);
            System.debug('METHOD USED: '+request.getMethod());
            System.debug('SENT PAYLOAD: '+payload);
            System.debug('SENT HEADERS: '+JSON.serializePretty(requestHeaders));
        }

        HttpResponse response;
        try {
            response = (new Http()).send(request);

            if (SYSTEM_DEBUG_ENABLED){
                System.debug('RESPONSE IN '+((Datetime.now()).getTime() - microtime));
                System.debug('RESPONSE STATUS: '+response.getStatus()+' - '+String.valueOf(response.getStatusCode()));
                for (String headerKey : response.getHeaderKeys()){
                    if (String.isNotBlank(headerKey)) System.debug('HEADER KEY: '+headerKey+' | VALUE: '+response.getHeader(headerKey));
                }

                System.debug('RESPONSE BODY: '+response.getBody());
            }

            return new RequestResponseObject(response);
        } catch (Exception ex) {
            if (SYSTEM_DEBUG_ENABLED) System.debug('CALLOUT EXCEPTION: '+ex.getMessage());

            return new RequestResponseObject(ex);
        }
    }
    public static void setLookup(SObject obj, Set<String> fieldSet, String fieldKey, List<String> objLookups,  Map<String, Id> lookups){

        String query = new Q(obj.getSObjectType()).selectFields(fieldSet).add(Q.condition(fieldKey).isIn(objLookups)).build();

        List<SObject> objectList = Database.query(query);

        for(Integer i = 0; i < objectList.size(); i++){
            lookups.put(objectList[i].getSObjectType().getDescribe().getName() + objectList[i].get(fieldKey), objectList[i].Id);
        }
    }
}