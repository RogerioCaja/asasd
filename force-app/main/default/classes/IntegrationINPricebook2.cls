@RestResource(urlMapping='/upsertPricebook2/*')
global with sharing class IntegrationINPricebook2 {

    global static Boolean hasError = false;
    global static Boolean errorCostPrice = false;
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
        Map<String, List<String>> response = new Map<String, List<String>>();
        response.put('salesOrgLookups',       new List<String>());
        response.put('cropLookups',           new List<String>());
        response.put('cultureLookups',        new List<String>());
        response.put('accountLookups',        new List<String>());
        response.put('salesOfficeLookups',    new List<String>());
        response.put('salesTeamLookups',      new List<String>());
        response.put('productGroupLookups',   new List<String>());
        response.put('productLookups',        new List<String>());
        response.put('salesConditionLookups', new List<String>());
        response.put('centerLookups',         new List<String>());
        
        return response;
    }

    global static void upsertInterestDiscount(Map<String, List<String>> lookupMap, Map<String, Id> lookups, List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> request, List<TemplateDataIntegrationFields.ResponseParent> responseList, 
    List<JurosDescontoAntecipao__c> interestDicountListToUpsert){
        
        List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> interestToRemove = new List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData>();
        List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> cloneRequest = request.clone();
        
        Integer valueToTransform;

        Map<String, List<String>> requirementsMap = prepareRequirements();
        Map<String, Boolean> isValidMap = new Map<String, Boolean>();

        for(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData interestDiscount : request){

            if(interestDiscount.typeCondition == 'ZPRS'){
                interestDiscount = getRecord(interestDiscount);
                if(errorCostPrice){
                    getRecordInCreation(interestDiscount, request);
                    interestToRemove.add(interestDiscount);
                }
                
            }
            if(interestDiscount.accountCode != null){
                valueToTransform = Integer.valueOf(interestDiscount.accountCode);
            	interestDiscount.accountCode = String.valueOf(valueToTransform);
            }
         	if(interestDiscount.product != null){
                valueToTransform = Integer.valueOf(interestDiscount.product);
            	interestDiscount.product = String.valueOf(valueToTransform);
            }
            if(Date.valueOf(interestDiscount.endDate) < Date.today()){
                isValidMap.put(interestDiscount.externalId, false);
            }
            else{
                isValidMap.put(interestDiscount.externalId, true);
            }
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

        IntegrationUtils.setLookup(new Product2(), new Set<String>{'Id', 'ProductCode__c'}, 'ProductCode__c', lookupMap.get('productLookups'), lookups);

        IntegrationUtils.setLookup(new Account(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('accountLookups'), lookups);

        IntegrationUtils.setLookup(new SalesCondition__c(), new Set<String>{'Id', 'ExternalId__c'}, 'ExternalId__c', lookupMap.get('salesConditionLookups'), lookups);

        IntegrationUtils.setLookup(new DistributionCenter__c(), new Set<String>{'Id', 'Code__c'}, 'Code__c', lookupMap.get('centerLookups'), lookups);

		
        for(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData interest : interestToRemove){
            request.remove(request.indexOf(interest));
        }
        FactoryDataIntegration.convertSObject(new JurosDescontoAntecipao__c(), 'IN', request, responseList, interestDicountListToUpsert, lookups, requirementsMap, isValidMap);
        
        IntegrationUtils.upsertRecords(
            Database.upsert(interestDicountListToUpsert, JurosDescontoAntecipao__c.ExternalId__c, false), 
            responseList, 
            interestDicountListToUpsert, 
            JurosDescontoAntecipao__c.ExternalId__c);

        hasError = false;
        setResponses(responseList);
            
        
        //Creating integration log
        IntegrationLog.createLog('Lista de Preço, Juros e Descontos de Antecipação IN', 'IN', JSON.serialize(cloneRequest), JSON.serialize(responseList), hasError);
    }


    global static Map<String, List<String>> prepareRequirements(){
        // A935 => Org.vendas/Moeda/Safra/Lst.preços/Cliente/Material
        // A936 => Org.vendas/Moeda/Safra/Lst.preços/GrpClients/Material
        // A937 => Org.vendas/Moeda/Safra/Lst.preços/Cód Cult./Eq.vendas/Material
        // A938 => Org.vendas/Moeda/Safra/Lst.preços/Eq.vendas/Material
        // A939 => Org.vendas/Moeda/Safra/Lst.preços/EscrVendas/Material
        // A940 => Org.vendas/Moeda/Safra/Lst.preços/Grp.merc
        // A941 => Org.vendas/Moeda/Safra/Material
        
        // A930 => Org.vendas/Safra/GrpClients/Material
        // A931 => Org.vendas/Safra/Centro/Material
        // A932 => Org.vendas/Safra/Centro/Grp.merc.
        // A933 => Org.vendas/Safra/Centro/Material
        // A934 => Org.vendas/Safra

        Map<String, List<String>> response = new Map<String, List<String>>();
        response.put('A930', new List<String>{'SalesOrg__c', 'harvest__c', 'AccountType__c','Product__c'});
        response.put('A945', new List<String>{'SalesOrg__c', 'harvest__c','SalesTeam__c' ,'Product__c'});
        response.put('A946', new List<String>{'SalesOrg__c', 'harvest__c','SalesTeam__c' ,'ProductGroup__c'});
        response.put('A933', new List<String>{'SalesOrg__c', 'harvest__c','DistributionCenter__c' ,'Product__c'});
        response.put('A934', new List<String>{'SalesOrg__c', 'harvest__c'});

        response.put('A935', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'Account__c','Product__c'});
        response.put('A936', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'AccountType__c', 'Product__c'});
        response.put('A937', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'Culture__c', 'SalesTeam__c' ,'Product__c'});
        response.put('A938', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'SalesTeam__c' ,'Product__c'});
        response.put('A939', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'SalesOffice__c' ,'Product__c'});
        response.put('A940', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'ProductGroup__c' });
        response.put('A941', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c','Product__c'});
        
        return response;
    }

    global static TemplateDataIntegrationFields.JurosDescontoAntecipaoINData getRecord(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData data){
        String externalId = createExternalId(data);
        JurosDescontoAntecipao__c condition;
        try{
            condition = [SELECT ExternalId__c, UnitPrice__c FROM JurosDescontoAntecipao__c WHERE DescriptionExternalId__c =: externalId];
        }
        catch(Exception e){
            errorCostPrice = true;
            condition = null;
        }
        
        if(condition != null){
            data.externalId = condition.ExternalId__c;
            data.costPrice = data.unitPrice; //this is unic field SAP send, then this field is confused
            data.unitPrice = String.valueOf(condition.UnitPrice__c);
        }  
        
        return data;
    }

    global static TemplateDataIntegrationFields.JurosDescontoAntecipaoINData getRecordInCreation(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData data, List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> datas){
        List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> priceConditonList = new List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData>();
        for(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData interest : datas){
            if(interest.typeCondition == 'ZPR0')
                priceConditonList.add(interest);
        }

        for(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData interest : priceConditonList){
            if(createExternalId(data) == createExternalId(interest)){
                interest.unitPrice = interest.unitPrice;
                interest.costPrice = data.unitPrice;
                break;
            }
        }
        errorCostPrice = false;
        return data;
    }

    global static String createExternalId(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData data){
        String externalId = data.orgVendas != '' && data.orgVendas != null ? data.orgVendas + '_' : '';
        externalId = externalId + (data.cropCode != '' && data.cropCode != null  ? data.cropCode + '_' : '');
        externalId = externalId + (data.typeCurrency != '' && data.typeCurrency != null  ? data.typeCurrency + '_' : '');
        externalId = externalId + (data.salesCondition != '' && data.salesCondition != null  ? data.salesCondition + '_' : '');
        externalId = externalId + (data.productGroup != '' && data.productGroup != null  ? data.productGroup + '_' : '');
        externalId = externalId + (data.salesOffice != '' && data.salesOffice != null  ? data.salesOffice + '_' : '');
        externalId = externalId + (data.cultureCode != '' && data.cultureCode != null  ? data.cultureCode + '_' : '');
        externalId = externalId + (data.accountGroup != '' && data.accountGroup != null  ? data.accountGroup + '_' : '');
        externalId = externalId + (data.accountCode != '' && data.accountCode != null  ? data.accountCode + '_' : '');
        externalId = externalId + (data.salesTeam != '' && data.salesTeam != null  ? data.salesTeam + '_' : '');
        externalId = externalId + (data.product != '' && data.product != null  ? data.product : '');

        return externalId;
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