@RestResource(urlMapping='/upsertProduct2/*')
global with sharing class IntegrationINProduct {
    public IntegrationINProduct() {

    }
    @HttpPost
    global static ResponseModel upsertProduct(List<TemplateDataIntegrationFields.Product2INData> request) {
        // Guarda a relação da conta com o pedido
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> productGroupLookups = new Set<String>();
        Set<String> productSubGroupLookups = new Set<String>();
        Set<String> productHierarchyLookups = new Set<String>();

    
        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        //List<TemplateDataINtegrationFields.Product2INData> productListToUpsert = new List<TemplateDataINtegrationFields.Product2INData>();
        List<TemplateDataINtegrationFields.OrgVProductINData> orgVProductListToUpsert = new List<TemplateDataINtegrationFields.OrgVProductINData>();
        List<Product2> productListToUpsert = new List<Product2>();
        

        //Application of business rules
        for (TemplateDataIntegrationFields.Product2INData product : request){
            // Pega a relação da conta com o pedido
            //Getting account parameters to search
            productGroupLookups.add(product.GrupoMercadoria);
            productSubGroupLookups.add(product.SubgrupoMercadoria);
            productHierarchyLookups.add(product.hierarquiaProduto);

            orgVProductListToUpsert.addAll(product.orgVProductItems);
            System.debug('orgVProductListToUpsert --->' + orgVProductListToUpsert);
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
        
        for (ProductHierarchy__c productHierarchy : [SELECT Id, External_Id__c FROM ProductHierarchy__c WHERE  External_Id__c IN : productHierarchyLookups]){
            lookups.put('ProductHierarchy__c' + productHierarchy.External_Id__c, productHierarchy.Id);
            
        }
       

        
        //Converting template to object list and validating required fields
        // Valida e adiciona objeto na lista para upsert
        FactoryDataIntegration.convertSObject(new Product2(), 'IN', request, responseList, productListToUpsert, lookups);
          
        //Upserting records (Product)
		IntegrationUtils.upsertRecords(
            Database.upsert(productListToUpsert, Product2.ProductCode__c, false), 
            responseList, 
            productListToUpsert, 
            Product2.ProductCode__c
        );
        
        //Upserting records (OrderItem)
        // Upsert OrderItem
        
        Map<String, List<TemplateDataIntegrationFields.Response>> orgVproductResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(orgVProductListToUpsert.size() != 0){
            orgVproductResponse.putAll(
                IntegrationINOrgVProduct.upsertOrgVProduct(orgVProductListToUpsert)
            );
        }

        //Associating child object's response with object response
        // Pega todas as respostas dos OrderItem
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            response.items = new List<TemplateDataIntegrationFields.Response>();
            if(orgVproductResponse.size() != 0 && orgVproductResponse.containsKey(response.idSalesforce)){
                response.items.addAll(orgVproductResponse.get(response.idSalesforce));
            } 
            else if(orgVproductResponse.size() != 0 && orgVproductResponse.containsKey(response.externalCode)){
                response.items.addAll(orgVproductResponse.get(response.externalCode));
            }
        }

        //Checking integration errors to log
        // Verifica erros de integração para o log
        Boolean hasError = false;

        for(TemplateDataIntegrationFields.ResponseParent responseProduct : responseList){
            if(responseProduct.status == false){
                hasError = true;
                break;
            } else {
                for(TemplateDataIntegrationFields.Response response : responseProduct.items){
                    if(response.status == false){
                        hasError = true;
                        break;
                    }
                }
            }
            
        }
		
        //Creating integration log
        IntegrationLog.createLog('Product2', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
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