@isTest
public with sharing class MockHttpResponseGenerator implements HttpCalloutMock {
    public MockHttpResponseGenerator() {

    }

    global HTTPResponse respond(HTTPRequest req) {
       
        System.assertEquals('https://homolog.transpofrete.com.br/api/calculo/calcularNota', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{'+
            '"transportadoras": ['+
              '{'+
              '  "prazoCliente": "string",'+
                '"PrevisaoEntrega": "string",'+
                '"peso": 0,'+
               ' "valor": 0,'+
               ' "nome": "string",'+
               ' "cnpj": "string",'+
               ' "valorCliente": "string",'+
               ' "status": "string",'+
               ' "tabela": {'+
             '     "codigo": 0,'+
                '  "nome": "string"'+
            '    },'+
              '  "diasEntrega": 0,'+
              '  "possuiIntrucoesEntrega": "string",'+
              '  "modal": "string",'+
               ' "tipoConhecimento": 0'+
             ' }'+
          '  ],'+
         '   "status": "string"'+
        '}');
        res.setStatusCode(200);
        return res;
    }
}
