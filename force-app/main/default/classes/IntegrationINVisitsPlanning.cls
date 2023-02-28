@RestResource(urlMapping='/upsertVisitsPlanning/*')
global without sharing class IntegrationINVisitsPlanning {

    @HttpPost
    global static void upsertVisitsPlanning(List<TemplateDataIntegrationFields.VisitPlanningINData> request) {
    }
    global class ResponseModel {

        List<TemplateDataIntegrationFields.ResponseParent> response;

        public ResponseModel(List<TemplateDataIntegrationFields.ResponseParent> response) {

            this.response = response;
            
        }
        public ResponseModel() {   
            this.response = new List<TemplateDataIntegrationFields.ResponseParent>();         
        }
    }
}
