public with sharing class FactoryDataIntegration {
       
    //Object validation of required fields, adding error response and objects for upsert
    @TestVisible
    private static void validateObject(String fieldId, String fieldKey, SObject data, List<SObject> listToUpsert, List<TemplateDataIntegrationFields.Response> responseList, List<String> requiredField){
        TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
        if (responseList instanceOf List<TemplateDataIntegrationFields.ResponseParent>) {
			response = new TemplateDataIntegrationFields.ResponseParent();
        }
        response.status = true;
        
        for (String field : requiredField) {
            if (IntegrationUtils.convertEmptyString(data.get(field) + '')) {
                if (String.isNotEmpty((String)data.get(fieldId))){
                    response.error(
                        data.get(fieldId) + '',
                        data.get(fieldKey) + '',
                        'Valor inválido para o campo obrigatório: ' + field,
                        String.valueOf(listToUpsert.getSObjectType())
                    );
                }
                else {
                    response.error(
                        data.get(fieldKey) + '',
                        'Valor inválido para o campo obrigatório: ' + field,
                        String.valueOf(listToUpsert.getSObjectType())
                    );
                }
                
                System.debug(response);
            	break;
            }
        }

        if(response.status){
            listToUpsert.add(data);
        }
        else{
            responseList.add(response);
        }
    }

    //Conversion of the template list into the object list
    public static void convertSObject(SObject sObj, String service, List<TemplateDataIntegrationFields.FieldData> fieldDataList, List<TemplateDataIntegrationFields.Response> responseList, List<SObject> listToUpsert, Map<String, String> lookups) {

        String sObjectName = String.valueOf(sObj.getSObjectType());

        Type t = Type.forName('TemplateDataIntegrationFields.' + sObjectName.replaceAll('__c|__mdt|__|_', '') +service+ 'Data');

        if (t == null) {
            throw new FactoryDataIntegrationException('Invalid defaults class.');
        }

        TemplateDataIntegrationFields.FieldData defaults = (TemplateDataIntegrationFields.FieldData) t.newInstance();

        for (TemplateDataIntegrationFields.FieldData Obj : fieldDataList) {
            validateObject(defaults.getFieldId(), defaults.getFieldKey(), Obj.serialize(lookups), listToUpsert, responseList, defaults.getRequiredFields());
        }
    }

    public static void convertSObject(SObject sObj, String service, List<TemplateDataIntegrationFields.JurosDescontoAntecipaoINData> fieldDataList, List<TemplateDataIntegrationFields.Response> responseList, List<SObject> listToUpsert, 
    Map<String, String> lookups, Map<String, List<String>> requiredFields, Map<String, Boolean> isValidMap) {

        TemplateDataIntegrationFields.JurosDescontoAntecipaoINData defaults = new TemplateDataIntegrationFields.JurosDescontoAntecipaoINData();

        for (TemplateDataIntegrationFields.JurosDescontoAntecipaoINData Obj : fieldDataList) {
            if(isValidMap.containsKey(Obj.externalId)){
                if(isValidMap.get(Obj.externalId))
                   validateObject(defaults.getFieldId(), defaults.getFieldKey(), Obj.serialize(lookups), listToUpsert, responseList, requiredFields.get(Obj.table));
               else
                   validateObject(defaults.getFieldId(), defaults.getFieldKey(), Obj.serialize(lookups), listToUpsert, responseList, defaults.getRequiredFields());
           }
        }
    }

    //Object child validation of required fields, adding error response and objects for upsert
    @TestVisible
    private static void validateObjectChild(String fieldKey, SObject data, List<SObject> listToUpsert, Map<String, List<TemplateDataIntegrationFields.Response>> responseMap, List<String> requiredField, Map<String, String> parentMapKeys){
        TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
        response.status = true;
        system.debug(requiredField);
        for (String field : requiredField) {
            system.debug(data.get(field)+'');

            if(IntegrationUtils.convertEmptyString(data.get(field)+'')){
                response.error(data.get(fieldKey)+'', 'Valor inválido para o campo obrigatório: '+field, String.valueOf(listToUpsert.getSObjectType()));
                system.debug(response);
            	break;
            }
        }
        if(response.status){
            listToUpsert.add(data);
        }
        else {
            System.debug(parentMapKeys.get(data.get(fieldKey) + ''));
            if(responseMap.keySet().contains(parentMapKeys.get(data.get(fieldKey) + ''))){
                responseMap.get(parentMapKeys.get(data.get(fieldKey) + '')).add(response);
            }
            else{
                responseMap.put(parentMapKeys.get(data.get(fieldKey) + ''), new List<TemplateDataIntegrationFields.Response>{response});
            }
        }
    }

    //Conversion of the template list into the object child list
    public static void convertSObjectChild(SObject sObj, String service, List<TemplateDataIntegrationFields.FieldDataChild> fieldDataList, Map<String, List<TemplateDataIntegrationFields.Response>> responseMap, List<SObject> listToUpsert, Map<String, String> lookups, Map<String, String> parentMapKeys) {

        String sObjectName = String.valueOf(sObj.getSObjectType());

        Type t = Type.forName('TemplateDataIntegrationFields.' + sObjectName.replaceAll('__c|__mdt|__|_', '') +service+ 'Data');

        if (t == null) {
            throw new FactoryDataIntegrationException('Invalid defaults class.');
        }

        TemplateDataIntegrationFields.FieldDataChild defaults = (TemplateDataIntegrationFields.FieldDataChild) t.newInstance();

        for(TemplateDataIntegrationFields.FieldDataChild Obj : fieldDataList){
            SObject serializedObject = Obj.serialize(lookups);
            
			String serializedKey = (String)serializedObject.get(defaults.getFieldKey());
            String fieldKey = String.isNotEmpty(serializedKey) ? defaults.getFieldKey() : defaults.getFieldExternal();

            validateObjectChild(fieldKey, serializedObject, listToUpsert, responseMap, defaults.getRequiredFields(), parentMapKeys);
        }
    }

    public class FactoryDataIntegrationException extends Exception {}
}