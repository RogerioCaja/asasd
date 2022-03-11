import { LightningElement, api } from 'lwc';

export default class OrderScreenFooter extends LightningElement {
    @api summary;
    finalizar(event){
        console.log('finalizar');
    }

    saveOrder(event){
        const order = new CustomEvent('saveorder');
        this.dispatchEvent(order);
    }
}