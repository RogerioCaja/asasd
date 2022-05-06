@isTest
    public with sharing class CalloutBPMock implements HttpCalloutMock {
        private final String body;
        private final Integer status;
    
        public CalloutBPMock(Boolean isSuccess) {
           if(isSuccess){
                status = 200;
                body = '[{"CodigoExterno": "11111","RuaEntrega": "","CidadeEntrega": "","Estado": "","PaisEntrega": "","CEPEntrega": "","RuaCobranca": "","CidadeCobranca": "","EstadoCobranca": "","PaisCobranca": "","CEPCobranca": "","ContaPai": "","CNPJ": "","CPF": "432423434","InscricaoMunicipal": "","InscricaoEstadual": "","Email": "","Telefone": "","Status": "","Credito": [{"OrganizacaoVendas": "","Valor": 7.0,"Bloqueado": "","Cultura": "","Garantia": "","Saldo": 9.0,"DataConcessao": "","DataVencimento": "","DataManutencao": "","Safra": 7.0}],"EstruturaOrganizacional": [{"OrganizacaoVendas": "","SetorAtividade": "","CanalDistribuicao": "","DomicilioFiscal": "","EscritorioVendas": "","EquipeVendas": "","GrupoClientes": "","SetorVendas": "","Status": "","Bloqueado": ""}]}]';           }
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
