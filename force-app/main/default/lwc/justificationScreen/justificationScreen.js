import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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
        if(this.justification != ''){
            const response = new CustomEvent('save',{
                detail : this.justification
            });
            this.dispatchEvent(response);
        }else{
            this.showToast('warning', 'Atenção', 'A justificativa não pode estar vazia');
        }
    }

    showToast(type, title, message) {
        let event = new ShowToastEvent({
            variant: type,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }
}