public without sharing class Lookup {
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String data, Boolean barterSale, String salesConditionData, Boolean priceScreen, Boolean clientTerritoriesScreen) {
        RequestDTO requestData = (RequestDTO) JSON.deserialize(data, RequestDTO.class);
        SalesConditionDTO requestSalesCondition = (SalesConditionDTO) JSON.deserialize(salesConditionData, SalesConditionDTO.class);
        
        System.debug(requestData);

        String query = getQueryBase(requestData);
        Set<Id> availableSalesCondition = new Set<Id>();
        String position = 'SellerPosition';

        if(requestData.targetObject == 'Territory2'){
            query +=  'AND Territory2Type.DeveloperName =: position';
        }
        if(requestData.targetObject == 'SalesCondition__c'){
            List<String> typeProducts;
            if( requestSalesCondition.typeOrder == 'Venda de Serviço'){
                typeProducts = new List<String>{'DIEN'};
            }else{
                typeProducts = new List<String>{'FERT', 'HAWA', 'ZCOM'};
            }
           
            Id recTypeZPR0 = Schema.SObjectType.JurosDescontoAntecipao__c.getRecordTypeInfosByDeveloperName().get('ZPR0').getRecordTypeId();
            
            for(JurosDescontoAntecipao__c listPrice : [SELECT Id, SalesCondition__c
                                                        FROM JurosDescontoAntecipao__c
                                                        WHERE RecordTypeId =: String.escapeSingleQuotes(recTypeZPR0)
                                                        AND Product__r.ProductType__c IN: typeProducts
                                                        AND StartDate__c <=: System.today()
                                                        AND EndDate__c >=: System.today()
                                                        AND SalesOrg__c =: requestSalesCondition.salesOrgId
                                                        AND harvest__r.Name =: requestSalesCondition.safraName 
                                                        AND Currency__c =: requestSalesCondition.currencyGet]){

                availableSalesCondition.add(listPrice.SalesCondition__c);
            }
            query += ' AND Id IN: availableSalesCondition';
        }

        if (requestData.targetObject == 'User' && !clientTerritoriesScreen) {
            Boolean userRelatedToTerritory = false;
            Set<Id> userTerritories = new Set<Id>();
            String userTerritoryType = '';
            List<String> territoryTypes = new List<String>{'Torre', 'SalesOrg', 'SalesOffice', 'SalesTeam', 'SellerPosition'};

            String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
            for (UserTerritory2Association userAssociation : [
                SELECT Id,
                       Territory2Id,
                       Territory2.Territory2Type.DeveloperName
                  FROM UserTerritory2Association
                 WHERE UserId =: UserInfo.getUserId()
            ]) {
                userTerritories.add(userAssociation.Territory2Id);
                if (userAssociation.Territory2.Territory2Type.DeveloperName == 'SellerPosition' && profileName != 'Balcão') {
                    userRelatedToTerritory = true;
                }

                userTerritoryType = territoryTypes.indexOf(userAssociation.Territory2.Territory2Type.DeveloperName) > territoryTypes.indexOf(userTerritoryType) &&
                                    territoryTypes.indexOf(userTerritoryType) > -1 ? userTerritoryType : userAssociation.Territory2.Territory2Type.DeveloperName;
            }

            System.debug('userRelatedToTerritory: ' + userRelatedToTerritory);
            Set<Id> relatedTerritories = new Set<Id>();
            if (!userRelatedToTerritory) {
                System.debug('profileName: ' + profileName);
                for (ObjectTerritory2Association objAssociation : [
                    SELECT Id,
                           Territory2Id,
                           Territory2.Territory2Type.DeveloperName
                      FROM ObjectTerritory2Association
                     WHERE ObjectId =: requestData.accountId
                ]) {
                    relatedTerritories.add(objAssociation.Territory2Id);

                    if (profileName == 'Balcão') {
                        userTerritories.add(objAssociation.Territory2Id);
                        userTerritoryType = territoryTypes.indexOf(objAssociation.Territory2.Territory2Type.DeveloperName) > territoryTypes.indexOf(userTerritoryType) &&
                                            territoryTypes.indexOf(userTerritoryType) > -1 ? userTerritoryType : objAssociation.Territory2.Territory2Type.DeveloperName;
                    }
                }

                System.debug('relatedTerritories: ' + relatedTerritories);
                System.debug('userTerritoryType: ' + userTerritoryType);
                System.debug('userTerritories: ' + userTerritories);
                String territoryQuery = 'SELECT Id, Territory2Type.DeveloperName FROM Territory2 WHERE Id IN: relatedTerritories ';
                if (userTerritoryType == 'Torre') territoryQuery += 'AND ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id IN: userTerritories';
                else if (userTerritoryType == 'SalesOrg') territoryQuery += 'AND ParentTerritory2.ParentTerritory2.ParentTerritory2Id IN: userTerritories';
                else if (userTerritoryType == 'SalesOffice') territoryQuery += 'AND ParentTerritory2.ParentTerritory2Id IN: userTerritories';
                else if (userTerritoryType == 'SalesTeam') territoryQuery += 'AND ParentTerritory2Id IN: userTerritories';
                
                System.debug('territoryQuery: ' + territoryQuery);
                for(SObject sobj : Database.query(territoryQuery)) {
                    relatedTerritories.add((Id)sobj.get('Id'));
                }
            }

            System.debug('relatedTerritories: ' + relatedTerritories);
            Set<Id> relatedUsers = new Set<Id>();
            if (userRelatedToTerritory) {
                relatedUsers.add(UserInfo.getUserId());
            } else {
                for (UserTerritory2Association userAssociation : [
                    SELECT Id,
                           UserId
                      FROM UserTerritory2Association
                     WHERE Territory2Id IN: relatedTerritories
                       AND Territory2.Territory2Type.DeveloperName = 'SellerPosition'
                   ]) {
                    relatedUsers.add(userAssociation.UserId);
                }
            }

            query += ' AND Id IN: relatedUsers';
        } else if (requestData.targetObject == 'CondicaoPagamento__c') {
            query += ' AND BarterCondition__c =: barterSale';
        }

        System.debug(query);
        query += ' LIMIT 25';
        return Database.query(query);
    }

    public static String getQueryBase(RequestDTO requestData) {
    	String query = 'SELECT Id, #SEARCH_FIELDS# FROM #OBJECT_API# WHERE Id != NULL ';
        query = query.replace('#OBJECT_API#', requestData.targetObject);

        Set<String> fieldsSet = getQueryFieldsSet(requestData);
        String fields = String.join((Iterable<String>)fieldsSet, ', ');
        query = query.replace('#SEARCH_FIELDS#', fields);

        if (requestData.searchValue != null) {
            query += 'AND ( #SEARCH_BASE# )';
        }

        String searchBase = parseSearchFields(requestData.searchFields);

        query = query.replaceAll('#SEARCH_BASE#', searchBase);

        if (requestData.searchValue != null) {
            query = query.replaceAll('#SEARCH_VALUE#', String.escapeSingleQuotes(requestData.searchValue));
        }

        if (requestData.relations != null && requestData.relations.size() > 0) {
            query += parseRelationFields(requestData.relations);
        }

        if (requestData.differentRelations != null && requestData.differentRelations.size() > 0) {
            query += parseDifferentRelationFields(requestData.differentRelations);
        }

        return query;
    }

    public static Set<String> getQueryFieldsSet(RequestDTO requestData) {
        Set<String> fieldsSet = new Set<String>();
        fieldsSet.addAll(requestData.searchFields);

        if (requestData.moreFields != null) {
            fieldsSet.addAll(requestData.moreFields);
        }

        return fieldsSet;
    }

    public static String parseSearchFields(List<String> searchFields) {
        String searchBase = '';

        for (Integer i=0; i<searchFields.size(); i++) {
            if (searchFields[i] != 'CashPayment__c') {
                if (i>0) {
                    searchBase += ' OR ' + searchFields[i];
                } else {
                    searchBase +=  searchFields[i];
                }

                searchBase += ' LIKE \'%#SEARCH_VALUE#%\' ';
            }
        }

        return searchBase;
    }

    public static String parseRelationFields(List<RelationDTO> relations) {
        String relationsBase = '';

        for (RelationDTO relation : relations) {
            relationsBase += ' AND ' + relation.parentRelationField +
                ' = ' + '\'' + relation.parentRecord + '\'';
        }

        return relationsBase;
    }

    public static String parseDifferentRelationFields(List<RelationDTO> differentRelations) {
        String relationsBase = '';

        for (RelationDTO relation : differentRelations) {
            relationsBase += ' AND ' + relation.parentRelationField +
                ' <> ' + '\'' + relation.parentRecord + '\'';
        }

        return relationsBase;
    }

    public class RequestDTO {
        public String targetObject;
        public String accountId;
        public List<String> searchFields;
        public List<String> moreFields;

        public List<RelationDTO> relations;
        public List<RelationDTO> differentRelations;

        public String searchValue;
    }

    public class RelationDTO {
        public String parentRelationField;
        public String parentRecord;
    }

    public class SalesConditionDTO{
        public String safraName;
        public String SalesOrgId;
        public String currencyGet;
        public String typeOrder;
    }
}