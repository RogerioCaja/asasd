import { LightningElement, api } from 'lwc';

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
        
        this.question = !this.question;
        
    }

    saveOrderReal(event){
        this.summaryDataLocale = {... this.summaryData};
        this.summaryDataLocale.justification = event.detail;
        const setSummaryData = new CustomEvent('setsummarydata');
        setSummaryData.data = this.summaryDataLocale;
      
        this.dispatchEvent(setSummaryData);
        
        const order = new CustomEvent('saveorder', {
            detail: "gerarpedido"
        });
        this.dispatchEvent(order);
    }
}