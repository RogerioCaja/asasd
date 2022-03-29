@RestResource(urlMapping='/upsertPricebook2/*')
global with sharing class IntegrationINPricebook2 {
    // {
    //     "request": [
    //                      {
    //                          "codExternal": "",
    //                          "typeCondition": "",
    //                          "description": "",
    //                          "orgVendas": "",
    //                          "listPrice": "",
    //                          "cropCode": "",
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
        Set<String> accountLookups = new Set<String>();
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

        for (Account account : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN : accountLookups]) {
            lookups.put('Account__c' + account.ExternalId__c, account.Id);
        }

        for (Cultura__c culture : [SELECT Id, Codigo__c FROM Cultura__c WHERE Codigo__c IN : cultureLookups]) {
            lookups.put('Culture__c' + culture.Codigo__c, culture.Id);
        }

        for (SalesOrg__c salesOrg : [SELECT Id, SalesOrganizationCode__c FROM SalesOrg__c WHERE SalesOrganizationCode__c IN : salesOrgLookups]) {
            lookups.put('SalesOrg__c' + salesOrg.SalesOrganizationCode__c, salesOrg.Id);
        }

        for (Safra__c crop : [SELECT Id, Code__c FROM Safra__c WHERE Code__c IN : cropLookups]) {
            lookups.put('Crop__c' + crop.Code__c, crop.Id);
        }

        for (SalesOffice__c salesOffice : [SELECT Id, Codigo__c FROM SalesOffice__c WHERE Codigo__c IN : salesOfficeLookups]) {
            lookups.put('SalesOffice__c' + salesOffice.Codigo__c, salesOffice.Id);
        }

        for (SalesTeam__c salesTeam : [SELECT Id, ExternalId__c FROM SalesTeam__c WHERE ExternalId__c IN : salesTeamLookups]) {
            lookups.put('SalesTeam__c' + salesTeam.ExternalId__c, salesTeam.Id);
        }

        for (ActivitySector__c activitySector : [SELECT Id, Codigo__c FROM ActivitySector__c WHERE Codigo__c IN : salesSectionLookups]) {
            lookups.put('SalesSection__c' + activitySector.Codigo__c, activitySector.Id);
        }

        for (ProductFamily__c productFamily : [SELECT Id, ExternalId__c FROM ProductFamily__c WHERE ExternalId__c IN : productFamilyLookups]) {
            lookups.put('ProductFamily__c' + productFamily.ExternalId__c, productFamily.Id);
        }

        FactoryDataIntegration.convertSObject(new Pricebook2(), 'IN', request, responseList, pricebookListToUpsert, lookups);

        IntegrationUtils.upsertRecords(
            Database.upsert(pricebookListToUpsert, Pricebook2.ExternalId__c, false), 
            responseList, 
            pricebookListToUpsert, 
            Pricebook2.ExternalId__c);

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
        Boolean hasError = false;

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
		
        //Creating integration log
        IntegrationLog.createLog('Pricebook IN', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
        

        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }

    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertPricebookEntry(List<TemplateDataIntegrationFields.PricebookEntryINData> request) {
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

        Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        List<Id> ProductIds =new List<Id>();
        List<PricebookEntry> standardValuesExists = [SELECT Pricebook2Id, Product2Id, UnitPrice, IsActive FROM PricebookEntry WHERE Pricebook2Id =: standardPB.Id];
        for(PricebookEntry pricebook : standardValuesExists){
            ProductIds.add(pricebook.Product2Id);
        }
        List<PricebookEntry> standardValuesList = new List<PricebookEntry>();

        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.PricebookEntryINData pricebookEntry : request) {
            parentMapKeys.put(pricebookEntry.pricebook2Id + '|' + pricebookEntry.productCode, lookups.containsKey('Pricebook2' + pricebookEntry.pricebook2Id) ? lookups.get('Pricebook2' + pricebookEntry.pricebook2Id) : pricebookEntry.pricebook2Id);
            
            PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPB.Id, Product2Id = lookups.get('Product2Id' + pricebookEntry.productCode), UnitPrice = pricebookEntry.unitPrice, IsActive = true);
            if(!ProductIds.contains(standardPBE.Product2Id))
                standardValuesList.add(standardPBE);
        }
        insert standardValuesList;

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
