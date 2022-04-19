@RestResource(urlMapping='/upsertAccount/*')
global with sharing class IntegrationINAccount {
    
    @HttpPost
    global static ResponseModel upsertAccount(List<TemplateDataIntegrationFields.VisaoOrcamentariaINData> request) {
        
        Map<String, Id> lookups = new Map<String, Id>();
        Set<String> recordType = new Set<String>();
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<Account> ListAccountToUpsert = new List<Account>();
        List<String> accountCNPJSet = new List<String>();
        System.debug(request);
        /*
        for (TemplateDataIntegrationFields.VisaoOrcamentariaINData listAccount : request){
            String cnpj = String.valueOf(listAccount.CNPJ_CLIENTE);
            
            
            if(listAccount.IDLinhaservico != null){
                recordType.add('Linha de Serviço');
            }else{
                recordType.add('Garantido/Realizado');
            }
            if(listAccount.NF != null || listAccount.Valor != null){
                recordType.add('Inadimplência');
            }
            if(listAccount.GarantidoTotalPorcente != null || listAccount.GarantidoTotalMargem != null || listAccount.GarantidoTotalReceita != null){
                recordType.add('Performance');
            }
            if(cnpj != null && cnpj.length() == 14){
                String cnpjFormat = cnpj.substring(0,2) + '.' + cnpj.substring(2,5) + '.' + cnpj.substring(5,8) + '/' + cnpj.substring(8,12) +'-'+ cnpj.substring(12,14);
                accountCNPJSet.add(cnpjFormat);
            }
        }
        
        //Account search based on Account CNPJ field sent
        if(accountCNPJSet != null){
            List<Account> accountList = new List<Account>([SELECT Id, CNPJ__c FROM Account WHERE CNPJ__c =: accountCNPJSet]);
            for (Account accoun : accountList) {
                String accountCNPJ = accoun.CNPJ__c.replaceAll('[^a-zA-Z0-9\\s+]', '');
                lookups.put('Account' + accountCNPJ, accoun.Id);
            }
        }

        System.debug('recordType '+recordType);
        List<RecordType> recordTypeLookup = new  List<RecordType>([SELECT Id, Name, DeveloperName FROM RecordType WHERE Name =: recordType AND SObjectType = 'Account']);
        //RecordType search based on RecordType Name field sent
        System.debug('recordTypeLookup '+recordTypeLookup);
        for (RecordType rType : recordTypeLookup) {
            lookups.put('RecordType' + rType.Name, rType.Id);
        }*/
        System.debug('lookups '+lookups);
        //colocar num map os tipos de record e os usar num for igual o primeiro e desta vez preenchendo o 
        FactoryDataIntegration.convertSObject(new Account(), 'IN', request, responseList, ListAccountToUpsert, lookups);

        Map<String, Account> visionMap = new Map<String, Account>();
        visionMap = getMapVisaoOrcamentariaToInsert(ListAccountToUpsert);
               
        system.debug(visionMap);
        //Upserting records (Visao_Orcamentaria)
        IntegrationUtils.upsertRecords(
            Database.upsert(visionMap.values(), Account.Chave_Externa__c, false), 
            responseList, 
            visionMap.values(), 
            Account.Chave_Externa__c
        );


        //Checking integration errors to log
        Boolean hasError = false;

        for(TemplateDataIntegrationFields.Response responseAccount : responseList){
            if(responseAccount.status == false){
                hasError = true;
                break;
            }
        }
        //Create Integration
        IntegrationLog.createLog('Dashboard Inbound Integration','Inbound',JSON.serialize(request),JSON.serialize(responseList),hasError);

        //Returning response
        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }
    
    public static Map<String, Account> getMapVisaoOrcamentariaToInsert(Account[] visaoOrcamentariaList){  
        Map<String, Account> visionMap = new Map<String, Account>();
        for(Account vision : visaoOrcamentariaList){
            visionMap.put(vision.Id_Identidade__c, vision);
        }
        return visionMap;
    }
    
    global class ResponseModel {

        @TestVisible
        List<TemplateDataIntegrationFields.Response> response;

        public ResponseModel(List<TemplateDataIntegrationFields.Response> response) {

            this.response = response;
            
        }
        public ResponseModel(TemplateDataIntegrationFields.ResponseParent response) {

            this.response = new List<TemplateDataIntegrationFields.ResponseParent>{response};
            
        }
        public ResponseModel() {   
            this.response = new List<TemplateDataIntegrationFields.Response>();         
        }
    }
}
