import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderSupplierScreen extends LightningElement {
    @api accountData;
    @api headerData;
    @api productData;
    @api divisionData;
    @api cloneData;
    @api commodityData;
    @api excludedItems;
    @api formsOfPayment;
    @api childOrder;
    @api combosSelecteds;

    showList = false;
    records = [];
    message = false;
    numberOfAccounts = 0;
    numberPages = [];
    numberOfPagesSection = [];
    selected = 1;
    showPrevious = false;
    showNext = false;
    showIcon = false;
    showPreviousSection = false;
    showNextSection = false;
    @api bpData = false;

    showResults(event) {
        console.log('bpData: ' + JSON.stringify(this.bpData));
        this.showList = event.showResults;
        this.records = event.results;
        this.message = event.message;  
    }

    showCount(event) {
        this.numberPages = [];
        this.numberOfPagesSection = [];
        let indexPages = 0;
        this.numberOfAccounts = event.numberOfAccounts;

        if (this.numberOfAccounts) {
            for (let i = 0; i < this.numberOfAccounts; i++) {
                
                this.numberPages.push({number: i + 1, selected: false})
                if (((i+1) - indexPages) == 10) {
                    indexPages = (i + 1);
                    this.numberOfPagesSection.push(this.numberPages);
                    this.numberPages = [];
                }
            }

            if (this.numberOfAccounts < 10) {
                this.numberOfPagesSection.push(this.numberPages);
            }

            if (this.numberOfAccounts > 10 && (this.numberOfAccounts - indexPages) != 10) {
                this.numberOfPagesSection.push(this.numberPages);
            }
        }

        this.numberPages = this.numberOfPagesSection[0];
        console.log('this.numberPages: ' + JSON.stringify(this.numberPages));
        if (this.numberOfAccounts > 1) {
            this.showNext = true;
        }

        if (this.numberOfAccounts > 10) {
            this.showNextSection = true;
        } else {
            this.showNextSection = false;
            this.showPreviousSection = false;
        }

        let key = 1;
        this.selected = key;

        if (this.selected == 1) {
            this.showPrevious=false;
        }

        setTimeout(() => { this.template.querySelectorAll(`div[data-target-id="${key}"]`)[0].classList.add('selected-index')}); 
        setTimeout(() => { this.template.querySelectorAll(`div[data-target-id="${key}"]`)[1].classList.add('selected-index')});
    }

    showMoreResults(key) {
        let elems = this.template.querySelectorAll('div[data-target-id]');
        var index = 0, length = elems.length;
        for ( ; index < length; index++) {
            elems[index].classList.remove('selected-index');
        }

        this.selected = Number(key);
        this.verifyNextAndPrevious();
        let value = (Number(key) - 1) * 50;

        setTimeout(() =>{ this.template.querySelector('c-custom-order-search').offSet = value; });
        setTimeout(() =>{ this.template.querySelector('c-custom-order-search').fetchData(); });
        setTimeout(() =>{ this.template.querySelectorAll(`div[data-target-id="${key}"]`)[0].classList.add('selected-index')});
        setTimeout(() =>{ this.template.querySelectorAll(`div[data-target-id="${key}"]`)[1].classList.add('selected-index')});
    }

    previousPage() {
        let value = this.numberPages.findIndex((element) => element.number == Number(this.selected) - 1);
        if (value == -1 && this.showPreviousSection) {
            this.previousSection();
        } else {
            this.showMoreResults(Number(this.selected) - 1);
        }
    }

    nextPage() {
        let value = this.numberPages.findIndex((element) => element.number == Number(this.selected) + 1);
        if (value == -1 && this.showNextSection) {
            this.nextSection();
        } else {
            this.showMoreResults(Number(this.selected) + 1);
        }
    }

    nextSection() {
        this.numberPages = this.numberOfPagesSection[Number(this.numberOfPagesSection.indexOf(this.numberPages)) + 1];
        this.showMoreResults(Number(this.numberPages[0].number));  
    }

    previousSection() {
        this.numberPages = this.numberOfPagesSection[Number(this.numberOfPagesSection.indexOf(this.numberPages)) - 1];
        this.showMoreResults(Number(this.numberPages[0].number));
    }

    clickInNumber(event) {
        this.showMoreResults(event.target.dataset.targetId);
    }

    verifyNextAndPrevious() {
        if ((this.selected) > 1) {
            this.showPrevious = true;
        } else {
            this.showPrevious = false;
        }
        
        if ((this.selected) == this.numberOfAccounts) {
            this.showNext = false;
        } else {
            this.showNext = true;
        }

        if ((this.selected) > 10) {
            this.showPreviousSection = true;
        } else {
            this.showPreviousSection = false;
        }

        if (Number(this.numberOfPagesSection.indexOf(this.numberPages)) == Number(this.numberOfPagesSection.length - 1)) {
            this.showNextSection = false;
        } else {
            this.showNextSection = true;
        }
    }

    connectedCallback() {
        if (this.bpData !== undefined) {
            this._verifyFieldsToSave();
        }
    }

    renderedCallback() {
        window.onscroll = () => {
            if (window.scrollY > 700 && this.showList) {
                this.showIcon = true;
            } else {
                this.showIcon = false;
            }
        }
    }

    scrollTopPage() {
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }

    selectAccountFromResults(event) {
        try {
            this.changeStyle(event.target.dataset.key);
            let listafiltrada = this.records.filter(i => event.target.dataset.key == i.Id);
            this.bpData = listafiltrada[0];
            this._verifyFieldsToSave();
        } catch(e) {
            console.log(e);
        }
    }

    changeStyle(key) {
        try {
            let elems = this.template.querySelectorAll('div[data-key]');
            var index = 0, length = elems.length;
            for ( ; index < length; index++) {
                elems[index].classList.remove('account-selected');
                elems[index].querySelector('.account-button button').classList.remove('selected');
                elems[index].style.display = '';
            }

            this.template.querySelector(`div[data-key="${key}"]`).classList.add('account-selected');
            this.template.querySelector(`button[data-key="${key}"]`).classList.add('selected');
            this.template.querySelector(`div[data-key="${key}"]`).style.display = 'none';
        } catch(e) {
            console.log(e);
        }
    }
 
    @api
    verifyMandatoryFields() {
        if (this.bpData !== undefined) {
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

    _setData() {
        const setBpData = new CustomEvent('setbpdata');
        setBpData.data = this.bpData;
        this.dispatchEvent(setBpData);
    }
}