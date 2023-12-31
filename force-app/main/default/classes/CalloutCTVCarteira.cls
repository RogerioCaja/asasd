public with sharing class CalloutCTVCarteira {

    @future(callout = true)
    public static void processIntegration(){
        List<Territory2> territoryList = new List<Territory2>([SELECT id, DeveloperName, lastmodifieddate, ParentTerritory2.DeveloperName, name, Territory2Type.DeveloperName FROM territory2]);
        sendOrder(territoryList);
    }

    public static void sendOrder(List<Territory2> territoryList) {

        List<RequestParameters> request = new List<RequestParameters>();
        
        for (Territory2 territory : territoryList) {
            System.debug('territory: '+ territory);
            request.add(new RequestParameters(territory));
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

        public RequestParameters(Territory2 territory){
            List<String> accountIds = new List<String>();
            CalloutCTVCarteira.HeaderInsert header = new CalloutCTVCarteira.HeaderInsert();
            UserTerritory2Association territoryAsso;

            Try{
                territoryAsso = [SELECT id, User.CodigoSAP__c FROM UserTerritory2Association WHERE Territory2Id =: territory.Id];
             } 
             Catch(System.QueryException e){
                territoryAsso = null;
            }
            List<ObjectTerritory2Association> terrytoryObject = new List<ObjectTerritory2Association>([SELECT Id, ObjectId  FROM ObjectTerritory2Association WHERE Territory2Id =: territory.Id]);
            for(ObjectTerritory2Association terrytory : terrytoryObject){
                accountIds.add(terrytory.ObjectId);
            }
            Territory2 territoryParrent;
            if(territory.ParentTerritory2Id != null){
                territoryParrent = [SELECT id, DeveloperName, lastmodifieddate, ParentTerritory2.DeveloperName, name, Territory2Type.DeveloperName FROM territory2 WHERE Id =: territory.ParentTerritory2Id];
            }
            List<Account> accountList = new List<Account>([SELECT Id, ExternalId__c  FROM Account WHERE Id =: accountIds]);
            header.IdTerritorio = territory.DeveloperName;
            header.VendedorSAP = territoryAsso != null ?  territoryAsso.User.CodigoSAP__c : null;
            header.DataHoraAtualizacao = territory.LastModifiedDate;
            header.TerritorioPai = territoryParrent != null ? territoryParrent.DeveloperName : null;
            header.NamePosition = territory.Name;
            header.TipoTerritorio = territory.Territory2Type.DeveloperName;
            List<CalloutCTVCarteira.ClienteParameters> clientList= new List<CalloutCTVCarteira.ClienteParameters>();
            if(header.TipoTerritorio == 'SellerPosition'){
                for(Account acc : accountList){
                    clientList.add(new CalloutCTVCarteira.ClienteParameters(acc.ExternalId__c));
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
