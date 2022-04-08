@RestResource(urlMapping='/upsertPricebook2/*')
global with sharing class IntegrationINPricebook2 {

    global static Boolean hasError = false;
    // This example of request
    // EndPoint => /services/apexrest/upsertPricebook2/
    // {
    //     "request": [
    //                      {
    //                          "name": ""
    //                          "codExternal": "",
    //                          "typeCondition": "PR00 pricebook,zd00 desconto,zj01 juros",
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
    //                          "productGroup": "",
    //                          "percentage": "",
    //                          "priority": "",
    //                          "product": "",
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

    //?Method Principals to integration, first method called
    @HttpPost
    global static ResponseModel upsertPricebook2(List<TemplateDataIntegrationFields.GenericINData> request){
        
        Map<String, Id> lookups = new Map<String, Id>();

        Map<String, List<String>> lookupMap = new Map<String, List<String>>();
        lookupMap = prepareData();

        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntryListToUpsert = new List<TemplateDataIntegrationFields.PricebookEntryINData>();

        List<Pricebook2> pricebookListToUpsert = new List<Pricebook2>();
        List<JurosDescontoAntecipao__c> interestDicountListToUpsert = new List<JurosDescontoAntecipao__c>();


        List<Object> requestNew = convertClass(request);
        if(requestNew[0] instanceof TemplateDataIntegrationFields.Pricebook2INData)
            upsertPricebook(lookupMap, lookups, requestNew, responseList, pricebookEntryListToUpsert, pricebookListToUpsert);
        else
            upsertInterestDiscount(lookupMap, lookups, requestNew, responseList, pricebookEntryListToUpsert, interestDicountListToUpsert);
            
        
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

        setLookup(new Pricebook2(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', new List<String>(pricebookLookups), lookups);

        setLookup(new Product2(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', new List<String>(productLookups), lookups);

        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.PricebookEntryINData pricebookEntry : request) {
            parentMapKeys.put(pricebookEntry.pricebook2Id + '|' + pricebookEntry.productCode, lookups.containsKey('Pricebook2' + pricebookEntry.pricebook2Id) ? lookups.get('Pricebook2' + pricebookEntry.pricebook2Id) : null);
            
            PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPB.Id, Product2Id = lookups.get('Product2' + pricebookEntry.productCode), UnitPrice = pricebookEntry.unitPrice, IsActive = true);
            if(!isStandardPricebook(standardPBE.Product2Id, standardValuesExists) && (lookups.get('Product2' + pricebookEntry.productCode) != null))
                standardValuesList.add(standardPBE);
        }
        if (standardValuesList.size() != 0) INSERT standardValuesList;
        
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

    //? Methods to preparing integration too, but is much important what anothers
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

    global static void setResponses(List<TemplateDataIntegrationFields.ResponseParent> responseList, List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntryListToUpsert){

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
            else if(pricebookEntriesResponse.size() != 0 && pricebookEntriesResponse.containsKey(response.externalCode)){ response.items.addAll(pricebookEntriesResponse.get(response.externalCode));
            }
        }

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


    //? Methods to preparing integration
    global static List<Object> convertClass(List<Object> requestGeneric){
        String requestNew = JSON.serialize(requestGeneric);
        if(requestNew.contains('ZPR0')){
            List<TemplateDataIntegrationFields.Pricebook2INData> pricebook = (List<TemplateDataIntegrationFields.Pricebook2INData>) JSON.deserialize(requestNew, List<TemplateDataIntegrationFields.Pricebook2INData>.class);
            return pricebook;
        }
        
        List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> interestValue = (List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData>) JSON.deserialize(requestNew, List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData>.class);
        return interestValue; 
    }

    global static Map<String, List<String>> prepareData(){
        List<String> salesOrgLookups      = new List<String>();
        List<String> cropLookups          = new List<String>();
        List<String> cultureLookups       = new List<String>();
        List<String> accountLookups       = new List<String>();
        List<String> salesOfficeLookups   = new List<String>();
        List<String> salesTeamLookups     = new List<String>();
        List<String> salesSectionLookups  = new List<String>();
        List<String> productGroupLookups  = new List<String>();
        List<String> productLookups       = new List<String>();

        Map<String, List<String>> response = new Map<String, List<String>>();
        response.put('salesOrgLookups', salesOrgLookups);
        response.put('cropLookups', cropLookups);
        response.put('cultureLookups', cultureLookups);
        response.put('accountLookups', accountLookups);
        response.put('salesOfficeLookups', salesOfficeLookups);
        response.put('salesTeamLookups', salesTeamLookups);
        response.put('salesSectionLookups', salesSectionLookups);
        response.put('productGroupLookups', productGroupLookups);
        response.put('productLookups', productLookups);

        return response;
    }


    //? Methods to upsert Pricebook and InterestDiscount
    global static void upsertPricebook(Map<String, List<String>> lookupMap, Map<String, Id> lookups, List<Object> objList, List<TemplateDataIntegrationFields.ResponseParent> responseList, 
     List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntryListToUpsert, List<Pricebook2> pricebookListToUpsert){

        List<TemplateDataIntegrationFields.Pricebook2INData> request = new List<TemplateDataIntegrationFields.Pricebook2INData>((List<TemplateDataIntegrationFields.Pricebook2INData>)objList);
        for(TemplateDataIntegrationFields.Pricebook2INData pricebook : request){

            lookupMap.get('salesOrgLookups').add(pricebook.orgVendas);
            lookupMap.get('cropLookups').add(pricebook.cropCode);
            lookupMap.get('cultureLookups').add(pricebook.cultureCode);
            lookupMap.get('accountLookups').add(pricebook.accountCode);
            lookupMap.get('salesOfficeLookups').add(pricebook.salesOffice);
            lookupMap.get('salesTeamLookups').add(pricebook.salesTeam);
            lookupMap.get('salesSectionLookups').add(pricebook.salesSector);
            lookupMap.get('productGroupLookups').add(pricebook.productGroup);

            if(pricebook.pricebookEntries != null){
                for(TemplateDataIntegrationFields.PricebookEntryINData pricebookEntry : pricebook.pricebookEntries){
                    pricebookEntry.pricebook2Id = pricebook.codExternal;
                }

                pricebookEntryListToUpsert.addAll(pricebook.pricebookEntries);
            } 

        }

        setLookup(new Account(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c',  lookupMap.get('accountLookups') , lookups);

        setLookup(new Cultura__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', lookupMap.get('cultureLookups'), lookups);

        setLookup(new SalesOrg__c(), new Set<String>{'Id', 'SalesOrganizationCode__c'}, 'SalesOrganizationCode__c', lookupMap.get('salesOrgLookups'), lookups);

        setLookup(new Safra__c(), new Set<String>{'Id', 'Code__c'}, 'Code__c', lookupMap.get('cropLookups'), lookups);

        setLookup(new SalesOffice__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', lookupMap.get('salesOfficeLookups'), lookups);

        setLookup(new SalesTeam__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('salesTeamLookups'), lookups);

        setLookup(new ActivitySector__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', lookupMap.get('salesSectionLookups'), lookups);

        setLookup(new ProductGroup__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('productGroupLookups'), lookups);


        FactoryDataIntegration.convertSObject(new Pricebook2(), 'IN', request, responseList, pricebookListToUpsert, lookups);

        IntegrationUtils.upsertRecords(
            Database.upsert(pricebookListToUpsert, Pricebook2.ExternalId__c, false), 
            responseList, 
            pricebookListToUpsert, 
            Pricebook2.ExternalId__c);

      
        
        hasError = false;
        setResponses(responseList, pricebookEntryListToUpsert);
       
        //Creating integration log
        IntegrationLog.createLog('Pricebook IN', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
    }

    global static void upsertInterestDiscount(Map<String, List<String>> lookupMap, Map<String, Id> lookups, List<Object> objList, List<TemplateDataIntegrationFields.ResponseParent> responseList, 
    List<TemplateDataIntegrationFields.PricebookEntryINData> pricebookEntryListToUpsert, List<JurosDescontoAntecipao__c> interestDicountListToUpsert){

        List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> request = new List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData>((List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData>)objList);
        for(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData interestDiscount : request){

            lookupMap.get('salesOrgLookups').add(interestDiscount.orgVendas);
            lookupMap.get('cropLookups').add(interestDiscount.cropCode);
            lookupMap.get('cultureLookups').add(interestDiscount.cultureCode);
            lookupMap.get('salesOfficeLookups').add(interestDiscount.salesOffice);
            lookupMap.get('salesTeamLookups').add(interestDiscount.salesTeam);
            lookupMap.get('productGroupLookups').add(interestDiscount.productGroup);
            lookupMap.get('productLookups').add(interestDiscount.product);
        }


        setLookup(new SalesOrg__c(), new Set<String>{'Id', 'SalesOrganizationCode__c'}, 'SalesOrganizationCode__c', lookupMap.get('salesOrgLookups'), lookups);
        
        setLookup(new Safra__c(), new Set<String>{'Id', 'Code__c'}, 'Code__c', lookupMap.get('cropLookups'), lookups);
        
        setLookup(new Cultura__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', lookupMap.get('cultureLookups'), lookups);

        setLookup(new SalesOffice__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', lookupMap.get('salesOfficeLookups'), lookups);

        setLookup(new SalesTeam__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('salesTeamLookups'), lookups);

        setLookup(new ProductGroup__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('productGroupLookups'), lookups);

        setLookup(new Product2(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('productLookups'), lookups);


        FactoryDataIntegration.convertSObject(new JurosDescontoAntecipao__c(), 'IN', request, responseList, interestDicountListToUpsert, lookups);

        IntegrationUtils.upsertRecords(
            Database.upsert(interestDicountListToUpsert, JurosDescontoAntecipao__c.ExternalId__c, false), 
            responseList, 
            interestDicountListToUpsert, 
            JurosDescontoAntecipao__c.ExternalId__c);

        hasError = false;
        setResponses(responseList, pricebookEntryListToUpsert);
            
        
        //Creating integration log
        IntegrationLog.createLog('Juros e Descontos de Antecipação IN', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
    }

    //? class to JSON responses 
    global class ResponseModel {

        global List<TemplateDataIntegrationFields.ResponseParent> response;

        public ResponseModel(List<TemplateDataIntegrationFields.ResponseParent> response) {

            this.response = response;
            
        }
        public ResponseModel() {   
            this.response = new List<TemplateDataIntegrationFields.ResponseParent>();         
        }
    }
  
}
