import { LightningElement, api, track } from 'lwc';
import approval from '@salesforce/apex/OrderScreenController.approvals';

export default class OrderSummaryScreen extends LightningElement {
    staticValue = 'hidden';
    hasData = true;
    @track orderMargin = 0;
    @track approval = '';
    @api accountData;
    @api productData;
    @api divisionData;
    @api summaryData;
    
    @api summaryDataLocale;
    @api productDataLocale = [];
    @api headerData;

    connectedCallback(){
        this.summaryDataLocale = {... this.summaryData};
        this.loadData();
        const data = {accountData: this.accountData, headerData: this.headerData, productData: this.productData, divisionData: this.divisionData, summaryData: this.summaryData};
        approval({
            data: JSON.stringify(data)
        }).then((result) => {
            this.approval = result;
        }).catch((err)=>{
            console.log(JSON.stringify(err));
        });
    }

    loadData(){
        if(this.productData){
            this.productDataLocale = JSON.parse(JSON.stringify(this.productData));
            console.log(JSON.stringify(this.productDataLocale));
            for(var i= 0; i< this.productDataLocale.length; i++){
                this.productDataLocale[i]['unitPrice'] = this.formatCurrency(this.productDataLocale[i].unitPrice);
                this.productDataLocale[i]['totalPrice']  = this.formatCurrency(this.productDataLocale[i].totalPrice);
                this.productDataLocale[i]['commercialDiscountValue']  =  this.formatCurrency(this.productDataLocale[i].commercialDiscountValue);
                this.productDataLocale[i]['commercialDiscountPercentage']  =  this.formatPercent(this.productDataLocale[i].commercialDiscountPercentage);
                this.orderMargin += this.productDataLocale[i].commercialMarginPercentage;
                this.productDataLocale[i]['commercialMarginPercentage']  = this.formatPercent( this.productDataLocale[i].commercialMarginPercentage);
            }
            this.orderMargin = this.formatPercent(this.orderMargin);
        }
    }

    formatCurrency(num){
        try{
            return parseFloat(num).toLocaleString("pt-BR", {style:"currency", currency:"BRL"});
        }
        catch(err){
            console.log(err);
        }
    }

    formatPercent(num){
        try{
            if(num.toString().indexOf('%') != -1)
                num = num.toString().split('%')[0];
            return Number(num/100).toLocaleString(undefined,{style: 'percent', minimumFractionDigits:2});
        }
        catch(err){
            console.log(err);
        }
        //num = parseFloat(num).toFixed()+'%';

    }

    changeObservation(event){
        this.summaryDataLocale.observation = event.target.value;
        const setSummaryData = new CustomEvent('setsummarydata');
        setSummaryData.data = this.summaryDataLocale;
      
        this.dispatchEvent(setSummaryData);
    }

    changeObservationSale(event){
        this.summaryDataLocale.billing_sale_observation = event.target.value;
        const setSummaryData = new CustomEvent('setsummarydata');
        setSummaryData.data = this.summaryDataLocale;
      
        this.dispatchEvent(setSummaryData);
    }
   
    @api showandHiddenTextArea(){
        // let values;
        // let buttons;
        // values = this.template.querySelectorAll('textarea');
        // buttons = this.template.querySelectorAll('button');

        // if(this.staticValue == 'hidden'){
        //     this.staticValue = "visible"
        //     values[0].style.visibility = this.staticValue;
        //     buttons[0].style.setProperty("-webkit-transform", "rotate(-180deg)", null);
        //     buttons[0].style.setProperty("transition-duration", "1s", null);
        // }
        // else{
        //     this.staticValue = "hidden"
        //     values[0].style.visibility = this.staticValue;
        //     buttons[0].style.setProperty("-webkit-transform", "rotate(0deg)", null);
        // }
    }
  

    
}