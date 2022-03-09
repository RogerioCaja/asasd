public with sharing class Lookup {
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String data) {
        RequestDTO requestData = (RequestDTO) JSON.deserialize(data, RequestDTO.class);

        System.debug(requestData);

        String query = getQueryBase(requestData);

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
            if (i>0) {
                searchBase += ' OR ' + searchFields[i];
            } else {
                searchBase +=  searchFields[i];
            }

            searchBase += ' LIKE \'%#SEARCH_VALUE#%\' ';
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