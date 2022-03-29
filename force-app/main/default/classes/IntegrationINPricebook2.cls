@RestResource(urlMapping='/upsertPricebook2/*')
global with sharing class IntegrationINPricebook2 {
    // EndPoint => /services/apexrest/upsertPricebook2/
    // {
    //     "request": [
    //                      {
    //                          "codExternal": "",
    //                          "typeCondition": "",
    //                          "description": "",
    //                          "orgVendas": "",
    //                          "listPrice": "",
    //                          "cropCode": "",
    //                          "cultureCode": "",
    //                          "accountCode": "",
    //                          "accountGroup": "",
    //                          "salesOffice": "",
    //                          "salesTeam": "",
    //                          "salesSector": "",
    //                          "initialDate": "",
    //                          "endDate": "",
    //                          "effectiveDate": "",
    //                          "typeCurrency": "",
    //                          "active": "",
    //                          "productFamily": "",
    //                          "pricebookentries": [
    //                              {
                                    
    //                                  "productCode": "XY123",
    //                                  "unitPrice": 100.00,
                               
    //                              },
    //                              {
                                    
    //                                  "productCode": "XY123",
    //                                  "unitPrice": 100.00,
                               
    //                              }
    //                          ]
    //                      }
    //                  ]
    //              }
    //    }

    @HttpPost
    global static ResponseModel upsertPricebook2(List<TemplateDataIntegrationFields.Pricebook2INData> request){
        Map<String, Id> lookups = new Map<String, Id>();

        // Set<String> recordTypeLookups = new Set<String>();
        Set<String> salesOrgLookups = new Set<String>();
        Set<String> cropLookups = new Set<String>();
        Set<String> cultureLookups = new Set<String>();
        List<String> accountLookups = new List<String>();
        Set<String> salesOfficeLookups = new Set<String>();
        Set<String> salesTeamLookups = new Set<String>();
        Set<String> salesSectionLookups = new Set<String>();
        Set<String> productFamilyLookups = new Set<String>();

        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntryListToUpsert = new List<TemplateDataIntegrationFields.PricebookEntryINData>();

        List<Pricebook2> pricebookListToUpsert = new List<Pricebook2>();

        for(TemplateDataIntegrationFields.Pricebook2INData pricebook : request){

            // recordTypeLookups.add(pricebook.typeCondition);
            salesOrgLookups.add(pricebook.orgVendas);
            cropLookups.add(pricebook.cropCode);
            cultureLookups.add(pricebook.cultureCode);
            accountLookups.add(pricebook.accountCode);
            salesOfficeLookups.add(pricebook.salesOffice);
            salesTeamLookups.add(pricebook.salesTeam);
            salesSectionLookups.add(pricebook.salesSector);
            productFamilyLookups.add(pricebook.productFamily);

            if(pricebook.pricebookEntries != null){
                for(TemplateDataIntegrationFields.PricebookEntryINData pricebookEntry : pricebook.pricebookEntries){
                    pricebookEntry.pricebook2Id = pricebook.codExternal;
                }

                pricebookEntryListToUpsert.addAll(pricebook.pricebookEntries);
            } 

        }


        setLookup(new Account(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', accountLookups, lookups);

        setLookup(new Cultura__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', new List<String>(cultureLookups), lookups);

        setLookup(new SalesOrg__c(), new Set<String>{'Id', 'SalesOrganizationCode__c'}, 'SalesOrganizationCode__c', new List<String>(salesOrgLookups), lookups);

        setLookup(new Safra__c(), new Set<String>{'Id', 'Code__c'}, 'Code__c', new List<String>(cropLookups), lookups);

        setLookup(new SalesOffice__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', new List<String>(salesOfficeLookups), lookups);

        setLookup(new SalesTeam__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', new List<String>(salesTeamLookups), lookups);

        setLookup(new ActivitySector__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', new List<String>(salesSectionLookups), lookups);

        setLookup(new ProductFamily__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', new List<String>(productFamilyLookups), lookups);


        FactoryDataIntegration.convertSObject(new Pricebook2(), 'IN', request, responseList, pricebookListToUpsert, lookups);

        IntegrationUtils.upsertRecords(
            Database.upsert(pricebookListToUpsert, Pricebook2.ExternalId__c, false), 
            responseList, 
            pricebookListToUpsert, 
            Pricebook2.ExternalId__c);

        Boolean hasError = false;
        setResponses(responseList, pricebookEntryListToUpsert, hasError);
        
        //Creating integration log
        IntegrationLog.createLog('Pricebook IN', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
        

        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }

    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertPricebookEntry(List<TemplateDataIntegrationFields.PricebookEntryINData> request) {
        Pricebook2 standardPB = [SELECT id FROM Pricebook2 WHERE isStandard=true];
        List<PricebookEntry> standardValuesExists = [SELECT Pricebook2Id, Product2Id, UnitPrice, IsActive FROM PricebookEntry WHERE Pricebook2Id =: standardPB.Id];
        List<PricebookEntry> standardValuesList = new List<PricebookEntry>();
       
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> productLookups = new Set<String>();
        Set<String> pricebookLookups = new Set<String>();

        

        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        List<PricebookEntry> pricebookEntryListToUpsert = new List<PricebookEntry>();

        for(TemplateDataIntegrationFields.PricebookEntryINData pricebookEntry : request){

            pricebookLookups.add(pricebookEntry.pricebook2Id);
            productLookups.add(pricebookEntry.productCode);
        }

        for(Pricebook2 pricebook : [SELECT Id, ExternalId__c FROM Pricebook2 WHERE ExternalId__c IN: pricebookLookups]){
            lookups.put('Pricebook2' + pricebook.ExternalId__c, pricebook.Id);
        }

        for(Product2 product : [SELECT Id, ExternalId__c FROM Product2 WHERE ExternalId__c IN: productLookups]){
            lookups.put('Product2Id' + product.ExternalId__c, product.Id);
        }

        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.PricebookEntryINData pricebookEntry : request) {
            parentMapKeys.put(pricebookEntry.pricebook2Id + '|' + pricebookEntry.productCode, lookups.containsKey('Pricebook2' + pricebookEntry.pricebook2Id) ? lookups.get('Pricebook2' + pricebookEntry.pricebook2Id) : pricebookEntry.pricebook2Id);
            
            PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPB.Id, Product2Id = lookups.get('Product2Id' + pricebookEntry.productCode), UnitPrice = pricebookEntry.unitPrice, IsActive = true);
            if(!isStandardPricebook(standardPBE.Product2Id, standardValuesExists))
                standardValuesList.add(standardPBE);
        }
        INSERT standardValuesList;

        FactoryDataIntegration.convertSObjectChild(
            new PricebookEntry(), 
            'IN', 
            request, 
            responseMap, 
            pricebookEntryListToUpsert, 
            lookups, 
            parentMapKeys
        );

        
        IntegrationUtils.upsertChildRecords(
            Database.upsert(pricebookEntryListToUpsert, PricebookEntry.Code__c, false), 
            responseMap, 
            pricebookEntryListToUpsert, 
            PricebookEntry.Code__c); 

        return responseMap;
    }

    global static Boolean isStandardPricebook(Id product2Id, List<PricebookEntry> standardValuesExists){
        List<Id> ProductIds =new List<Id>();
        for(PricebookEntry pricebook : standardValuesExists){
            ProductIds.add(pricebook.Product2Id);
        }

        return ProductIds.contains(product2Id);
    }

    global static void setLookup(SObject obj, Set<String> fieldSet, String fieldKey, List<String> objLookups,  Map<String, Id> lookups){

        String query = new Q(obj.getSObjectType()).selectFields(fieldSet).add(Q.condition(fieldKey).isIn(objLookups)).build();

        List<SObject> objectList = Database.query(query);

        for(Integer i = 0; i < objectList.size(); i++){
            lookups.put(objectList[i].getSObjectType().getDescribe().getName() + objectList[i].get(fieldKey), objectList[i].Id);
        }
    }

    global static void setResponses(List<TemplateDataIntegrationFields.ResponseParent> responseList, List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntryListToUpsert, Boolean hasError){

        Map<String, List<TemplateDataIntegrationFields.Response>> pricebookEntriesResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(pricebookEntryListToUpsert.size() != 0){
            pricebookEntriesResponse.putAll(
                upsertPricebookEntry(pricebookEntryListToUpsert)
            );
        }

        //Associating child object's response with object response
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            response.items = new List<TemplateDataIntegrationFields.Response>();
            if(pricebookEntriesResponse.size() != 0 && pricebookEntriesResponse.containsKey(response.idSalesforce)){
                response.items.addAll(pricebookEntriesResponse.get(response.idSalesforce));
            } 
            else if(pricebookEntriesResponse.size() != 0 && pricebookEntriesResponse.containsKey(response.externalCode)){
                response.items.addAll(pricebookEntriesResponse.get(response.externalCode));
            }
        }

        //Checking integration errors to log
       

        for(TemplateDataIntegrationFields.ResponseParent responsePricebook : responseList){
            if(responsePricebook.status == false){
                hasError = true;
                break;
            } else {
                for(TemplateDataIntegrationFields.Response response : responsePricebook.items){
                    if(response.status == false){
                        hasError = true;
                        break;
                    }
                }
            }
        }
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
