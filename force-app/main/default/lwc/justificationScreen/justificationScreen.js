import { LightningElement, api } from 'lwc';

export default class JustificationScreen extends LightningElement {
    @api justification = '';
    changeTextJustification(event){
        this.justification = event.target.value;
    }
    cancel(){
        const response = new CustomEvent('closejustification');
        this.dispatchEvent(response);
    }

    save(){
        const response = new CustomEvent('save',{
            detail : this.justification
        });
        this.dispatchEvent(response);
    }
}