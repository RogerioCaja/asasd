import { LightningElement, api } from 'lwc';

export default class OrderScreenFooter extends LightningElement {
    @api valorTotal;
    @api qtdItens;
    @api frete;
    @api summary;
    finalizar(event){
        console.log('finalizar');
    }

    saveOrderPre(event){
      
        const order = new CustomEvent('saveorder', {
            detail: "prepedido"
        });
        this.dispatchEvent(order);
    }

    saveOrder(event){
        
        const order = new CustomEvent('saveorder', {
            detail: "gerarpedido"
        });
        this.dispatchEvent(order);
    }
}