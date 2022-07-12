import {
    LightningElement,
    api,
    track
} from 'lwc';
import fetchRecords from '@salesforce/apex/CustomLookupController.fetchRecords';
import fetchOrderRecords from '@salesforce/apex/CustomLookupController.fetchProductsRecords';
import fetchAccountRecords from '@salesforce/apex/CustomAccountLookupController.fetchAccountRecords';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';

export default class CustomOrderSearch extends LightningElement {

    @api objectName;
    @api fieldName;
    @api value;
    @api iconName;
    @api label;
    @api placeholder;
    @api className;
    @api productParams;
    @api required = false;
    @track searchString;
    @track selectedRecord;
    @api recordsList;
    @api message;
    @track showPill = false;
    @track showSpinner = false;
    @api showResultList = false;

    //Variaveis para mensagem
    _title = 'Operação inválida';
    message = 'Sample Message';
    variant = 'warning';
    variantOptions = [{
            label: 'error',
            value: 'error'
        },
        {
            label: 'warning',
            value: 'warning'
        },
        {
            label: 'success',
            value: 'success'
        },
        {
            label: 'info',
            value: 'info'
        },
    ];

    connectedCallback() {
        if (this.value)
            this.fetchData();
    }

    searchRecords(event) {
        console.log('searchRecords function');
        this.searchString = this.template.querySelector('input[name="search"]').value;
        console.log(this.searchString);
        if (this.searchString) {
            this.fetchData();
        } else {
            this.showResultList = false;
            this.showNotification('Necessário digitar algum nome de conta');
        }
    }

    fetchData() {
        this.showSpinner = true;
        this.message = '';
        this.recordsList = [];
        console.log('this.objectName: ' + this.objectName);
        if (this.objectName == 'Account') {
            fetchAccountRecords({
                    searchString: this.searchString
                })
                .then(result => {
                    const tabEvent = new CustomEvent("showresults");
                    if (result && result.length > 0) {
                        this.recordsList = result;
                        /*console.log(JSON.parse(JSON.stringify(result)));
                        if (selectedAccount) { this.recordsList.filter(x => x.Id !== this.selectedRecord.Id); }
                        console.log(JSON.parse(JSON.stringify( this.recordsList)));*/
                        this.showResultList = true;

                        tabEvent.results = this.recordsList;
                        tabEvent.showResults = true;
                        tabEvent.message = false;
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
                });
        }else if (this.objectName == 'Product2' || this.objectName == 'Commodity') {
            console.log('this.productParams: ' + JSON.stringify(this.productParams));
            fetchOrderRecords({
                    searchString: this.searchString,
                    data: JSON.stringify(this.productParams),
                    isCommodity: this.objectName == 'Commodity' ? true : false
                })
                .then(result => {
                    const tabEvent = new CustomEvent("showresults");
                    if (result && result.length > 0) {
                        this.recordsList = result;
                        /*console.log(JSON.parse(JSON.stringify(result)));
                        if (selectedAccount) { this.recordsList.filter(x => x.Id !== this.selectedRecord.Id); }
                        console.log(JSON.parse(JSON.stringify( this.recordsList)));*/
                        this.showResultList = true;

                        tabEvent.results = this.recordsList;
                        tabEvent.showResults = true;
                        tabEvent.message = false;
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
                });
        } else {
            fetchRecords({
                    objectName: this.objectName,
                    filterField: this.fieldName,
                    searchString: this.searchString,
                    value: this.value
                })
                .then(result => {
                    const tabEvent = new CustomEvent("showresults");
                    if (result && result.length > 0) {
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
                });
        }

    }

    dispatchEventHandler(recordId) {

        const event = new CustomEvent('child', {
            detail: recordId
        });

        this.dispatchEvent(event);
    }

    showNotification(message, variant = 3) {
        const evt = new ShowToastEvent({
            title: this._title,
            message: `${message}`,
            variant: this.variant[variant].value,
        });
        this.dispatchEvent(evt);
    }

}