public without sharing class CalloutCTVCarteira {

    @future(callout = true)
    public static void processIntegration(){
        List<Territory2> territoryList = new List<Territory2>([SELECT id, DeveloperName, lastmodifieddate, ParentTerritory2.DeveloperName, name, Territory2Type.DeveloperName FROM territory2]);
        sendOrder(territoryList);
    }

    public static void sendOrder(List<Territory2> territoryList) {

        List<RequestParameters> request = new List<RequestParameters>();
        List<String> territoryIdList = new List<String>();
        List<String> territoryParrentIdList = new List<String>();
        for (Territory2 territory : territoryList) {
            territoryIdList.add(territory.Id);
            if(territory.ParentTerritory2Id != null){
                territoryParrentIdList.add(territory.ParentTerritory2Id);
            }
        }
        List<UserTerritory2Association> territoryAssoList  = new List<UserTerritory2Association>([SELECT id, Territory2Id, User.CodigoSAP__c FROM UserTerritory2Association WHERE Territory2Id =: territoryIdList]);
        Map<String,UserTerritory2Association> territoryUserAssociationMap = new Map<String,UserTerritory2Association>();
        for (UserTerritory2Association territory : territoryAssoList) {
            territoryUserAssociationMap.put(territory.Territory2Id, territory);
        }
        UserTerritory2Association territoryUserAsso;
        //
        Map<String,Territory2> territoryParentMap = new Map<String,Territory2>();
        List<Territory2> territoryParentList = new List<Territory2>([SELECT id, DeveloperName, lastmodifieddate, ParentTerritory2.DeveloperName, name, Territory2Type.DeveloperName FROM territory2 WHERE Id =: territoryParrentIdList]);
        for (Territory2 territory : territoryParentList) {
            territoryParentMap.put(territory.id, territory);
        }
        Territory2 territoryParent;
        //
        List<ObjectTerritory2Association> terrytoryObject = new List<ObjectTerritory2Association>([SELECT Id, Territory2Id, ObjectId, Object.ExternalId__c  FROM ObjectTerritory2Association WHERE Territory2Id =: territoryIdList]);
        Map<String,List<String>> terrytoryObjectMap = new Map<String,List<String>>();
        for(ObjectTerritory2Association terrytory : terrytoryObject){
            if(terrytoryObjectMap.contains(terrytory.Territory2Id)){
                List<String> accountObjectList = terrytoryObjectMap.get(terrytory.Territory2Id);
                accountObjectList.add(terrytory.Object.ExternalId__c);
                terrytoryObjectMap.put(terrytory.Territory2Id,accountObjectList);
            }else{
                List<String> objectTerritoryAccountList = new List<String>();
                objectTerritoryAccountList.add(terrytory.Object.ExternalId__c);
                terrytoryObjectMap.put(terrytory.Territory2Id,objectTerritoryAccountList);
            }
        }

        List<String> objectAccountExternalList;
        for (Territory2 territory : territoryList) {
            System.debug('territory: '+ territory);
            if(territoryUserAssociationMap.contains(territory.Id)){
                territoryUserAsso = territoryUserAssociationMap.get(territory.Id);
            }else{
                territoryUserAsso = null;
            }
            if(terrytoryObjectMap.contains(territory.Id)){
                objectAccountExternalList = terrytoryObjectMap.get(territory.Id);
            }else{
                objectAccountExternalList = null;
            }
            if(territoryParentMap.contains(territory.ParentTerritory2Id)){
                territoryParent = territoryParentMap.get(territory.ParentTerritory2Id);
            }else{
                territoryParent = null;
            }
            request.add(new RequestParameters(territory,territoryUserAsso, objectAccountExternalList, territoryParent));
        }
        String code = (!Test.isRunningTest() ? getAcessCode() : 'acessToken');
        System.debug('AcessCode: '+ code);
        String payload = JSON.serialize(request);
        System.debug('PayloadCheck: '+ payload);
        //Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
        String accessToken = code;//! FALTA SABER A RESPOSTA DO SAP QUANTO A AUTENTICAÇÃO! F
        //Url mock: https://aabb2740-69b0-4737-925c-2c40367a3737.mock.pstmn.io//CalloutCTVCarteira
        //Path geralmente cadastrado dentro de ua customSettings 
        String endpoint = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/gtw/sales-territory/v1/webhook/_notify' : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-type', 'application/json');
        headersMap.put('Authorization', 'Bearer '+ accessToken);
        
        IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap);

        if (responseObject.success) {

            HttpResponse response = responseObject.response;

            IntegrationLog.createLog('CTV OUT', 'OUT', response.getBody(), payload, false);
            System.debug('response.getBody(): '+ response.getBody());
        } else {
            IntegrationLog.createLog('CTV OUT', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
        }
    }
    public static String getAcessCode(){
        String payloadToken = 'grant_type=client_credentials';
        String endpointToken = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/identityserver/oauth2/token' : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMapToken = new Map<String, String>();
        headersMapToken.put('Content-type', 'application/x-www-form-urlencoded');
        headersMapToken.put('Authorization', 'Basic dEQxV2M0bWtXdnRWNWVtRXZSOHlVRF9iUFZvYTpmZmVJQUs5SmdPNXNsbXI1UzVMUXNNcTBOME1h');
        IntegrationUtils.RequestResponseObject responseObject2 = IntegrationUtils.executeCallout(endpointToken, payloadToken, headersMapToken);
        
        if (responseObject2.success) {
            HttpResponse response = responseObject2.response;
            ResponseParametersToken responses = (ResponseParametersToken) JSON.deserialize(response.getBody(), ResponseParametersToken.class);
            return responses.access_token;
        } else {
            return null;
        }
    }

    //! Preparing data to Callout
    public class RequestParameters{
        public Object header;
        //public List<CalloutCTVCarteira.ClienteParameters> Clientes;

        public RequestParameters(Territory2 territory, UserTerritory2Association territoryAsso, List<String> accountExternalIds, Territory2 territoryParent){
            CalloutCTVCarteira.HeaderInsert header = new CalloutCTVCarteira.HeaderInsert();

            header.IdTerritorio = territory.DeveloperName;
            header.VendedorSAP = territoryAsso != null ?  territoryAsso.User.CodigoSAP__c : null;
            header.DataHoraAtualizacao = territory.LastModifiedDate;
            header.TerritorioPai = territoryParent != null ? territoryParent.DeveloperName : null;
            header.NamePosition = territory.Name;
            header.TipoTerritorio = territory.Territory2Type.DeveloperName;
            List<CalloutCTVCarteira.ClienteParameters> clientList= new List<CalloutCTVCarteira.ClienteParameters>();
            if(header.TipoTerritorio == 'SellerPosition'){
                for(String acc : accountExternalIds){
                    clientList.add(new CalloutCTVCarteira.ClienteParameters(acc));
                }
            }

            header.Clientes = clientList;
            this.header = header;
        }
    }
    public class HeaderInsert{
        public String IdTerritorio;
        public String TerritorioPai;
        public Datetime DataHoraAtualizacao;
        public String NamePosition;
        public String VendedorSAP;
        public String TipoTerritorio;
        public List<CalloutCTVCarteira.ClienteParameters> Clientes;
        public HeaderInsert(){}
    }


    public class ClienteParameters{
        public String CodigoCliente;

        public ClienteParameters(String codigo){
            this.CodigoCliente = codigo;
        }
    }

    //! Response part
    public class ResponseParameters {
        public List<ResponseParametersWrapper> responses;

        public ResponseParameters(List<ResponseParametersWrapper> responses) {
            this.responses = responses;
        }
    }

    public class ResponseParametersWrapper {
        public Boolean Status; 
        public List<OrderDetails> DetalhesPedido;
        public List<Messages> Mensagens; 
    }

    public class ResponseParametersToken {
        public String access_token; 
        public String scope; 
        public String token_type; 
        public Decimal expires_in; 
    }

    public class Messages{
        public String Tipo;
        public String Mensagem;
    }

    public class OrderDetails{
        public String StatusSap;
        public String NumeroOrdemVenda;
    }
}
