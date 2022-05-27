@isTest
public with sharing class IntegrationINInvoiceTest {
  
    @TestSetup
    static void makeData(){
        Account account = new Account (
            Name = 'Teste 12',
            BillingStreet = ' ',
            BillingState = '' ,
            Phone= '00000000000', 
            BillingCity = ' ', 
            BillingLongitude = 000000,
            BillingLatitude = 00000,
            BillingPostalCode = '',
            ExternalId__c = '2884',
            Company__c = 'Empresa 012'
        );
        insert account;

        Account account2 = new Account (
            Name = 'Propriedade',
            BillingStreet = ' ',
            BillingState = '' ,
            Phone= '00000000000', 
            BillingCity = ' ', 
            BillingLongitude = 000000,
            BillingLatitude = 00000,
            BillingPostalCode = '',
            ExternalId__c = '2885',
            Company__c = 'Propriedade 012'
        );
        insert account2;
        
    }
    @isTest
    static void verifyIntegrationInvoice(){
        List<TemplateDataINtegrationFields.ItensNotaFiscalINData> listItemsList = new List<TemplateDataINtegrationFields.ItensNotaFiscalINData>();
        TemplateDataIntegrationFields.ItensNotaFiscalINData listItemInvoice = new TemplateDataIntegrationFields.ItensNotaFiscalINData();
        listItemInvoice.notaFiscal = '1620';
        listItemInvoice.codigoMaterial ='100';
        listItemInvoice.quantidade = 12;
        listItemInvoice.valorTotalItem = 1020;
        listItemInvoice.lote ='1';
        listItemInvoice.unidadeMedida ='1';
        listItemInvoice.naturezaOperacao ='Venda de mercadoria';
        listItemInvoice.descontoNF = 1;
        listItemInvoice.valorUnitarioNF = 4;
        listItemsList.add(listItemInvoice);

        List<TemplateDataIntegrationFields.NotaFiscalINData> listInvoiceList = new List<TemplateDataINtegrationFields.NotaFiscalINData>();
        TemplateDataIntegrationFields.NotaFiscalINData listInvoice = new TemplateDataINtegrationFields.NotaFiscalINData();
        listInvoice.invoiceName = '1620';
        listInvoice.numeroNotaFiscal = '1620';
        listInvoice.cliente = '100';
        listInvoice.numeroPedido = '100';
        listInvoice.codigoEmpresa = '1';
        listInvoice.propriedade = '100';
        listInvoice.serie = '001';
        listInvoice.localNegocios = 'Minas Gerais';
        listInvoice.codigoStatus = '1';
        listInvoice.chaveAcesso = '3511.0444.4631.5600.0184.5505.9000.1947.4412.0510.2788';
        listInvoice.valorTotalNf = 110;
        listInvoice.naturezaOperacao = '09090945';
        listInvoice.itensNotaFiscal = listItemsList;
        listInvoiceList.add(listInvoice);

        IntegrationINInvoice.ResponseModel modelo = IntegrationINInvoice.upsertInvoice(listInvoiceList);
    }
}
