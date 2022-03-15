public with sharing class IntegrationFreightLincros {
    public IntegrationFreightLincros() {

    }

    public static String AuthLincros(){
        HttpRequest request = new HttpRequest();
		request.setEndpoint('https://homolog.transpofrete.com.br/api/auth/login');
		request.setMethod('POST');
        String payload = 'jurema';
        request.setBody(payload);
		Http sendRequest = new Http();
	    HttpResponse response  =  sendRequest.send(request);
		AuthResult authResult = (AuthResult)JSON.deserialize(response.getBody(), AuthResult.class);
		return authResult.access_token;
    }

    public class AuthResult{
        public String access_token;
    }

    public class Login{
        public String login;
        public String password;
    }

    @AuraEnabled
    public static Decimal Response(String data){
        HttpRequest request = new HttpRequest();

		request.setEndpoint('https://homolog.transpofrete.com.br/api/calculo/calcularNota');
		request.setMethod('POST');
        request.setTimeout(110000);
        String accessToken = AuthLincros();
        Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', 'Bearer ' + accessToken);

        if (headersMap != null && headersMap.size() > 0){
            for (String headerKey : headersMap.keySet()){
                request.setHeader(headerKey, headersMap.get(headerKey));
            }
        }
        RequestParameters payload = (RequestParameters) JSON.deserialize(data, RequestParameters.class);
        System.debug(payload);
        HttpResponse response;
        response = (new Http()).send(request);


        if(response.getStatus() == '200'){
            System.debug(response.getBody());
            Response responseRequest = (Response) JSON.deserialize(response.getBody(), Response.class);
            return responseRequest.transportadoras[0].valor; 
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
