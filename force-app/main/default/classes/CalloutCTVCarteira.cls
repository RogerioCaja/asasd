public with sharing class CalloutCTVCarteira {

    public static IntegrationUtils.CalloutCTVResponse processIntegration(){

        List<Territory2> territoryList = new List<Territory2>([SELECT id, DeveloperName, lastmodifieddate, ParentTerritory2.DeveloperName, name, Territory2Type.DeveloperName FROM territory2]);

        
        IntegrationUtils.CalloutCTVResponse calloutResponse = sendOrder(territoryList);

        if (calloutResponse.success) {
            
            //ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponse;

        }
        
        return calloutResponse;
    }

    public static IntegrationUtils.CalloutCTVResponse sendOrder(List<Territory2> territoryList) {
            
        List<RequestParameters> request = new List<RequestParameters>();

        for (Territory2 territory : territoryList) {
            request.add(new RequestParameters(territory));
        }

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
        public Object header;

        public List<CalloutCTVCarteira.ClienteParameters> Clientes;

        public RequestParameters(Territory2 territory){
            List<String> accountIds = new List<String>();
            
            UserTerritory2Association territoryAsso = [SELECT id, User.CodigoSAP__c FROM UserTerritory2Association WHERE Territory2Id =: territory.Id];
            List<ObjectTerritory2Association> terrytoryObject = new List<ObjectTerritory2Association>([SELECT Id, ObjectId  FROM ObjectTerritory2Association WHERE Territory2Id =: territory.Id]);
            
            for(ObjectTerritory2Association terrytory : terrytoryObject){
                
                accountIds.add(terrytory.ObjectId);
            }

            List<Account> accountList = new List<Account>([SELECT Id, ExternalId__c  FROM Account WHERE Id =: accountIds]);

            CalloutCTVCarteira.HeaderInsert header = new CalloutCTVCarteira.HeaderInsert();
            header.IdTerritorio = territory.DeveloperName;
            header.VendedorSAP = territoryAsso.User.CodigoSAP__c;
            header.DataHoraAtualizacao = territory.LastModifiedDate;
            header.TerritorioPai = territory.ParentTerritory2Id;
            header.NamePosition = territory.Name;
            header.TipoTerritorio = territory.Territory2Type.DeveloperName;
            this.header = header; 
    
            for(Account acc : accountList){
                Clientes.add(new CalloutCTVCarteira.ClienteParameters(acc.ExternalId__c));
            }
        }
    }

    public class HeaderInsert{
        public String IdTerritorio;
        public String TerritorioPai;
        public Datetime DataHoraAtualizacao;
        public String NamePosition;
        public String VendedorSAP;
        public String TipoTerritorio;

        public HeaderInsert(){}
    }

    public class HeaderUpdate{
        public String codSap;
        public String codSalesforce;
        public Date  expiredDate;

        // public HeaderUpdate(){}
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
