import { LightningElement, api, track } from 'lwc';
import needJustification from '@salesforce/apex/OrderScreenController.needJustification';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
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
  

    saveOrderPre(event){
        if(this.headerData.pre_pedido != false){
            const order = new CustomEvent('saveorder', {
                detail: "prepedido"
            });
            this.dispatchEvent(order);
        }
        else{
            this.showNotification('Pedido já foi efetivado, logo não pode haver modificações', 'Pedido Efetivado');
        }
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
        if(this.headerData.pre_pedido != false){
            const order = new CustomEvent('saveorder', {
                detail: "gerarpedido"
            });
            this.dispatchEvent(order);
        }
        else{
            this.showNotification('Pedido já foi efetivado, logo não pode haver modificações', 'Pedido Efetivado');
        }
        
    }

    showNotification(message, title, variant = 'warning') {
        const evt = new ShowToastEvent({
            title: title,
            message: `${message}`,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}