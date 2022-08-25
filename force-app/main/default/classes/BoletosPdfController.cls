public with sharing class BoletosPdfController {
    public string base64 {get; set;}
    public string fileName {get; set;}
    public boletosPdfController(ApexPages.StandardController stdController){
        Id boletosIdPgReference = Id.valueOf(String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('Id').escapeHtml4()));
       Boletos__c boleto = [SELECT Id, Base64__c, AccountCode__r.Name, Name FROM Boletos__c WHERE Id =: boletosIdPgReference LIMIT 1];
        //System.debug('boleto ' + boleto);  
        this.base64 = boleto.Base64__c;
        string boletoName = boleto.Name;
        this.fileName = '/'+boleto.Name;
            System.debug(this.fileName);
        //this.fileName = 'teste';
        //String yourFileName = 'MeuArquivo.pdf' ;
        //Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=;' + yourFileName );
        //String FileName = 'Boleto.pdf';
        //Apexpages.currentPage().getHeaders().put( 'content-disposition', 'attachment; filename= FileName.pdf');
        //Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename=AccountReport.pdf');
        //System.debug('this.base64 ' + this.base64);
    }
}