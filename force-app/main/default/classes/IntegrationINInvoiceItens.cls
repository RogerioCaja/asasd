global with sharing class IntegrationINInvoiceItens {
    public IntegrationINInvoiceItens() {

    }
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertInvoiceItens(List<TemplateDataIntegrationFields.ItensNotaFiscalINData> request) {
        // Guarda as relações de order e product de preço com OrderItem
        Map<String, Id> lookups = new Map<String, Id>();

        //Set<String> orderLookups = new Set<String>();
        Set<String> productLookups = new Set<String>();
        Set<String> invoiceLookups = new Set<String>();
        // Guarda um mapa com uma lista de respostas
        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // Guarda uma lista com os OrderItem para fazer o upsert
        List<ItensNotaFiscal__c> invoiceItensListToUpsert = new List<ItensNotaFiscal__c>();

        //Application of business rules
        for(TemplateDataIntegrationFields.ItensNotaFiscalINData itensNotaFiscal : request){

            // Pega a relação do OrderItem com Order
            //Getting order parameters to search
            //orderLookups.add(OrderItemINData.orderExternalId);

            // Pega a relação do Product com o OrderItem
            //Getting product parameters to search
            productLookups.add(itensNotaFiscal.codigoMaterial);
            invoiceLookups.add(itensNotaFiscal.notaFiscal);
        }

        // Pega o produto com base no ExternalID recebido
        //Product2 search based on ExternalId__c field sent
        for (Product2 product : [SELECT Id,ProductCode FROM Product2 WHERE ProductCode IN: productLookups ]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Product2' + product.ProductCode, product.Id);
        }
        for (NotaFiscal__c invoice : [SELECT Id, invoiceNumber__c, ExternalID__c FROM NotaFiscal__c WHERE invoiceNumber__c IN: invoiceLookups]){
          lookups.put('NotaFiscal__c' + invoice.invoiceNumber__c, invoice.Id);
        }
        // Pega o pedido com base no ExternalId recebido
        //Order search based on ExternalId__c field sent

        // Associa as respostas do OrderItem com Order
        //OrderItem ExternalId Map to Order ExternalId for association of responses
        Map<String, String> parentMapKeys = new Map<String, String>();
        
        for(TemplateDataIntegrationFields.ItensNotaFiscalINData invoiceItem : request) {
            // como estava = parentMapKeys.put(ORDEREXTERNALID + '|' + ORDERITEMEXTERNALID, lookups.containsKey('Order'+ORDEREXTERNALID) ? lookups.get('Order'+ORDEREXTERNALID) : ORDEREXTERNALID);
            //parentMapKeys.put(invoiceItem.nfExternalId + '|' + invoiceItem.notaFiscal, lookups.containsKey('NotaFiscal__c'+invoiceItem.nfExternalId) ? String.valueOf(lookups.get('NotaFiscal__c'+invoiceItem.nfExternalId)) : invoiceItem.nfExternalId);
        }
        
        // Valida e adiciona os OrderItem na lista para o upsert
        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObjectChild(
            new ItensNotaFiscal__c(), 
            'IN', 
            request, 
            responseMap, 
            invoiceItensListToUpsert, 
            lookups, 
            parentMapKeys
        );

        //Upserting records
        List<Database.UpsertResult> upsResults = Database.upsert(invoiceItensListToUpsert, ItensNotaFiscal__c.ExternalID__c, false);

        IntegrationUtils.upsertChildRecords(upsResults, responseMap, invoiceItensListToUpsert, ItensNotaFiscal__c.ExternalID__c); 
        system.debug('invoiceItensListToUpsert' + invoiceItensListToUpsert);
        system.debug('ItensNotaFiscal__c.ExternalID__c' + ItensNotaFiscal__c.ExternalID__c);
        //Returning response
        return responseMap;
    }
}
