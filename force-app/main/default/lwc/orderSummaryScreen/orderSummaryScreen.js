import { LightningElement, api, track } from 'lwc';
import approval from '@salesforce/apex/OrderScreenController.approvals';

export default class OrderSummaryScreen extends LightningElement {
    staticValue = 'hidden';
    hasData = true;
    disabled=false;
    isBarter = false;
    @track orderMargin = 0;
    @track approval = '';
    @api accountData;
    @api productData;
    @api divisionData;
    @api commodityData;
    @api summaryData;
    
    @api summaryDataLocale;
    @api productDataLocale = [];
    @api commodityDataLocale = [];
    @api divisionDataLocale;
    @api headerData;
    @api cloneData;

    connectedCallback(){
        this.summaryDataLocale = {... this.summaryData};
        this.loadData();
        const data = {accountData: this.accountData, headerData: this.headerData, productData: this.productData, divisionData: this.divisionData, summaryData: this.summaryData};
        approval({
            data: JSON.stringify(data)
        }).then((result) => {
            if(result)
                this.approval = result;
            else
                this.approval = 'Não precisa de aprovação'
        }).catch((err)=>{
            console.log(JSON.stringify(err));
        });
    }

    loadData(){
       
        if(this.productData){
            this.productDataLocale = JSON.parse(JSON.stringify(this.productData));
           
            this.commodityDataLocale;
            if(this.commodityData){
                this.commodityDataLocale= JSON.parse(JSON.stringify(this.commodityData));
            }
            
           
            if (this.headerData.status_pedido == 'Em aprovação - Gerente Filial' || this.headerData.status_pedido == 'Em aprovação - Gerente Regional' ||
                this.headerData.status_pedido == 'Em aprovação - Diretor' || this.headerData.status_pedido == 'Em aprovação - Comitê Margem' || this.headerData.status_pedido == 'Em aprovação - Mesa de Grãos') {
                this.disabled = true;
            }

            
            
            let orderTotalPrice = 0;
            let orderTotalCost = 0;
            if(this.headerData.tipo_venda == 'Venda Barter'){
                for(var i= 0; i< this.productDataLocale.length; i++){
                    this.isBarter = true;
                    this.orderMargin = this.commodityDataLocale[0].marginValue;
                    this.productDataLocale[i]['unitPrice'] = (Number(this.productDataLocale[i].unitPrice) / Number(this.commodityDataLocale[0].commodityPrice)).toFixed(4).toString() + ' por saca';
                    this.productDataLocale[i]['totalPrice']  = Number(Number(this.productDataLocale[i]['unitPrice'].toString().replace(' por saca', '')) * Number(this.productDataLocale[i].quantity)).toFixed(2).toString() + ' sacas';
                    this.productDataLocale[i]['commercialDiscountValue']  =  this.commodityDataLocale[0].discount;
                    let totalProductPrice = Number(this.productDataLocale[i].unitPrice.replace(' por saca', '')) * Number(this.productDataLocale[i].quantity);
                    this.productDataLocale[i]['commercialDiscountPercentage']  =  this.productDataLocale[i].commercialDiscountPercentage;
                    this.productDataLocale[i]['commercialMarginPercentage']  = Number((Number(this.productDataLocale[i].commercialMarginPercentage) / 100) * Number(totalProductPrice)).toFixed(2).toString() + ' sacas';
                    this.productDataLocale[i]['divisionData'] = [];
                    if(this.divisionData){
                        for(var j=0; j< this.divisionData.length; j++){
                            if(this.divisionData[j].productPosition == i)
                                this.productDataLocale[i]['divisionData'].push(this.divisionData[j])
                        }
                    }
                }
            }
            else{
                for(var i= 0; i< this.productDataLocale.length; i++){
                    orderTotalPrice += Number(this.productDataLocale[i].unitPrice) * Number(this.productDataLocale[i].quantity);
                    orderTotalCost += Number(this.productDataLocale[i].practicedCost) * Number(this.productDataLocale[i].quantity);
                    this.productDataLocale[i]['unitPrice'] = this.formatCurrency(this.productDataLocale[i].unitPrice);
                    this.productDataLocale[i]['totalPrice']  = this.formatCurrency(this.productDataLocale[i].totalPrice);
                    this.productDataLocale[i]['commercialDiscountValue']  =  this.formatCurrency(this.productDataLocale[i].commercialDiscountValue);
                    this.productDataLocale[i]['commercialDiscountPercentage']  =  this.productDataLocale[i].commercialDiscountPercentage;
                    this.productDataLocale[i]['commercialMarginPercentage']  = this.productDataLocale[i].commercialMarginPercentage + '%';
                    this.productDataLocale[i]['divisionData'] = [];
                    if(this.divisionData){
                        for(var j=0; j< this.divisionData.length; j++){
                            if(this.divisionData[j].productPosition == i)
                                this.productDataLocale[i]['divisionData'].push(this.divisionData[j])
                        }
                    }
                }
            }
            
            if(this.headerData.tipo_venda != 'Venda Barter')
            {
                this.orderMargin = ((1 - (orderTotalCost / orderTotalPrice)) * 100).toFixed(2) + '%';
            }
            this.summaryDataLocale.orderMargin = this.orderMargin;
            this.defineOrderMargin();
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
            num = num.toString();
            num = parseFloat(num.replace(',', '.'));
            return (parseFloat(num)/100).toLocaleString(undefined,{style: 'percent', minimumFractionDigits:2});
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

    defineOrderMargin(event){
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