import { LightningElement, api, track } from 'lwc';
import approval from '@salesforce/apex/OrderScreenController.approvals';
import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';

export default class OrderSummaryScreen extends LightningElement {
    staticValue = 'hidden';
    hasData = true;
    disabled=false;
    isBarter = false;
    formattedPaymentDate;
    formattedDeliveryDate;
    totalDelivery;
    hideMargin = false;

    @track orderMargin = 0;
    @track approval = '';
    @track approvalMargin = 'Dispensado';

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

        let getCompanyData = {
            ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
            accountId: this.accountData.Id != null ? this.accountData.Id : '',
            orderType: this.headerData.tipo_venda,
            approvalNumber: 1
        }

        getAccountCompanies({data: JSON.stringify(getCompanyData), isHeader: false, verifyUserType: true})
        .then((result) => {
            this.hideMargin = JSON.parse(result);
        });

        const data = {accountData: this.accountData, headerData: this.headerData, productData: this.productData, divisionData: this.divisionData, summaryData: this.summaryData};
        approval({
            data: JSON.stringify(data)
        }).then((result) => {
            if(result){
                this.approval = result;
                if(this.approval.includes('- Comitê de Margem')){
                    this.approval.replace('- Comitê de Margem', '');
                    this.approvalMargin = 'Necessário';
                }
                this.summaryDataLocale.approval = this.approval;
            } 
            else{
                this.approval = 'Não precisa de aprovação'
                this.summaryDataLocale.approval = this.approval;
            }
            this.defineApproval();  
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

            this.formattedPaymentDate = this.headerData.data_pagamento.split('-')[2] + '/' + this.headerData.data_pagamento.split('-')[1] + '/' + this.headerData.data_pagamento.split('-')[0];
            this.formattedDeliveryDate = this.headerData.data_entrega.split('-')[2] + '/' + this.headerData.data_entrega.split('-')[1] + '/' + this.headerData.data_entrega.split('-')[0];
            
            let orderTotalPrice = 0;
            let orderTotalCost = 0;
            if(this.headerData.tipo_venda == 'Venda Barter'){
                for(var i= 0; i< this.productDataLocale.length; i++){
                    this.isBarter = true;
                    this.hideMargin = true;
                    this.orderMargin = this.commodityDataLocale[0].marginValue;
                    this.totalDelivery = this.commodityDataLocale[0].totalDeliveryFront.replace(' sacas', '');
                    let unitPrice = Number(this.productDataLocale[i].unitPrice) / Number(this.commodityDataLocale[0].commodityPrice);
                    this.productDataLocale[i]['unitPrice'] = this.fixDecimalPlacesFront(unitPrice).toString() + ' por saca';
                    this.productDataLocale[i]['totalPrice']  = this.fixDecimalPlacesFront(Number(unitPrice * Number(this.productDataLocale[i].quantity))).toString() + ' sacas';
                    this.productDataLocale[i]['commercialDiscountValue']  =  this.commodityDataLocale[0].discountFront;
                    let totalProductPrice = Number(unitPrice) * Number(this.productDataLocale[i].quantity);
                    this.productDataLocale[i]['commercialDiscountPercentage']  =  this.productDataLocale[i].commercialDiscountPercentageFront;
                    this.productDataLocale[i]['commercialMarginPercentage']  = this.fixDecimalPlacesFront(Number((Number(this.productDataLocale[i].commercialMarginPercentage) / 100) * Number(totalProductPrice))).toString() + ' sacas';
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
                    console.log('this.productDataLocale[i]: ' + JSON.stringify(this.productDataLocale[i]));
                    orderTotalPrice += Number(this.productDataLocale[i].unitPrice) * Number(this.productDataLocale[i].quantity);
                    orderTotalCost += Number(this.productDataLocale[i].practicedCost) * Number(this.productDataLocale[i].quantity);
                    this.productDataLocale[i]['unitPrice'] = 'R$ ' + this.fixDecimalPlacesFront(this.productDataLocale[i].unitPrice);
                    this.productDataLocale[i]['totalPrice']  = 'R$ ' + this.fixDecimalPlacesFront(this.productDataLocale[i].totalPrice);
                    this.productDataLocale[i]['commercialDiscountValue']  = 'R$ ' +  this.fixDecimalPlacesFront(this.productDataLocale[i].commercialDiscountValue);
                    this.productDataLocale[i]['commercialDiscountPercentage']  =  this.fixDecimalPlacesPercentage(this.productDataLocale[i].commercialDiscountPercentage);
                    this.productDataLocale[i]['commercialMarginPercentage']  = this.fixDecimalPlacesFront(this.productDataLocale[i].commercialMarginPercentage) + '%';
                    this.productDataLocale[i]['divisionData'] = [];
                    if(this.divisionData){
                        for(var j=0; j< this.divisionData.length; j++){
                            if(this.divisionData[j].productPosition == i)
                                this.productDataLocale[i]['divisionData'].push(this.divisionData[j])
                        }
                    }
                }
            }
            
            if (this.headerData.tipo_venda != 'Venda Barter') {
                let margin = (1 - (orderTotalCost / orderTotalPrice)) * 100;
                this.orderMargin = this.fixDecimalPlacesFront(margin) + '%';
                this.summaryDataLocale.orderMargin = (+(Math.trunc(+(margin + 'e' + 6)) + 'e' + -6)).toFixed(6);
            } else {
                this.summaryDataLocale.orderMargin = this.orderMargin;
            }

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

    fixDecimalPlacesFront(value) {
        let formatNumber = new Intl.NumberFormat('de-DE').format(Number(Math.round(value + 'e' + 2) + 'e-' + 2));
        return formatNumber;
    }

    fixDecimalPlacesPercentage(value) {
        value = value.toString().includes(',') ? value.toString().replace(',', '.') : value.toString();
        value = value.includes('%') ? Number(value.replace('%', '')) : Number(value);
        return Number(Math.round(value + 'e' + 2) + 'e-' + 2).toString().replace('.', ',') + '%';
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

    defineApproval(event){
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