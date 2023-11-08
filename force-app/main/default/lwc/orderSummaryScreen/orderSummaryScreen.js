import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import approval from '@salesforce/apex/OrderScreenController.approvals';
import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';
import getAccountDistrCenters from '@salesforce/apex/OrderScreenController.getAccountDistrCenters';
import verifyProductDisponibility from '@salesforce/apex/OrderScreenController.verifyProductDisponibility';
import isSeedSale from '@salesforce/apex/OrderScreenController.isSeedSale';
import getPaymentTypes from '@salesforce/apex/OrderScreenController.getPaymentTypes';
import checkSalesOrgFreight from '@salesforce/apex/OrderScreenController.checkSalesOrgFreight';
import getParentIdFromAccountProperty from '@salesforce/apex/OrderScreenController.getParentIdFromAccountProperty';
import getSafraInfos from '@salesforce/apex/OrderScreenController.getSafraInfos';
export default class OrderSummaryScreen extends LightningElement {
    showLoading = false;
    staticValue = 'hidden';
    showFreightScreen=false;
    allowFreight=false;
    currentFreight;
    allowCloseFreightScreen=false;
    hasData = true;
    disabled=false;
    isBarter = false;
    formattedPaymentDate;
    formattedDeliveryDate;
    totalDelivery;
    hideMargin = false;
    hideBagQuantity = false;
    @api seedSale = false;
    clientProperty = '';

    germoTotalValue = 0;
    orderTotalPrice = 0;
    orderTotalPriceFront = 0;
    orderTotalToDistribution = 0;
    tsiTotalPriceFront = 0;
    tsiTotalToDistribution = 0;
    royaltiesTotalPriceFront = 0;
    royaltiesTotalToDistribution = 0;
    
    showRed;
    showTsiRed;
    showRoyaltiesRed;
    @api allowFormOfPayment = false;

    showProductDivision = false;
    currentDivisionProduct = {};
    divisionProducts = [];
    productPosition;
    multiplicity;
    safraData = {};

    showFormOfPayment = false;
    blockPaymentFields = false;
    currentDate;
    maxDate;
    paymentLastPosition = 0;
    paymentsTypes = [];
    @api formsOfPayment = [];

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
    @api childOrder;
    @api excludedItems;
    @api combosSelecteds;
    @api taxData;
    @api bpData;

    styleAndConfigsForPayment = {};

    connectedCallback(){
        if (this.formsOfPayment === undefined) {
            this.formsOfPayment = [];
        } else {
            for (let index = 0; index < this.formsOfPayment.length; index++) {
                this.paymentLastPosition = this.formsOfPayment[index].paymentPosition;
            }
        }

        getParentIdFromAccountProperty({
            accountId: this.headerData.cliente_entrega.Id
        }).then((result) =>{
            this.clientProperty = result
        });
        
        getPaymentTypes()
        .then((result) => {
            let payments = JSON.parse(result);
            this.paymentsTypes = JSON.parse(JSON.stringify(payments));
        });

        this.summaryDataLocale = {... this.summaryData};
        

        let getCompanyData = {
            ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
            accountId: this.accountData.Id != null ? this.accountData.Id : '',
            orderType: this.headerData.tipo_venda,
            approvalNumber: 1
        }
        
        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let yyyy = today.getFullYear();

        this.currentDate = yyyy + '-' + mm + '-' + dd;
        this.maxDate = this.headerData.data_pagamento;

        console.log('this.childOrder: ' + this.childOrder);
        getAccountCompanies({data: JSON.stringify(getCompanyData), isHeader: false, verifyUserType: true, priceScreen: false, childOrder: this.childOrder})
        .then((result) => {
            this.hideMargin = JSON.parse(result);
        });
        isSeedSale({salesOrgId: this.headerData.organizacao_vendas.Id, productGroupName: null})
            .then((result) => {
                this.seedSale = result;
                if (this.seedSale && !this.headerData.IsOrderChild && this.headerData.tipo_venda != 'Venda Barter') {
                    this.allowFormOfPayment = true;
                }
                this.loadData();
        });
        
        if (this.headerData.IsOrderChild) {
            this.showLoading = true;
            isSeedSale({salesOrgId: this.headerData.organizacao_vendas.Id, productGroupName: null})
            .then((result) => {
                this.seedSale = result
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

        getSafraInfos({safraId: this.headerData.safra.Id, salesConditionId: this.headerData.condicao_venda.Id, salesOrgId: this.headerData.organizacao_vendas.Id})
        .then((result) => {
            let safraResult = JSON.parse(result);
            this.safraData = {initialDate:safraResult.initialDate,endDate:safraResult.endDateBilling};
        });

        this.configStylesForPayments();
    }

    isSeedsAndInputs(){
        try{
            return (this.headerData.companySector.toUpperCase() == 'INSUMOS');
        }catch(err){
            console.log(err);
            return false;
        }
        
    }

    configStylesForPayments(){
        if(!this.isSeedsAndInputs()){
            this.styleAndConfigsForPayment['label'] = 'Germoplasma';
            this.styleAndConfigsForPayment['display'] = '';
            this.styleAndConfigsForPayment['padding'] = 'padding-top: 70px;';
            this.styleAndConfigsForPayment['width'] = '';
            return 'Germoplasma';
        }

        this.styleAndConfigsForPayment['label'] = '';
        this.styleAndConfigsForPayment['display'] = 'display: none';
        this.styleAndConfigsForPayment['padding'] = 'padding-top: 20px;';
        this.styleAndConfigsForPayment['width'] = 'width: 45% !important';
        return '';
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

    @api
    loadData(orderScreen, newProductData){
        if (orderScreen) {
            this.productData = JSON.parse(JSON.stringify(newProductData));
        }

        if(this.productData){
            this.productDataLocale = JSON.parse(JSON.stringify(this.productData));
           
            this.commodityDataLocale;
            if(this.commodityData){
                this.commodityDataLocale= JSON.parse(JSON.stringify(this.commodityData));
            }

            let getCompanyData = {
                ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
                accountId: this.accountData.Id != null ? this.accountData.Id : '',
                orderType: this.headerData.tipo_venda,
                approvalNumber: 1
            }

            getAccountCompanies({data: JSON.stringify(getCompanyData), isHeader: true, verifyUserType: false})
            .then((result) => {
               this.salesOrgId = JSON.parse(result).companyInfoHeader.salesOrgId;
               if(this.headerData.frete == 'CIF'){
                    checkSalesOrgFreight({salesOrgId: this.salesOrgId})
                    .then((result) => {
                        let summary = JSON.parse(JSON.stringify(this.summaryDataLocale));
                        let numberOfProducts = 0;
                        for (let i = 0; i < this.productDataLocale.length; i++) {
                            numberOfProducts += Number(this.productDataLocale[i].quantity);
                        }
                        let currentFreight = this.isFilled(this.headerData.freightPerUnit) ? (this.headerData.freightPerUnit * numberOfProducts) : summary.freightValue;

                        this.allowFreight = this.headerData.IsOrderChild || this.childOrder ? false : result;
                        this.showFreightScreen = result;
                        summary.freightValue = summary.freightValue === undefined ? 0 : (this.headerData.IsOrderChild || this.childOrder ? currentFreight : summary.freightValue);
                        summary.freightValueFront = this.fixDecimalPlacesFront(summary.freightValue);
                        this.currentFreight = summary.freightValue;
                        this.summaryDataLocale = JSON.parse(JSON.stringify(summary));
                        this.showFreightScreen = this.showFreightScreen && !this.headerData.IsOrderChild ? true : false;

                        if (this.showFreightScreen && this.headerData.frete == 'FOB') {
                            this.allowCloseFreightScreen = true;
                        }
                    });
               }
            });
           
            if (this.headerData.status_pedido == 'Em aprovação - Gerente Filial' || this.headerData.status_pedido == 'Em aprovação - Gerente Regional' || this.headerData.status_pedido == 'Em Aprovação - Diretor Torre' ||
                this.headerData.status_pedido == 'Em aprovação - Diretor' || this.headerData.status_pedido == 'Em aprovação - Comitê Margem' || this.headerData.status_pedido == 'Em aprovação - Mesa de Grãos') {
                this.disabled = true;
            }

            this.formattedPaymentDate = this.headerData.data_pagamento.split('-')[2] + '/' + this.headerData.data_pagamento.split('-')[1] + '/' + this.headerData.data_pagamento.split('-')[0];
            this.formattedDeliveryDate = this.headerData.data_entrega.split('-')[2] + '/' + this.headerData.data_entrega.split('-')[1] + '/' + this.headerData.data_entrega.split('-')[0];
            
            let orderTotalPrice = 0;
            let orderTotalPriceToCalcMargin = 0;
            let orderTotalCost = 0;
            let royaltiesTotalPrice = 0;
            let tsiTotalPrice = 0;
            if(this.headerData.tipo_venda == 'Venda Barter'){
                for(var i= 0; i< this.productDataLocale.length; i++){
                    orderTotalPrice += Number(this.productDataLocale[i].unitPrice) * Number(this.productDataLocale[i].quantity);
                    orderTotalCost += Number(this.productDataLocale[i].practicedCost) * Number(this.productDataLocale[i].quantity);
                    orderTotalPriceToCalcMargin += Number(this.productDataLocale[i].unitPrice) * Number(this.productDataLocale[i].quantity);
                    this.isBarter = true;
                    this.hideMargin = true;
                    this.hideBagQuantity = this.headerData.IsOrderChild ? true : false;
                    this.orderMargin = this.commodityDataLocale[0].marginValue;
                    this.totalDelivery = this.isFilled(this.commodityDataLocale[0].totalDeliveryFront) ? this.commodityDataLocale[0].totalDeliveryFront.replace(' sacas', '') : this.commodityDataLocale[0].totalDelivery.replace(' sacas', '');
                    let unitPrice = Number(this.productDataLocale[i].unitPrice) / Number(this.commodityDataLocale[0].commodityPrice);
                    this.productDataLocale[i]['unitPrice'] = this.fixDecimalPlacesFront(unitPrice).toString() + ' por saca';
                    this.productDataLocale[i]['totalPrice']  = this.fixDecimalPlacesFront(Number(unitPrice * Number(this.productDataLocale[i].quantity))).toString() + ' sacas';
                    this.productDataLocale[i]['commercialDiscountValue']  =  this.commodityDataLocale[0].discountFront;
                    let totalProductPrice = Number(unitPrice) * Number(this.productDataLocale[i].quantity);
                    this.productDataLocale[i]['commercialDiscountPercentage']  =  this.productDataLocale[i].commercialDiscountPercentageFront;
                    this.productDataLocale[i]['commercialMarginPercentage']  = this.fixDecimalPlacesFront(Number((Number(this.productDataLocale[i].commercialMarginPercentage) / 100) * Number(totalProductPrice))).toString() + ' sacas';
                    this.productDataLocale[i]['divisionData'] = [];
                    if (this.divisionData) {
                        for (var j=0; j< this.divisionData.length; j++) {
                            let counter = this.headerData.pedido_mae.Id != null ? i : i + 1;
                            if (this.divisionData[j].productPosition == counter) {
                                let currentDivision = JSON.parse(JSON.stringify(this.divisionData[j]));
                                let splitedDate = currentDivision.deliveryDate.split('-');
                                currentDivision.dateToShow = splitedDate[2] + '/' + splitedDate[1] + '/' + splitedDate[0];
                                this.productDataLocale[i]['divisionData'].push(currentDivision);
                            }
                        }
                    }
                }
            }
            else{
                for(var i= 0; i< this.productDataLocale.length; i++){
                    console.log(this.seedSale)
                    orderTotalPrice += Number(this.productDataLocale[i].unitPrice) * Number(this.productDataLocale[i].quantity) + (this.seedSale ? Number(this.productDataLocale[i].brokerage) : 0);
                    orderTotalPriceToCalcMargin += Number(this.productDataLocale[i].unitPrice) * Number(this.productDataLocale[i].quantity);
                    orderTotalCost += Number(this.productDataLocale[i].practicedCost) * Number(this.productDataLocale[i].quantity);
                    tsiTotalPrice += Number(this.productDataLocale[i].tsiTotalPrice);
                    royaltiesTotalPrice += Number(this.productDataLocale[i].royaltyTotalPrice);
                    
                    let currentTotalPrice = this.seedSale && this.isFilled(this.productDataLocale[i].brokerage) && this.productDataLocale[i].brokerage > 0 ? this.productDataLocale[i].totalPriceWithBrokerage : this.productDataLocale[i].totalPrice;
                    currentTotalPrice = Number(currentTotalPrice) + (this.seedSale ? Number(this.productDataLocale[i].tsiTotalPrice) + Number(this.productDataLocale[i].royaltyTotalPrice) : 0);
                    this.productDataLocale[i]['unitPrice'] = (this.headerData.moeda == 'BRL' ? 'R$ ' : 'US$ ') + this.fixDecimalPlacesFront(this.productDataLocale[i].unitPrice);
                    this.productDataLocale[i]['totalPrice'] = (this.headerData.moeda == 'BRL' ? 'R$ ' : 'US$ ') + this.fixDecimalPlacesFront(currentTotalPrice);
                    this.productDataLocale[i]['commercialDiscountValue'] = (this.headerData.moeda == 'BRL' ? 'R$ ' : 'US$ ') + this.fixDecimalPlacesFront(this.productDataLocale[i].commercialDiscountValue);
                    this.productDataLocale[i]['commercialDiscountPercentage']  =  this.fixDecimalPlacesPercentage(this.productDataLocale[i].commercialDiscountPercentage);
                    this.productDataLocale[i]['commercialMarginPercentage']  = this.fixDecimalPlacesFront(this.productDataLocale[i].commercialMarginPercentage) + '%';
                    this.productDataLocale[i]['divisionData'] = [];
                    if(this.divisionData){
                        for (var j=0; j< this.divisionData.length; j++) {
                            let counter = this.headerData.pedido_mae.Id != null ? i : i + 1;
                            if(this.divisionData[j].productPosition == counter) {
                                let currentDivision = JSON.parse(JSON.stringify(this.divisionData[j]));
                                let splitedDate = currentDivision.deliveryDate.split('-');
                                currentDivision.dateToShow = splitedDate[2] + '/' + splitedDate[1] + '/' + splitedDate[0];
                                this.productDataLocale[i]['divisionData'].push(currentDivision);
                            }
                        }
                    }
                }
            }
            
            let summary = JSON.parse(JSON.stringify(this.summaryDataLocale));
            this.germoTotalValue = orderTotalPrice;
            this.orderTotalPrice = this.germoTotalValue + Number(this.headerData.frete == 'CIF' && this.seedSale ? summary.freightValue : 0);
            this.orderTotalPriceFront = this.fixDecimalPlacesFront(this.orderTotalPrice);
            this.orderTotalToDistribution = this.orderTotalPrice;

            this.royaltiesTotalPrice = royaltiesTotalPrice;
            this.royaltiesTotalPriceFront = this.fixDecimalPlacesFront(royaltiesTotalPrice);
            this.royaltiesTotalToDistribution = royaltiesTotalPrice;

            this.tsiTotalPrice = tsiTotalPrice;
            this.tsiTotalPriceFront = this.fixDecimalPlacesFront(tsiTotalPrice);
            this.tsiTotalToDistribution = tsiTotalPrice;
            
            if (this.headerData.tipo_venda == 'Venda Barter' && this.headerData.IsOrderChild) {
                this.summaryDataLocale.orderMargin = this.headerData.orderMargin;
            } else {
                let margin = (1 - (orderTotalCost / orderTotalPriceToCalcMargin)) * 100;
                this.orderMargin = this.fixDecimalPlacesFront(margin) + '%';
                this.summaryDataLocale.orderMargin = (+(Math.trunc(+(margin + 'e' + 6)) + 'e' + -6)).toFixed(6);
            }

            this.summaryDataLocale.totalValue = orderTotalPrice + royaltiesTotalPrice + tsiTotalPrice;

            this.defineOrderMargin();
        }
    }

    openFreight(event) {
        this.showFreightScreen = true;
    }

    chooseDistributionCenter(event){
        let oldDC = this.isFilled(this.selectedDistributionCenter) ? this.selectedDistributionCenter : null;
        let DCs = this.distrCenterResult;
        if(this.isFilled(event)){
            try{
                this.selectedDistributionCenter = DCs.find(element => element.centerId == event.target.dataset.targetId);
                if(this.isFilled(oldDC)) DCs.find(element => element.centerId == oldDC.centerId).selected = false;
                DCs.find(element => element.centerId == this.selectedDistributionCenter.centerId).selected = true;
            }catch(err){
                console.log(err);
            }
        }

        this.distrCenterResult = JSON.parse(JSON.stringify(DCs));
    }

    onSelectDistrCenter(){
        this.showLoading = true;
        try{
            
            this.selectDistributionCenter = !this.selectDistributionCenter;
            this.summaryDataLocale.centerId = this.selectedDistributionCenter.centerId;
            this.verifyProdDisponiblity();
            
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

        let availableDivisions = [];
        let divisions = JSON.parse(JSON.stringify(this.divisionData));
        console.log('divisions: ' + JSON.stringify(divisions));
        for (let index = 0; index < divisions.length; index++) {
            console.log('divisions[index].productId: ' + divisions[index].productId);
            let deletedProduct = this.unavailableProducts.find(e => e.productId == divisions[index].productId);
            if (!this.isFilled(deletedProduct)) {
                console.log('add - divisions[index].productId: ' + divisions[index].productId);
                availableDivisions.push(divisions[index]);
            }
        }

        this.showUnavailableProducts = false;
        this.productData = JSON.parse(JSON.stringify(availableProducts));
        this._setProductData();

        this.divisionData = JSON.parse(JSON.stringify(availableDivisions));		 
        this._setDivisionData();
        if (availableProducts.length > 0) {
            this.loadData();
        }
    }
    changeFreightValue(event) {
        let fieldValue = event.target.value;
        fieldValue = fieldValue.toString().includes('.') ? fieldValue.toString().replace('.', '') : fieldValue;
        fieldValue = fieldValue.toString().includes(',') ? fieldValue.toString().replace(',', '.') : fieldValue;
        
        let summary = JSON.parse(JSON.stringify(this.summaryDataLocale));
        summary.freightValue = this.fixFreightDecimalPlaces(fieldValue);
        summary.freightValueFront = this.fixDecimalPlacesFront(fieldValue);
        this.summaryDataLocale = JSON.parse(JSON.stringify(summary));
    }

    closeFreightScreen() {
        this.showFreightScreen = false;
        let summary = JSON.parse(JSON.stringify(this.summaryDataLocale));
        summary.freightValue = this.isFilled(this.currentFreight) ? this.currentFreight : 0;
        summary.freightValueFront = this.fixDecimalPlacesFront(summary.freightValue);
        this.summaryDataLocale = JSON.parse(JSON.stringify(summary));
    }

    confirmFreight() {
        let variable = 'freight-value';
        if(!this.template.querySelector(`[data-target-id="${variable}"]`).checkValidity()){
            this.showToast('warning', 'Atenção', 'Valor de frete inválido');
            return;
        }

        this.showFreightScreen = false;
        let summary = JSON.parse(JSON.stringify(this.summaryDataLocale));
        this.currentFreight = this.fixFreightDecimalPlaces(summary.freightValue);

        let allPayments = JSON.parse(JSON.stringify(this.formsOfPayment));
        let germoplasmaValue = 0;
        for (let index = 0; index < allPayments.length; index++) {
            if (allPayments[index].paymentType == 'Germoplasma') germoplasmaValue += Number(allPayments[index].value);
        }

        this.orderTotalPrice = Number(this.germoTotalValue) + Number(this.headerData.frete == 'CIF' && this.seedSale ? summary.freightValue : 0);
        this.orderTotalPriceFront = this.fixDecimalPlacesFront(this.orderTotalPrice);
        this.orderTotalToDistribution = this.orderTotalPrice - Number(this.headerData.frete == 'CIF' && this.seedSale ? germoplasmaValue : 0);
        this.changeFreight();
    }

    fixFreightDecimalPlaces(value) {
        return (+(Math.trunc(+(value + 'e' + 4)) + 'e' + -4)).toFixed(4);
    }

    formatCurrency(num){
        try{
            return parseFloat(num).toLocaleString("pt-BR", {style:"currency", currency:this.headerData.moeda});
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
                    if (fieldValue > this.maxDate) {
                        allPayments[index].paymentDay = null;
                    } else {
                        allPayments[index].paymentDay = fieldValue;
                        if (allPayments[index].paymentType != '') allPayments[index].paymentKey = allPayments[index].paymentType + '-' + fieldValue;
                    }
                } else if (fieldId.includes('valueId')) {
                    fieldValue = fieldValue.toString().includes('.') ? fieldValue.toString().replaceAll('.', '') : fieldValue;
                    fieldValue = fieldValue.toString().includes(',') ? fieldValue.toString().replace(',', '.') : fieldValue;
                    allPayments[index].value = this.fixDecimalPlaces(fieldValue);
                    allPayments[index].valueFront = this.fixDecimalPlacesFront(fieldValue);
                }
            }
        }

        this.formsOfPayment = JSON.parse(JSON.stringify(allPayments));
        this.recalcTotalToDistribution();
    }

    recalcTotalToDistribution(){
        let value = 0;
        let tsiValue = 0;
        let royaltiesValue = 0;
        let allPayments = JSON.parse(JSON.stringify(this.formsOfPayment));
        
        if (allPayments.length == 0) {
            value = 0.01;
            allPayments.push(this.createDefaultValues('Germoplasma'));

            if (this.royaltiesTotalPrice > 0) {
                royaltiesValue = 0.01;
                allPayments.push(this.createDefaultValues('Royalties'));
            }
            if (this.tsiTotalPrice > 0) {
                tsiValue = 0.01;
                allPayments.push(this.createDefaultValues('TSI'));
            }
            this.formsOfPayment = JSON.parse(JSON.stringify(allPayments));

        } else {
            for (let index = 0; index < allPayments.length; index++) {
                let currentValue = this.isFilled(allPayments[index].value) ? allPayments[index].value : 0;
                if (allPayments[index].paymentType == 'Germoplasma') value += Number(currentValue);
                if (allPayments[index].paymentType == 'TSI') tsiValue += Number(currentValue);
                if (allPayments[index].paymentType == 'Royalties') royaltiesValue += Number(currentValue);
            }
        }
        
        this.orderTotalToDistribution = this.fixDecimalPlacesFront(Number(this.orderTotalPrice) - Number(value));
        this.showRed = this.orderTotalToDistribution < 0;
        
        this.tsiTotalToDistribution = this.fixDecimalPlacesFront(Number(this.tsiTotalPrice) - Number(tsiValue));;
        this.showTsiRed = this.tsiTotalToDistribution < 0;
        
        this.royaltiesTotalToDistribution = this.fixDecimalPlacesFront(Number(this.royaltiesTotalPrice) - Number(royaltiesValue));;
        this.showRoyaltiesRed = this.royaltiesTotalToDistribution < 0;
    }

    createDefaultValues(paymentType) {
        this.paymentLastPosition = this.paymentLastPosition + 1;
        let divPosition = this.paymentLastPosition;
        let paymentTypeId = 'paymentTypeId-' + divPosition;
        let paymentDayId = 'paymentDayId-' + divPosition;
        let valueId = 'valueId-' + divPosition;
        
        let newDefaultValues = {
            paymentType: paymentType,
            paymentDay: this.headerData.data_pagamento,
            value: 0.01,
            valueFront: this.fixDecimalPlaces('0.01'),
            paymentPosition: this.paymentLastPosition,
            paymentTypeId: paymentTypeId,
            paymentDayId: paymentDayId,
            valueId: valueId,
            paymentKey: paymentType + '-' + this.headerData.data_pagamento,
            saved: true
        };
        return newDefaultValues;
    }

    newFields() {
        let allFromsOfPayment = JSON.parse(JSON.stringify(this.formsOfPayment));
        this.paymentLastPosition = this.paymentLastPosition + 1;
        let divPosition = this.paymentLastPosition;
        let paymentTypeId = 'paymentTypeId-' + divPosition;
        let paymentDayId = 'paymentDayId-' + divPosition;
        let valueId = 'valueId-' + divPosition;
        
        if(allFromsOfPayment.length < 10){
            allFromsOfPayment.push({
                paymentType: this.isSeedsAndInputs() ? 'Germoplasma' : '',
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
        }else{
            this.showToast('warning', 'Atenção!', 'É possível inserir no máximo 10 formas de pagamento.');
        }
    }

    validRegexField(allPayment){
        let isPassed = true;
        try{
            for (let index = 0; index < allPayment.length; index++) {
                if(!this.template.querySelector(`[data-target-id="${allPayment[index].valueId}"]`).checkValidity()){
                    isPassed = false
                }
            }
        }catch(err){
            console.log(err)
        }
        return isPassed;
    }
    confirmFormOfPayment() {
        let allPayments = JSON.parse(JSON.stringify(this.formsOfPayment));
        let groupedFormsOfPayment = [];

        for (let index = 0; index < allPayments.length; index++) {
            let checkFields = allPayments[index];
            let pushValue = true;
            if (this.isFilled(allPayments[index].paymentType) && this.isFilled(allPayments[index].paymentDay) && this.isFilled(allPayments[index].value)) {
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

        try{
            const result = this.validRegexField(allPayments)
            if(!result){
                this.showToast('warning', 'Atenção!', 'Valor inserido no formato incorreto.');
                return;
            }
        }catch(err){
            console.log(err)
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

    openDivisionModal(event) {
        this.productDivision(event.target.dataset.targetId);
    }

    productDivision(position) {
        let distributedQuantity = 0;
        this.divisionProducts = this.isFilled(this.divisionData) ? JSON.parse(JSON.stringify(this.divisionData)) : [];
        for (let index = 0; index < this.divisionProducts.length; index++) {
            if (this.divisionProducts[index].productPosition == position) {
                this.divisionProducts[index].showInfos = true;
                distributedQuantity += Number(this.divisionProducts[index].quantity);
            } else {
                this.divisionProducts[index].showInfos = false;
            }
        }

        let currentProduct = this.productDataLocale.find(e => e.position == position);
        let availableQuantity = Number(currentProduct.quantity) - Number(distributedQuantity);
        this.productPosition = position;
        this.multiplicity = this.isFilled(currentProduct.multiplicity) && currentProduct.multiplicity > 0 ? currentProduct.multiplicity : 1;
        let allowChange = (this.headerData.tipo_pedido != 'Pedido Filho' && !this.headerData.IsOrderChild && this.isFilled(this.headerData.codigo_sap)) ||
                          (this.headerData.tipo_pedido == 'Pedido Filho' && this.isFilled(this.headerData.codigo_sap)) ? true : false;
        this.currentDivisionProduct = {productId:currentProduct.productId,unitPrice:currentProduct.unitPrice,position:position,name:currentProduct.name,quantity:currentProduct.quantity,availableQuantity:availableQuantity,showRed:availableQuantity < 0 ? true : false,dontAllowChange:allowChange};
        this.showProductDivision = !this.showProductDivision;
        if (!this.currentDivisionProduct.dontAllowChange) this.newDivisionFields();
    }

    newDivisionFields() {
        let allDivisions = JSON.parse(JSON.stringify(this.divisionProducts));
        let divPosition = this.isFilled(allDivisions) ? allDivisions.length : 0;
        let deliveryId = 'deliveryId-' + divPosition;
        let quantityId = 'quantityId-' + divPosition;
        let orderItemKey = this.currentDivisionProduct.productId;
        allDivisions.push({productId: this.currentDivisionProduct.productId, deliveryDate: null, quantity: null, position: divPosition, deliveryId: deliveryId, quantityId: quantityId, orderItemKey: orderItemKey, productPosition: this.productPosition, showInfos: true});
        this.divisionProducts = JSON.parse(JSON.stringify(allDivisions));
    }

    showDivisionModal() {
        let quantityError = this.quantityExceed();
        if (quantityError) this.showToast('warning', 'Atenção!', 'A soma das quantidades não pode ultrapassar ' + this.currentDivisionProduct.quantity + '.');
        else this.showProductDivision = !this.showProductDivision;
    }

    quantityExceed() {
        let allDivisions = JSON.parse(JSON.stringify(this.divisionProducts));
        if (allDivisions.length > 0) {
            let allDivisionQuantitys = 0;
            for (let index = 0; index < allDivisions.length; index++) {
                let existingProductDivision = allDivisions[index];
                if (existingProductDivision.productPosition == this.productPosition) allDivisionQuantitys += Number(existingProductDivision.quantity);
            }
            if (allDivisionQuantitys > Number(this.currentDivisionProduct.quantity)) return true;
            else return false;
        }
    }

    confirmDivision() {
        let quantityError = this.quantityExceed();
        if (quantityError) {
            this.showToast('warning', 'Atenção!', 'A soma das quantidades não pode ultrapassar ' + this.currentDivisionProduct.quantity + '.');
        } else {
            let filledDivisions = [];
            for (let index = 0; index < this.divisionProducts.length; index++) {
                let checkFields = this.divisionProducts[index];
                let pushValue = true;
                if (this.isFilled(checkFields.quantity) && checkFields.quantity > 0 && this.isFilled(checkFields.deliveryDate)) {
                    for (let i = 0; i < filledDivisions.length; i++) {
                        if (filledDivisions[i].deliveryDate == checkFields.deliveryDate && filledDivisions[i].productId == checkFields.productId) {
                            filledDivisions[i].quantity = Number(filledDivisions[i].quantity) + Number(checkFields.quantity);
                            pushValue = false;
                        }
                    }
                    if (pushValue) filledDivisions.push(checkFields);
                }
            }

            for (let index = 0; index < filledDivisions.length; index++) {
                if (filledDivisions[index].productPosition == this.productPosition) filledDivisions[index].orderItemKey = this.currentDivisionProduct.productId;
            }

            this.divisionData = JSON.parse(JSON.stringify(filledDivisions));
            this.showProductDivision = !this.showProductDivision;
            this.showToast('success', 'Sucesso!', 'Remessas salvas.');
            this._setDivisionData();
            let allProducts = JSON.parse(JSON.stringify(this.productDataLocale));
            for (var i= 0; i< allProducts.length; i++) {
                allProducts[i].divisionData = [];
                for (var j=0; j< this.divisionData.length; j++) {
                    let counter = this.headerData.pedido_mae.Id != null ? i : i + 1;
                    if (this.divisionData[j].productPosition == counter) {
                        let currentDivision = JSON.parse(JSON.stringify(this.divisionData[j]));
                        let splitedDate = currentDivision.deliveryDate.split('-');
                        currentDivision.dateToShow = splitedDate[2] + '/' + splitedDate[1] + '/' + splitedDate[0];
                        if (currentDivision.quantity > 0) allProducts[i].divisionData.push(currentDivision);
                    }
                }
            }
            this.productDataLocale = JSON.parse(JSON.stringify(allProducts));
        }
    }

    divisionChange(event) {
        let allDivisions = JSON.parse(JSON.stringify(this.divisionProducts));
        let fieldId = event.target.dataset.targetId;
        let fieldValue = event.target.value;
        let currentProduct;

        if (this.isFilled(fieldValue)) {
            if (fieldId.includes('deliveryId-')) {
                currentProduct = allDivisions.find(e => e.deliveryId == fieldId);
                if (fieldValue >= this.currentDate && fieldValue >= this.safraData.initialDate && fieldValue <= this.safraData.endDate) {
                    currentProduct.deliveryDate = fieldValue;
                } else {
                    currentProduct.deliveryDate = null;
                    let formatInitialDate = this.safraData.initialDate.split('-')[2] + '/' + this.safraData.initialDate.split('-')[1] + '/' + this.safraData.initialDate.split('-')[0];
                    let formatEndDate = this.safraData.endDate.split('-')[2] + '/' + this.safraData.endDate.split('-')[1] + '/' + this.safraData.endDate.split('-')[0];
                    this.showToast('warning', 'Atenção!', 'A data de remessa precisa ser maior que a atual e estar entre a vigência de entrega da Safra: ' + formatInitialDate + '-' + formatEndDate + '.');
                }
            } else if (fieldId.includes('quantityId-')) {
                let productQuantity = 0;
                for (let index = 0; index < allDivisions.length; index++) {
                    if (allDivisions[index].productPosition == this.currentDivisionProduct.position && allDivisions[index].quantityId != fieldId) productQuantity = productQuantity + (Number(allDivisions[index].quantity));
                }

                currentProduct = allDivisions.find(e => e.quantityId == fieldId);
                this.currentDivisionProduct.availableQuantity = Number(this.currentDivisionProduct.quantity) - ((Number(productQuantity)));
                if ((parseFloat(fieldValue) + parseFloat(productQuantity)) <= parseFloat(this.currentDivisionProduct.quantity)) {
                    currentProduct.quantity = this.calculateMultiplicity(fieldValue);
                } else {
                    currentProduct.quantity = this.currentDivisionProduct.quantity - Number(productQuantity);
                    this.showToast('warning', 'Atenção!', 'A quantidade foi arredondada para ' + currentProduct.quantity + ' para não exceder.');
                }

                this.currentDivisionProduct.availableQuantity = Number(this.currentDivisionProduct.quantity) - ((Number(productQuantity) + Number(currentProduct.quantity)));
                if (this.currentDivisionProduct.availableQuantity < 0) this.currentDivisionProduct.showRed = true;
                else this.currentDivisionProduct.showRed = false;
            }
            this.divisionProducts = JSON.parse(JSON.stringify(allDivisions));
        }
    }

    calculateMultiplicity(quantity) {
        if (this.isFilled(this.multiplicity)) {
            this.multiplicity = this.multiplicity > 0 ? this.multiplicity : 1;
            let remainder = (quantity * 100) % (this.multiplicity * 100);
            if (quantity > this.currentDivisionProduct.availableQuantity) {
                this.showToast('warning', 'Atenção!', 'A quantidade não pode ultrapassar ' + this.currentDivisionProduct.availableQuantity + '.');
                return this.currentDivisionProduct.availableQuantity;
            }

            if (remainder == 0) {
                return quantity;
            } else {
                quantity = this.fixDecimalPlacesFront(quantity);
                quantity = quantity.toString().includes(',') ? Number(quantity.replace(',', '.')) : quantity;
                quantity = Math.ceil(quantity / this.multiplicity) * this.multiplicity;
                this.showToast('warning', 'Atenção!', 'A quantidade foi arredondada para ' + this.fixDecimalPlacesFront(quantity) + '.');
                return quantity;
            }
        }
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
    changeFreight(){
        const setSummaryData = new CustomEvent('setsummarydata');
        setSummaryData.data = this.summaryDataLocale;
        this.dispatchEvent(setSummaryData);
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

    _setDivisionData() {
        const setdivisiondata = new CustomEvent('setdivisiondata');
        setdivisiondata.data = this.divisionData;
        this.dispatchEvent(setdivisiondata);
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