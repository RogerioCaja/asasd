@RestResource(urlMapping='/upsertInvoice/*')
global with sharing class IntegrationINInvoice {
    public IntegrationINInvoice() {

    }
    @HttpPost
    global static ResponseModel upsertInvoice(List<TemplateDataIntegrationFields.NotaFiscalINData> request) {
        // Guarda a relação da conta com o pedido
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> accountLookups = new Set<String>();
        Set<String> orderLookups = new Set<String>();
        Set<String> companyLookups = new Set<String>();
        Set<String> receiverLookups = new Set<String>();
        

    
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        //List<TemplateDataINtegrationFields.Product2INData> productListToUpsert = new List<TemplateDataINtegrationFields.Product2INData>();
        List<NotaFiscal__c> notaFiscalListToUpsert = new List<NotaFiscal__c>();
        
        
        //Application of business rules
        for (TemplateDataIntegrationFields.NotaFiscalINData invoice : request){
            // Pega a relação da conta com o pedido
            //Getting account parameters to search
            accountLookups.add(invoice.cliente);
            orderLookups.add(invoice.cpfCnpjCliente);
            companyLookups.add(invoice.codigoEmpresa);
            receiverLookups.add(invoice.propriedade);
        }
        
        // Pega o Id da conta com base no CNPJ da conta
        //Account search based on CNPJ field sent
        for (Account account : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : receiverLookups]) {
            lookups.put('Account' + account.ExternalId__c, account.Id);
        }
        for (Account account : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : accountLookups]) {
            lookups.put('Account' + account.ExternalId__c, account.Id);
        }
        for (Order order : [SELECT Id, CodigoSap__c FROM Order WHERE  CodigoSap__c IN : orderLookups]){
            lookups.put('Order' + order.CodigoSap__c, order.Id);
        }

        for (SalesOrg__c salesOrg : [SELECT Id, SalesOrganizationCode__c FROM SalesOrg__c  WHERE  SalesOrganizationCode__c IN : companyLookups]){
            lookups.put('SalesOrg__c' + salesOrg.SalesOrganizationCode__c, salesOrg.Id);
        }
       

        
        //Converting template to object list and validating required fields
        // Valida e adiciona objeto na lista para upsert
        FactoryDataIntegration.convertSObject(new NotaFiscal__c(), 'IN', request, responseList, notaFiscalListToUpsert, lookups);
          
        //Upserting records (Product)
		IntegrationUtils.upsertRecords(
            Database.upsert(notaFiscalListToUpsert, NotaFiscal__c.Name, false), 
            responseList, 
            notaFiscalListToUpsert, 
            NotaFiscal__c.Name
        );
        
        //Upserting records (OrderItem)
        // Upsert OrderItem
        /*
        Map<String, List<TemplateDataIntegrationFields.Response>> orderItemsResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(orderItemListToUpsert.size() != 0){
            orderItemsResponse.putAll(
                IntegrationInboundOrderItem.upsertOrderItem(orderItemListToUpsert)
            );
        }

        //Associating child object's response with object response
        // Pega todas as respostas dos OrderItem
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            response.items = new List<TemplateDataIntegrationFields.Response>();
            if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.idSalesforce)){
                response.items.addAll(orderItemsResponse.get(response.idSalesforce));
            } 
            else if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.externalCode)){
                response.items.addAll(orderItemsResponse.get(response.externalCode));
            }
        }
*/
        //Checking integration errors to log
        // Verifica erros de integração para o log
        Boolean hasError = false;

        for(TemplateDataIntegrationFields.ResponseParent responseProduct : responseList){
            if(responseProduct.status == false){
                hasError = true;
                break;
            } /*else {
                for(TemplateDataIntegrationFields.Response response : responseProduct.items){
                    if(response.status == false){
                        hasError = true;
                        break;
                    }
                }
            }
            */
        }
		
        //Creating integration log
        IntegrationLog.createLog('Nota Fiscal', 'Inbound', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
        //Returning response
         // Retorna a resposta Outbound
        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }
    // Classe que cria a resposta
    global class ResponseModel {

        List<TemplateDataIntegrationFields.ResponseParent> response;

        public ResponseModel(List<TemplateDataIntegrationFields.ResponseParent> response) {

            this.response = response;
            
        }
        public ResponseModel() {   
            this.response = new List<TemplateDataIntegrationFields.ResponseParent>();         
        }
    }
}
