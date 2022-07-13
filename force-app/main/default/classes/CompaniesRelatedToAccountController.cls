public class CompaniesRelatedToAccountController {
    @AuraEnabled
    public static String getCompanies(String accountId) {
        List<CompanyData> companies = new List<CompanyData>();
        for (Company__c company : [
            SELECT Id,
                   Name,
                   SalesOrg__r.Name,
                   SalesOffice__r.Name,
                   SalesTeam__r.Name,
                   ActivitySector__r.Name,
                   DistributionChannel__r.Name,
                   ClientGroup__c,
                   SupplierCenter__c
              FROM Company__c
             WHERE Conta__c =: accountId
        ]) {
            CompanyData companyData = new CompanyData();
            companyData.id = company.Id != null ? company.Id : '';
            companyData.name = company.Name != null ? company.Name : '';
            companyData.salesOrg = company.SalesOrg__r.Name != null ? company.SalesOrg__r.Name : '';
            companyData.salesOffice = company.SalesOffice__r.Name != null ? company.SalesOffice__r.Name : '';
            companyData.salesTeam = company.SalesTeam__r.Name != null ? company.SalesTeam__r.Name : '';
            companyData.activitySector = company.ActivitySector__r.Name != null ? company.ActivitySector__r.Name : '';
            companyData.distributionChannel = company.DistributionChannel__r.Name != null ? company.DistributionChannel__r.Name : '';
            companyData.clientGroup = company.ClientGroup__c != null ? company.ClientGroup__c : '';
            companyData.supplierCenter = company.SupplierCenter__c != null ? company.SupplierCenter__c : '';
            companies.add(companyData);
        }

        return JSON.serialize(companies);
    }

    public class CompanyData {
        public String id;
        public String name;
        public String salesOrg;
        public String salesOffice;
        public String salesTeam;
        public String activitySector;
        public String distributionChannel;
        public String clientGroup;
        public String supplierCenter;
    }
}