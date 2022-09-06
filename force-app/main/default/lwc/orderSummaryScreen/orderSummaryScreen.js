import { LightningElement, api, track } from 'lwc';
import approval from '@salesforce/apex/OrderScreenController.approvals';
import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';
import getAccountDistrCenters from '@salesforce/apex/OrderScreenController.getAccountDistrCenters';
import verifyProductDisponibility from '@salesforce/apex/OrderScreenController.verifyProductDisponibility';
import isSeedSale from '@salesforce/apex/OrderScreenController.isSeedSale';

export default class OrderSummaryScreen extends LightningElement {
    showLoading = false;
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

    distrCenterResult=[];
    selectDistributionCenter = false;
    selectedDistributionCenter;
    showUnavailableProducts = false;
    unavailableProducts;
    columns = [
        {label: 'Nome do Produto', fieldName: 'name'},
        {label: 'Código', fieldName: 'sapProductCode'},
        {label: 'Quantidade', fieldName: 'quantity'},
        {label: 'Preço Praticado', fieldName: 'unitPriceFront'}
    ];

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
        this.summaryDataLocale = {... this.summaryData};
        this.loadData();

        let getCompanyData = {
            ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
            accountId: this.accountData.Id != null ? this.accountData.Id : '',
            orderType: this.headerData.tipo_venda,
            approvalNumber: 1
        }

        getAccountCompanies({data: JSON.stringify(getCompanyData), isHeader: false, verifyUserType: true, priceScreen: false})
        .then((result) => {
            this.hideMargin = JSON.parse(result);
        });

        if (this.headerData.IsOrderChild) {
            this.showLoading = true;
            isSeedSale({salesOrgId: this.headerData.organizacao_vendas.Id})
            .then((result) => {
                console.log('result: ' + result);
                if (result) {
                    this.getDistributionCenters();
                } else {
                    this.showLoading = false;
                }
            });
        }

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

    getDistributionCenters() {
        this.showLoading = true;
        this.showUnavailableProducts = false;
        getAccountDistrCenters({salesOrgId: this.headerData.organizacao_vendas.Id})
        .then((result) => {
            try{
                this.distrCenterResult = JSON.parse(result);
                if (this.headerData.centerId != null) {
                    this.selectedDistributionCenter = this.distrCenterResult.find(element => element.centerId == this.headerData.centerId)
                    this.showLoading = false;
                } else {
                    if(this.distrCenterResult.length == 0){
                        this.showToast('warning', 'Atenção!', 'Não foi encontrado centro de distribuição relacionado a organização de vendas. Contate o administrador do sistema.');
                        this.showLoading = false;
                    }
                    else if(this.distrCenterResult.length == 1){
                        this.selectedDistributionCenter = this.distrCenterResult[0];
                        this.summaryDataLocale.centerId = this.selectedDistributionCenter.centerId;
                        this.onSelectDistrCenter();
                    }
                    else if(this.distrCenterResult.length > 1){
                        this.selectDistributionCenter = true;
                        this.showLoading = false;
                    }
                }
            }catch(err){
                console.log(err)
                this.showLoading = false;
            }
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

    chooseDistributionCenter(event){
        var oldDC = this.isFilled(this.selectedDistributionCenter) ? this.selectedDistributionCenter : null;
        let DCs = this.distrCenterResult;
        if(this.isFilled(event)){
            try{
                this.selectedDistributionCenter = event.target.dataset.targetId;
                if(this.isFilled(oldDC)) DCs.find(element => element.centerId == oldDC).selected = false;
                DCs.find(element => element.centerId == this.selectedDistributionCenter).selected = true;
            }catch(err){
                console.log(err);
            }
        }

        this.distrCenterResult = JSON.parse(JSON.stringify(DCs));
    }

    onSelectDistrCenter(){
        this.showLoading = true;
        try{
            if(!this.isFilled(this.summaryDataLocale.centerId)){
                this.selectDistributionCenter = !this.selectDistributionCenter;
                this.summaryDataLocale.centerId = this.selectedDistributionCenter.centerId;
                this.verifyProdDisponiblity();
            } else {
                this.showLoading = false;
            }
        
            const setSummaryData = new CustomEvent('setsummarydata');
            setSummaryData.data = this.summaryDataLocale;
        
            this.dispatchEvent(setSummaryData);
        }catch(err){
            console.log(err)
        }
    }

    verifyProdDisponiblity() {
        let orderProductsId = [];
        let products = JSON.parse(JSON.stringify(this.productData));
        for (let index = 0; index < products.length; index++) {
            orderProductsId.push(products[index].productId);
        }

        let disponibilityData = {
            orderProductsId: orderProductsId,
            salesOrgId: this.headerData.organizacao_vendas.Id,
            supplierCenter: this.distrCenterResult.find(element => element.centerId == this.selectedDistributionCenter.centerId).code
        }

        this.unavailableProducts = [];
        verifyProductDisponibility({data: JSON.stringify(disponibilityData)})
        .then((result) => {
            let missingProducts = [];
            let availableProducts = JSON.parse(result);

            for (let index = 0; index < products.length; index++) {
                if (!availableProducts.includes(products[index].productId)) {
                    missingProducts.push(products[index]);
                    this.showUnavailableProducts = true;
                }
            }
            
            this.unavailableProducts = JSON.parse(JSON.stringify(missingProducts));
            this.showLoading = false;
        });
    }

    excludeProducts() {
        let availableProducts = [];
        let products = JSON.parse(JSON.stringify(this.productData));
        for (let index = 0; index < products.length; index++) {
            let deletedProduct = this.unavailableProducts.find(e => e.productId == products[index].productId);
            if (!this.isFilled(deletedProduct)) {
                availableProducts.push(products[index]);
            }
        }

        this.showUnavailableProducts = false;
        this.productData = JSON.parse(JSON.stringify(availableProducts));
        if (availableProducts.length > 0) {
            this.loadData();
        }
        
        this._setProductData();
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

    _setProductData() {
        const setProductData = new CustomEvent('setproductdata');
        setProductData.data = this.productData;
        this.dispatchEvent(setProductData);
    }
   
    isFilled(field) {
        return ((field !== undefined && field != null && field != '') || field == 0);
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