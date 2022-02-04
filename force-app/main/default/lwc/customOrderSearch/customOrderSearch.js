import { LightningElement, api, track } from 'lwc';
import fetchRecords from '@salesforce/apex/CustomLookupController.fetchRecords';

export default class CustomOrderSearch extends LightningElement {

    @api objectName;
    @api fieldName;
    @api value;
    @api iconName;
    @api label;
    @api placeholder;
    @api className;
    @api required = false;
    @track searchString;
    @track selectedRecord;
    @api recordsList;
    @api message;
    @track showPill = false;
    @track showSpinner = false;
    @api showResultList = false;

    connectedCallback() {
        if(this.value)
            this.fetchData();
    }

    searchRecords(event) {
        console.log('searchRecords function');
        this.searchString = this.template.querySelector('input[name="search"]').value;
        console.log(this.searchString);
        if(this.searchString) {
            this.fetchData();
        } else {
            this.showResultList = false;
        }
    }

    selectItem(event) {
        if(event.currentTarget.dataset.key) {
    		var index = this.recordsList.findIndex(x => x.value === event.currentTarget.dataset.key)
            if(index != -1) {
                this.selectedRecord = this.recordsList[index];
                this.value = this.selectedRecord.value;
                this.showResultList = false;
                this.showPill = true;

                this.dispatchEventHandler(this.selectedRecord.value);
            }
        }
    }

    removeItem() {
        this.showPill = false;
        this.value = '';
        this.selectedRecord = '';
        this.searchString = '';

        this.dispatchEventHandler(null);
    }

    showRecords() {
        console.log(this.recordsList && this.searchString);
        console.log(this.recordsList);
        console.log(this.searchString);
        if(this.recordsList && this.searchString) {
            this.showResultList = true;
        }
    }

    fetchData() {
        this.showSpinner = true;
        this.message = '';
        this.recordsList = [];
        fetchRecords({
            objectName : this.objectName,
            filterField : this.fieldName,
            searchString : this.searchString,
            value : this.value
        })
        .then(result => {
            const tabEvent = new CustomEvent("showresults");
            if(result && result.length > 0) {
                    console.log(JSON.stringify(result));
                    this.recordsList = result;
                    this.showResultList = true;

                    tabEvent.results = result;
                    tabEvent.showResults = true;
                    tabEvent.message = false;
                    console.log(this.showResultList);
            } else {
                tabEvent.results = result;
                tabEvent.showResults = true;
                tabEvent.message = "Nenhum registro encontrado para '" + this.searchString + "'";
            }
            
            this.dispatchEvent(tabEvent);
            this.showSpinner = false;
        }).catch(error => {
            this.message = error.message;
            this.showSpinner = false;
        })

    }

    dispatchEventHandler(recordId){

        const event = new CustomEvent('child', {
            detail: recordId
        });

        this.dispatchEvent(event);
    }

}