@RestResource(urlMapping='/upsertAccount/*')
global with sharing class IntegrationINAccount {
    
    @HttpPost
    global static ResponseModel upsertAccount(List<TemplateDataIntegrationFields.AccountINData> request) {
        
        Map<String, Id> lookups = new Map<String, Id>();
        Set<String> recordType = new Set<String>();
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TemplateDataIntegrationFields.CompanyINData> requestCompanyList = new List<TemplateDataIntegrationFields.CompanyINData>();
        List<TemplateDataIntegrationFields.LimiteCreditoINData> requestCreditoList = new List<TemplateDataIntegrationFields.LimiteCreditoINData>();
        List<Account> ListAccountToUpsert = new List<Account>();
        //Company Lists
        Set<String> accountIdList = new Set<String>();
        Set<String> salesOrganizationIdList = new Set<String>();
        Set<String> activitySectorIdList = new Set<String>();
        Set<String> distributionChannelIdList = new Set<String>();
        Set<String> salesOfficeIdList = new Set<String>();
        Set<String> salesTeamIdList = new Set<String>();
        //Credito Lists
        Set<String> cultureIdList = new Set<String>();
        Set<Decimal> safraIdList = new Set<Decimal>();
        System.debug(request);
        for(TemplateDataIntegrationFields.AccountINData req : request){
            for(TemplateDataIntegrationFields.CompanyINData comp : req.companyEntries){
                comp.accountId = req.CodigoExterno;

                salesOrganizationIdList.add(comp.OrganizacaoVendas);
                activitySectorIdList.add(comp.SetorAtividade);
                distributionChannelIdList.add(comp.CanalDistribuicao);
                salesOfficeIdList.add(comp.EscritorioVendas);
                salesTeamIdList.add(comp.EquipeVendas);
                requestCompanyList.add(comp);
            }
            for(TemplateDataIntegrationFields.LimiteCreditoINData  cred : req.creditoEntries){
                cred.accountId = req.CodigoExterno;
                salesOrganizationIdList.add(cred.OrganizacaoVendas);
                cultureIdList.add(cred.Cultura);
                safraIdList.add(cred.Safra);
                requestCreditoList.add(cred);
            }
            accountIdList.add(req.CodigoExterno);
            accountIdList.add(req.ContaPai);
        }
        
        //Sales Lookup
        if(salesOrganizationIdList != null){
            List<SalesOrg__c> salesList = new List<SalesOrg__c>([SELECT Id, SalesOrganizationCode__c FROM SalesOrg__c WHERE SalesOrganizationCode__c =: salesOrganizationIdList]);
            for (SalesOrg__c sales : salesList) {
                lookups.put('SalesOrg__c' + sales.SalesOrganizationCode__c, sales.Id);
            }
        }
        //Setor Atividade Lookup
        if(activitySectorIdList != null){
            List<ActivitySector__c> activyList = new List<ActivitySector__c>([SELECT Id, Codigo__c FROM ActivitySector__c WHERE Codigo__c =: activitySectorIdList]);
            for (ActivitySector__c sector : activyList) {
                lookups.put('ActivitySector__c' + sector.Codigo__c, sector.Id);
            }
        }
        //Canal Distribuicao Lookup
        if(distributionChannelIdList != null){
            List<DistributionChannel__c> distributionList = new List<DistributionChannel__c>([SELECT Id, Codigo__c FROM DistributionChannel__c WHERE Codigo__c =: distributionChannelIdList]);
            for (DistributionChannel__c distribution : distributionList) {
                lookups.put('DistributionChannel__c' + distribution.Codigo__c, distribution.Id);
            }
        }
        //sales Office Lookup
        if(salesOfficeIdList != null){
            List<SalesOffice__c> salesOfficeList = new List<SalesOffice__c>([SELECT Id, Codigo__c FROM SalesOffice__c WHERE Codigo__c =: salesOfficeIdList]);
            for (SalesOffice__c office : salesOfficeList) {
                lookups.put('SalesOffice__c' + office.Codigo__c, office.Id);
            }
        }
        //sales Team Lookup
        if(salesTeamIdList != null){
            List<SalesTeam__c> salesTeamList = new List<SalesTeam__c>([SELECT Id, ExternalId__c FROM SalesTeam__c WHERE ExternalId__c =: salesTeamIdList]);
            for (SalesTeam__c team : salesTeamList) {
                lookups.put('SalesTeam__c' + team.ExternalId__c, team.Id);
            }
        }


        //sales Team Lookup
        if(cultureIdList != null){
            List<Cultura__c> cultureList = new List<Cultura__c>([SELECT Id, ExternalId__c FROM Cultura__c WHERE ExternalId__c =: cultureIdList]);
            for (Cultura__c cult : cultureList) {
                lookups.put('Cultura__c' + cult.Codigo__c, cult.Id);
            }
        }
        //sales Team Lookup
        if(safraIdList != null){
            List<Safra__c> safraList = new List<Safra__c>([SELECT Id, Code__c FROM Safra__c WHERE ExternalId__c =: safraIdList]);
            for (Safra__c safra : safraList) {
                lookups.put('Safra__c' + safra.Code__c, safra.Id);
            }
        }

        //colocar num map os tipos de record e os usar num for igual o primeiro e desta vez preenchendo o 
        FactoryDataIntegration.convertSObject(new Account(), 'IN', request, responseList, ListAccountToUpsert, lookups);

        Map<String, Account> accountMap = new Map<String, Account>();
        accountMap = getMapAccountToInsert(ListAccountToUpsert);
               
        System.debug(accountMap);
        //Upserting records (Account)
        IntegrationUtils.upsertRecords(
            Database.upsert(accountMap.values(), Account.ExternalId__c, false), 
            responseList, 
            accountMap.values(), 
            Account.ExternalId__c
        );

        //sales Team Lookup
        if(accountIdList != null){
            List<Account> accountList = new List<Account>([SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c =: accountIdList]);
            for (Account account : accountList) {
                lookups.put('Account' + account.ExternalId__c, account.Id);
            }
        }

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
    
    public void companyINToInsert(List<Object> request, List<TemplateDataIntegrationFields.CompanyINData> request, List<TemplateDataIntegrationFields.Response> responseList, Map<String, Id> lookups){  
        List<Company__c> companyList = new List<Company__c>();
        FactoryDataIntegration.convertSObject(new Company__c(), 'IN', request, responseList, companyList, lookups);

        Map<String, Company__c> companyMap = new Map<String, Company__c>();
        companyMap = getMapCompanyToInsert(companyList);
               
        //Upserting records (Account)
        IntegrationUtils.upsertRecords(
            Database.upsert(companyMap.values(), Company__c.accountId, false), 
            responseCompanyList, 
            companyMap.values(), 
            Company__c.accountId
        );
    }
    public static Map<String, Company__c> getMapCompanyToInsert(Company__c[] companyList){  
        Map<String, Company__c> visionMap = new Map<String, Company__c>();
        for(Company__c company : companyList){
            visionMap.put(company.Conta__c, company);//trocar
        }
        return visionMap;
    }

    public static Map<String, Account> getMapAccountToInsert(Account[] accountList){  
        Map<String, Account> visionMap = new Map<String, Account>();
        for(Account account : accountList){
            visionMap.put(account.ExternalId__c, account);
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
