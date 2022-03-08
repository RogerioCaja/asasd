import {
    LightningElement,
    api,
    track
} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const actions = [{
        label: 'Adicionar remessa',
        name: 'adicionar_remessa'
    },
    {
        label: 'Remover',
        name: 'delete'
    }
];
export default class OrderProductScreen extends LightningElement {
    name='';unity='';productGroup='';sapStatus='';activePrinciple='';commercialDiscountPercentage='';
    commercialAdditionPercentage='';financialAdditionPercentage='';financialDecreasePercentage='';
    commercialDiscountValue;commercialAdditionValue;financialAdditionValue;financialDecreaseValue;
    listPrice;unitPrice;totalPrice;dosage;quantity;invoicedQuantity;listTotalPrice;

    columnUnity=true;columnListPrice=true;columnDosage=false;columnQuantity=true;columnUnitPrice=true;
    columnTotalPrice=true;columnCommercialDiscountPercentage=false;columnCommercialDiscountValue=false;
    columnCommercialAdditionPercentage=true;columnCommercialAdditionValue=true;
    columnFinancialAdditionPercentage=true;columnFinancialAdditionValue=true;
    columnFinancialDecreasePercentage=false;columnFinancialDecreaseValue=false;columnInvoicedQuantity=false;
    columnActivePrinciple=false;columnGroup=false;columnSapStatus=true;

    paymentDate;hectares;priceBookListId;

    baseProducts = [];
    showBaseProducts = false;
    showIncludedProducts = false;
    message = false;
    createNewProduct = false;
    showList = false;
    changeColumns = false;
    selectedProducts;
    columns = [];
    
    @track products = [];
    @api productData;
    @api headerData;
    
    connectedCallback(event) {
        this.paymentDate = this.headerData.data_pagamento;
        this.hectares = this.headerData.hectares;
        this.priceBookListId = this.headerData.lista_precos;

        this.products = this.isFilled(this.productData) ? this.productData : [];
        this.showIncludedProducts = this.isFilled(this.products);
        this.applySelectedColumns(event);
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'adicionar_remessa':
                this.template.querySelector('c-modal-remessa').openModal(row);
                break;
            case 'delete':
                const rows = this.products;
                const rowIndex = rows.indexOf(row);
                rows.splice(rowIndex, 1);
                this.products = rows;
                break;
        }
    }

    getFieldsValueProduct() {

    }

    getSelectedName(event){
        this.selectedProducts =  event.detail.selectedRows;
        console.log(JSON.parse(JSON.stringify(this.selectedProducts)));
    }

    showProductModal(event) {
        let currentProduct = this.baseProducts.find(e => e.Id == event.target.dataset.targetId);
        this.createNewProduct = !this.createNewProduct;

        this.name = currentProduct.Name;
        this.unity = 'Quilos';
        this.productGroup = currentProduct.family;
        this.listPrice = currentProduct.listPrice;
        this.invoicedQuantity = 50;
        this.sapStatus = 'Concluído';
    }

    changeTableColumns(event) {
        if (event.target.dataset.targetId == 'columnUnity') this.columnUnity = !this.columnUnity;
        if (event.target.dataset.targetId == 'columnListPrice') this.columnListPrice = !this.columnListPrice;
        if (event.target.dataset.targetId == 'columnDosage') this.columnDosage = !this.columnDosage;
        if (event.target.dataset.targetId == 'columnQuantity') this.columnQuantity = !this.columnQuantity;
        if (event.target.dataset.targetId == 'columnUnitPrice') this.columnUnitPrice = !this.columnUnitPrice;
        if (event.target.dataset.targetId == 'columnTotalPrice') this.columnTotalPrice = !this.columnTotalPrice;
        if (event.target.dataset.targetId == 'columnCommercialDiscountPercentage') this.columnCommercialDiscountPercentage = !this.columnCommercialDiscountPercentage;
        if (event.target.dataset.targetId == 'columnCommercialDiscountValue') this.columnCommercialDiscountValue = !this.columnCommercialDiscountValue;
        if (event.target.dataset.targetId == 'columnCommercialAdditionPercentage') this.columnCommercialAdditionPercentage = !this.columnCommercialAdditionPercentage;
        if (event.target.dataset.targetId == 'columnCommercialAdditionValue') this.columnCommercialAdditionValue = !this.columnCommercialAdditionValue;
        if (event.target.dataset.targetId == 'columnFinancialAdditionPercentage') this.columnFinancialAdditionPercentage = !this.columnFinancialAdditionPercentage;
        if (event.target.dataset.targetId == 'columnFinancialAdditionValue') this.columnFinancialAdditionValue = !this.columnFinancialAdditionValue;
        if (event.target.dataset.targetId == 'columnFinancialDecreasePercentage') this.columnFinancialDecreasePercentage = !this.columnFinancialDecreasePercentage;
        if (event.target.dataset.targetId == 'columnFinancialDecreaseValue') this.columnFinancialDecreaseValue = !this.columnFinancialDecreaseValue;
        if (event.target.dataset.targetId == 'columnInvoicedQuantity') this.columnInvoicedQuantity = !this.columnInvoicedQuantity;
        if (event.target.dataset.targetId == 'columnActivePrinciple') this.columnActivePrinciple = !this.columnActivePrinciple;
        if (event.target.dataset.targetId == 'columnGroup') this.columnGroup = !this.columnGroup;
        if (event.target.dataset.targetId == 'columnSapStatus') this.columnSapStatus = !this.columnSapStatus;
    }

    applySelectedColumns(event) {
        let selectedColumns = [{label: 'Nome', fieldName: 'name'}];
        if (this.columnUnity) selectedColumns.push({label: 'Unidade de Medida', fieldName: 'unity'})
        if (this.columnListPrice) selectedColumns.push({label: 'Preço da Lista', fieldName: 'listPrice'})
        if (this.columnDosage) selectedColumns.push({label: 'Dosagem', fieldName: 'dosage'})
        if (this.columnQuantity) selectedColumns.push({label: 'Quantidade', fieldName: 'quantity'})
        if (this.columnUnitPrice) selectedColumns.push({label: 'Preço Unitário', fieldName: 'unitPrice'})
        if (this.columnTotalPrice) selectedColumns.push({label: 'Preço Total', fieldName: 'totalPrice'})
        if (this.columnCommercialDiscountPercentage) selectedColumns.push({label: 'Percentual de Desconto Comercial', fieldName: 'commercialDiscountPercentage'})
        if (this.columnCommercialDiscountValue) selectedColumns.push({label: 'Valor de Desconto Comercial', fieldName: 'commercialDiscountValue'})
        if (this.columnCommercialAdditionPercentage) selectedColumns.push({label: 'Percentual de Acréscimo Comercial', fieldName: 'commercialAdditionPercentage'})
        if (this.columnCommercialAdditionValue) selectedColumns.push({label: 'Valor de Acréscimo Comercial', fieldName: 'commercialAdditionValue'})
        if (this.columnFinancialAdditionPercentage) selectedColumns.push({label: 'Percentual de Acréscimo Financeiro', fieldName: 'financialAdditionPercentage'})
        if (this.columnFinancialAdditionValue) selectedColumns.push({label: 'Valor de Acréscimo Financeiro', fieldName: 'financialAdditionValue'})
        if (this.columnFinancialDecreasePercentage) selectedColumns.push({label: 'Percentual de Decréscimo Financeiro', fieldName: 'financialDecreasePercentage'})
        if (this.columnFinancialDecreaseValue) selectedColumns.push({label: 'Valor de Decréscimo Financeiro', fieldName: 'financialDecreaseValue'})
        if (this.columnInvoicedQuantity) selectedColumns.push({label: 'Quantidade Faturada', fieldName: 'invoicedQuantity'})
        if (this.columnActivePrinciple) selectedColumns.push({label: 'Princípio Ativo', fieldName: 'activePrinciple'})
        if (this.columnGroup) selectedColumns.push({label: 'Grupo do Produto', fieldName: 'productGroup'})
        if (this.columnSapStatus) selectedColumns.push({label: 'Status SAP', fieldName: 'sapStatus'})

        if (selectedColumns.length >= 2) {
            this.columns = selectedColumns;
            this.changeColumns = false;
        } else {
            this.showToast('warning', 'Atenção!', 'É preciso selecionar ao menos uma coluna.');
        }
    }

    showTableColumns(event) {
        this.changeColumns = !this.changeColumns;
    }

    changeToPercentage(event) {
        event.target.value = event.target.value.replace('.', ',');
        let int = event.target.value.slice(0, event.target.value.length - 1);
        if (int.includes('%')) {
            event.target.value = '%';
        } else if (int.length >= 3 && int.length <= 7 && !int.includes(',')) {
            event.target.value = int.slice(0, 2) + ',' + int.slice(2, 7) + '%';
            event.target.setSelectionRange(4, 4);
        } else if (int.length >= 5 & int.length <= 8) {
            let whole = int.slice(0, 2);
            let fraction = int.slice(3, 7);
            event.target.value = whole + ',' + fraction + '%';
        } else {
            event.target.value = int + '%';
            event.target.setSelectionRange(event.target.value.length - 1, event.target.value.length - 1);
        }
    }

    changeValue(event) {
        if (this.isFilled(event.target.value)) {
            if (event.target.dataset.targetId == 'unitPrice') {
                this.unitPrice = event.target.value;
                this.calculateDiscountOrAddition();
                this.calculateTotalPrice();
            } else if (event.target.dataset.targetId == 'commercialDiscountPercentage') {
                this.commercialDiscountPercentage = event.target.value;
                this.commercialDiscountValue = this.isFilled(this.listTotalPrice) ?
                                               this.calculateValue(this.commercialDiscountPercentage, this.listTotalPrice) :
                                               this.commercialDiscountValue;
                this.calculateTotalPrice();
            } else if (event.target.dataset.targetId == 'commercialDiscountValue') {
                this.commercialDiscountValue = event.target.value;
                this.commercialDiscountPercentage = this.isFilled(this.listTotalPrice) ?
                                                    this.calculatePercentage(this.commercialDiscountValue, this.listTotalPrice) :
                                                    this.commercialDiscountPercentage;
                this.calculateTotalPrice();
            } else if (event.target.dataset.targetId == 'commercialAdditionPercentage') {
                this.commercialAdditionPercentage = event.target.value;
                this.commercialAdditionValue = this.isFilled(this.listTotalPrice) ?
                                               this.calculateValue(this.commercialAdditionPercentage, this.listTotalPrice) :
                                               this.commercialAdditionValue;
                this.calculateTotalPrice();
            } else if (event.target.dataset.targetId == 'commercialAdditionValue') {
                this.commercialAdditionValue = event.target.value;
                this.commercialAdditionPercentage = this.isFilled(this.listTotalPrice) ?
                                                    this.calculatePercentage(this.commercialAdditionValue, this.listTotalPrice) :
                                                    this.commercialAdditionPercentage;
                this.calculateTotalPrice();
            } else if (event.target.dataset.targetId == 'financialAdditionPercentage') {
                this.financialAdditionPercentage = event.target.value;
                this.financialAdditionValue = this.isFilled(this.listTotalPrice) ?
                                              this.calculateValue(this.financialAdditionPercentage, this.listTotalPrice) :
                                              this.financialAdditionValue;
                this.calculateTotalPrice();
            } else if (event.target.dataset.targetId == 'financialAdditionValue') {
                this.financialAdditionValue = event.target.value;
                this.financialAdditionPercentage = this.isFilled(this.listTotalPrice) ?
                                                   this.calculatePercentage(this.financialAdditionValue, this.listTotalPrice) :
                                                   this.financialAdditionPercentage;
                this.calculateTotalPrice();
            } else if (event.target.dataset.targetId == 'financialDecreasePercentage') {
                this.financialDecreasePercentage = event.target.value;
                this.financialDecreaseValue = this.isFilled(this.listTotalPrice) ?
                                              this.calculateValue(this.financialDecreasePercentage, this.listTotalPrice) :
                                              this.financialDecreaseValue;
                this.calculateTotalPrice();
            } else if (event.target.dataset.targetId == 'financialDecreaseValue') {
                this.financialDecreaseValue = event.target.value;
                this.financialDecreasePercentage = this.isFilled(this.listTotalPrice) ?
                                                   this.calculatePercentage(this.financialDecreaseValue, this.listTotalPrice) :
                                                   this.financialDecreasePercentage;
                this.calculateTotalPrice();
            } else if (event.target.dataset.targetId == 'dosage') {
                this.dosage = event.target.value;
                this.quantity = this.dosage * this.hectares;
                this.listTotalPrice = this.listPrice * this.quantity;
            } else if (event.target.dataset.targetId == 'quantity') {
                this.quantity = event.target.value;
                this.listTotalPrice = this.listPrice * this.quantity;
                this.calculateTotalPrice();
                this.calculateDiscountOrAddition();
            }
            if (event.target.dataset.targetId == 'activePrinciple') this.activePrinciple = event.target.value;
            if (event.target.dataset.targetId == 'productGroup') this.productGroup = event.target.value;
        }
    }

    calculateTotalPrice() {
        this.totalPrice = null;

        if (this.isFilled(this.quantity) && this.isFilled(this.listPrice)) {
            this.totalPrice = this.quantity * this.listPrice;
            this.totalPrice = this.isFilled(this.commercialAdditionValue) ? (this.totalPrice + Number(this.commercialAdditionValue)) : this.totalPrice;
            this.totalPrice = this.isFilled(this.commercialDiscountValue) ? (this.totalPrice - Number(this.commercialDiscountValue)) : this.totalPrice;
            this.totalPrice = this.isFilled(this.financialAdditionValue) ? (this.totalPrice + Number(this.financialAdditionValue)) : this.totalPrice;
            this.totalPrice = this.isFilled(this.financialDecreaseValue) ? (this.totalPrice - Number(this.financialDecreaseValue)) : this.totalPrice;
        }
    }

    calculateDiscountOrAddition() {
        if (this.isFilled(this.listPrice) && this.isFilled(this.quantity) && this.isFilled(this.unitPrice)) {
            this.commercialAdditionValue = '0';
            this.commercialDiscountValue = '0';
            this.commercialAdditionPercentage = '0%';
            this.commercialDiscountPercentage = '0%';
            let currentPrice = this.unitPrice * this.quantity;
            
            if (this.isFilled(currentPrice) && this.unitPrice > this.listPrice) {
                this.commercialAdditionValue = (currentPrice - this.listTotalPrice).toFixed(4);
                this.commercialAdditionPercentage = this.calculatePercentage(this.commercialAdditionValue, this.listTotalPrice);
            } else if (this.isFilled(currentPrice) && this.unitPrice < this.listPrice) {
                this.commercialDiscountValue = (this.listTotalPrice - currentPrice).toFixed(4);
                this.commercialDiscountPercentage = this.calculatePercentage(this.commercialDiscountValue, this.listTotalPrice);
            }
        }
    }

    calculatePercentage(valueToBeCalculated, total) {
        let percentageValue = ((valueToBeCalculated * 100) / total).toFixed(4) + '%';
        percentageValue = percentageValue.includes('.') ? percentageValue.replace('.', ',') : percentageValue;
        return percentageValue;
    }

    calculateValue(percentage, total) {
        percentage = percentage.includes(',') ? percentage.replace(',', '.').replace('%', '') : percentage.replace('%', '');
        let value = ((parseFloat(percentage) / 100) * total).toFixed(4);
        return value;
    }

    isFilled(field) {
        return (field !== undefined && field != null && field != '');
    }
        
    includeProduct() {
        console.log('includeProduct');
        if (this.isFilled(this.name) && this.isFilled(this.unity) && this.isFilled(this.listPrice) && this.isFilled(this.unitPrice) &&
            this.isFilled(this.totalPrice) && this.isFilled(this.commercialDiscountPercentage) && this.isFilled(this.commercialDiscountValue) &&
            this.isFilled(this.commercialAdditionPercentage) && this.isFilled(this.commercialAdditionValue) &&
            this.isFilled(this.financialAdditionPercentage) && this.isFilled(this.financialAdditionValue) &&
            this.isFilled(this.financialDecreasePercentage) && this.isFilled(this.financialDecreaseValue) &&
            this.isFilled(this.dosage) && this.isFilled(this.quantity) && this.isFilled(this.invoicedQuantity) &&
            this.isFilled(this.activePrinciple) && this.isFilled(this.productGroup) && this.isFilled(this.sapStatus)) {
            let allProducts = JSON.parse(JSON.stringify(this.products));
            allProducts.push({
                name: this.name,
                unity: this.unity,
                listPrice: this.listPrice,
                unitPrice: this.unitPrice,
                totalPrice: this.totalPrice,
                commercialDiscountPercentage: this.commercialDiscountPercentage,
                commercialDiscountValue: this.commercialDiscountValue,
                commercialAdditionPercentage: this.commercialAdditionPercentage,
                commercialAdditionValue: this.commercialAdditionValue,
                financialAdditionPercentage: this.financialAdditionPercentage,
                financialAdditionValue: this.financialAdditionValue,
                financialDecreasePercentage: this.financialDecreasePercentage,
                financialDecreaseValue: this.financialDecreaseValue,
                dosage: this.dosage,
                quantity: this.quantity,
                invoicedQuantity: this.invoicedQuantity,
                activePrinciple: this.activePrinciple,
                productGroup: this.productGroup,
                sapStatus: this.sapStatus
            });
            
            this.products = JSON.parse(JSON.stringify(allProducts));
            this.name = '';
            this.unity = '';
            this.productGroup = '';
            this.sapStatus = '';
            this.activePrinciple = '';
            this.commercialDiscountPercentage = '';
            this.commercialAdditionPercentage = '';
            this.financialAdditionPercentage = '';
            this.financialDecreasePercentage = '';
            this.commercialDiscountValue = null;
            this.commercialAdditionValue = null;
            this.financialAdditionValue = null;
            this.financialDecreaseValue = null;
            this.listPrice = null;
            this.unitPrice = null;
            this.totalPrice = null;
            this.dosage = null;
            this.quantity = null;
            this.invoicedQuantity = null;
            this.showIncludedProducts = true;
            this.createNewProduct = false;

            this.showToast('success', 'Sucesso!', 'Produto incluso.');
            this._verifyFieldsToSave();
            this.showProductModal();
        } else {
            this.showToast('error', 'Atenção!', 'Todos campos são obrigatórios.');
        }
    }

    @api
    _verifyFieldsToSave() {
        if (this.verifyMandatoryFields()) {
            this._setData();
            return true;
        }
        return false;
    }

    @api
    verifyMandatoryFields() {
        if (this.products !== undefined) {
            return true;
        }
        return false;
    }

    _setData() {
        const setHeaderData = new CustomEvent('setproductdata');
        setHeaderData.data = this.products;
        this.dispatchEvent(setHeaderData);
    }

    showResults(event){
        this.showBaseProducts = event.showResults;
        this.baseProducts = event.results;
        this.message = event.message;
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