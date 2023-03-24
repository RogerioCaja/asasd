import {
    LightningElement,
    api,
    track
} from 'lwc';
import fetchRecords from '@salesforce/apex/CustomLookupController.fetchRecords';
import fetchOrderRecords from '@salesforce/apex/CustomLookupController.fetchProductsRecords';
import fetchAccountRecords from '@salesforce/apex/CustomAccountLookupController.fetchAccountRecords';
import fetchAccountsWithTerritories from '@salesforce/apex/CustomLookupController.fetchAccountsWithTerritories';
import getNumberOfAccounts from '@salesforce/apex/CustomAccountLookupController.getNumberOfAccounts';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';

export default class CustomOrderSearch extends LightningElement {

    @api percentage = 30;
    @api objectName;
    @api fieldName;
    @api value;
    @api iconName;
    @api label;
    @api placeholder;
    @api className;
    @api productParams;
    @api salesOrg;
    @api territoryParams;
    @api seedPrice;
    @api required = false;
    @track searchString;
    @api offSet = 0;
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

    get getStyle() {
        return 'width: ' + this.percentage + '% !important';
    }

    connectedCallback() {
        if (this.value)
            this.fetchData();
    }

    searchRecords(event) {
        console.log('searchRecords function');
        this.searchString = this.template.querySelector('input[name="search"]').value;
        const tabEvent = new CustomEvent("modesearch");
        this.dispatchEvent(tabEvent)
        console.log(this.searchString);
        this.offSet = 0;
        if (this.searchString) {
            this.fetchData();
        }else if(!this.searchString && this.objectName == 'Account'){
            this.fetchData();
        } else {
            this.showResultList = false;
            if(this.objectName == 'Product2'){
                this.showNotification('Necessário digitar algum nome de um produto');
            }else{
                this.showNotification('Necessário digitar algum nome de conta');
            }
        }
    }

    @api fetchData() {
        this.showSpinner = true;
        this.message = '';
        this.recordsList = [];
        console.log('this.objectName: ' + this.objectName);
        if (this.objectName == 'Account' || this.objectName == 'BPAccount') {
            fetchAccountRecords({
                    searchString: this.searchString,
                    offSet: this.offSet,
                    salesOrg: this.objectName == 'BPAccount' ? this.salesOrg : null
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

                        if(this.offSet == 0){
                            getNumberOfAccounts({
                                searchString: this.searchString,
                                salesOrg: this.objectName == 'BPAccount' ? this.salesOrg : null
                            }).then(resultCount => {
                                const tabEvent = new CustomEvent("showcount");
                                tabEvent.numberOfAccounts = resultCount;
                                this.dispatchEvent(tabEvent);
                            })
                        }
                        
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
                    isCommodity: this.objectName == 'Commodity' ? true : false,
                    productsIds: [],
                    priceScreen: false,
                    getSeedPrices: this.seedPrice,
                    isLimit: false
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
        }else if(this.objectName == 'ObjectTerritory2Association'){
            console.log('this.territoryParams: ' + JSON.stringify(this.territoryParams));
            if(this.territoryParams.territory == '' && this.territoryParams.ctv == '' && !this.territoryParams.withoutTerritory) {
                this.showSpinner = false;
                this.showNotification('Pelo menos um dos campos deve estar preenchido(CTV ou Território)')
                return;
            }
            
            fetchAccountsWithTerritories({
                searchString: this.searchString,
                data: JSON.stringify(this.territoryParams)
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
        }
         else {
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