import { LightningElement, api } from 'lwc';

export default class OrderAccountScreen extends LightningElement {

    showList = false;
    records = [];
    message = false;

    account;

    showResults(event){
        console.log('showResults');
        this.showList = event.showResults;
        this.records = event.results;
        this.message = event.message;
    }

    accountSelected(event){
        console.log('accountSelected event', event);
        try{
        this.account = event.account;
        console.log('accountSelected:'+ event.account);
        }catch(e){
            console.log(e);
        }
    }
}