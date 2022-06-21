public without sharing class Lookup {
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String data, Boolean barterSale) {
        RequestDTO requestData = (RequestDTO) JSON.deserialize(data, RequestDTO.class);

        System.debug(requestData);

        String query = getQueryBase(requestData);

        Set<Id> availableCtvs = new Set<Id>();
        if (requestData.targetObject == 'User') {
            Boolean userRelatedToTerritory = false;
            Set<Id> userTerritories = new Set<Id>();
            String userTerritoryType = '';
            List<String> territoryTypes = new List<String>{'Torre', 'SalesOrg', 'SalesOffice', 'SalesTeam', 'SellerPosition'};

            for (UserTerritory2Association userAssociation : [
                SELECT Id,
                       Territory2Id,
                       Territory2.Territory2Type.DeveloperName
                  FROM UserTerritory2Association
                 WHERE UserId =: UserInfo.getUserId()
            ]) {
                userTerritories.add(userAssociation.Territory2Id);
                if (userAssociation.Territory2.Territory2Type.DeveloperName == 'SellerPosition') {
                    userRelatedToTerritory = true;
                }

                userTerritoryType = territoryTypes.indexOf(userAssociation.Territory2.Territory2Type.DeveloperName) > territoryTypes.indexOf(userTerritoryType) &&
                                    territoryTypes.indexOf(userTerritoryType) > -1 ? userTerritoryType : userAssociation.Territory2.Territory2Type.DeveloperName;
            }

            Set<Id> relatedTerritories = new Set<Id>();
            if (!userRelatedToTerritory) {
                for (ObjectTerritory2Association objAssociation : [
                    SELECT Id,
                           Territory2Id
                      FROM ObjectTerritory2Association
                     WHERE ObjectId =: requestData.accountId
                ]) {
                    relatedTerritories.add(objAssociation.Territory2Id);
                }

                String territoryQuery = 'SELECT Id, Territory2Type.DeveloperName FROM Territory2 WHERE Id IN: relatedTerritories ';
                if (userTerritoryType == 'Torre') territoryQuery += 'AND ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id IN: userTerritories';
                else if (userTerritoryType == 'SalesOrg') territoryQuery += 'AND ParentTerritory2.ParentTerritory2.ParentTerritory2Id IN: userTerritories';
                else if (userTerritoryType == 'SalesOffice') territoryQuery += 'AND ParentTerritory2.ParentTerritory2Id IN: userTerritories';
                else if (userTerritoryType == 'SalesTeam') territoryQuery += 'AND ParentTerritory2Id IN: userTerritories';
                
                for(SObject sobj : Database.query(territoryQuery)) {
                    relatedTerritories.add((Id)sobj.get('Id'));
                }
            }

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
                ' <> ' + relation.parentRecord;
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
}