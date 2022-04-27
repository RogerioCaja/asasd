public with sharing class CalloutCTVCarteira {

    public static IntegrationUtils.CalloutCTVResponse processIntegration(){

        List<Territory2> territoryList = new List<Territory2>([SELECT id, DeveloperName, lastmodifieddate, ParentTerritory2.DeveloperName, name, Territory2Type.DeveloperName FROM territory2]);

        
        IntegrationUtils.CalloutCTVResponse calloutResponse = sendOrder(territoryList);

        if (calloutResponse.success) {
            System.debug('integração foi um sucesso');
            //ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponse;

        }
        
        return calloutResponse;
    }

    public static IntegrationUtils.CalloutCTVResponse sendOrder(List<Territory2> territoryList) {
            
        List<RequestParameters> request = new List<RequestParameters>();

        for (Territory2 territory : territoryList) {
            request.add(new RequestParameters(territory));
        }
        /*
        String payloadAcess = '"grant_type=client_credentials" -H "Authorization: Basic dEQxV2M0bWtXdnRWNWVtRXZSOHlVRF9iUFZvYTpmZmVJQUs5SmdPNXNsbXI1UzVMUXNNcTBOME1h"';
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://apim.agrogalaxy.com.br/identityserver/oauth2/token');
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setHeader('Content-Length',String.valueOf(payloadAcess.length()));
        req.setBody(payloadAcess);
        Http binding = new Http();
        HttpResponse res = binding.send(req);
        System.debug('res: '+ res);
            */
        String payload = JSON.serialize(request);
        System.debug('PayloadCheck: '+ payload);
        //Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
        String accessToken = '';//! FALTA SABER A RESPOSTA DO SAP QUANTO A AUTENTICAÇÃO! F
        
        //Path geralmente cadastrado dentro de ua customSettings
        String endpoint = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/gtw/sales-territory/v1/webhook/_notify' : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-type', 'application/json');
        headersMap.put('Authorization', 'Bearer '+ accessToken);
        
        IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap);

        if (responseObject.success) {

            HttpResponse response = responseObject.response;

            IntegrationLog.createLog('Pedido OUT', 'OUT', response.getBody(), payload, false);
            // .WSLog('Pedido', 'OUTBOUND', response.getBody(), payload, false);
            try {

                List<ResponseParametersWrapper> responses = (List<ResponseParametersWrapper>) JSON.deserialize(response.getBody(), List<ResponseParametersWrapper>.class);
                return new IntegrationUtils.CalloutCTVResponse(new ResponseParameters(responses));
            } catch (Exception e) {
                
                String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

                return new IntegrationUtils.CalloutCTVResponse(defaultErrorMessage);
            }
        } else {

            IntegrationLog.createLog('Pedido OUT', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
            return new IntegrationUtils.CalloutCTVResponse(responseObject.exceptionObject.getMessage());
        }
    }

    //! Preparing data to Callout
    public class RequestParameters{
        public String IdTerritorio;
        public String TerritorioPai;
        public Datetime DataHoraAtualizacao;
        public String NamePosition;
        public String VendedorSAP;
        public String TipoTerritorio;
        public List<CalloutCTVCarteira.ClienteParameters> Clientes;

        public RequestParameters(Territory2 territory){
            List<String> accountIds = new List<String>();
            
            UserTerritory2Association territoryAsso = [SELECT id, User.CodigoSAP__c FROM UserTerritory2Association WHERE Territory2Id =: territory.Id];
            List<ObjectTerritory2Association> terrytoryObject = new List<ObjectTerritory2Association>([SELECT Id, ObjectId  FROM ObjectTerritory2Association WHERE Territory2Id =: territory.Id]);
            
            for(ObjectTerritory2Association terrytory : terrytoryObject){
                
                accountIds.add(terrytory.ObjectId);
            }

            List<Account> accountList = new List<Account>([SELECT Id, ExternalId__c  FROM Account WHERE Id =: accountIds]);

            this.IdTerritorio = territory.DeveloperName;
            this.VendedorSAP = territoryAsso.User.CodigoSAP__c;
            this.DataHoraAtualizacao = territory.LastModifiedDate;
            this.TerritorioPai = territory.ParentTerritory2Id;
            this.NamePosition = territory.Name;
            this.TipoTerritorio = territory.Territory2Type.DeveloperName;
            List<CalloutCTVCarteira.ClienteParameters> clientList= new List<CalloutCTVCarteira.ClienteParameters>();
            for(Account acc : accountList){
                clientList.add(new CalloutCTVCarteira.ClienteParameters(acc.ExternalId__c));
            }
            this.Clientes = clientList;
        }
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
        public String OrderNumber; 
        public List<OrderDetails> DetalhesPedido;
        public List<Messages> Mensagens; 
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
