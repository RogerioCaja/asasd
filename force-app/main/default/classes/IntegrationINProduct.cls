@RestResource(urlMapping='/upsertProduct2/*')
global with sharing class IntegrationINProduct {
    public IntegrationINProduct() {

    }
    //@HttpPost
    global static ResponseModel upsertProduct(List<TemplateDataIntegrationFields.ProductINData> request) {
        // Guarda a relação da conta com o pedido
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> productGroupLookups = new Set<String>();
        Set<String> productSubGroupLookups = new Set<String>();
        

        // Guarda uma lista de respostas
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        // Guarda uma lista de orderItem para fazer o upsert
        //List<TemplateDataIntegrationFields.OrderItemINData> orderItemListToUpsert = new List<TemplateDataIntegrationFields.OrderItemINData>();
        // Guarda uma lista de pedidos para fazer o upsert
        List<Order> productListToUpsert = new List<Order>();

        //Application of business rules
        for (TemplateDataIntegrationFields.ProductINData product : request){
            // Pega a relação da conta com o pedido
            //Getting account parameters to search
            productGroupLookups.add(product.GrupoMercadoria);
            productSubGroupLookups.add(product.SubgrupoMercadoria);

 /*           
            if(order.orderItems != null) {
                // Adiciona todos os External Id e o catalogo de preço de order nos orderItem
                //Putting the Order's ExternalId parameter in the OrderItem
                for (TemplateDataIntegrationFields.OrderItemINData orderItem : order.orderItems){
                    orderItem.orderExternalId = order.orderNumber;
                }
                // Adiciona os orderItem na lista para upsert
                //Getting list of order items
                orderItemListToUpsert.addAll(order.orderItems);
            }
            */
        }
        // Pega o Id da conta com base no CNPJ da conta
        //Account search based on CNPJ field sent
        for (ProductGroup__c productGroup : [SELECT Id, ExternalId__c FROM ProductGroup__c WHERE ExternalId__c IN : productGroupLookups]) {
            //Map structure for the model -> object name + parameter to record id
            //Example
            lookups.put('ProductGroup__c' + productGroup.ExternalId__c, productGroup.Id);
        }

        for (ProductSubgroup__c productSubGroup : [SELECT Id, ExternalId__c FROM ProductSubgroup__c WHERE  ExternalId__c IN : productSubGroupLookups]){
            lookups.put('ProductSubgroup__c' + productSubGroup.ExternalId__c, productSubGroup.Id);
            
        }
       

        
        //Converting template to object list and validating required fields
        // Valida e adiciona objeto na lista para upsert
        FactoryDataIntegration.convertSObject(new Product2(), 'IN', request, responseList, productListToUpsert, lookups);
          
        //Upserting records (Product)
		IntegrationUtils.upsertRecords(
            Database.upsert(productListToUpsert, /*Product2.ExternalId__c,*/ false), 
            responseList, 
            productListToUpsert, 
            Product2.ExternalId__c
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

        for(TemplateDataIntegrationFields.ResponseParent responseOrder : responseList){
            if(responseOrder.status == false){
                hasError = true;
                break;
            } else {
                for(TemplateDataIntegrationFields.Response response : responseOrder.items){
                    if(response.status == false){
                        hasError = true;
                        break;
                    }
                }
            }
        }
		
        //Creating integration log
        IntegrationLog.createLog('Product2', 'Inbound', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
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