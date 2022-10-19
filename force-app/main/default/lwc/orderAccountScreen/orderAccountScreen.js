import { LightningElement, api } from 'lwc';

export default class OrderAccountScreen extends LightningElement {

    showList = false;
    records = [];
    message = false;
    numberOfAccounts = 0;
    numberPages = [];
    selected = 1;
    showPrevious = false;
    showNext = false;
    @api selectedAccount = false;
    @api childOrder;
    @api cloneData;

    account;

    showResults(event){
        console.log('showResults');
        this.showList = event.showResults;
        this.records = event.results;
        this.message = event.message;  
    }

    showCount(event){
        this.numberPages = [];
        this.numberOfAccounts = event.numberOfAccounts;

        if(this.numberOfAccounts){
            for(let i = 0; i < this.numberOfAccounts; i++){
                this.numberPages.push({number: i+1, selected: false})
            }
        }

        console.log(this.numberOfAccounts);
        if(this.numberOfAccounts > 1){
            this.showNext=true;
        }
        let key = 1;
        this.selected = key;
        setTimeout(() => { this.template.querySelectorAll(`div[data-target-id="${key}"]`)[0].classList.add('selectedIndex')}); 
        setTimeout(() => { this.template.querySelectorAll(`div[data-target-id="${key}"]`)[1].classList.add('selectedIndex')});
       
    }

    showMoreResults(key){
        let elems = this.template.querySelectorAll('div[data-target-id]');
        var index = 0, length = elems.length;
        for ( ; index < length; index++) {
            elems[index].classList.remove('selectedIndex');
        }

        this.template.querySelectorAll(`div[data-target-id="${key}"]`)[0].classList.add('selectedIndex');
        this.template.querySelectorAll(`div[data-target-id="${key}"]`)[1].classList.add('selectedIndex');
        
        this.selected = Number(key)
        this.verifyNextAndPrevious()
        let value = (Number(key) - 1) * 30;
        
        setTimeout(() =>{ this.template.querySelector('c-custom-order-search').offSet = value; })

        setTimeout(() =>{ this.template.querySelector('c-custom-order-search').fetchData(); })
    }

    previousPage(){
        this.showMoreResults(Number(this.selected) - 1);
    }

    nextPage(){
        this.showMoreResults(Number(this.selected) + 1);
    }

    clickInNumber(event){
        this.showMoreResults(event.target.dataset.targetId);
    }

    verifyNextAndPrevious(){
        if((this.selected) > 1){
            this.showPrevious = true;
        }else{
            this.showPrevious = false;
        }
        if((this.selected) == this.numberOfAccounts){
            this.showNext = false;
        }else{
            this.showNext = true;
        }
    }

    renderedCallback(){
        console.log(this.selectedAccount);
    }

    selectAccountFromResults(event){
        try{
            console.log(event.target.key, event.target.dataset.key, event.target.dataset.key.toString());
            this.changeStyle(event.target.dataset.key);
            let listafiltrada = this.records.filter(i => event.target.dataset.key == i.Id);
            console.log(listafiltrada, listafiltrada[0]);
            this.selectedAccount = listafiltrada[0];
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
                elems[index].style.display = '';
            }
            this.template.querySelector(`div[data-key="${key}"]`).classList.add('accountSelected');
            this.template.querySelector(`button[data-key="${key}"]`).classList.add('selected');
            this.template.querySelector(`div[data-key="${key}"]`).style.display = 'none';
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