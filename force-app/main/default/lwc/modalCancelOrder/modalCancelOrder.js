import { LightningElement, wire, api } from 'lwc';
import {CloseActionScreenEvent} from 'lightning/actions'
import notifyRecordUpdateAvailable from 'lightning/uiRecordApi'
import getCancelReasons from '@salesforce/apex/CancelOrderPopUpController.getCancelReasons';
import saveOrder from '@salesforce/apex/CancelOrderPopUpController.saveOrder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ModalSupimpa extends LightningElement {
    @api recordId;
    
    valueCancel = '';
    valueDescription = '';
    shouldHasDescription = false;
    optionList;
    optionData;

    get options(){
        return this.optionList;
    }

    @wire(getCancelReasons)
    wireCancelReasons({data, error}){
        if(data){
            this.optionData = data;
            this.createOptions(data);
        }
    }

    changeValue(event){
        const field = event.target.dataset.id
        if(field === 'cancel_reason'){
            this.valueCancel = event.target.value;
            this.shouldHasDescription = this.optionData.find((reason) => {
                if(reason.id === event.target.value){
                    return reason.shouldHasDescription
                }
            });
        }else if(field === 'cancel_description'){
            this.description = event.target.value;
        }
    }

    

    async handleSave(){
        if(this.valueCancel === '' || this.valueCancel === undefined || this.valueCancel === null){
            return;
        }
        await this.saveOrder();
        this.handleClose();
    
    }

    async saveChangeOrder(){
        saveOrder({data: JSON.stringify({recordId : this.recordId, reasonId: this.valueCancel, description: this.description})})
        .then((result) =>{
            //TO-DO popup sucesso ou falha
            if(result === 'Pedido cancelado com sucesso!'){
                this.showToast('success', 'Sucesso', result);
                notifyRecordUpdateAvailable([{recordId : this.recordId}]);
            }else{
                this.showToast('error', 'Erro', result);
            }
        }).catch((e) => {
            console.error(e);
        })
    }

    handleClose(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    createOptions(reasonData){
        const newOptions = reasonData.map(reason => {
            const object = {label: reason.cancelName, value: reason.id};
            return object;
        });
        newOptions.unshift({label: 'Escolha um motivo...', value: ''});
        this.optionList = newOptions;
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