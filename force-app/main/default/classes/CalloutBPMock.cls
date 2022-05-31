@isTest
    public with sharing class CalloutBPMock implements HttpCalloutMock {
        private final String body;
        private final Integer status;
    
        public CalloutBPMock(Boolean isSuccess) {
           if(isSuccess){
                status = 200;
                body = '[{"CodigoExterno": "11111","RuaEntrega": "","CidadeEntrega": "Londrina","Estado": "Paran\u00e1","PaisEntrega": "Brasil","CEPEntrega": "80010010","RuaCobranca": "","CidadeCobranca": "","EstadoCobranca": "","PaisCobranca": "","CEPCobranca": "","ContaPai": "10010101","CNPJ": "95978007000199","CPF": "432423434","InscricaoMunicipal": "","InscricaoEstadual": "","Email": "bpagrogalaxy@example.com","Telefone": "551192920101","Status": "","Credito": [{"OrganizacaoVendas": "Agro100","Valor": 0.0,"Bloqueado": "","Cultura": "cultura_test","Saldo": 0.0,"Safra": 1223.0}],"EstruturaOrganizacional": [{"OrganizacaoVendas": "Agro100","Partner": "test1", "SetorAtividade": "setor teste","CanalDistribuicao": "dist_canal teste","DomicilioFiscal": "domicilo teste","EscritorioVendas": "escritorio teste","EquipeVendas": "equipe teste","GrupoClientes": "REDISTRIBUICAO","SetorVendas": "setor teste","Status": "Removida","Bloqueado": ""}]}]';           }
           else{
                status = 400;
                body = '[{"CodigoExterno": "","RuaEntrega": "","CidadeEntrega": "","Estado": "","PaisEntrega": "","CEPEntrega": "","RuaCobranca": "","CidadeCobranca": "","EstadoCobranca": "","PaisCobranca": "","CEPCobranca": "","ContaPai": "","CNPJ": "","CPF": "","InscricaoMunicipal": "","InscricaoEstadual": "","Email": "","Telefone": "","Status": "","Credito": [{"OrganizacaoVendas": "","Valor": 0.0,"Bloqueado": "","Cultura": "","Saldo": 0.0,"Safra": 0.0}],"EstruturaOrganizacional": [{"OrganizacaoVendas": "","SetorAtividade": "","CanalDistribuicao": "","DomicilioFiscal": "","EscritorioVendas": "","EquipeVendas": "","GrupoClientes": "","SetorVendas": "","Status": "","Bloqueado": "false"}]}]';
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
