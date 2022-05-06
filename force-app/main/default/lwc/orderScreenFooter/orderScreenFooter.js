import { LightningElement, api } from 'lwc';

export default class OrderScreenFooter extends LightningElement {
    @api summary;
    finalizar(event){
        console.log('finalizar');
    }

    saveOrder(event){
        const order = new CustomEvent('saveorder', {detail: event.target.name });
        this.dispatchEvent(order);
    }
}