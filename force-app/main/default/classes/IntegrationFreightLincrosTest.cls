@isTest
public with sharing class IntegrationFreightLincrosTest {
    public IntegrationFreightLincrosTest() {

    }

    @isTest 
    static void testCallout() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        HttpResponse res = CalloutClass.getInfoFromExternalService();
        
        // Verify response received contains fake values
        String contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        String actualValue = res.getBody();
        String expectedValue = '{'+
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
    '}';
        System.assertEquals(actualValue, expectedValue);
        System.assertEquals(200, res.getStatusCode());
    }
}
