import { LightningElement, api } from 'lwc';

export default class OrderAccountScreen extends LightningElement {

    showList = false;
    records = [];
    message = false;
    selectedAccount = false;

    account;

    showResults(event){
        console.log('showResults');
        this.showList = event.showResults;
        this.records = event.results;
        this.message = event.message;
    }

    renderedCallback(){}

    selectAccount(event){
        try{
            console.log(event.target.key, event.target.dataset.key, event.target.dataset.key.toString());
            this.changeStyle(event.target.dataset.key);
            const listafiltrada = this.records.filter(i => event.target.dataset.key == i.Id);
            console.log(listafiltrada);
            this.selectedAccount = listafiltrada;
            this._verifyFieldsToSave();
        }catch(e){
            console.log(e);
        }
    }

    changeStyle(key){
        try{
            let elems = this.template.querySelectorAll('div[data-key]');
            var index = 0, length = elems.length;
            for ( ; index < length; index++) {
                elems[index].classList.remove('accountSelected');
                elems[index].querySelector('.botaoConta button').classList.remove('selected');
            }
            this.template.querySelector(`div[data-key="${key}"]`).classList.add('accountSelected');
            this.template.querySelector(`button[data-key="${key}"]`).classList.add('selected');
        }catch(e){
            console.log(e);
        }
    }

    @api
    verifyMandatoryFields(){
        if(this.selectedAccount !== undefined){
            return true;
        }
        return false;
    }

    @api
    _verifyFieldsToSave() {
        if (this.verifyMandatoryFields()) {
            this._setData();
            return true;
        }
        return false;
    }   

    _setData(){
        const setAccountData = new CustomEvent('setaccountdata');
        setAccountData.data = this.selectedAccount;
        this.dispatchEvent(setAccountData);
    }
}