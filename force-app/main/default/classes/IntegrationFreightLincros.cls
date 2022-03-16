public with sharing class IntegrationFreightLincros {
    public IntegrationFreightLincros() {

    }

    public static String AuthLincros(){
        HttpRequest request = new HttpRequest();
		request.setEndpoint('https://homolog.transpofrete.com.br/api/auth/login');
        String payload = '{'+
		'  "login": "",'+
		'  "senha": ""'+
		'}';
		request.setMethod('POST');
        request.setBody(payload);
		Http sendRequest = new Http();
	    HttpResponse response  =  sendRequest.send(request);
		AuthResult authResult = (AuthResult)JSON.deserialize(response.getBody(), AuthResult.class);
		return authResult.access_token;
    }

    public class AuthResult{
        public String access_token;
    }

    private HttpRequest makeRequest(String data){
        //Instancia de um HTTP request
        HttpRequest request = new HttpRequest();

        //Conversão dos dados para JSON
        RequestParameters conversion = (RequestParameters) JSON.deserialize(data, RequestParameters.class);
        String payload = JSON.serialize(conversion);

        //Parte efetiva de montagem na estrutura do request
		request.setEndpoint('https://homolog.transpofrete.com.br/api/calculo/calcularNota');
		request.setMethod('POST');
        request.setTimeout(110000);
        request.setBody(payload);
        String accessToken = AuthLincros();
        
        Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', accessToken);

        if (headersMap != null && headersMap.size() > 0){
            for (String headerKey : headersMap.keySet()){
                request.setHeader(headerKey, headersMap.get(headerKey));
            }
        }

        return request;
    }

    private Response sendRequest(HttpRequest request){
        response = (new Http()).send(request);
    }

    private Boolean validateResponse(HttpResponse response){
        
    }

    @AuraEnabled
    public static Decimal getFreight(String data){
        
      
        data = '{'+
		'  "destinatario": "36064352000158",'+
		'  "remetente": "26143384000195",'+
        '  "cepOrigem": "09981123",'+
        '  "cepDestino": "69088254"'+
		'}';

       
       
        HttpRequest request = makeRequest();

        HttpResponse response;
       


        if(response.getStatus() == '200'){
            System.debug(response.getBody());
            Response responseRequest = (Response) JSON.deserialize(response.getBody(), Response.class);
            return responseRequest; 
        }

        return 0.00;

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
        public String cepOrigem;
        public String cepDestino;
    }

    public class Response{

        List<ShippingCompany> transportadoras;
        public String status;
    }
}
