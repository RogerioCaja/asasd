public with sharing class CalloutBP {
    
    public static IntegrationUtils.CalloutBpResponse processIntegration(){

        IntegrationUtils.CalloutBpResponse calloutBpResponse = sendOrder();
        
        List<Account> accountList = new List<Account>();
        List<LimiteCreditoINData> creditoList = new List<LimiteCreditoINData>();
        List<CompanyINData> companyList = new List<CompanyINData>();
        if (calloutBpResponse.success) {
            ResponseParameters resp = (ResponseParameters) calloutBpResponse.parsedResponse;
            
            Map<String, Id> lookups = new Map<String, Id>();
            List<String> accountIdsList = new List<String>();
            List<AccountINData> accountInDataList = new List<AccountINData>();
            for(ResponseParametersWrapper valor : resp.responses){
                accountInDataList.addALL(valor.AccountINData);
            }
            for(AccountINData valor : accountInDataList){
                
                accountIdsList.add(valor.CodigoExterno);
            }
            System.debug('accountIdsList: '+ accountIdsList);
            List<Account> accountListExternalId = new List<Account>([SELECT Id FROM Account WHERE ExternalId__c =: accountIdsList]);
            for(Account acc : accountListExternalId){
                lookups.put('Account' + acc.ExternalId__c, acc.Id);
            }

            for(AccountINData valor : accountInDataList){
                for(LimiteCreditoINData cred : valor.creditoEntries){
                    cred.CodigoExternoAccount = valor.CodigoExterno;
                    creditoList.add(cred);
                }
                for(CompanyINData company : valor.companyEntries){
                    company.CodigoExternoAccount = valor.CodigoExterno;
                    companyList.add(company);
                }
                Account ac = new Account(
                ExternalId__c = valor.CodigoExterno,
                ParentId = lookups.containsKey('Account__c'+valor.ContaPai) ? lookups.get('Account__c'+valor.ContaPai) : null,
                CNPJ__c = valor.CNPJ,
                CPF__c = valor.CPF,
                MunicipalRegistration__c = valor.InscricaoMunicipal,
                StateRegistration__c = valor.InscricaoEstadual,
                Email__c = valor.Email,
                Phone = valor.Telefone,
                Status__c = valor.Status);
                
                ac.ShippingStreet = valor.RuaEntrega;
                ac.ShippingCity = valor.CidadeEntrega;
                ac.ShippingState = valor.EstadoEntrega;
                ac.ShippingCountry = valor.PaisEntrega;
                ac.ShippingPostalCode = valor.CEPEntrega;
                ac.BillingStreet = valor.RuaCobranca;
                ac.BillingCity = valor.CidadeCobranca;
                ac.BillingState = valor.EstadoCobranca;
                ac.BillingCountry = valor.PaisCobranca;
                ac.BillingPostalCode = valor.CEPCobranca;
                accountList.add(ac);
            }
            System.debug('accountList: '+ accountList);
                       
            if (!accountList.isEmpty()) {
				upsert accountList ExternalId__c;
			}
            Map<String, Id> newLookups = creatyNewLookup(companyList, creditoList, lookups);
            System.debug('creditoList: '+ creditoList);
            System.debug('companyList: '+ companyList);
            System.debug('newLookups: '+ newLookups);
            creatyCredit(creditoList, newLookups);
            creatyCompany(companyList, newLookups);
            System.debug('integração foi um sucesso');
        }
        
        return calloutBpResponse;
    }
    public static Map<String, Id> creatyNewLookup(List<CompanyINData> companyList, List<LimiteCreditoINData> creditoList, Map<String, Id> lookups){
        Set<String> accountIdList = new Set<String>();
        Set<String> salesOrganizationIdList = new Set<String>();
        Set<String> activitySectorIdList = new Set<String>();
        Set<String> distributionChannelIdList = new Set<String>();
        Set<String> salesOfficeIdList = new Set<String>();
        Set<String> salesTeamIdList = new Set<String>();
        
        List<String> cultureIdsList = new List<String>();
        List<String> safraIdsList = new List<String>();

        for(LimiteCreditoINData valor : creditoList){
            accountIdList.add(valor.CodigoExternoAccount);
            salesOrganizationIdList.add(valor.OrganizacaoVendas);
            cultureIdsList.add(valor.Cultura);
            safraIdsList.add(String.valueOf(valor.Safra));
        }
        for(CompanyINData valor : companyList){
            accountIdList.add(valor.CodigoExternoAccount);
            salesOrganizationIdList.add(valor.OrganizacaoVendas);
            activitySectorIdList.add(valor.SetorAtividade);
            distributionChannelIdList.add(valor.CanalDistribuicao);
            salesOfficeIdList.add(valor.EscritorioVendas);
            salesTeamIdList.add(valor.EquipeVendas);
        }
        //Get Account
        List<Account> accountListExternalId = new List<Account>([SELECT Id FROM Account WHERE ExternalId__c =: accountIdList]);
        for(Account acc : accountListExternalId){
            lookups.put('Account' + acc.ExternalId__c, acc.Id);
        }
        //Get SalesOrg
        List<SalesOrg__c> salesList = new List<SalesOrg__c>([SELECT Id, SalesOrganizationCode__c FROM SalesOrg__c WHERE SalesOrganizationCode__c =: salesOrganizationIdList]);
        for (SalesOrg__c sales : salesList) {
            lookups.put('SalesOrg__c' + sales.SalesOrganizationCode__c, sales.Id);
        }
        //Get ActivitySector
        List<ActivitySector__c> activyList = new List<ActivitySector__c>([SELECT Id, Codigo__c FROM ActivitySector__c WHERE Codigo__c =: activitySectorIdList]);
        for (ActivitySector__c sector : activyList) {
            lookups.put('ActivitySector__c' + sector.Codigo__c, sector.Id);
        }
        //Get DistributionChannel
        List<DistributionChannel__c> distributionList = new List<DistributionChannel__c>([SELECT Id, Codigo__c FROM DistributionChannel__c WHERE Codigo__c =: distributionChannelIdList]);
        for (DistributionChannel__c distribution : distributionList) {
            lookups.put('DistributionChannel__c' + distribution.Codigo__c, distribution.Id);
        }
        //Get SalesOffice
        List<SalesOffice__c> salesOfficeList = new List<SalesOffice__c>([SELECT Id, Codigo__c FROM SalesOffice__c WHERE Codigo__c =: salesOfficeIdList]);
        for (SalesOffice__c office : salesOfficeList) {
            lookups.put('SalesOffice__c' + office.Codigo__c, office.Id);
        }
        //Get salesTeam
        List<SalesTeam__c> salesTeamList = new List<SalesTeam__c>([SELECT Id, ExternalId__c FROM SalesTeam__c WHERE ExternalId__c =: salesTeamIdList]);
        for (SalesTeam__c team : salesTeamList) {
            lookups.put('SalesTeam__c' + team.ExternalId__c, team.Id);
        }
        //Get Culture
        List<Cultura__c> cultureList = new List<Cultura__c>([SELECT Id, Codigo__c FROM Cultura__c WHERE Codigo__c =: cultureIdsList]);
        for (Cultura__c cult : cultureList) {
            lookups.put('Cultura__c' + cult.Codigo__c, cult.Id);
        }
        //Get Safra
        List<Safra__c> safraList = new List<Safra__c>([SELECT Id, Code__c FROM Safra__c WHERE Code__c =: safraIdsList]);
            for (Safra__c safra : safraList) {
            lookups.put('Safra__c' + safra.Code__c, safra.Id);
        }
        return lookups;
    }
    public static void creatyCompany(List<CompanyINData> companyList, Map<String, Id> lookups){
        
        List<Company__c> companyListToUpsert = new List<Company__c>();
        for(CompanyINData valor : companyList){
            Company__c company = new Company__c(
            Conta__c = lookups.containsKey('Account__c'+valor.CodigoExternoAccount) ? lookups.get('Account__c'+valor.CodigoExternoAccount) : null,
            SalesOrg__c = lookups.containsKey('SalesOrg__c'+valor.OrganizacaoVendas) ? lookups.get('SalesOrg__c'+valor.OrganizacaoVendas) : null,
            ActivitySector__c = lookups.containsKey('ActivitySector__c'+valor.SetorAtividade) ? lookups.get('ActivitySector__c'+valor.SetorAtividade) : null,
            DistributionChannel__c = lookups.containsKey('DistributionChannel__c'+valor.CanalDistribuicao) ? lookups.get('DistributionChannel__c'+valor.CanalDistribuicao) : null,
            FiscalDomicile__c = valor.DomicilioFiscal,
            SalesOffice__c = lookups.containsKey('SalesOffice__c'+valor.EscritorioVendas) ? lookups.get('SalesOffice__c'+valor.EscritorioVendas) : null,
            SalesTeam__c = lookups.containsKey('SalesTeam__c'+valor.EquipeVendas) ? lookups.get('SalesTeam__c'+valor.EquipeVendas) : null,
            ClientGroup__c = valor.GrupoClientes,
            Blocked__c = valor.Bloqueado,
            Status__c = valor.Status,
            SalesSector__c = valor.SetorVendas,
            ExternalId__c = valor.CodigoExternoAccount + valor.OrganizacaoVendas + valor.SetorAtividade + valor.CanalDistribuicao + valor.EscritorioVendas + valor.EquipeVendas
            );
            companyListToUpsert.add(company);
        }
        if (!companyListToUpsert.isEmpty()) {
            upsert companyListToUpsert ExternalId__c;
        }

    }
    public static void creatyCredit(List<LimiteCreditoINData> creditoList, Map<String, Id> lookups){

        List<LimiteCredito__c> creditListToUpsert = new List<LimiteCredito__c>();
        for(LimiteCreditoINData valor : creditoList){
            LimiteCredito__c credit = new LimiteCredito__c(
            Account__c = lookups.containsKey('Account__c'+valor.CodigoExternoAccount) ? lookups.get('Account__c'+valor.CodigoExternoAccount) : null,
            OrganizacaoVendas__c = lookups.containsKey('SalesOrg__c'+valor.OrganizacaoVendas) ? lookups.get('SalesOrg__c'+valor.OrganizacaoVendas) : null,
            Culture__c = lookups.containsKey('Culture__c'+valor.Cultura) ? lookups.get('Culture__c'+valor.Cultura) : null,
            Guarantee__c = valor.Garantia,
            LimitValue__c = valor.Valor,
            BlockedCredit__c = valor.Bloqueado,
            LimitBalance__c = valor.Saldo,
            ConcessionDate__c = valor.DataConcessao,
            EndDate__c = valor.DataVencimento,
            MaintenanceDate__c = valor.DataManutencao,
            Safra__c = lookups.containsKey('Safra__c'+String.valueOf(valor.Safra)) ? lookups.get('Safra__c'+String.valueOf(valor.Safra)) : null,
            ExternalId__c = valor.CodigoExternoAccount + valor.Safra + valor.Cultura + valor.Garantia);
            creditListToUpsert.add(credit);
        }
        if (!creditListToUpsert.isEmpty()) {
            upsert creditListToUpsert ExternalId__c;
        }
    } 

    public static IntegrationUtils.CalloutBpResponse sendOrder() {

        List<RequestParameters> request = new List<RequestParameters>();
        Datetime UTC = System.now().addHours(-1); 
        Organization orgDetails = [SELECT Id, TimeZoneSidKey FROM Organization WHERE Id = :UserInfo.getOrganizationId()]; 
        Timezone tz = Timezone.getTimeZone(orgDetails.TimeZoneSidKey);
        Datetime orgTime = UTC.addSeconds((tz.getOffset(UTC)/1000)); 
        System.debug('orgTime: '+ orgTime);

        request.add(new RequestParameters(orgTime));
        System.debug('request: '+ request);
        
        String code = (!Test.isRunningTest() ? getAcessCode() : 'acessToken');
        System.debug('AcessCode: '+ code);
        String payload = JSON.serialize(request);
        System.debug('PayloadCheck: '+ payload);
        //Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
        String accessToken = code;//! FALTA SABER A RESPOSTA DO SAP QUANTO A AUTENTICAÇÃO! F
        //Url mock: https://aabb2740-69b0-4737-925c-2c40367a3737.mock.pstmn.io//CalloutBP
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
            System.debug('response.getBody(): '+ response.getBody());
            try {
                
                List<ResponseParametersWrapper> responses = (List<ResponseParametersWrapper>) JSON.deserialize(response.getBody(), List<ResponseParametersWrapper>.class);
                return new IntegrationUtils.CalloutBpResponse(new ResponseParameters(responses));
            } catch (Exception e) {
                
                String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

                return new IntegrationUtils.CalloutBpResponse(defaultErrorMessage);
            }
        } else {

            IntegrationLog.createLog('Pedido OUT', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
            return new IntegrationUtils.CalloutBpResponse(responseObject.exceptionObject.getMessage());
        }
    }
    public static String getAcessCode(){
        String payloadToken = 'grant_type=client_credentials';
        String endpointToken = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/identityserver/oauth2/token' : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMapToken = new Map<String, String>();
        headersMapToken.put('Content-type', 'application/x-www-form-urlencoded');
        headersMapToken.put('Authorization', 'Basic SWFOUmpqbkFMd2xLZEVhdW1VR3pfZDdV4S0lmVmZOQmY1WXZKY1o2YThh');
        IntegrationUtils.RequestResponseObject responseObject2 = IntegrationUtils.executeCallout(endpointToken, payloadToken, headersMapToken);
        System.debug('responseObject2: '+ responseObject2);
        if (responseObject2.success) {
            HttpResponse response = responseObject2.response;
            System.debug('response.getBody(): '+ response.getBody());
            ResponseParametersToken responses = (ResponseParametersToken) JSON.deserialize(response.getBody(), ResponseParametersToken.class);
            System.debug('responses: '+ responses);
            return responses.access_token;
        } else {
            return null;
        }
    }

    //! Preparing data to Callout
    public class RequestParameters{
        public Datetime Tempo;

        public RequestParameters(Datetime orgTime){
            Datetime now = orgTime;
            this.Tempo = now;
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
        public Boolean succeeded;
        public String errorMessage;
        public List<AccountINData> AccountINData;
    }
    public class AccountINData {
        public String CodigoExterno;
        public String RuaEntrega;
        public String CidadeEntrega;
        public String EstadoEntrega;
        public String PaisEntrega;
        public String CEPEntrega;
        public String RuaCobranca;
        public String CidadeCobranca;
        public String EstadoCobranca;
        public String PaisCobranca;
        public String CEPCobranca;
        public String ContaPai;
        public String CNPJ;
        public String CPF;
        public String InscricaoMunicipal;
        public String InscricaoEstadual;
        public String Email;
        public String Telefone;
        public String Status;
        public List<LimiteCreditoINData> creditoEntries;
        public List<CompanyINData> companyEntries;
    }

    public class ResponseParametersToken {
        public String access_token; 
        public String scope; 
        public String token_type; 
        public Decimal expires_in; 
    }
    public class LimiteCreditoINData{
        public String CodigoExternoAccount;
        public String OrganizacaoVendas;
        public Decimal Valor;
        public Boolean Bloqueado;
        public String Cultura;
        public String Garantia;
        public Decimal Saldo;
        public Date DataConcessao;
        public Date DataVencimento;
        public Date DataManutencao;
        public Decimal Safra;
    }

    public class CompanyINData{
    public String CodigoExternoAccount;    
    public String OrganizacaoVendas;
    public String SetorAtividade;
    public String CanalDistribuicao;
    public String DomicilioFiscal;
    public String EscritorioVendas;
    public String EquipeVendas;
    public String GrupoClientes;
    public Boolean Bloqueado;
    public String Status;
    public String SetorVendas;
    }
    
}
