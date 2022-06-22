import { LightningElement, api, track } from 'lwc';
import needJustification from '@salesforce/apex/OrderScreenController.needJustification';
export default class OrderScreenFooter extends LightningElement {
    @api valorTotal;
    @api qtdItens;
    @api frete;
    @api summary;
    @api summaryDataLocale;
    @api summaryData;
    @api justification;
    question = false;
  

    saveOrderPre(event){
      
        const order = new CustomEvent('saveorder', {
            detail: "prepedido"
        });
        this.dispatchEvent(order);
    }

     openOrCloseJustification(event){
        this.summaryDataLocale = {... this.summaryData};
        if(this.summaryDataLocale.approval != 'Não precisa de aprovação'){
            needJustification().then((result) =>{
                if(result == true){
                    this.question = !this.question;
                }else{
                    this.saveOrderReal();
                }
            })
        }
        else{
            this.saveOrderReal();
        }
    }

    closeJustification(){
        this.question = !this.question;
    }

    saveOrderReal(event){
        if(event != undefined){
            this.summaryDataLocale = {... this.summaryData};
            this.summaryDataLocale.justification = event.detail;
            const setSummaryData = new CustomEvent('setsummarydata');
            setSummaryData.data = this.summaryDataLocale;
          
            this.dispatchEvent(setSummaryData);
        }
       
        const order = new CustomEvent('saveorder', {
            detail: "gerarpedido"
        });
        this.dispatchEvent(order);
    }
}