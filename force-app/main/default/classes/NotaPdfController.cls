public with sharing class NotaPdfController {

    public string base64 {get; set;}

    public NotaPdfController(ApexPages.StandardController stdController) {
        Id notasIdPgReference = Id.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('Id').escapeHtml4()));
        NotaFiscal__c notaFiscal = [SELECT Id, Base64__c FROM NotaFiscal__c WHERE Id =: notasIdPgReference LIMIT 1];

        this.base64 = notaFiscal.Base64__c;
    } 
}
