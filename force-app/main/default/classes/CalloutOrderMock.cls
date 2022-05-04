@isTest
public with sharing class CalloutOrderMock implements HttpCalloutMock {
    private final String body;
    private final Integer status;

    public CalloutOrderMock(Boolean isSuccess, String orderNumber) {
       if(isSuccess){
            status = 200;
            body = '[{"IV_TYPE":"C","IS_HEADER_IN":{"DOC_TYPE":"ZVNO","SALES_ORG":"1000","DISTR_CHAN":"10","DIVISION":"30",'
                        + '"REQ_DATE_H":"20220510","INCOTERMS1":"CIF","INCOTERMS2":"CIF","PMNTTRMS":"AVAT","PYMT_METH":"B",'
                        + '"CT_VALID_F":"","CT_VALID_T":"","ORD_REASON":"","PURCH_NO_C":"Teste Ordem de Venda","ZZSAFRA":"2022/2023",'
                        + '"ZZCOD_CULTURA":"001",'
                        + '"ZZPED_CRM":"123456",'
                        + '"ZZDATA_CARENCIA":"20220503",'
                        + '"ZZDATA_VENCTO":"20220530"'
                        + '},'
                        + '"IT_ITEMS_IN":['
                            + '{'
                                + '   "ITM_NUMBER":"000010",'
                                + '   "MATERIAL":"5000011",'
                                + ' "PLANT":"1001",'
                                + ' "TARGET_QTY":"11.00"'
                                + '},'
                                + '{'
                                    + '  "ITM_NUMBER":"000020",'
                                    + '  "MATERIAL":"5000011",'
                                    + '  "PLANT":"1001",'
                                    + '  "TARGET_QTY":"12.20"'
                                    + ' }'
                                    + '],'
                                    + ' "IT_CONDITIONS_IN":['
                                        + '{'
                        + '    "ITM_NUMBER":"000010",'
                        + '   "COND_TYPE":"",'
                        + '  "COND_VALUE":"",'
                        + '   "CURRENCY":"BRL"'
                        + ' },'
                        + ' {'
                            + '   "ITM_NUMBER":"000020",'
                            + '   "COND_TYPE":"",'
                            + '   "COND_VALUE":"",'
                            + '   "CURRENCY":"BRL"'
                            + ' }'
                            + '],'
                            + '"IT_ORDER_SCHEDULES_IN":['
                        + ' {'
                            + '  "ITM_NUMBER":"000010",'
                            + '  "REQ_DATE":"20220610",'
                            + '  "REQ_QTY":"11.02"'
                            + '},'
                     + '{'
                        + ' "ITM_NUMBER":"000020",'
                        + ' "REQ_DATE":"20220710",'
                        + ' "REQ_QTY":"12.30"'
                        + ' }'
                        + ' ],'
                        + '  "IT_PARTNERS":['
                        + '   {'
                            + '    "PARTN_ROLE":"AG",'
                            + '    "PARTN_NUMB":"1000010"'
                            + ' },'
                            + ' {'
                                + '    "PARTN_ROLE":"RM",'
                                + '    "PARTN_NUMB":"1000010"'
                                + ' }'
                                + ' ]'
                                + ' } ]   ';
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
