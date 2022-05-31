@isTest
public with sharing class IntegrationINProductTest {

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

        Product2 prod = new Product2(
            Name = 'Laptop X2020', 
            Family = 'Hardware',
            ExternalId__c = '0002',
            ClasseAvaliacao__c = 'chucrute2',
            GrupoQuimico__c = 'Só pó quimico',
            MarcadoEliminacao__c = 'S',
            NCM__c = 'S',
            NumeroRegistro__c = '0002',
            OrigemMaterial__c = 'Himalaia',
            UnidadeMedida__c = 'KG'
        );
        insert prod;
        
    }

    @isTest
    static void verifyIntegrationProduct(){
        List<TemplateDataINtegrationFields.Product2INData> listProduct2List = new List<TemplateDataIntegrationFields.Product2INData>();
        TemplateDataIntegrationFields.Product2INData listProduct = new TemplateDataIntegrationFields.Product2INData();
        listProduct.TextoBreveMaterial = 'Café'; 
        listProduct.ProductCode = 'CF01'; 
        listProduct.TextoBreveMaterial = 'Café em graõs'; 
        listProduct.UnidadeMedida = 'Kg'; 
        listProduct.UnidadeMedidaRemessa = 'Tonelada'; 
        listProduct.Status = 'Adicionada'; 
        listProduct.TipoMaterial = 'Grãos'; 
        listProduct.GrupoMercadoria = 'Cafés'; 
        listProduct.SubgrupoMercadoria = 'CF'; 
        listProduct.MarcadoEliminacao = 'Não'; 
        listProduct.UnidadePeso = 'LT'; 
        listProduct.CodigoControle = 'CF'; 
        listProduct.ClasseAvaliacao = 'Ok'; 
        listProduct.OrigemMaterial = 'Minas Gerais'; 
        listProduct.Marca = 'Arabico'; 
        listProduct.NCM = '85432000'; 
        listProduct.GrupoQuimico = 'N'; 
        listProduct.IngredienteAtivo = 'SM'; 
        listProduct.NumeroRegistro = '001'; 
        listProduct.PesoBruto = 1;
        listProduct2List.add(listProduct);

        IntegrationINProduct.ResponseModel modelo = IntegrationINProduct.upsertProduct(listProduct2List);
    }
}
