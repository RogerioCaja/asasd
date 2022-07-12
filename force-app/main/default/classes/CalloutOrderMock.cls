@isTest
public with sharing class CalloutOrderMock implements HttpCalloutMock {
    private final String body;
    private final Integer status;

    public CalloutOrderMock(Boolean isSuccess, String orderNumber, Boolean isAccessToken) {
       if(isSuccess && !isAccessToken){
            status = 200;
            body = '{' 
                +'"ET_RETURN": {'
                +'"item": ['
                    +'   {'
                    +'        "TYPE": "S",'
                    +'        "CODE": "V4233",'
                    +'        "MESSAGE": "SALES_HEADER_IN has been processed successfully",'
                    +'        "LOG_NO": "",'
                    +'        "LOG_MSG_NO": "000000",'
                    +'        "MESSAGE_V1": "VBAKKOM",'
                    +'        "MESSAGE_V2": "10.05.2022",'
                    +'        "MESSAGE_V3": "10:18:25",'
                    +'        "MESSAGE_V4": ""'
                    +'    },'
                    +'    {'
                    +'        "TYPE": "S",'
                    +'        "CODE": "V4233",'
                    +'        "MESSAGE": "SALES_ITEM_IN has been processed successfully",'
                    +'        "LOG_NO": "",'
                    +'        "LOG_MSG_NO": "000000",'
                    +'        "MESSAGE_V1": "VBAPKOM",'
                    +'        "MESSAGE_V2": "000010",'
                    +'        "MESSAGE_V3": "",'
                    +'        "MESSAGE_V4": ""'
                    +'    },'
                    +'    {'
                    +'        "TYPE": "S",'
                    +'        "CODE": "V4233",'
                    +'        "MESSAGE": "SALES_ITEM_IN has been processed successfully",'
                    +'        "LOG_NO": "",'
                    +'        "LOG_MSG_NO": "000000",'
                    +'        "MESSAGE_V1": "VBAPKOM",'
                    +'        "MESSAGE_V2": "000020",'
                    +'        "MESSAGE_V3": "",'
                    +'        "MESSAGE_V4": ""'
                    +'    },'
                    +'    {'
                    +'        "TYPE": "S",'
                    +'        "CODE": "V4233",'
                    +'        "MESSAGE": "SALES_CONDITIONS_IN has been processed successfully",'
                    +'        "LOG_NO": "",'
                    +'        "LOG_MSG_NO": "000000",'
                    +'        "MESSAGE_V1": "KONVKOM",'
                    +'        "MESSAGE_V2": "",'
                    +'        "MESSAGE_V3": "",'
                    +'        "MESSAGE_V4": ""'
                    +'    },'
                    +'    {'
                    +'        "TYPE": "S",'
                    +'        "CODE": "V4233",'
                    +'        "MESSAGE": "SALES_CONDITIONS_IN has been processed successfully",'
                    +'        "LOG_NO": "",'
                    +'        "LOG_MSG_NO": "000000",'
                    +'        "MESSAGE_V1": "KONVKOM",'
                    +'        "MESSAGE_V2": "",'
                    +'        "MESSAGE_V3": "",'
                    +'        "MESSAGE_V4": ""'
                    +'    },'
                    +'    {'
                    +'        "TYPE": "S",'
                    +'        "CODE": "V1311",'
                    +'        "MESSAGE": "Standard Order BR 342 has been saved.",'
                    +'        "LOG_NO": "",'
                    +'        "LOG_MSG_NO": "000000",'
                    +'        "MESSAGE_V1": "Standard Order BR",'
                    +'        "MESSAGE_V2": "342",'
                    +'        "MESSAGE_V3": "",'
                    +'        "MESSAGE_V4": ""'
                    +'    }'
                    +']'
                    +'},'
                    +'"EV_SALES_DOC": "0000000342"'
                    +'}';
       }
       else if(isAccessToken){
            status = 200;
            body = '{"access_token" : "fdgfdbvkhjfdv"}';
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
