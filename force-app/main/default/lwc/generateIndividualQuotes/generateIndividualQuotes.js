import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import GENERAL_QUOTE_OBJECT from '@salesforce/schema/GeneralQuotas__c';
import GENERAL_QUOTE_NAME from '@salesforce/schema/GeneralQuotas__c.Name';

import CROP_OBJECT from '@salesforce/schema/Safra__c';
import CROP_NAME from '@salesforce/schema/Safra__c.Name';

import CULTIVATE_OBJECT from '@salesforce/schema/Product2';
import CULTIVATE_NAME from '@salesforce/schema/Product2.Name';

import SELLER_OBJECT from '@salesforce/schema/User';
import SELLER_NAME from '@salesforce/schema/User.Name';

import getQuoteData from '@salesforce/apex/GenerateIndividualQuotesController.getQuoteData';
import createIndividualQuote from '@salesforce/apex/GenerateIndividualQuotesController.createIndividualQuote';

export default class GenerateIndividualQuotes extends NavigationMixin(LightningElement) {
    @track redispatchGeneralQuoteObject = GENERAL_QUOTE_OBJECT;
    generalQuote;
    @track redispatchGeneralQuoteSearchFields = [GENERAL_QUOTE_NAME];
    @track redispatchGeneralQuoteListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    @track redispatchCropObject = CROP_OBJECT;
    crop;
    @track redispatchCropSearchFields = [CROP_NAME];
    @track redispatchCropListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    @track redispatchCultivateObject = CULTIVATE_OBJECT;
    cultivate;
    @track redispatchCultivateSearchFields = [CULTIVATE_NAME];
    @track redispatchCultivateListItemOptions = {
        title: 'Name',
        description: 'Name'
    };
    
    @track redispatchSellerObject = SELLER_OBJECT;
    seller;
    @track redispatchSellerSearchFields = [SELLER_NAME];
    @track redispatchSellerListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    @api recordId;
    individualQuoteData = {}

    connectedCallback() {
        getQuoteData({generalQuoteId: this.recordId})
        .then((result) => {
            this.individualQuoteData = JSON.parse(result);
            console.log('result: ' + JSON.stringify(this.individualQuoteData));
        });
    }

    selectItemRegister(event){
        try {
            if (this.isFilled(event)) {
                let field = event.target.name;
                if (field == 'quantity') {
                    this.individualQuoteData.quantity = event.target.value;
                    this.individualQuoteData.balance = event.target.value;
                } else {
                    const { record } = event.detail;
                    console.log('event.detail: ' + JSON.stringify(event.detail));
                    this.individualQuoteData.sellerId = record.Id;
                    console.log('this.individualQuoteData.sellerId: ' + this.individualQuoteData.sellerId);
                }
                this.individualQuoteData = JSON.parse(JSON.stringify(this.individualQuoteData));
                console.log('this.individualQuoteData: ' + this.individualQuoteData);
            }
        } catch (err) {
            console.log(err);
        }
    }

    removeItemRegister(event) {
        try {
            let field = event.target.name;
            this.individualQuoteData[field] = null;
        } catch (err) {
            console.log(err);
        }
    }

    createQuote() {
        createIndividualQuote({individualQuoteData: JSON.stringify(this.individualQuoteData)})
        .then((result) => {
            let quoteResponse = result;
            console.log('quoteResponse: ' + quoteResponse);
            if (!quoteResponse.includes('Erro')) {
                this.showToast('success', 'Sucesso!', 'Cota criada.');
                this.redirectToIndividualQuote(quoteResponse);
            } else {
                console.log('quoteResponse: ' + quoteResponse);
                this.showToast('error', 'Erro', 'Erro na criação da cota, tente novamente mais tarde.');
            }
        });
    }

    isFilled(field) {
        return ((field !== undefined && field != null && field != '') || field == 0);
    }

    showToast(type, title, message) {
        let event = new ShowToastEvent({
            variant: type,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }

    redirectToIndividualQuote(individualQuoteId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: individualQuoteId,
                objectApiName: 'IndividualQuotas__c',
                actionName: 'view'
            }
        });
    }
}