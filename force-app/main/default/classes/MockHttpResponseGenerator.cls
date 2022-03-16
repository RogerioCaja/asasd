@isTest
global with sharing class MockHttpResponseGenerator implements HttpCalloutMock {
    global Boolean fail;
    global MockHttpResponseGenerator(Boolean fail) {
        this.fail = fail;
    }

    global HTTPResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        if (req.getEndpoint().endsWith('login')) {
            System.assertEquals('https://homolog.transpofrete.com.br/api/auth/login', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());

            res.setBody('{"accessToken": "kjhvngbjfggfb"}');
           
        } else if (req.getEndpoint().endsWith('calcularNota')) {
            System.assertEquals('https://homolog.transpofrete.com.br/api/calculo/calcularNota', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());

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
        }
        
        
        // Create a fake response
        if(fail == true) res.setStatusCode(400);
        else res.setStatusCode(200);
        return res;
    } 
}