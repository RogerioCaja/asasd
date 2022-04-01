public class IntegrationUtils {
    
    //String check
    public static Boolean convertEmptyString(String str) {
        return ((String.isBlank(str) || str == 'null' || str == null || str == '') ? true : false); 
    }
    
    //Records upsert validation, adding results to the response list
    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, List<TemplateDataIntegrationFields.ResponseParent> responseList, List<SObject> sObjectListToUpsert, Schema.SObjectField field){
        TemplateDataIntegrationFields.ResponseParent responseData;
        Boolean hasError = false;
        for (TemplateDataIntegrationFields.Response response : responseList) {
            if(response.status == false)
				hasError = true;                
        }

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new TemplateDataIntegrationFields.ResponseParent();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if (upsResult.isSuccess()) {
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            }
            else {
                responseData.error(
                    String.valueOf(objResult.get(field)),
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
                hasError = true;
            }
            responseList.add(responseData);
        }
        return hasError;
    }

    //Child records upsert validation, adding results to the response list
    public static void upsertChildRecords(List<Database.UpsertResult> upsResults, Map<String, List<TemplateDataIntegrationFields.Response>> responseMap, List<SObject> sObjectListToUpsert, Schema.SObjectField field){
        TemplateDataIntegrationFields.Response responseData;

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new TemplateDataIntegrationFields.Response();

            SObject objResult = sObjectListToUpsert[i];

            Database.UpsertResult upsResult = upsResults[i];
            
            if(upsResult.isSuccess()){
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                ); 
            }
            else {
                responseData.error(
                    String.valueOf(objResult.get(field)), 
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
            }
            
            //Associating child object's response with object response
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if (objResult.getSObjectType() == globalDescribe.get('PricebookEntry')) {
                PricebookEntry aux = (PricebookEntry)objResult;
                if(responseMap.keySet().contains(aux.Pricebook2Id)){
                    responseMap.get(aux.Pricebook2Id).add(responseData);
                }
                else{
                    responseMap.put(aux.Pricebook2Id, new List<TemplateDataIntegrationFields.Response>{responseData});
                }
            }
        }
    }
    
}