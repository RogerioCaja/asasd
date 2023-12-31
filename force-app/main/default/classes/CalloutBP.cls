public without sharing class CalloutBP {
    @future(callout = true)
    public static void processIntegration(){

        IntegrationUtils.CalloutBpResponse calloutBpResponse = sendOrder();
        
        List<Account> accountList = new List<Account>();
        List<LimiteCreditoINData> creditoList = new List<LimiteCreditoINData>();
        List<CompanyINData> companyList = new List<CompanyINData>();
        if (calloutBpResponse.success) {
            ResponseParameters resp = (ResponseParameters) calloutBpResponse.parsedResponse;
            System.debug('resp: '+ resp);
            Map<String, Id> lookups = new Map<String, Id>();
            List<String> accountIdsList = new List<String>();
            List<String> accountFatherIdsList = new List<String>();
            List<String> userCodigoSapList = new List<String>();
            for(ResponseParametersWrapper valor : resp.responses){
                if(valor.CodigoExterno != null){
                    accountIdsList.add(valor.CodigoExterno);
                }
                if(valor.ContaPai != null){
                    accountIdsList.add(valor.ContaPai);
                    accountFatherIdsList.add(valor.ContaPai);
                }
            }
            System.debug('accountIdsList: '+ accountIdsList);
            List<Account> accountListExternalId = new List<Account>([SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c =: accountIdsList]);
            for(Account acc : accountListExternalId){
                lookups.put('Account' + acc.ExternalId__c, acc.Id);
            }

            for(ResponseParametersWrapper valor : resp.responses){
                for(LimiteCreditoINData cred : valor.Credito){
                    cred.CodigoExternoAccount = valor.CodigoExterno;
                    creditoList.add(cred);
                }
                for(CompanyINData company : valor.EstruturaOrganizacional){
                    company.CodigoExternoAccount = valor.CodigoExterno;
                    company.CodigoExternoFatherAccount = valor.ContaPai;
                    companyList.add(company);
                }
                String statusType;
                if(valor.Status == ''){
                    statusType = 'Ativo';
                }else{
                    statusType = 'Bloqueado';
                }
                String email = null;
                if(!valor.Email.contains('.com')){
                    if(valor.Email != '' && valor.Email != null){
                        email = valor.Email + '.com';
                    }
                }else{
                    email = valor.Email;
                }
                Account ac = new Account(
                Name = valor.Nome,
                Company__c = valor.Nome,    
                ExternalId__c = valor.CodigoExterno,
                ParentId = lookups.containsKey('Account'+valor.ContaPai) ? lookups.get('Account'+valor.ContaPai) : null,
                CNPJ__c = valor.CNPJ,
                CPF__c = valor.CPF,
                MunicipalRegistration__c = valor.InscricaoMunicipal,
                StateRegistration__c = valor.InscricaoEstadual,
                Email__c = email,
                Phone = valor.Telefone,
                Status__c = statusType);
                
                ac.ShippingStreet = valor.RuaEntrega;
                ac.ShippingCity = valor.CidadeEntrega;
                ac.ShippingState = valor.Estado;
                ac.ShippingCountry = valor.PaisEntrega;
                ac.ShippingPostalCode = valor.CEPEntrega;
                ac.BillingStreet = valor.RuaCobranca;
                ac.BillingCity = valor.CidadeCobranca;
                ac.BillingState = valor.EstadoCobranca;
                ac.BillingCountry = valor.PaisCobranca;
                ac.BillingPostalCode = valor.CEPCobranca;
                accountList.add(ac);
            }
            for(CompanyINData company : companyList){
                if(company.Partner != null && company.Partner != ''){
                    userCodigoSapList.add(company.Partner);
                }
            }          
            Database.UpsertResult[] resultsAccount;
            if (!accountList.isEmpty()) {
                System.debug('accountList: '+accountList);
                resultsAccount = Database.upsert(accountList, Account.ExternalId__c, false);
            }
            List<Account> accountFatherListExternalId = new List<Account>([SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c =: accountFatherIdsList]);
            creatyAccountTerrytoryAssossiation(accountList,accountFatherListExternalId, userCodigoSapList, resp, companyList);

            for(Account acc : accountList){
                lookups.put('Account__c' + acc.ExternalId__c, acc.Id);
            }

            Map<String, Id> newLookups = creatyNewLookup(companyList, creditoList, lookups);
            Map<String, String> nameLookups = creatyNameLookup(companyList, creditoList);
            System.debug('creditoList: '+ creditoList);
            System.debug('companyList: '+ companyList);
            System.debug('newLookups: '+ newLookups);
            Database.UpsertResult[] resultsCredit = creatyCredit(creditoList, newLookups);
            Database.UpsertResult[] resultsCompany = creatyCompany(companyList, newLookups, nameLookups);
           
            String resultsError = '';


            for(Database.UpsertResult results : resultsCompany){
                System.debug('Database.UpsertResult: ' + results);
                if(!results.isSuccess()){
                    resultsError += 'Company Error: ' + results.getErrors() + '/ ';
                }
            }

            for(Database.UpsertResult results : resultsCredit){
                System.debug('Database.UpsertResult: ' + results);
                if(!results.isSuccess()){
                    resultsError += 'Credit Error: ' + results.getErrors() + '/ ';
                }
            }

            for(Database.UpsertResult results : resultsAccount){
                System.debug('Database.UpsertResult: ' + results);
                if(!results.isSuccess()){
                    resultsError += 'Account Error: ' + results.getErrors() + '/ ';
                }
            }

            if(resultsError != ''){
                Datetime UTC = System.now().addMinutes(-3);  
                Organization orgDetails = [SELECT Id, TimeZoneSidKey FROM Organization WHERE Id = :UserInfo.getOrganizationId()]; 
                Timezone tz = Timezone.getTimeZone(orgDetails.TimeZoneSidKey);
                Datetime orgTime = UTC.addSeconds((tz.getOffset(UTC)/1000)); 
                IntegrationLog.createLog('Bp OUT Insertion Error', 'OUT', resultsError,String.valueOf(orgTime), true);
            }
            System.debug('integração foi um sucesso');
        }
        
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
            if(valor.CodigoExternoAccount != null){
                accountIdList.add(valor.CodigoExternoAccount);
            }
            if(valor.OrganizacaoVendas != null){
                salesOrganizationIdList.add(valor.OrganizacaoVendas);
            }
            if(valor.Cultura != null){
                cultureIdsList.add(valor.Cultura);
            }
            if(valor.Safra != null){
                safraIdsList.add(valor.Safra);
            }
        }
        for(CompanyINData valor : companyList){
            if(valor.CodigoExternoAccount != null){
                accountIdList.add(valor.CodigoExternoAccount);
            }
            if(valor.OrganizacaoVendas != null){
                salesOrganizationIdList.add(valor.OrganizacaoVendas);
            }
            if(valor.SetorAtividade != null){
                activitySectorIdList.add(valor.SetorAtividade);
            }
            if(valor.CanalDistribuicao != null){
                distributionChannelIdList.add(valor.CanalDistribuicao);
            }
            if(valor.EscritorioVendas != null){
                salesOfficeIdList.add(valor.EscritorioVendas);
            }
            if(valor.EquipeVendas != null){
                salesTeamIdList.add(valor.EquipeVendas);
            }
        }
        //Get Account
        List<Account> accountListExternalId = new List<Account>([SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c =: accountIdList]);
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
    public static Map<String, String> creatyNameLookup(List<CompanyINData> companyList, List<LimiteCreditoINData> creditoList){
        Map<String, String> lookups = new Map<String, String>();
        Set<String> salesOrganizationIdList = new Set<String>();
        Set<String> salesTeamIdList = new Set<String>();
        for(LimiteCreditoINData valor : creditoList){
            salesOrganizationIdList.add(valor.OrganizacaoVendas);
        }
        for(CompanyINData valor : companyList){
            salesOrganizationIdList.add(valor.OrganizacaoVendas);
            salesTeamIdList.add(valor.EquipeVendas);
        }
        //Get SalesOrg
        List<SalesOrg__c> salesList = new List<SalesOrg__c>([SELECT Id, Name, SalesOrganizationCode__c FROM SalesOrg__c WHERE SalesOrganizationCode__c =: salesOrganizationIdList]);
        for (SalesOrg__c sales : salesList) {
            if(!lookups.containsKey('SalesOrg__c' + sales.SalesOrganizationCode__c)){
                lookups.put('SalesOrg__c' + sales.SalesOrganizationCode__c, sales.Name);
            }
        }
        //Get salesTeam
        List<SalesTeam__c> salesTeamList = new List<SalesTeam__c>([SELECT Id,Name, ExternalId__c FROM SalesTeam__c WHERE ExternalId__c =: salesTeamIdList]);
        for (SalesTeam__c team : salesTeamList) {
            if(!lookups.containsKey('SalesTeam__c' + team.ExternalId__c)){
                lookups.put('SalesTeam__c' + team.ExternalId__c, team.Name);
            }
        }
        return lookups;
    }

    public static void creatyAccountTerrytoryAssossiation(List<Account> accountList,List<Account> accountFatherListExternalId, List<String> userCodigoSapList, ResponseParameters resp, List<CompanyINData> companyList){
        Map<String, Id> accountExternalIdMap = new Map<String, Id>();
        Map<String, Id> accountFatherExternalIdMap = new Map<String, Id>();
        for(Account acc : accountList){
            accountExternalIdMap.put(acc.ExternalId__c, acc.Id);
        }
        for(Account acc : accountFatherListExternalId){
            accountFatherExternalIdMap.put(acc.ExternalId__c, acc.Id);
        }
        List<User> userList = new List<User>([SELECT Id, CodigoSap__c FROM User WHERE CodigoSap__c =: userCodigoSapList]);
        List<String> userIdsList = new List<String>();
        for(User user : userList){
            userIdsList.add(user.Id);
        }
        List<UserTerritory2Association> userTerrytoryList = new List<UserTerritory2Association>([SELECT Id, UserId, User.CodigoSap__c, Territory2Id  FROM UserTerritory2Association WHERE UserId =: userIdsList]);
        Map<String, UserTerritory2Association> userTerrytoryMap = new Map<String, UserTerritory2Association>();
        
        
        for(UserTerritory2Association userTerrytory : userTerrytoryList){
            userTerrytoryMap.put(userTerrytory.User.CodigoSap__c, userTerrytory);
        }
        System.debug('userTerrytoryMap: '+userTerrytoryMap);
        List<ObjectTerritory2Association> objectTerritoryList = new List<ObjectTerritory2Association>();
        List<String> objectTerritoryObjectIdList = new List<String>();
        List<String> objectTerritoryObjectToDeleteList = new List<String>();
        List<String> objectTerritoryTerritory2IdList = new List<String>();
        for(CompanyINData company : companyList){
            UserTerritory2Association userTerrytory = userTerrytoryMap.get(company.Partner);
            String accountId = accountExternalIdMap.get(company.CodigoExternoAccount);
            String accountFatherId = accountFatherExternalIdMap.get(company.CodigoExternoFatherAccount);
            if(userTerrytory != null){
                objectTerritoryTerritory2IdList.add(userTerrytory.Territory2Id);
                objectTerritoryObjectIdList.add(accountId);
                objectTerritoryObjectToDeleteList.add(accountId);
                ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = accountId, Territory2Id = userTerrytory.Territory2Id, AssociationCause='Territory2Manual');
                objectTerritoryList.add(objObjectTerritory2Association);

                if(accountFatherId != null || accountFatherId != ''){
                    objectTerritoryTerritory2IdList.add(userTerrytory.Territory2Id);
                    objectTerritoryObjectIdList.add(accountFatherId);

                    ObjectTerritory2Association objObjectTerritory2Association2 = new ObjectTerritory2Association(ObjectId = accountFatherId, Territory2Id = userTerrytory.Territory2Id, AssociationCause='Territory2Manual');
                    objectTerritoryList.add(objObjectTerritory2Association2);
                }
            }
        }
        Set<ObjectTerritory2Association> removeDuplicates = new Set<ObjectTerritory2Association>();
        List<ObjectTerritory2Association> resultList = new List<ObjectTerritory2Association>();
        List<String> resultWithoutFatherIdList = new List<String>();
        List<ObjectTerritory2Association> resultWithoutFatherList = new List<ObjectTerritory2Association>();
        List<ObjectTerritory2Association> resultBaseListToCheck = new List<ObjectTerritory2Association>([SELECT ObjectId, Territory2Id, AssociationCause  FROM ObjectTerritory2Association WHERE ObjectId IN: objectTerritoryObjectToDeleteList]);
        for(ObjectTerritory2Association results : resultBaseListToCheck){
            resultWithoutFatherIdList.add(results.ObjectId);
        }
        List<Account> resultAccountsList = new List<Account>([SELECT Id, ParentId FROM Account WHERE ParentId IN: resultWithoutFatherIdList]);
        System.debug('resultAccountsList: '+resultAccountsList);
        Map<String,Account> resultAccountsMap = new Map<String,Account>();
        for(Account result : resultAccountsList){
            resultAccountsMap.put(result.ParentId, result);
        }
        for(ObjectTerritory2Association results : resultBaseListToCheck){
            Account accountCheck = resultAccountsMap.get(results.ObjectId);
            if(!resultAccountsMap.containsKey(results.ObjectId)){
                resultWithoutFatherList.add(results);
            }
        }
        List<ObjectTerritory2Association> resultBaseList = new List<ObjectTerritory2Association>([SELECT ObjectId, Territory2Id, AssociationCause  FROM ObjectTerritory2Association WHERE ObjectId IN: objectTerritoryObjectIdList AND Territory2Id IN: objectTerritoryTerritory2IdList]);
        List<ObjectTerritory2Association> oldResultBaseList = new List<ObjectTerritory2Association>();
        Map<String,String> resultBaseMap = new  Map<String,String>();
        Map<String,String> resultMapToMaintain = new  Map<String,String>();
        System.debug('resultBaseList: '+resultBaseList);
        for (ObjectTerritory2Association records : resultBaseList) {
            String keyName = String.valueOf(records.ObjectId) + String.valueOf(records.Territory2Id);
            resultBaseMap.put(keyName, '');
        }
        System.debug('resultBaseMap: '+resultBaseMap);
        for (ObjectTerritory2Association newRecords : objectTerritoryList) {
            if (removeDuplicates.add(newRecords)) {
                String keyName = String.valueOf(newRecords.ObjectId) + String.valueOf(newRecords.Territory2Id);
                System.debug('keyName: '+keyName);
                if(!resultBaseMap.containsKey(keyName)){
                    resultList.add(newRecords);  
                }else{
                    resultMapToMaintain.put(keyName, '');
                }
            } 
        }
        System.debug('resultWithoutFatherList: '+resultWithoutFatherList);
        for (ObjectTerritory2Association records : resultWithoutFatherList) {
            String keyName = String.valueOf(records.ObjectId) + String.valueOf(records.Territory2Id);
            System.debug('keyName: '+keyName);
            if(!resultMapToMaintain.containsKey(keyName)){
                oldResultBaseList.add(records);
            }
        }
        System.debug('resultMapToMaintain: '+resultMapToMaintain);
        System.debug('oldResultBaseList: '+oldResultBaseList);
        if (!oldResultBaseList.isEmpty()) {
            Database.delete(oldResultBaseList, false);
        }
        System.debug('resultList'+ resultList);
        if (!resultList.isEmpty()) {
            Try{
                Database.upsert(resultList, false);
             } 
             Catch(System.Exception e){
                System.debug('Exception type caught: ' + e.getTypeName());
    			System.debug('Message: ' + e.getMessage());
    			System.debug('Cause: ' + e.getCause());  
    			System.debug('Line number: ' + e.getLineNumber());
    			System.debug('Stack trace: ' + e.getStackTraceString());
            }
        }
    }
    public static Database.UpsertResult[] creatyCompany(List<CompanyINData> companyList, Map<String, Id> lookups, Map<String, String> nameLookups){
        String statusName;
        List<Company__c> companyListToUpsert = new List<Company__c>();
        Map<String,String> checkExternalId = new Map<String,String>();
        for(CompanyINData valor : companyList){
            if(valor.Status == ''){
                statusName = 'Adicionada';
            }else{
                statusName = 'Removida';
            }
            String salesOrgName = nameLookups.containsKey('SalesOrg__c'+valor.OrganizacaoVendas) ? nameLookups.get('SalesOrg__c'+valor.OrganizacaoVendas) : '';
            String salesTeamName = nameLookups.containsKey('SalesTeam__c'+valor.EquipeVendas) ? nameLookups.get('SalesTeam__c'+valor.EquipeVendas) : '';
            Company__c company = new Company__c(
            Name = salesOrgName + ' - ' + salesTeamName,
            Conta__c = lookups.containsKey('Account__c'+valor.CodigoExternoAccount) ? lookups.get('Account__c'+valor.CodigoExternoAccount) : null,
            SalesOrg__c = lookups.containsKey('SalesOrg__c'+valor.OrganizacaoVendas) ? lookups.get('SalesOrg__c'+valor.OrganizacaoVendas) : null,
            ActivitySector__c = lookups.containsKey('ActivitySector__c'+valor.SetorAtividade) ? lookups.get('ActivitySector__c'+valor.SetorAtividade) : null,
            DistributionChannel__c = lookups.containsKey('DistributionChannel__c'+valor.CanalDistribuicao) ? lookups.get('DistributionChannel__c'+valor.CanalDistribuicao) : null,
            FiscalDomicile__c = valor.DomicilioFiscal,
            SalesOffice__c = lookups.containsKey('SalesOffice__c'+valor.EscritorioVendas) ? lookups.get('SalesOffice__c'+valor.EscritorioVendas) : null,
            SalesTeam__c = lookups.containsKey('SalesTeam__c'+valor.EquipeVendas) ? lookups.get('SalesTeam__c'+valor.EquipeVendas) : null,
            ClientGroup__c = valor.GrupoClientes,
            SupplierCenter__c = valor.CentroFornecedor,
            Status__c = statusName,
            SalesSector__c = valor.SetorVendas,
            ExternalId__c = valor.CodigoExternoAccount + valor.CentroFornecedor + valor.OrganizacaoVendas + valor.SetorAtividade + valor.CanalDistribuicao + valor.EscritorioVendas + valor.EquipeVendas
            );
            if(!checkExternalId.containsKey(company.ExternalId__c)){
                checkExternalId.put(company.ExternalId__c,company.ExternalId__c);
                companyListToUpsert.add(company);
            }
        }
        System.debug('companyListToUpsert: '+ companyListToUpsert);
        if (!companyListToUpsert.isEmpty()) {
            Database.UpsertResult[] resultCompanyList = Database.upsert(companyListToUpsert, Company__c.ExternalId__c, false);
            return resultCompanyList;
        }
        return null;
    }
    public static Database.UpsertResult[] creatyCredit(List<LimiteCreditoINData> creditoList, Map<String, Id> lookups){

        List<LimiteCredito__c> creditListToUpsert = new List<LimiteCredito__c>();
        for(LimiteCreditoINData valor : creditoList){
            Boolean blocked = false;
            if(valor.Bloqueado == null){
                blocked = false;
            }
            if(valor.Bloqueado == 'true'){
                blocked = true;
            }
            if(valor.Safra != null && valor.Saldo != null && valor.Valor != null){
            	LimiteCredito__c credit = new LimiteCredito__c(
            	Account__c = lookups.containsKey('Account__c'+valor.CodigoExternoAccount) ? lookups.get('Account__c'+valor.CodigoExternoAccount) : null,
            	OrganizacaoVendas__c = lookups.containsKey('SalesOrg__c'+valor.OrganizacaoVendas) ? lookups.get('SalesOrg__c'+valor.OrganizacaoVendas) : null,
            	Culture__c = lookups.containsKey('Culture__c'+valor.Cultura) ? lookups.get('Culture__c'+valor.Cultura) : null,
            	LimitValue__c = valor.Valor,
            	BlockedCredit__c = blocked,
            	LimitBalance__c = valor.Saldo,
            	Safra__c = lookups.containsKey('Safra__c'+valor.Safra) ? lookups.get('Safra__c'+valor.Safra) : null,
            	ExternalId__c = valor.CodigoExternoAccount + valor.Safra + valor.Cultura);
            	creditListToUpsert.add(credit);
            }
        }
        System.debug('creditListToUpsert'+ creditListToUpsert);
        if (!creditListToUpsert.isEmpty()) {
            Database.UpsertResult[] resultCreditList = Database.upsert(creditListToUpsert, LimiteCredito__c.ExternalId__c, false);
            return resultCreditList;
        }
        return null;
    } 

    public static IntegrationUtils.CalloutBpResponse sendOrder() {

        List<RequestParameters> request = new List<RequestParameters>();
        Datetime UTC = System.now().addMinutes(-3);  
        Organization orgDetails = [SELECT Id, TimeZoneSidKey FROM Organization WHERE Id = :UserInfo.getOrganizationId()]; 
        Timezone tz = Timezone.getTimeZone(orgDetails.TimeZoneSidKey);
        Datetime orgTime = UTC.addSeconds((tz.getOffset(UTC)/1000)); 

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
        String endpoint = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/gtw/sf-bp-out/v1/sf-bp-out' : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-type', 'application/json');
        headersMap.put('Authorization', 'Bearer '+ accessToken);
        
        IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCalloutGet(endpoint, payload, headersMap);

        if (responseObject.success) {

            HttpResponse response = responseObject.response;

            //IntegrationLog.createLog('Bp OUT', 'OUT', response.getBody(), payload, false);
            // .WSLog('Pedido', 'OUTBOUND', response.getBody(), payload, false);
            System.debug('response.getBody(): '+ response.getBody());
            try {
                List<ResponseParametersWrapper> responses = (List<ResponseParametersWrapper>) JSON.deserialize(response.getBody(), List<ResponseParametersWrapper>.class);
                System.debug('responses2: '+ responses);
                IntegrationLog.createLog('Bp OUT', 'OUT', response.getBody(), payload, false);
                return new IntegrationUtils.CalloutBpResponse(new ResponseParameters(responses));
        
            } catch (Exception e) {
                try{
                    ResponseNothing responses = (ResponseNothing) JSON.deserialize(response.getBody(), ResponseNothing.class);
                    String defaultErrorMessager = 'Malformatted HTTP Response Exception: ' + e.getMessage();
                    //IntegrationLog.createLog('Bp OUT', 'OUT', response.getBody(), payload, false);
                    return new IntegrationUtils.CalloutBpResponse(defaultErrorMessager);
                } catch (Exception er) {
                    String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + er.getMessage();
                    IntegrationLog.createLog('Bp OUT', 'OUT', defaultErrorMessage, payload, true);
                    return new IntegrationUtils.CalloutBpResponse(defaultErrorMessage);
                }
            }
        } else {

            IntegrationLog.createLog('Bp OUT', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
            return new IntegrationUtils.CalloutBpResponse(responseObject.exceptionObject.getMessage());
        }
    }
    public static String getAcessCode(){
        String payloadToken = 'grant_type=client_credentials';
        String endpointToken = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/identityserver/oauth2/token' : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMapToken = new Map<String, String>();
        headersMapToken.put('Content-type', 'application/x-www-form-urlencoded');
        headersMapToken.put('Authorization', 'Basic dEQxV2M0bWtXdnRWNWVtRXZSOHlVRF9iUFZvYTpmZmVJQUs5SmdPNXNsbXI1UzVMUXNNcTBOME1h');
        IntegrationUtils.RequestResponseObject responseObject2 = IntegrationUtils.executeCallout(endpointToken, payloadToken, headersMapToken);
        System.debug('responseObject2: '+ responseObject2);
        if (responseObject2.success) {
            HttpResponse response = responseObject2.response;
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
            System.debug('responses: '+ responses);
            this.responses = responses;
        }
    }
    //! Response part
    public class ResponseNothing {
        public String dt_atualizacao;
        public String message;
        public String time_hour_plus_utc;
        public String time_hour_utc;
    }

    public class ResponseParametersWrapper {
        public String Nome;
        public String CodigoExterno;
        public String RuaEntrega;
        public String CidadeEntrega;
        public String Estado;
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
        public List<LimiteCreditoINData> Credito;
        public List<CompanyINData> EstruturaOrganizacional;
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
        public String Bloqueado;
        public String Cultura;
        public Decimal Saldo;
        public String Safra;
    }

    public class CompanyINData{
    
    public String Partner;
    public String CodigoExternoAccount;
    public String CodigoExternoFatherAccount;    
    public String OrganizacaoVendas;
    public String SetorAtividade;
    public String CanalDistribuicao;
    public String DomicilioFiscal;
    public String EscritorioVendas;
    public String CentroFornecedor;
    public String EquipeVendas;
    public String GrupoClientes;
    public String Status;
    public String SetorVendas;
    }
}