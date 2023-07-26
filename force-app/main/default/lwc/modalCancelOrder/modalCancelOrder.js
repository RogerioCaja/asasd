import { LightningElement, wire, api } from 'lwc';
import {CloseActionScreenEvent} from 'lightning/actions'
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getCancelReasons from '@salesforce/apex/CancelOrderPopUpController.getCancelReasons';
import getOrderById from '@salesforce/apex/CancelOrderPopUpController.getOrderById';
import saveOrder from '@salesforce/apex/CancelOrderPopUpController.saveOrder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const STATUS_INVALID_TO_UPTADE_LIST = ['001', '0001', '1', '2', '3', '4', '5'];
export default class ModalCancelOrder extends LightningElement {
    @api recordId;
    isLoading = true;
    
    
    valueCancel = '';
    valueDescription = '';
    shouldHasDescription = false;
    optionList;
    optionData;

    get options(){
        return this.optionList;
    }


    connectedCallback(){
        this.loadVariable();
    }
    
    async loadVariable(){
        await this.recordId;
        if(this.recordId){
            this.isLoading = false;
            getOrderById({id : this.recordId}).then((result) => {
                let order = result;
                if(STATUS_INVALID_TO_UPTADE_LIST.includes(order.Status)){
                    this.showToast('warning', 'Atenção', 'Não é possível cancelar o pedido!');
                    this.handleClose(); 
                }else if(order.Status == 'X'){
                    this.showToast('warning', 'Atenção', 'Pedido já está cancelado!');
                    this.handleClose(); 
                }
            })
        }
    }

    @wire(getCancelReasons)
    wireCancelReasons({data, error}){
        try{
            if(data){
                this.optionData = data;
                this.createOptions(data);
            }
            if(error){
                console.log(error);
            }
        }catch(e){
            console.log(e);
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

    disconnectedCallback(){
        notifyRecordUpdateAvailable([{recordId : this.recordId}]);
    }

    async saveChangeOrder(){
        if(this.valueCancel === '' || this.valueCancel === undefined || this.valueCancel === null){
            this.showToast('warning', 'Atenção', 'Selecione um motivo!')
            return;
        }

        saveOrder({data: JSON.stringify({recordId : this.recordId, reasonId: this.valueCancel, description: this.description})})
        .then((result) =>{
            if(result === 'Pedido cancelado com sucesso!'){
                this.showToast('success', 'Sucesso', result);
            }else{
                this.showToast('error', 'Erro', result);
            }
        }).catch((e) => {
            console.error(e);
        }).finally(() => {
            this.handleClose();
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