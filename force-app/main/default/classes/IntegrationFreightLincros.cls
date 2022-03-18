public with sharing class IntegrationFreightLincros {
    public IntegrationFreightLincros() {}

    private static String authLincros(){
        String payload = '{'+
		'  "login": "",'+
		'  "senha": ""'+
		'}';

        HttpRequest request = new HttpRequest();
		request.setEndpoint('https://homolog.transpofrete.com.br/api/auth/login');
		request.setMethod('POST');
        request.setBody(payload);

	    HttpResponse response  =   (new Http()).send(request);
		AuthResult authResult = (AuthResult)JSON.deserialize(response.getBody(), AuthResult.class);
		return authResult.accessToken;
    }

    private static HttpRequest makeRequest(String data){
        //Instancia de um HTTP request
        HttpRequest request = new HttpRequest();

        //Conversão dos dados para JSON
        RequestParameters conversion = (RequestParameters) JSON.deserialize(data, RequestParameters.class);
        String payload = JSON.serialize(conversion);

        //Parte efetiva de montagem na estrutura do request
		request.setEndpoint('https://deployment.transpofrete.com.br/api/calculo/calcularNota');
		request.setMethod('POST');
        request.setTimeout(110000);
        request.setBody(payload);
       
        String ACCESS_TOKEN = AccessToken__c.getValues('token').Token__c;

        Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', 'Bearer' + ACCESS_TOKEN);

        if (headersMap != null && headersMap.size() > 0){
            for (String headerKey : headersMap.keySet()){
                request.setHeader(headerKey, headersMap.get(headerKey));
            }
        }

        System.debug(request.getBody());
        return request;
    }

    private static Response sendRequest(HttpRequest request){
        //Envio do Request
        HttpResponse response = (new Http()).send(request);

        // Verificação do status, se vier status positivo, montará a Response com dados
        // Senão retorna um Response vazio
        if(isValidResponse(response)){
            System.debug(response.getBody());
            Response responseRequest = (Response) JSON.deserialize(response.getBody(), Response.class);
            return responseRequest; 
        }
        else{
            return new Response();
        }
    }

    private static Boolean isValidResponse(HttpResponse response){
        if(response.getStatusCode()  == 200){
            return true;
        }
        return false;
    }

    @AuraEnabled
    public static String getFreight(String data){
        
        data = '{'+
		'  "destinatario": "36064352000158",'+
		'  "remetente": "26143384000195",'+
        '  "cepOrigem": 75800093,'+
        '  "cepDestino": 75800095'+
		'}';

       
        HttpRequest request = makeRequest(data);
        Response response = sendRequest(request);

        System.debug(JSON.serializePretty(response));
        return JSON.serializePretty(response);
    }

    public class ShippingCompany{

        public String prazoCliente;
        public String PrevisaoEntrega;
        public Decimal peso;
        public Decimal valor;
        public String nome;
        public String cnpj;
        public String valorCliente;
        public String status;
        public Table tabela;
        public Integer diasEntrega;
        public String possuiIntrucoesEntrega;
        public String modal;
        public Integer tipoConhecimento;
    }

    public class Table{

        public Integer codigo;
        public String nome;
    }

    public class RequestParameters{

        public String destinatario;
        public String remetente;
        public Integer cepOrigem;
        public Integer cepDestino;
    }

    public class Response{

        public List<ShippingCompany> transportadoras;
        public String status;
    }

    public class AuthResult{
        public String accessToken;
    }
}
