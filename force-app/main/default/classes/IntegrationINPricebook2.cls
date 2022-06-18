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
        
        Integer valueToTransform;
        Map<String, List<String>> requirementsMap = prepareRequirements();
        Map<String, Boolean> isValidMap = new Map<String, Boolean>();
    
        for(TemplateDataIntegrationFields.JurosDescontoAntecipaoINData interestDiscount : request){

            if(interestDiscount.product != null){
            	interestDiscount.product = String.valueOf(interestDiscount.product).leftPad(18, '0');
            }

            if(Date.valueOf(interestDiscount.endDate) < Date.today()){
                isValidMap.put(interestDiscount.externalId, false);
            }
            else{
                isValidMap.put(interestDiscount.externalId, true);
            }
            
            if(interestDiscount.accountCode != null){
                valueToTransform = Integer.valueOf(interestDiscount.accountCode);
            	interestDiscount.accountCode = String.valueOf(valueToTransform);
            }

            if(interestDiscount.accountCode != null){
                lookupMap.get('accountLookups').add(interestDiscount.accountCode);
            }
            if(interestDiscount.orgVendas != null){
                lookupMap.get('salesOrgLookups').add(interestDiscount.orgVendas);
            }
            if(interestDiscount.cropCode != null){
                lookupMap.get('cropLookups').add(interestDiscount.cropCode);
            }
            if(interestDiscount.cultureCode != null){
                lookupMap.get('cultureLookups').add(interestDiscount.cultureCode);
            }
            if(interestDiscount.salesOffice != null){
                 lookupMap.get('salesOfficeLookups').add(interestDiscount.salesOffice);
            }
            if(interestDiscount.salesTeam != null){
                lookupMap.get('salesTeamLookups').add(interestDiscount.salesTeam);
            }
            if(interestDiscount.productGroup != null){
                lookupMap.get('productGroupLookups').add(interestDiscount.productGroup);
            }
            if(interestDiscount.product != null){
               lookupMap.get('productLookups').add(interestDiscount.product);
            }
            if(interestDiscount.salesCondition != null){
                lookupMap.get('salesConditionLookups').add(interestDiscount.salesCondition);
            }
            if(interestDiscount.center != null){
                lookupMap.get('centerLookups').add(interestDiscount.center);
            }
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

		
        FactoryDataIntegration.convertSObject(new JurosDescontoAntecipao__c(), 'IN', request, responseList, interestDicountListToUpsert, lookups, requirementsMap, isValidMap);
        
        List<JurosDescontoAntecipao__c> priceWithoutZPRS = removeZPRSData(interestDicountListToUpsert, responseList);
        System.debug(priceWithoutZPRS);
        IntegrationUtils.upsertRecords(
            Database.upsert(priceWithoutZPRS, JurosDescontoAntecipao__c.ExternalId__c, false), 
            responseList, 
            priceWithoutZPRS, 
            JurosDescontoAntecipao__c.ExternalId__c);

        List<JurosDescontoAntecipao__c> priceWithZPRS = ZPRSData(interestDicountListToUpsert, responseList);
        System.debug('Aqui => '+ priceWithZPRS);
        IntegrationUtils.upsertRecords(
            Database.upsert(priceWithZPRS, JurosDescontoAntecipao__c.ExternalId__c, false), 
            responseList, 
            priceWithZPRS, 
            JurosDescontoAntecipao__c.ExternalId__c);

        hasError = false;
        setResponses(responseList);
        
        Set<String> externalIdSet = new Set<String>();
        List<TemplateDataIntegrationFields.ResponseParent> removeToDataList = new List<TemplateDataIntegrationFields.ResponseParent>();
        Map<String, TemplateDataIntegrationFields.ResponseParent> permitToDataMap = new Map<String, TemplateDataIntegrationFields.ResponseParent>();
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            if(response.idSalesforce != ''){
                permitToDataMap.put(response.externalCode, response);
            }
            if(!externalIdSet.contains(response.externalCode)){
                externalIdSet.add(response.externalCode);
                
            }   
            else{
                removeToDataList.add(response);
            }
            	
        }
        
        for(TemplateDataIntegrationFields.ResponseParent response : removeToDataList){
            responseList.remove(responseList.indexOf(response));
        }
        
        for(TemplateDataIntegrationFields.ResponseParent response : responseList){
            responseList[responseList.indexOf(response)] = permitToDataMap.containsKey(response.externalCode) ? permitToDataMap.get(response.externalCode) : response;
        }
        
        //Creating integration log
        IntegrationLog.createLog('Lista de Preço, Juros e Descontos de Antecipação IN', 'IN', JSON.serialize(request), JSON.serialize(responseList), hasError);
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
        response.put('A930', new List<String>{'SalesOrg__c', 'harvest__c', 'ClientGroup__c','Product__c'});
        response.put('A945', new List<String>{'SalesOrg__c', 'harvest__c','SalesTeam__c' ,'Product__c'});
        response.put('A946', new List<String>{'SalesOrg__c', 'harvest__c','SalesTeam__c' ,'ProductGroup__c'});
        response.put('A933', new List<String>{'SalesOrg__c', 'harvest__c','DistributionCenter__c' ,'Product__c'});
        response.put('A934', new List<String>{'SalesOrg__c', 'harvest__c'});

        response.put('A935', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'Account__c','Product__c'});
        response.put('A936', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'ClientGroup__c', 'Product__c'});
        response.put('A937', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'Culture__c', 'SalesTeam__c' ,'Product__c'});
        response.put('A938', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'SalesTeam__c' ,'Product__c'});
        response.put('A939', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'SalesOffice__c' ,'Product__c'});
        response.put('A940', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c', 'SalesCondition__c', 'ProductGroup__c' });
        response.put('A941', new List<String>{'SalesOrg__c', 'Currency__c' ,'harvest__c','Product__c'});
        
        return response;
    }


    global static List<JurosDescontoAntecipao__c> removeZPRSData(List<JurosDescontoAntecipao__c> context, List<TemplateDataIntegrationFields.ResponseParent> responseList){
        
        List<JurosDescontoAntecipao__c> newContext = new List<JurosDescontoAntecipao__c>();
        Map<String, String> pricesMap = new Map<String, String>();
        Map<String, String> externalIdMap = new Map<String, String>();
        Set<String> repetitons = new Set<String>();

        List<JurosDescontoAntecipao__c> pricesList = new List<JurosDescontoAntecipao__c>();
        for(JurosDescontoAntecipao__c interest : context){
            if(interest.Cost__c == null){
                newContext.add(interest);
            }
        }
        for(JurosDescontoAntecipao__c prices : newContext){
            String externalId = (
                String.valueOf(prices.StartDate__c)+'_'+
                String.valueOf(prices.SalesOrg__c).subString(0, 15)+'_'+
                (prices.harvest__c == null ? '' : String.valueOf(prices.harvest__c).subString(0, 15)+'_')+
                (prices.Currency__c == null ? '' : String.valueOf(prices.Currency__c)+'_')+
                (prices.SalesCondition__c == null ? '' : String.valueOf(prices.SalesCondition__c).subString(0, 15)+'_')+
                (prices.ProductGroup__c == null ? '' : String.valueOf(prices.ProductGroup__c).subString(0, 15)+'_')+
                (prices.SalesOffice__c == null ? '' : String.valueOf(prices.SalesOffice__c).subString(0, 15)+'_')+
                (prices.Culture__c == null ? '' : String.valueOf(prices.Culture__c).subString(0, 15)+'_')+
                (prices.ClientGroup__c == null ? '' : String.valueOf(prices.ClientGroup__c)+'_')+
                (prices.Account__c == null ? '' : String.valueOf(prices.Account__c).subString(0, 15)+'_')+
                (prices.SalesTeam__c == null ? '' : String.valueOf(prices.SalesTeam__c).subString(0, 15)+'_')+
                (prices.Product__c == null ? '' : String.valueOf(prices.Product__c).subString(0, 15))
            );
            System.debug(externalId);
            externalIdMap.put(externalId,prices.ExternalId__c);
            repetitons.add(prices.ExternalId__c);
            prices.EndDate__c = prices.EndDate__c != null ? String.valueOf(prices.EndDate__c).contains('9999') ? Date.valueOf(String.valueOf(prices.EndDate__c).replace('9999', '2999')) : prices.EndDate__c : null;
            pricesMap.put(externalId, prices.UnitPrice__c + '|' + prices.EndDate__c);
        }
        
        for(JurosDescontoAntecipao__c prices : [ SELECT Id, ExternalId__c, UnitPrice__c, DescriptionExternalId__c
                                                FROM JurosDescontoAntecipao__c
                                                WHERE DescriptionExternalId__c IN: pricesMap.keySet()
                                                AND RecordType.DeveloperName = 'ZPR0']){ 
            if(externalIdMap.containsKey(prices.DescriptionExternalId__c)) externalIdMap.remove(prices.DescriptionExternalId__c);    
            pricesList.add(new JurosDescontoAntecipao__c(IsActive__c = Date.valueOf(pricesMap.get(prices.DescriptionExternalId__c).substringAfter('|')) < Date.today() ? false : true ,EndDate__c = Date.valueOf(pricesMap.get(prices.DescriptionExternalId__c).substringAfter('|')), UnitPrice__c = Decimal.valueOf(pricesMap.get(prices.DescriptionExternalId__c).substringBefore('|')), ExternalId__c = prices.ExternalId__c));
        }
        Set<String> externalIdSet = new Set<String>();
        for(String value : externalIdMap.values()){
        	externalIdSet.add(value);
        }
        for(JurosDescontoAntecipao__c interest : newContext){
            if(externalIdSet.contains(interest.ExternalId__c)){
                pricesList.add(interest);
            }
        }
        
         for(String repetiton : repetitons){
            TemplateDataIntegrationFields.ResponseParent response = new TemplateDataIntegrationFields.ResponseParent();
            response.status = true;
            response.success('', repetiton, 'JurosDescontoAntecipao__c');
            responseList.add(response);
        }
 
        return pricesList;
    }

    global static List<JurosDescontoAntecipao__c> onlyZPRSData(List<JurosDescontoAntecipao__c> context){
        List<JurosDescontoAntecipao__c> newContext = new List<JurosDescontoAntecipao__c>();
        for(JurosDescontoAntecipao__c interest : context){
            if(interest.Cost__c != null){
                newContext.add(interest);
            }
        }
        return newContext;
    }

    global static List<JurosDescontoAntecipao__c> ZPRSData(List<JurosDescontoAntecipao__c> context, List<TemplateDataIntegrationFields.ResponseParent> responseList){
        Map<String, Decimal> pricesMap = new Map<String, Decimal>();
        List<JurosDescontoAntecipao__c> pricesList = new List<JurosDescontoAntecipao__c>();
        Set<String> repetitonsZPRS = new Set<String>();
        Map<String, String> externalIdMap = new Map<String, String>();
        for(JurosDescontoAntecipao__c prices : onlyZPRSData(context)){
            String externalId = (
                String.valueOf(prices.StartDate__c)+'_'+
                String.valueOf(prices.SalesOrg__c).subString(0, 15)+'_'+
                (prices.harvest__c == null ? '' : String.valueOf(prices.harvest__c).subString(0, 15)+'_')+
                (prices.Currency__c == null ? '' : String.valueOf(prices.Currency__c)+'_')+
                (prices.SalesCondition__c == null ? '' : String.valueOf(prices.SalesCondition__c).subString(0, 15)+'_')+
                (prices.ProductGroup__c == null ? '' : String.valueOf(prices.ProductGroup__c).subString(0, 15)+'_')+
                (prices.SalesOffice__c == null ? '' : String.valueOf(prices.SalesOffice__c).subString(0, 15)+'_')+
                (prices.Culture__c == null ? '' : String.valueOf(prices.Culture__c).subString(0, 15)+'_')+
                (prices.ClientGroup__c == null ? '' : String.valueOf(prices.ClientGroup__c)+'_')+
                (prices.Account__c == null ? '' : String.valueOf(prices.Account__c).subString(0, 15)+'_')+
                (prices.SalesTeam__c == null ? '' : String.valueOf(prices.SalesTeam__c).subString(0, 15)+'_')+
                (prices.Product__c == null ? '' : String.valueOf(prices.Product__c).subString(0, 15))
            );
            System.debug(externalId);
            externalIdMap.put(externalId,prices.ExternalId__c);
            repetitonsZPRS.add(prices.ExternalId__c);
            pricesMap.put(externalId, prices.Cost__c);
        }
 		
        if(pricesMap.isEmpty()) return new List<JurosDescontoAntecipao__c>();
		List<JurosDescontoAntecipao__c> interestList =  onlyZPRSData(context);
        for(JurosDescontoAntecipao__c prices : [ SELECT Id, ExternalId__c, UnitPrice__c, DescriptionExternalId__c
                                                FROM JurosDescontoAntecipao__c
                                                WHERE DescriptionExternalId__c IN: pricesMap.keySet()
                                                AND RecordType.DeveloperName = 'ZPR0']){ 
            if(externalIdMap.containsKey(prices.DescriptionExternalId__c)) externalIdMap.remove(prices.DescriptionExternalId__c);
            pricesList.add(new JurosDescontoAntecipao__c(Cost__c = pricesMap.get(prices.DescriptionExternalId__c), ExternalId__c = prices.ExternalId__c));
        }
       	Set<String> externalIdSet = new Set<String>();
        for(String value : externalIdMap.values()){
        	externalIdSet.add(value);
        }
        for(JurosDescontoAntecipao__c interest : interestList){
            if(externalIdSet.contains(interest.ExternalId__c)){
                pricesList.add(interest);
            }
            
        }
        
        for(String repetiton : repetitonsZPRS){
            TemplateDataIntegrationFields.ResponseParent response = new TemplateDataIntegrationFields.ResponseParent();
            response.status = true;
            response.success('ZPRS', repetiton, 'JurosDescontoAntecipao__c');
            responseList.add(response);
        }
        return pricesList;
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