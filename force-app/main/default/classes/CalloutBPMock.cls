@isTest
    public with sharing class CalloutBPMock implements HttpCalloutMock {
        private final String body;
        private final Integer status;
    
        public CalloutBPMock(Boolean isSuccess) {
           if(isSuccess){
                status = 200;
                body = '[{"AccountINData":[ {"CodigoExterno": "3123123W","RuaEntrega": "321","CidadeEntrega": "TEST","Estado": "Sp","PaisEntrega": "brazil","CEPEntrega": "9084345","RuaCobranca": "rua teste","CidadeCobranca": "cityTest","EstadoCobranca": "cityTest","PaisCobranca": "Sp","CEPCobranca": "","ContaPai": "","CNPJ": "312321","CPF": "123123","InscricaoMunicipal": "","InscricaoEstadual": "","Email": "tefenome","Telefone": "","Status": "","creditoEntries": [{"OrganizacaoVendas": "","Valor": 0.0,"Bloqueado": "false","Cultura": "","Garantia": "","Saldo": 0.0,"DataConcessao": "","DataVencimento": "","DataManutencao": "","Safra": 0.0}],"companyEntries1": [{"OrganizacaoVendas": "","SetorAtividade": "","CanalDistribuicao": "","DomicilioFiscal": "","EscritorioVendas": "","EquipeVendas": "","GrupoClientes": "","SetorVendas": "","Bloqueado": "false","Status": ""}]}]}]';           }
           else{
                status = 400;
                body = '[{"CodigoExterno": "","RuaEntrega": "","CidadeEntrega": "","Estado": "","PaisEntrega": "","CEPEntrega": "","RuaCobranca": "","CidadeCobranca": "","EstadoCobranca": "","PaisCobranca": "","CEPCobranca": "","ContaPai": "","CNPJ": "","CPF": "","InscricaoMunicipal": "","InscricaoEstadual": "","Email": "","Telefone": "","Status": "","Credito": [{"OrganizacaoVendas": "","Valor": 0.0,"Bloqueado": "","Cultura": "","Garantia": "","Saldo": 0.0,"DataConcessao": "","DataVencimento": "","DataManutencao": "","Safra": 0.0}],"EstruturaOrganizacional": [{"OrganizacaoVendas": "","SetorAtividade": "","CanalDistribuicao": "","DomicilioFiscal": "","EscritorioVendas": "","EquipeVendas": "","GrupoClientes": "","SetorVendas": "","Status": "","Bloqueado": "false"}]}]';
            }
            
        }
        
        public String getExternalId() {
            return '00000101';
        }
        
        public String getBody() {
            return this.body;
        }
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(status);
            response.setBody(body);
            return response;
        }
    }