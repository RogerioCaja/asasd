import { LightningElement, api, track } from 'lwc';
import needJustification from '@salesforce/apex/OrderScreenController.needJustification';
export default class OrderScreenFooter extends LightningElement {
    @api valorTotal;
    @api qtdItens;
    @api frete;
    @api summary;
    @api summaryDataLocale;
    @api headerData;
    @api summaryData;
    @api justification;
    question = false;
    barterSale = false;

    connectedCallback(event) {
        if (this.headerData.tipo_venda == 'Venda Barter') {
            this.barterSale = true;
        }
    }

    saveOrderPre(event){
      
        const order = new CustomEvent('saveorder', {
            detail: "prepedido"
        });
        this.dispatchEvent(order);
    }

     openOrCloseJustification(event){
        this.summaryDataLocale = {... this.summaryData};
        if(this.summaryDataLocale.approval != 'Não precisa de aprovação' && this.headerData.pre_pedido != false){
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