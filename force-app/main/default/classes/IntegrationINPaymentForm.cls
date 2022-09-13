global without sharing class IntegrationINPaymentForm {
    public IntegrationINPaymentForm() {

    }

    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertFormPayment(List<TemplateDataIntegrationFields.FormPaymentINData> request) {
        // Guarda as relações de order e product de preço com OrderItem
        Map<String, Id> lookups = new Map<String, Id>();
        Set<String> orderLookups = new Set<String>();
        // Guarda um mapa com uma lista de respostas
        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // Guarda uma lista com os OrderItem para fazer o upsert
        List<FormPayment__c> formPaymentListToUpsert = new List<FormPayment__c>();
        
        List<String> idsOrderItem = new List<String>();

        //Application of business rules
        for(TemplateDataIntegrationFields.FormPaymentINData PaymentFormINData : request) {

            orderLookups.add(PaymentFormINData.orderExternalId);
            idsOrderItem.add(PaymentFormINData.orderExternalId + '|' + PaymentFormINData.paymentItemCode);
            System.debug('idsOrderItem ' + idsOrderItem);
        }

        

        Map<String, FormPayment__c> formPaymentIdsMap = new Map<String, FormPayment__c>();
        List<FormPayment__c> formPaymentSelectList = new List<FormPayment__c>([SELECT Id FROM FormPayment__c WHERE ExternalId__c IN: idsOrderItem]);
    
        for(FormPayment__c formPayment : formPaymentSelectList){
            formPaymentIdsMap.put(formPayment.ExternalId__c, formPayment);
        }
        System.debug('formPaymentIdsMap ' + formPaymentIdsMap);
        for (TemplateDataIntegrationFields.FormPaymentINData formPay : request){
            
        }
        System.debug('orderLookups ' + orderLookups);
        for (Order order : [SELECT Id, NumeroPedidoApp__c FROM Order WHERE NumeroPedidoApp__c IN : orderLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Order' + order.NumeroPedidoApp__c, order.Id);
            System.debug('lookups ' + lookups);
        }

        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.FormPaymentINData formPaym : request) {
            parentMapKeys.put(formPaym.orderExternalId + '|' + formPaym.paymentItemCode, lookups.containsKey('Order'+formPaym.orderExternalId) ? String.valueOf(lookups.get('Order'+formPaym.orderExternalId)) : formPaym.orderExternalId);
            System.debug('parentMapKeys ' + parentMapKeys);
        }
        // Valida e adiciona os OrderItem na lista para o upsert
        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObjectChild(
            new FormPayment__c(), 
            'IN', 
            request, 
            responseMap, 
            formPaymentListToUpsert, 
            lookups, 
            parentMapKeys
        );
        System.debug('formPaymentListToUpsert ' + formPaymentListToUpsert);

        List<Database.UpsertResult> upsResults = Database.upsert(formPaymentListToUpsert, FormPayment__c.ExternalId__c, false);
        IntegrationUtils.upsertChildRecords(upsResults, responseMap, formPaymentListToUpsert, FormPayment__c.ExternalId__c); 

        return responseMap;
    }
}
