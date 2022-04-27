@isTest
public with sharing class CalloutCTVMock implements HttpCalloutMock {
    private final String body;
    private final Integer status;

    public CalloutCTVMock(Boolean isSuccess, String orderNumber) {
        if(isSuccess){
            status = 200;
            body = '[{ "OrderNumber":' + '"' +orderNumber+ '"' + ',"DetalhesPedido":[{"StatusSap": "Integrado","NumeroOrdemVenda" : "0001" }],"Mensagens":[{"Tipo": "S","Mensagem": "Teste" }] }]';
        }
        else{
            status = 400;
            body = '{ "OrderNumber":' +orderNumber+ ',"DetalhesPedido":[{"StatusSap": "Integrado","NumeroOrdemVenda" : "0001" }],"Mensagens":[{"Tipo": "S","Mensagem": "Teste" }] }';
        }
    }
    
    public String getExternalId() {
        return '00000101';
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
    