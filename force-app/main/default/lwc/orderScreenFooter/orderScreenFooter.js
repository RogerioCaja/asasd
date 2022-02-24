import { LightningElement, api } from 'lwc';

export default class OrderScreenFooter extends LightningElement {
    @api summary;
    finalizar(event){
        console.log('finalizar');
    }
}