@isTest
public with sharing class IntegrationFreightLincrosTest {
    public IntegrationFreightLincrosTest() {

    }

    @isTest 
    static void testCalloutSuccess() {
        IntegrationFreightLincros a = new IntegrationFreightLincros();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
        
        String data = '{'+
		'  "destinatario": "36064352000158",'+
		'  "remetente": "26143384000195",'+
        '  "cepOrigem": "09981123",'+
        '  "cepDestino": "69088254"'+
		'}';
   
        String res = IntegrationFreightLincros.getFreight(data);
        
      
       
        String actualValue = res;
        IntegrationFreightLincros.Response response = new IntegrationFreightLincros.Response();
        IntegrationFreightLincros.ShippingCompany shipping = new IntegrationFreightLincros.ShippingCompany();
        IntegrationFreightLincros.Table table = new IntegrationFreightLincros.Table();
        table.codigo = 0;
        table.nome = 'string';
        shipping.prazoCliente = 'string';
        shipping.PrevisaoEntrega = 'string';
        shipping.peso = 0;
        shipping.valor = 0;
        shipping.nome = 'string';
        shipping.cnpj = 'string';
        shipping.valorCliente = 'string';
        shipping.status = 'string';
        shipping.tabela = table;
        shipping.diasEntrega = 0;
        shipping.possuiIntrucoesEntrega = 'string';
        shipping.modal = 'string';
        shipping.tipoConhecimento = 0;

        response.transportadoras = new List<IntegrationFreightLincros.ShippingCompany>{shipping};
        response.status = 'string';

        String expectedValue = JSON.serializePretty(response);
        System.assertEquals(actualValue, expectedValue);
      
    }

    @isTest 
    static void testCalloutFailed() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        
        String data = '{'+
		'  "destinatario": "36064352000158",'+
		'  "remetente": "26143384000195",'+
        '  "cepOrigem": "09981123",'+
        '  "cepDestino": "69088254"'+
		'}';
     
        String res = IntegrationFreightLincros.getFreight(data);
        
       
        String actualValue = res;
        String expectedValue = JSON.serializePretty(new IntegrationFreightLincros.Response());
        System.assertEquals(actualValue, expectedValue);
      
    }
}
