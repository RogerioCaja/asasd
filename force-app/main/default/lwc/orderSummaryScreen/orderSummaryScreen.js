import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import approval from '@salesforce/apex/OrderScreenController.approvals';
import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';
import getPaymentTypes from '@salesforce/apex/OrderScreenController.getPaymentTypes';

export default class OrderSummaryScreen extends LightningElement {
    staticValue = 'hidden';
    hasData = true;
    disabled=false;
    isBarter = false;
    formattedPaymentDate;
    formattedDeliveryDate;
    totalDelivery;
    hideMargin = false;
    
    orderTotalPrice = 0;
    orderTotalToDistribution = 0;
    showRed;
    showFormOfPayment = false;
    blockPaymentFields = false;
    currentDate;
    paymentLastPosition = 0;
    paymentsTypes = [];
    @api formsOfPayment = [];

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
    @api excludedItems;

    connectedCallback(){
        if (this.formsOfPayment === undefined) {
            this.formsOfPayment = [];
        } else {
            for (let index = 0; index < this.formsOfPayment.length; index++) {
                this.paymentLastPosition = this.formsOfPayment[index].paymentPosition;
            }
        }

        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let yyyy = today.getFullYear();

        this.currentDate = yyyy + '-' + mm + '-' + dd;
        getPaymentTypes()
        .then((result) => {
            let teste = JSON.parse(result);
            this.paymentsTypes = JSON.parse(JSON.stringify(teste));
        });

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
            
            this.orderTotalPrice = orderTotalPrice;
            this.orderTotalToDistribution = orderTotalPrice;
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

    fixDecimalPlaces(value) {
        return (+(Math.trunc(+(value + 'e' + 6)) + 'e' + -6)).toFixed(6);
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

    openFormOfPayment(event) {
        this.recalcTotalToDistribution();
        let allPayments = JSON.parse(JSON.stringify(this.formsOfPayment));
        let savedPayments = []
        for (let index = 0; index < allPayments.length; index++) {
            if (allPayments[index].saved) {
                allPayments[index].valueFront = this.fixDecimalPlacesFront(allPayments[index].value);
                savedPayments.push(allPayments[index]);
            }
        }
        this.formsOfPayment = JSON.parse(JSON.stringify(savedPayments));
        this.showFormOfPayment = !this.showFormOfPayment;
    }

    changeValue(event) {
        let fieldId = event.target.dataset.targetId;
        let fieldValue = event.target.value;
        let paymentPosition = fieldId.split('-')[1];
        let allPayments = JSON.parse(JSON.stringify(this.formsOfPayment));
        
        for (let index = 0; index < allPayments.length; index++) {
            if (allPayments[index].paymentPosition == paymentPosition) {
                if (fieldId.includes('paymentTypeId')) {
                    allPayments[index].paymentType = fieldValue;
                    if (allPayments[index].paymentDay != '') allPayments[index].paymentKey = fieldValue + '-' + allPayments[index].paymentDay;
                } else if (fieldId.includes('paymentDayId')) {
                    allPayments[index].paymentDay = fieldValue;
                    if (allPayments[index].paymentType != '') allPayments[index].paymentKey = allPayments[index].paymentType + '-' + fieldValue;
                } else if (fieldId.includes('valueId')) {
                    fieldValue = fieldValue.toString().includes('.') ? fieldValue.toString().replace('.', '') : fieldValue;
                    fieldValue = fieldValue.toString().includes(',') ? fieldValue.toString().replace(',', '.') : fieldValue;
                    allPayments[index].value = this.fixDecimalPlaces(fieldValue);
                    allPayments[index].valueFront = this.fixDecimalPlacesFront(fieldValue);
                    this.recalcTotalToDistribution();
                }
            }
        }

        this.formsOfPayment = JSON.parse(JSON.stringify(allPayments));
    }

    recalcTotalToDistribution(){
        let value = 0;
        let allPayments = JSON.parse(JSON.stringify(this.formsOfPayment))
        for (let index = 0; index < allPayments.length; index++) {
            value += allPayments[index].value;
        }
        this.orderTotalToDistribution = Number(this.orderTotalPrice) - Number(value);
    }

    newFields() {
        let allFromsOfPayment = JSON.parse(JSON.stringify(this.formsOfPayment));
        this.paymentLastPosition = this.paymentLastPosition + 1;
        let divPosition = this.paymentLastPosition;
        let paymentTypeId = 'paymentTypeId-' + divPosition;
        let paymentDayId = 'paymentDayId-' + divPosition;
        let valueId = 'valueId-' + divPosition;
        
        allFromsOfPayment.push({
            paymentType: '',
            paymentDay: null,
            value: '',
            paymentPosition: this.paymentLastPosition,
            paymentTypeId: paymentTypeId,
            paymentDayId: paymentDayId,
            valueId: valueId,
            paymentKey: '',
            saved: false
        });
        this.formsOfPayment = JSON.parse(JSON.stringify(allFromsOfPayment));
    }

    confirmFormOfPayment() {
        let allPayments = JSON.parse(JSON.stringify(this.formsOfPayment));
        let groupedFormsOfPayment = [];

        for (let index = 0; index < allPayments.length; index++) {
            let checkFields = allPayments[index];
            let pushValue = true;
            if (allPayments[index].paymentType != '' && allPayments[index].paymentDay != '' && allPayments[index].value != '') {
                if (checkFields.paymentKey != '') {
                    for (let i = 0; i < groupedFormsOfPayment.length; i++) {
                        if (groupedFormsOfPayment[i].paymentKey == checkFields.paymentKey) {
                            groupedFormsOfPayment[i].value = Number(groupedFormsOfPayment[i].value) + Number(checkFields.value);
                            pushValue = false;
                        }
                    }
                    if (pushValue) {
                        checkFields.saved = true;
                        groupedFormsOfPayment.push(checkFields);
                    }
                }
            } else {
                this.showToast('warning', 'Atenção!', 'Todos os campos são obrigatórios.');
                return;
            }
        }

        this.formsOfPayment = JSON.parse(JSON.stringify(groupedFormsOfPayment));
        if (this.formsOfPayment.length > 10) {
            this.showToast('warning', 'Atenção!', 'É possível inserir no máximo 10 formas de pagamento.');
        } else {
            this.showFormOfPayment = !this.showFormOfPayment;
            this.setFormsOfPayment();
        }
    }

    excludeLine(event) {
        let currentLines = JSON.parse(JSON.stringify(this.formsOfPayment));
        let linesToUse = [];
        for (let index = 0; index < currentLines.length; index++) {
            if (currentLines[index].paymentPosition != event.target.dataset.targetId) {
                linesToUse.push(currentLines[index]);
            }
        }

        this.formsOfPayment = JSON.parse(JSON.stringify(linesToUse));
        this.recalcTotalToDistribution();
    }

    showToast(type, title, message) {
        let event = new ShowToastEvent({
            variant: type,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }

    closeFormOfPayment() {
        this.showFormOfPayment = !this.showFormOfPayment;
    }

    setFormsOfPayment(){
        const setformsofpayment = new CustomEvent('setformsofpayment');
        setformsofpayment.data = this.formsOfPayment;
        this.dispatchEvent(setformsofpayment);
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