@RestResource(urlMapping='/upsertPricebook2/*')
global with sharing class IntegrationINPricebook2 {

    global static Boolean hasError = false;
    // This example of request
    // EndPoint => /services/apexrest/upsertPricebook2/
    // {
//     "request": [

//         {
//             "table" : "A935", 
//             "typeCondition": "PR00",
//             "product": "744463",
//             "productGroup": "001",
//             "center": "001",
//             "unitPrice": "98.0000",
//             "salesCondition": "0004",
//             "cropCode": "21/22",
//             "cultureCode": "001",
//             "accountCode": "988827",
//             "accountGroup": "A",
//             "orgVendas": "01",
//             "salesOffice": "XPTO",
//             "salesTeam": "ZYD",
//             "initialDate": "",
//             "endDate": "",
//             "typeCurrency": "BRL",
//             "productMultiplier": "1",
//             "unitMeasurement": "LT",
            
//          }
//     ]
// }

    //?Method Principals to integration, first method called
    @HttpPost
    global static ResponseModel upsertPricebook2(List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> request){
        
        Map<String, Id> lookups = new Map<String, Id>();

        Map<String, List<String>> lookupMap = new Map<String, List<String>>();
        lookupMap = prepareData();

        List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
        List<JurosDescontoAntecipao__c> interestDicountListToUpsert = new List<JurosDescontoAntecipao__c>();

        upsertInterestDiscount(lookupMap, lookups, request, responseList, interestDicountListToUpsert);
         
        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }

    global static Map<String, List<String>> prepareData(){
        List<String> salesOrgLookups       = new List<String>();
        List<String> cropLookups           = new List<String>();
        List<String> cultureLookups        = new List<String>();
        List<String> accountLookups        = new List<String>();
        List<String> salesOfficeLookups    = new List<String>();
        List<String> salesTeamLookups      = new List<String>();
        List<String> productGroupLookups   = new List<String>();
        List<String> productLookups        = new List<String>();
        List<String> salesConditionLookups = new List<String>();
        List<String> centerLookups         = new List<String>();

        Map<String, List<String>> response = new Map<String, List<String>>();
        response.put('salesOrgLookups', salesOrgLookups);
        response.put('cropLookups', cropLookups);
        response.put('cultureLookups', cultureLookups);
        response.put('accountLookups', accountLookups);
        response.put('salesOfficeLookups', salesOfficeLookups);
        response.put('salesTeamLookups', salesTeamLookups);
        response.put('productGroupLookups', productGroupLookups);
        response.put('productLookups', productLookups);
        response.put('salesConditionLookups', salesConditionLookups);
        response.put('centerLookups', centerLookups);

        return response;
    }

    global static void upsertInterestDiscount(Map<String, List<String>> lookupMap, Map<String, Id> lookups, List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> request, List<TemplateDataIntegrationFields.ResponseParent> responseList, 
    List<JurosDescontoAntecipao__c> interestDicountListToUpsert){

        for(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData interestDiscount : request){

            lookupMap.get('accountLookups').add(interestDiscount.accountCode);
            lookupMap.get('salesOrgLookups').add(interestDiscount.orgVendas);
            lookupMap.get('cropLookups').add(interestDiscount.cropCode);
            lookupMap.get('cultureLookups').add(interestDiscount.cultureCode);
            lookupMap.get('salesOfficeLookups').add(interestDiscount.salesOffice);
            lookupMap.get('salesTeamLookups').add(interestDiscount.salesTeam);
            lookupMap.get('productGroupLookups').add(interestDiscount.productGroup);
            lookupMap.get('productLookups').add(interestDiscount.product);
            lookupMap.get('salesConditionLookups').add(interestDiscount.salesCondition);
            lookupMap.get('centerLookups').add(interestDiscount.center);
        }

        IntegrationUtils.setLookup(new SalesOrg__c(), new Set<String>{'Id', 'SalesOrganizationCode__c'}, 'SalesOrganizationCode__c', lookupMap.get('salesOrgLookups'), lookups);
        
        IntegrationUtils.setLookup(new Safra__c(), new Set<String>{'Id', 'Code__c'}, 'Code__c', lookupMap.get('cropLookups'), lookups);
        
        IntegrationUtils.setLookup(new Cultura__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', lookupMap.get('cultureLookups'), lookups);

        IntegrationUtils.setLookup(new SalesOffice__c(), new Set<String>{'Id', 'Codigo__c'}, 'Codigo__c', lookupMap.get('salesOfficeLookups'), lookups);

        IntegrationUtils.setLookup(new SalesTeam__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('salesTeamLookups'), lookups);

        IntegrationUtils.setLookup(new ProductGroup__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('productGroupLookups'), lookups);

        IntegrationUtils.setLookup(new Product2(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('productLookups'), lookups);

        IntegrationUtils.setLookup(new Account(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('salesConditionLookups'), lookups);

        IntegrationUtils.setLookup(new SalesCondition__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('accountLookups'), lookups);

        IntegrationUtils.setLookup(new DistributionCenter__c(), new Set<String>{'Id', 'Code__c'}, 'Code__c', lookupMap.get('centerLookups'), lookups);


        FactoryDataIntegration.convertSObject(new JurosDescontoAntecipao__c(), 'IN', request, responseList, interestDicountListToUpsert, lookups);

        IntegrationUtils.upsertRecords(
            Database.upsert(interestDicountListToUpsert, JurosDescontoAntecipao__c.ExternalId__c, false), 
            responseList, 
            interestDicountListToUpsert, 
            JurosDescontoAntecipao__c.ExternalId__c);

        hasError = false;
        setResponses(responseList);
            
        
        //Creating integration log
        IntegrationLog.createLog('Lista de Preço, Juros e Descontos de Antecipação IN', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
    }

    global static void setResponses(List<TemplateDataIntegrationFields.ResponseParent> responseList){

        for(TemplateDataIntegrationFields.ResponseParent responseListPrice : responseList){
            if(responseListPrice.status == false){
                hasError = true;
                break;
            }
        }
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
