public with sharing class CalloutBP {

    public static IntegrationUtils.CalloutBpResponse processIntegration(){

        IntegrationUtils.CalloutBpResponse calloutBpResponse = sendOrder();

        if (calloutBpResponse.success) {
            System.debug('integração foi um sucesso');

        }
        
        return calloutBpResponse;
    }

    public static IntegrationUtils.CalloutBpResponse sendOrder() {

        List<RequestParameters> request = new List<RequestParameters>();
        
        request.add(new RequestParameters());
        System.debug('request: '+ request);
        
        String code = (!Test.isRunningTest() ? getAcessCode() : 'acessToken');
        System.debug('AcessCode: '+ code);
        String payload = JSON.serialize(request);
        System.debug('PayloadCheck: '+ payload);
        //Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
        String accessToken = code;//! FALTA SABER A RESPOSTA DO SAP QUANTO A AUTENTICAÇÃO! F
        //Url mock: https://aabb2740-69b0-4737-925c-2c40367a3737.mock.pstmn.io//CalloutBP
        //Path geralmente cadastrado dentro de ua customSettings 
        String endpoint = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/gtw/sales-territory/v1/webhook/_notify' : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-type', 'application/json');
        headersMap.put('Authorization', 'Bearer '+ accessToken);
        
        IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap);

        if (responseObject.success) {

            HttpResponse response = responseObject.response;

            IntegrationLog.createLog('Pedido OUT', 'OUT', response.getBody(), payload, false);
            // .WSLog('Pedido', 'OUTBOUND', response.getBody(), payload, false);
            System.debug('response.getBody(): '+ response.getBody());
            try {
                
                List<ResponseParametersWrapper> responses = (List<ResponseParametersWrapper>) JSON.deserialize(response.getBody(), List<ResponseParametersWrapper>.class);
                return new IntegrationUtils.CalloutBpResponse(new ResponseParameters(responses));
            } catch (Exception e) {
                
                String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

                return new IntegrationUtils.CalloutBpResponse(defaultErrorMessage);
            }
        } else {

            IntegrationLog.createLog('Pedido OUT', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
            return new IntegrationUtils.CalloutBpResponse(responseObject.exceptionObject.getMessage());
        }
    }
    public static String getAcessCode(){
        String payloadToken = 'grant_type=client_credentials';
        String endpointToken = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/identityserver/oauth2/token' : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMapToken = new Map<String, String>();
        headersMapToken.put('Content-type', 'application/x-www-form-urlencoded');
        headersMapToken.put('Authorization', 'Basic dEQxV2M0bWtXdnRWNWVtRXZSOHlVRF9iUFZvYTpmZmVJQUs5SmdPNXNsbXI1UzVMUXNNcTBOME1h');
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
        public Datetime Tempo;

        public RequestParameters(){
            DateTime now = DateTime.now();
            this.Tempo = now;
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
