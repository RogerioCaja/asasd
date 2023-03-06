import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProductRecords from '@salesforce/apex/CustomLookupController.fetchProductsRecords';
import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';
import getFinancialInfos from '@salesforce/apex/OrderScreenController.getFinancialInfos';

import SAFRA_OBJECT from '@salesforce/schema/Safra__c';
import SAFRA_NAME from '@salesforce/schema/Safra__c.Name';

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
    searchData = {
        safra: {},
        account: {},
        ctv: {},
        paymentDate: ''
    };
    columns = [
        {label: 'Código', fieldName: 'sapProductCode'},
        {label: 'Produto', fieldName: 'name'},
        {label: 'Grupo', fieldName: 'productGroupName'},
        {label: 'Safra', fieldName: 'safra'},
        {label: 'Tabela de Preços', fieldName: 'salesCondition'},
        {label: 'Valor Data Informada', fieldName: 'valueDiscounted'},
        {label: 'Valor Data Safra', fieldName: 'realValue'}
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
                    this.searchData[field] = {Id: record.Id, Name: record.Name};
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
        } catch (err) {
            console.log(err);
        }
    }

    changeSearchValue(event) {
        this.productSearch = event.target.value;
    }

    searchProducts() {
        if (this.searchData.ctv.Id === undefined || this.searchData.safra.Id === undefined || this.searchData.paymentDate == '') {
            this.showToast('warning', 'Atenção', 'Campos obrigatórios não preenchidos.');
            return;
        }

        let getCompanyData = {
            ctvId: this.isFilled(this.searchData.ctv.Id) ? this.searchData.ctv.Id : '',
            accountId: this.isFilled(this.searchData.account.Id) ? this.searchData.account.Id : '',
            orderType: 'VendaNormal',
            approvalNumber: 1
        }

        this.showLoading = true;
        getAccountCompanies({data: JSON.stringify(getCompanyData), isHeader: false, verifyUserType: false, priceScreen: true})
        .then((result) => {
            let companyResult = JSON.parse(result).listCompanyInfos;
            let productParams = {
                safra: this.searchData.safra.Id,
                orderType: 'VendaNormal',
                supplierCenter: companyResult[0].supplierCenter,
                salesOrgId: companyResult[0].salesOrgId != null ? companyResult[0].salesOrgId : '',
                salesOfficeId: companyResult[0].salesOfficeId != null ? companyResult[0].salesOfficeId : '',
                salesTeamId: companyResult[0].salesTeamId != null ? companyResult[0].salesTeamId : '',
                accountId: this.isFilled(this.searchData.account.Id) ? this.searchData.account.Id : '',
                ctvId: this.isFilled(this.searchData.ctv.Id) ? this.searchData.ctv.Id : '',
                numberOfRowsToSkip: 0
            };

            let orderData = {
                paymentDate: this.searchData.paymentDate != null ? this.searchData.paymentDate : '',
                salesOrg: companyResult[0].salesOrgId != null ? companyResult[0].salesOrgId : '',
                salesOffice: companyResult[0].salesOfficeId != null ? companyResult[0].salesOfficeId : '',
                salesTeam: companyResult[0].salesTeamId != null ? companyResult[0].salesTeamId : '',
                clientGroup: companyResult[0].clientGroup != null ? companyResult[0].clientGroup : '',
                accountId: this.isFilled(this.searchData.account.Id) ? this.searchData.account.Id : '',
                safra: this.searchData.safra.Id != null ? this.searchData.safra.Id : ''
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
                    isLimit: false
                })
                .then(result => {
                    this.showBaseProducts = result.recordsDataList.length > 0;
                    this.productsPriceMap = result.recordsDataMap;
                    this.salesInfos = result.salesResult;
                    let productRecords = [];
                    
                    for (let index = 0; index < result.recordsDataList.length; index++) {
                        let priorityInfos = this.getProductByPriority(result.recordsDataList[index]);
                        let realValue = this.fixDecimalPlacesFront(priorityInfos.listPrice);
                        let discountedValue = this.calculateDiscountValues(priorityInfos);
                        
                        productRecords.push({
                            sapProductCode: priorityInfos.sapProductCode,
                            name: priorityInfos.Name,
                            productGroupName: priorityInfos.productGroupName,
                            safra: this.searchData.safra.Name,
                            salesCondition: priorityInfos.salesCondition,
                            valueDiscounted: discountedValue,
                            realValue: realValue.split(',').length == 1 ? realValue + ',00' : realValue,
                        })
                    }

                    this.baseProducts = JSON.parse(JSON.stringify(productRecords));
                    this.showLoading = false;
                });
            })
        });
    }

    getProductByPriority(selectedProduct) {
        let priorityPrice;
        let productsPrice = this.productsPriceMap;
        let productId = this.isFilled(selectedProduct.Id) ? selectedProduct.Id : selectedProduct.productId;

        let key1 = this.searchData.account.Id + '-' + productId;
        let key2 = this.salesInfos.segmento + '-' + productId;
        let key3 = this.salesInfos.salesTeamId + '-' + productId;
        let key4 = this.salesInfos.salesOfficeId + '-' + productId;
        let key5 = selectedProduct.productGroupId;
        let key6 = productId;

        if (this.isFilled(productsPrice[key1])) {
            priorityPrice = productsPrice[key1];
        } else if (this.isFilled(productsPrice[key2])) {
            priorityPrice = productsPrice[key2];
        } else if (this.isFilled(productsPrice[key3])) {
            priorityPrice = productsPrice[key3];
        } else if (this.isFilled(productsPrice[key4])) {
            priorityPrice = productsPrice[key4];
        } else if (this.isFilled(productsPrice[key5])) {
            priorityPrice = productsPrice[key5];
        } else if (this.isFilled(productsPrice[key6])) {
            priorityPrice = productsPrice[key6];
        }

        return priorityPrice;
    }

    calculateDiscountValues(productInfos) {
        let defaultKey = this.financialInfos.salesOrg + '-' + this.searchData.safra.Id;
        let key1 = defaultKey + '-' + this.financialInfos.clientGroup + '-' + productInfos.productId;
        let key2 = defaultKey + '-' + this.financialInfos.salesTeam + '-' + productInfos.productId;
        let key3 = defaultKey + '-' + this.financialInfos.salesTeam + '-' + productInfos.productGroupId;
        let key4 = defaultKey + '-' + productInfos.productGroupId;
        
        let currentDiscountOrAddition = 0;
        let financialValues = this.financialInfos.financialValues;
        if (this.isFilled(financialValues[key1])) {
            currentDiscountOrAddition = financialValues[key1];
        } else if (this.isFilled(financialValues[key2])) {
            currentDiscountOrAddition = financialValues[key2];
        } else if (this.isFilled(financialValues[key3])) {
            currentDiscountOrAddition = financialValues[key3];
        } else if (this.isFilled(financialValues[key4])) {
            currentDiscountOrAddition = financialValues[key4];
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