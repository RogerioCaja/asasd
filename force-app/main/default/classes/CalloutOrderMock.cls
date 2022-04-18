@isTest
public with sharing class CalloutOrderMock implements HttpCalloutMock {
    private final String body;
    private final Integer status;

    public CalloutOrderMock(Boolean isSuccess, Boolean isTimeout, String orderNumber) {
        if(isSuccess) {
            status = 200;
            body ='{"NumeroOrdemVenda":"0010000027","OrderNumber":"' + orderNumber + '"}';
        } else if(isTimeout) {
            status = 504;
            body = 'Timeout Test';
        } else {
            status = 200;
            body = '{"OrderNumber":"'+ orderNumber +'","Mensagens":[{"Tipo":"W","Mensagem":"O pedido '+orderNumber+' já foi integrado. Ordem de venda N. 0010000027"}]}';
        }
    }
    
    public String getExternalId() {
        return '0010000027';
    }
    
    public String getBody() {
        return this.body;
    }
    
    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(status);
		response.setBody(body);
        return response;
    }
}
