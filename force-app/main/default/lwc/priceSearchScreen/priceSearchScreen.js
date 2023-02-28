import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProductRecords from '@salesforce/apex/CustomLookupController.fetchProductsRecords';
import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';
import getFinancialInfos from '@salesforce/apex/OrderScreenController.getFinancialInfos';

import SAFRA_OBJECT from '@salesforce/schema/Safra__c';
import SAFRA_NAME from '@salesforce/schema/Safra__c.Name';

import CONDICAO_VENDA_OBJECT from '@salesforce/schema/SalesCondition__c';
import CONDICAO_VENDA_NAME from '@salesforce/schema/SalesCondition__c.Name';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';

import CTV_OBJECT from '@salesforce/schema/User';
import CTV_NAME from '@salesforce/schema/User.Name';

export default class PriceSearchScreen extends LightningElement {
    @track redispatchSafraObject = SAFRA_OBJECT;
    safra;
    @track redispatchSafraSearchFields = [SAFRA_NAME];
    @track redispatchSafraListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    @track redispatchCondicaoVendaObject = CONDICAO_VENDA_OBJECT;
    condicao_venda;
    @track redispatchCondicaoVendaSearchFields = [CONDICAO_VENDA_NAME];
    @track redispatchCondicaoVendaListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    @track redispatchAccountObject = ACCOUNT_OBJECT;
    account;
    @track redispatchAccountSearchFields = [ACCOUNT_NAME];
    @track redispatchAccountListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    @track redispatchCtvObject = CTV_OBJECT;
    ctv;
    @track redispatchCtvSearchFields = [CTV_NAME];
    @track redispatchCtvListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    currentDate;
    baseProducts = [];
    productSearch = '';
    financialInfos = [];
    showLoading = false;
    showBaseProducts = false;
    productsPriceMap;
    salesInfos;
    fieldKey = true;
    company;
    salesOrgId = '';
    noProductsFound = false;

    searchData = {
        safra: {},
        account: {},
        ctv: {},
        paymentDate: '',
        sales_condition: {},
        tipo_venda: ''
    };
    columns = [
        {label: 'Código', fieldName: 'sapProductCode'},
        {label: 'Produto', fieldName: 'name'},
        {label: 'Grupo', fieldName: 'productGroupName'},
        {label: 'Safra', fieldName: 'safra'},
        {label: 'Tabela de Preços', fieldName: 'salesCondition'},
        {label: 'Valor Data Informada', fieldName: 'valueDiscounted'},
        {label: 'Valor Data Safra', fieldName: 'realValue'},
        {label: 'Time de Vendas', fieldName: 'salesTeamName'},
        {label: 'Escritório de Vendas', fieldName: 'salesOfficeName'}
    ];

    connectedCallback() {
        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let yyyy = today.getFullYear();

        this.currentDate = yyyy + '-' + mm + '-' + dd;
    }

    isFilled(field) {
        return ((field !== undefined && field != null && field != '') || field == 0);
    }

    selectItemRegister(event){
        try { 
            if (this.isFilled(event)) {
                let field = event.target.name;
                if (field == 'paymentDate') {
                    this.searchData[field] = event.target.value;
                } else {
                    const { record } = event.detail;
                    let currentValue = this.searchData[field];
                    this.searchData[field] = {Id: record.Id, Name: record.Name};
                    if (field == 'safra') {
                        if (JSON.stringify(this.searchData.ctv) === '{}') {
                            this.fieldKey = true;
                        } else {
                            this.fieldKey = false;
                        }
                    } else if (field == 'ctv') {

                        if (JSON.stringify(this.searchData.safra) === '{}') {
                            this.fieldKey = true;
                        } else {
                            this.fieldKey = false;
                        }

                        let getCompanyData = {
                            ctvId: this.isFilled(this.searchData.ctv.Id) ? this.searchData.ctv.Id : '',
                            accountId: this.isFilled(this.searchData.account.Id) ? this.searchData.account.Id : '',
                            orderType: 'VendaNormal',
                            approvalNumber: 1
                        }
                        
                        if (currentValue.Id != this.searchData[field].Id) {
                            this.showLoading = true;
                            getAccountCompanies({data: JSON.stringify(getCompanyData), isHeader: false, verifyUserType: false, priceScreen: true, childOrder: false})
                            .then((result) => {
                                this.showLoading = false;
                                this.company = JSON.parse(result).listCompanyInfos;
                                this.salesOrgId = this.company[0].salesOrgId;
                            });
                        }
                        
                    }
                }
                this.searchData = JSON.parse(JSON.stringify(this.searchData));
            }
        } catch (err) {
            console.log(err);
        }
    }

    removeItemRegister(event) {
        try {
            let field = event.target.name;
            this.searchData[field] = {};
            if (field == 'safra' || field == 'ctv') {
                this.fieldKey = true;
                this.template.querySelector('[data-name="sales_condition"]').clearAll();
                this.searchData = JSON.parse(JSON.stringify(this.searchData));
            }
        } catch (err) {
            console.log(err);
        }
    }

    changeSearchValue(event) {
        this.productSearch = event.target.value;
    }

    searchProducts() {
        if (this.searchData.ctv.Id === undefined || this.searchData.safra.Id === undefined || this.searchData.paymentDate == '' || this.searchData.sales_condition.Id === undefined) {
            this.showToast('warning', 'Atenção', 'Campos obrigatórios não preenchidos.');
            return;
        }
        this.showLoading = true;

        let productParams = {
            safra: this.searchData.safra.Id,
            orderType: 'VendaNormal',
            supplierCenter: this.company[0].supplierCenter,
            salesOrgId: this.company[0].salesOrgId != null ? this.company[0].salesOrgId : '',
            salesOfficeId: this.company[0].salesOfficeId != null ? this.company[0].salesOfficeId : '',
            salesTeamId: this.company[0].salesTeamId != null ? this.company[0].salesTeamId : '',
            accountId: this.isFilled(this.searchData.account.Id) ? this.searchData.account.Id : '',
            activitySectorName: '',
            ctvId: this.isFilled(this.searchData.ctv.Id) ? this.searchData.ctv.Id : '',
            numberOfRowsToSkip: 0,
            salesConditionId : this.searchData.sales_condition.Id != null ? this.searchData.sales_condition.Id : '',
            dontGetSeeds: false,
            paymentDate: this.headerData.data_pagamento
        };

        let orderData = {
            paymentDate: this.searchData.paymentDate != null ? this.searchData.paymentDate : '',
            salesOrg: this.company[0].salesOrgId != null ? this.company[0].salesOrgId : '',
            salesOffice: this.company[0].salesOfficeId != null ? this.company[0].salesOfficeId : '',
            salesTeam: this.company[0].salesTeamId != null ? this.company[0].salesTeamId : '',
            accountId: this.isFilled(this.searchData.account.Id) ? this.searchData.account.Id : '',
            safra: this.searchData.safra.Id != null ? this.searchData.safra.Id : '',
            salesCondition : this.searchData.sales_condition.Id != null ? this.searchData.sales_condition.Id : ''
        };

        getFinancialInfos({data: JSON.stringify(orderData)})
        .then((result) => {
            this.financialInfos = JSON.parse(result);

            getProductRecords({
                searchString: this.productSearch,
                data: JSON.stringify(productParams),
                isCommodity: false,
                productsIds: [],
                priceScreen: true,
                getSeedPrices: false,
                isLimit: false
            })
            .then(result => {
                this.showBaseProducts = result.recordsDataList.length > 0;
                this.noProductsFound  = result.recordsDataList.length == 0;
                this.productsPriceMap = result.recordsDataMap;
                this.salesInfos = result.salesResult;
                let productRecords = [];
                
                for (let index = 0; index < result.recordsDataList.length; index++) {
                    let priorityInfos = this.getProductByPriority(result.recordsDataList[index]);

                    for (let i = 0; i < priorityInfos.length; i++) {
                        let realValue = this.fixDecimalPlacesFront(priorityInfos[i].listPrice);
                        let discountedValue = this.calculateDiscountValues(priorityInfos[i]);
                        productRecords.push({
                            sapProductCode: priorityInfos[i].sapProductCode,
                            name: priorityInfos[i].Name,
                            productGroupName: priorityInfos[i].productGroupName,
                            safra: this.searchData.safra.Name,
                            salesCondition: priorityInfos[i].salesCondition,
                            valueDiscounted: discountedValue,
                            realValue: realValue.split(',').length == 1 ? realValue + ',00' : realValue,
                            salesTeamName: priorityInfos[i].salesTeamName,
                            salesOfficeName: priorityInfos[i].salesOfficeName
                        })
                    }
                    
                }

                this.baseProducts = JSON.parse(JSON.stringify(productRecords));
                this.showLoading = false;
            });
        })
    }

    getProductByPriority(selectedProduct) {
        let priorityPrice = [];
        let productsPrice = this.productsPriceMap;
        let productId = this.isFilled(selectedProduct.Id) ? selectedProduct.Id : selectedProduct.productId;

        let key1 = 'G-' + this.searchData.account.Id + '-' + productId;
        let key2 = 'G-' + this.salesInfos.segmento + '-' + productId;
        let key3 = 'G-' + this.salesInfos.salesTeamId + '-' + productId;
        let key4 = 'G-' + this.salesInfos.salesOfficeId + '-' + productId;
        let key5 = 'G-' + selectedProduct.productGroupId;
        let key6 = 'G-' + productId;

        if (this.isFilled(productsPrice[key1])) {
            priorityPrice.push(productsPrice[key1]);
        }
        if (this.isFilled(productsPrice[key2])) {
            priorityPrice.push(productsPrice[key2]);
        }
        if (this.isFilled(productsPrice[key3])) {
            priorityPrice.push(productsPrice[key3]);
        }
        if (this.isFilled(productsPrice[key4])) {
            priorityPrice.push(productsPrice[key4]);
        }
        if (this.isFilled(productsPrice[key5])) {
            priorityPrice.push(productsPrice[key5]);
        }
        if (this.isFilled(productsPrice[key6])) {
            priorityPrice.push(productsPrice[key6]);
        }

        return priorityPrice;
    }

    calculateDiscountValues(productInfos) {
        let defaultKey = this.financialInfos.salesOrg + '-' + this.searchData.safra.Id;
        let key1 = defaultKey + '-' + this.financialInfos.salesOffice + '-' + productInfos.productId;
        let key2 = defaultKey + '-' + this.financialInfos.salesOffice;
        let key3 = defaultKey + '-' + productInfos.productGroupId;
        
        let currentDiscountOrAddition = 0;
        let financialValues = this.financialInfos.financialValues;
        if (this.isFilled(financialValues[key1])) {
            currentDiscountOrAddition = financialValues[key1];
        } else if (this.isFilled(financialValues[key2])) {
            currentDiscountOrAddition = financialValues[key2];
        } else if (this.isFilled(financialValues[key3])) {
            currentDiscountOrAddition = financialValues[key3];
        } else if (this.isFilled(financialValues[defaultKey])) {
            currentDiscountOrAddition = financialValues[defaultKey];
        }
        currentDiscountOrAddition = (currentDiscountOrAddition / 30) * (this.financialInfos.dayDifference < 0 ? (this.financialInfos.dayDifference * -1) : this.financialInfos.dayDifference);

        let discountedValue = productInfos.listPrice;
        if (!this.financialInfos.correctPayment) {
            let totalValue = this.calculateValue(currentDiscountOrAddition, discountedValue);
            discountedValue = this.financialInfos.isDiscount ? discountedValue - totalValue : discountedValue + totalValue;
        }
        return this.fixDecimalPlacesFront(discountedValue);
    }

    calculateValue(percentage, total) {
        percentage = percentage != '' ? percentage : 0;
        let value = (parseFloat(percentage) / 100) * total;
        return value;
    }

    fixDecimalPlacesFront(value) {
        let formatNumber = new Intl.NumberFormat('de-DE').format(Number(Math.round(value + 'e' + 2) + 'e-' + 2));
        return formatNumber;
    }

    showToast(type, title, message) {
        let event = new ShowToastEvent({
            variant: type,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }
}