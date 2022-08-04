@isTest
public with sharing class IntegrationINProductTest {
    
    @TestSetup
    static void makeData(){
        ProductHierarchy__c productHierarchy = new ProductHierarchy__c(
            Name = 'Hierarquia Teste',
            External_Id__c ='hierarquia01'
        );
        

        ProductGroup__c productGroup = new ProductGroup__c(
            Name = 'Grupo de produto Teste',
            ExternalId__c = 'gp01'
        );

        ProductSubgroup__c productSubGroup = new ProductSubgroup__c( 
            Name =  'SubGrupo de produto Teste',
            ExternalId__c = 'sgp01'
        );

        SalesOrg__c salesOrg = new SalesOrg__c(
            Name = 'AgroGalaxy',
            SalesOrganizationCode__c = '1000'
        );

        Product2 product = new Product2(
            Name = 'Laptop X200', 
            Family = 'Hardware',
            ExternalId__c = '0001',
            ProductCode__c = '0001',
            ProductCode = '0001',
            ClasseAvaliacao__c = 'av01',
            GrupoQuimico__c = 'bg1',
            MarcadoEliminacao__c = 'tes01',
            NCM__c = '85432000',
            NumeroRegistro__c = '2',
            OrigemMaterial__c = 'sp',
            UnidadeMedida__c = 'un'
        );
    }

    @isTest
    static void verifyIntegrationProduct(){
        List<TemplateDataIntegrationFields.Product2INData> listProductList = new List<TemplateDataIntegrationFields.Product2INData>(); //Lista
        TemplateDataIntegrationFields.Product2INData lisProduct = new TemplateDataIntegrationFields.Product2INData(); //Objeto
        lisProduct.TextoBreveMaterial = 'Produto Agro';
        lisProduct.ProductCode = '100';
        lisProduct.DescricaoMaterial = 'Semente Agro';
        lisProduct.UnidadeMedida = 'Kg';
        lisProduct.UnidadeMedidaRemessa = 'Kg';
        lisProduct.TipoMaterial = 'Semente';
        lisProduct.hierarquiaProduto = 'hierarquia01';//Lookup
        lisProduct.GrupoMercadoria = 'gp01';//Lookup
        lisProduct.SubgrupoMercadoria = 'sgp01';//Lookup
        lisProduct.SubgrupoMercadoria2 = 'PREMIUM';
        lisProduct.MarcadoEliminacao = 'Sem elminação';
        lisProduct.UnidadePeso = 'kg';
        lisProduct.ClasseAvaliacao = 'Top';
        lisProduct.OrigemMaterial = 'Minas';
        lisProduct.Marca = 'semente storm';
        lisProduct.NCM = '85432000';
        lisProduct.GrupoQuimico = 'sem';
        lisProduct.IngredienteAtivo = 'terra';
        lisProduct.NumeroRegistro = '0405';
        lisProduct.PesoBruto = 10;
        lisProduct.multiplicidade = 1;
        
        TemplateDataIntegrationFields.OrgVProductINData listOrgVProduct = new TemplateDataIntegrationFields.OrgVProductINData();
        listOrgVProduct.OrganizacaoVendas = '1000'; //Lookup
        listOrgVProduct.OrgProduct = '100'; //Lookup
        listOrgVProduct.SetorAtividade = 'Terra 2 de minas';
        listOrgVProduct.centroFilial = '1001';
        listOrgVProduct.Status = 'Adicionada';
        lisProduct.orgVProductItems = new List<TemplateDataINtegrationFields.OrgVProductINData>();
        listProductList.add(lisProduct);
        IntegrationINProduct.ResponseModel modelo = IntegrationINProduct.upsertProduct(listProductList);
    }
}
