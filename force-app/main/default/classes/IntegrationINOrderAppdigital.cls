@RestResource(urlMapping='/upsertOrderAppdigital/*')
global with sharing class IntegrationINOrderAppdigital {
    public IntegrationINOrderAppdigital() {

    }
    @HttpPost
    global static ResponseModel upsertOrder(List<TemplateDataIntegrationFields.OrderINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        Map<String, List<String>> lookupMap = new Map<String, List<String>>();
        lookupMap = prepareData();

        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        List<TemplateDataIntegrationFields.OrderItemINData> orderItemListToUpsert = new List<TemplateDataIntegrationFields.OrderItemINData>();

        List<Order> orderListToUpsert = new List<Order>();

        for (TemplateDataIntegrationFields.OrderINData order : request){
   
            lookupMap.get('salesOrgLookups').add(order.SalesOrg);
            lookupMap.get('cropLookups').add(order.Crop);
            lookupMap.get('cultureLookups').add(order.Culture);
            lookupMap.get('accountLookups').add(order.PaymentAccount);
            lookupMap.get('accountLookups').add(order.ShippingAccount);
            lookupMap.get('salesSectionLookups').add(order.ActivitySector);
            lookupMap.get('salesCTVLookups').add(order.SalesCTV);
            lookupMap.get('pricebookLookups').add(order.pricebook2Id);
            lookupMap.get('orderMotherLookups').add(order.orderMother);

            if(order.orderItems != null) {
                for (TemplateDataIntegrationFields.OrderItemINData orderItem : order.orderItems){
                   orderItem.orderExternalId = order.CodigoSap;
                }
                orderItemListToUpsert.addAll(order.orderItems);
            }
        }


        //SetLookups
        IntegrationUtils.setLookup(new Account(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c',  lookupMap.get('accountLookups') , lookups);
        IntegrationUtils.setLookup(new Safra__c(), new Set<String>{'Id', 'Code__c'}, 'Code__c', lookupMap.get('cropLookups'), lookups);
        IntegrationUtils.setLookup(new Cultura__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', lookupMap.get('cultureLookups'), lookups);
        IntegrationUtils.setLookup(new SalesOrg__c(), new Set<String>{'Id', 'SalesOrganizationCode__c'}, 'SalesOrganizationCode__c', lookupMap.get('salesOrgLookups'), lookups);
        IntegrationUtils.setLookup(new ActivitySector__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', lookupMap.get('salesSectionLookups'), lookups);
        // => IntegrationUtils.setLookup(new User(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c',  lookupMap.get('salesCTVLookups') , lookups);
        IntegrationUtils.setLookup(new Pricebook2(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c',  lookupMap.get('pricebookLookups') , lookups);
        IntegrationUtils.setLookup(new Order(), new Set<String>{'Id', 'CodigoSap__c'}, 'CodigoSap__c',  lookupMap.get('orderMotherLookups') , lookups);

        System.debug('lookups =>' + lookups);
        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObject(new Order(), 'IN', request, responseList, orderListToUpsert, lookups);
          
        //Upserting records (Order)
		IntegrationUtils.upsertRecords(
            Database.upsert(orderListToUpsert, Order.CodigoSap__c, false), 
            responseList, 
            orderListToUpsert, 
            Order.CodigoSap__c
        );
        
        //Upserting records (OrderItem)
        Map<String, List<TemplateDataIntegrationFields.Response>> orderItemsResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(orderItemListToUpsert.size() != 0){
             orderItemsResponse.putAll(
                IntegrationINOrderItemAppdigital.upsertOrderItem(orderItemListToUpsert)
             );
         }

        //Associating child object's response with object response
         for(TemplateDataIntegrationFields.ResponseParent response : responseList){
             response.items = new List<TemplateDataIntegrationFields.Response>();
             if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.idSalesforce)){
                 response.items.addAll(orderItemsResponse.get(response.idSalesforce));
            } 
             else if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.externalCode)){
                response.items.addAll(orderItemsResponse.get(response.externalCode));
             }
         }

        //Checking integration errors to log
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
        //IntegrationUtils.createLog('Order', 'Inbound', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
        //Returning response
        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }

    global static Map<String, List<String>> prepareData(){
        List<String> salesOrgLookups      = new List<String>();
        List<String> cropLookups          = new List<String>();
        List<String> cultureLookups       = new List<String>();
        List<String> accountLookups       = new List<String>();
        List<String> salesSectionLookups  = new List<String>();
        List<String> salesCTVLookups  = new List<String>();
        List<String> pricebookLookups  = new List<String>();
        List<String> orderMotherLookups = new List<String>();

        Map<String, List<String>> response = new Map<String, List<String>>();
        response.put('salesOrgLookups', salesOrgLookups);
        response.put('cropLookups', cropLookups);
        response.put('cultureLookups', cultureLookups);
        response.put('accountLookups', accountLookups);
        response.put('salesSectionLookups', salesSectionLookups);
        response.put('salesCTVLookups', salesCTVLookups);
        response.put('pricebookLookups', pricebookLookups);
        response.put('orderMotherLookups', orderMotherLookups);

        return response;
    }

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
