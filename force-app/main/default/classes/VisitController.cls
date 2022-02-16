public with sharing class VisitController {
    public VisitDAO visit {get; set;}
    public String visitIdPageReference {get; set;}

    public VisitController() {
        if(ApexPages.currentPage().getParameters().get('Id') != null) {
            this.visitIdPageReference = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('Id').escapeHtml4());
        }

        // getVisitById(visitIdPageReference, 
        // new Set<String>{
            
        // })
    }

    public static String getDatetime(){
        Datetime  dt = DateTime.now();
        String dateFormat = dt.format('dd/MM/yyyy HH:mm:ss', 
        'America/Sao_Paulo');

        return dateFormat;
    }

    public void getVisitById(Id visitId, Set<String> fieldsSet){
        //0011100002ChWgSAAV
        //0011100002ChWqAAAV
        //Verify Id
        //Boolean isTrueFormat = Pattern.matches('([0-9]){10} ([A-Z] + [a-z]){8}', this.visitIdPageReference);
        Boolean isNotBlank = String.isNotBlank(this.visitIdPageReference);
        
        //Modeling Query to search data
        String query = 'SELECT Id, #FIELDS# FROM Visit__c WHERE Id = #OBJECTID#';
        String fields = String.join((Iterable<String>)fieldsSet, ', ');
        query = query.replace('#FIELDS#', fields);
        
        //Verify Id between IF 
        if(isNotBlank){
            query = query.replace('#OBJECTID#', this.visitIdPageReference);
        }
         
    }

    public class VisitDAO{

        // CTV da Visita, Data de Início e Fim do Plano de visitas; Nome do Plano, Organização de Vendas, Safra, Cultura
        // Cliente, Tipo da visita, Local da visita, Base check in, Data e hora da visita, status da visita
        public String visitCTV;
        public String initialDate;
        public String endDate;
        public String planName;
        public String orgSales;
        public String crop;
        public String culture;

        public String account;
        public String visitType;
        public String visitAddress;
        public String baseCheck;
        public String dateAndHourVisit;
        public String visitStatus;

        public VisitDAO(){}
        public VisitDAO(Order o){}

    }

  
}
