import {
    LightningElement,
    api,
    track
} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const actions = [
    { label: 'Editar', name: 'edit' },
];
export default class OrderProductScreen extends LightningElement {
    @track addProduct={};
    costPrice;
    multiplicity=5;
    listTotalPrice;
    productPosition;

    selectedColumns={
        columnListPrice: true,
        columnQuantity: true,
        columnUnitPrice: true,
        columnTotalPrice: true,
        columnCommercialAdditionValue: true,
        columnFinancialAdditionValue: true,
        columnSapStatus: true
    }

    paymentDate;hectares;priceBookListId;

    baseProducts = [];
    showBaseProducts = false;
    showIncludedProducts = false;
    message = false;
    createNewProduct = false;
    updateProduct = false;
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

    showProductModal(event) {
        this.createNewProduct = !this.createNewProduct;

        if (this.createNewProduct) {
            let currentProduct = this.baseProducts.find(e => e.Id == event.target.dataset.targetId);
            this.costPrice = currentProduct.costPrice;
            this.addProduct = {
                entryId: currentProduct.entryId,
                productId: currentProduct.Id,
                name: currentProduct.Name,
                unity: currentProduct.unity,
                listPrice: currentProduct.listPrice,
                dosage: null,
                quantity: null,
                unitPrice: null,
                totalPrice: null,
                commercialDiscountPercentage: '',
                commercialDiscountValue: null,
                commercialAdditionPercentage: '',
                commercialAdditionValue: null,
                financialAdditionPercentage: '',
                financialAdditionValue: null,
                financialDecreasePercentage: '',
                financialDecreaseValue: null,
                invoicedQuantity: 50,
                activePrinciple: currentProduct.activePrinciple != null ? currentProduct.activePrinciple : '',
                productGroup: currentProduct.productGroup != null ? currentProduct.productGroup : '',
                sapStatus: 'Concluído'
            };
        }
    }

    changeTableColumns(event) {
        let field = event.target.dataset.targetId;
        this.selectedColumns[field] = this.isFilled(this.selectedColumns[field]) ? !this.selectedColumns[field] : true;
    }

    applySelectedColumns(event) {
        let selectedColumns = [{label: 'Nome', fieldName: 'name'}];
        if (this.isFilled(this.selectedColumns.columnUnity)) selectedColumns.push({label: 'Unidade de Medida', fieldName: 'unity'})
        if (this.isFilled(this.selectedColumns.columnListPrice)) selectedColumns.push({label: 'Preço da Lista', fieldName: 'listPrice'})
        if (this.isFilled(this.selectedColumns.columnDosage)) selectedColumns.push({label: 'Dosagem', fieldName: 'dosage'})
        if (this.isFilled(this.selectedColumns.columnQuantity)) selectedColumns.push({label: 'Quantidade', fieldName: 'quantity'})
        if (this.isFilled(this.selectedColumns.columnUnitPrice)) selectedColumns.push({label: 'Preço Unitário', fieldName: 'unitPrice'})
        if (this.isFilled(this.selectedColumns.columnTotalPrice)) selectedColumns.push({label: 'Preço Total', fieldName: 'totalPrice'})
        if (this.isFilled(this.selectedColumns.columnCommercialDiscountPercentage)) selectedColumns.push({label: 'Percentual de Desconto Comercial', fieldName: 'commercialDiscountPercentage'})
        if (this.isFilled(this.selectedColumns.columnCommercialDiscountValue)) selectedColumns.push({label: 'Valor de Desconto Comercial', fieldName: 'commercialDiscountValue'})
        if (this.isFilled(this.selectedColumns.columnCommercialAdditionPercentage)) selectedColumns.push({label: 'Percentual de Acréscimo Comercial', fieldName: 'commercialAdditionPercentage'})
        if (this.isFilled(this.selectedColumns.columnCommercialAdditionValue)) selectedColumns.push({label: 'Valor de Acréscimo Comercial', fieldName: 'commercialAdditionValue'})
        if (this.isFilled(this.selectedColumns.columnFinancialAdditionPercentage)) selectedColumns.push({label: 'Percentual de Acréscimo Financeiro', fieldName: 'financialAdditionPercentage'})
        if (this.isFilled(this.selectedColumns.columnFinancialAdditionValue)) selectedColumns.push({label: 'Valor de Acréscimo Financeiro', fieldName: 'financialAdditionValue'})
        if (this.isFilled(this.selectedColumns.columnFinancialDecreasePercentage)) selectedColumns.push({label: 'Percentual de Decréscimo Financeiro', fieldName: 'financialDecreasePercentage'})
        if (this.isFilled(this.selectedColumns.columnFinancialDecreaseValue)) selectedColumns.push({label: 'Valor de Decréscimo Financeiro', fieldName: 'financialDecreaseValue'})
        if (this.isFilled(this.selectedColumns.columnInvoicedQuantity)) selectedColumns.push({label: 'Quantidade Faturada', fieldName: 'invoicedQuantity'})
        if (this.isFilled(this.selectedColumns.columnActivePrinciple)) selectedColumns.push({label: 'Princípio Ativo', fieldName: 'activePrinciple'})
        if (this.isFilled(this.selectedColumns.columnGroup)) selectedColumns.push({label: 'Grupo do Produto', fieldName: 'productGroup'})
        if (this.isFilled(this.selectedColumns.columnSapStatus)) selectedColumns.push({label: 'Status SAP', fieldName: 'sapStatus'})

        if (selectedColumns.length >= 2) {
            selectedColumns.push({
                type: 'action',
                typeAttributes: {
                    rowActions: actions,
                    menuAlignment: 'right'
                }
            });
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
        let fieldId = event.target.dataset.targetId;
        let fieldValue = event.target.value;
        
        if (this.isFilled(fieldValue)) {
            this.addProduct[fieldId] = fieldValue;
            if (fieldId == 'unitPrice') {
                this.calculateDiscountOrAddition();
                this.calculateTotalPrice();
            } else if (fieldId == 'commercialDiscountPercentage') {
                this.addProduct.commercialDiscountValue = 
                    this.isFilled(this.listTotalPrice) ?
                    this.calculateValue(this.addProduct.commercialDiscountPercentage, this.listTotalPrice) :
                    this.addProduct.commercialDiscountValue;
                
                this.calculateTotalPrice();
            } else if (fieldId == 'commercialDiscountValue') {
                this.addProduct.commercialDiscountPercentage = 
                    this.isFilled(this.listTotalPrice) ?
                    this.calculatePercentage(this.addProduct.commercialDiscountValue, this.listTotalPrice) :
                    this.addProduct.commercialDiscountPercentage;
                
                this.calculateTotalPrice();
            } else if (fieldId == 'commercialAdditionPercentage') {
                this.addProduct.commercialAdditionValue = 
                    this.isFilled(this.listTotalPrice) ?
                    this.calculateValue(this.addProduct.commercialAdditionPercentage, this.listTotalPrice) :
                    this.addProduct.commercialAdditionValue;
                
                this.calculateTotalPrice();
            } else if (fieldId == 'commercialAdditionValue') {
                this.addProduct.commercialAdditionPercentage = 
                    this.isFilled(this.listTotalPrice) ?
                    this.calculatePercentage(this.addProduct.commercialAdditionValue, this.listTotalPrice) :
                    this.addProduct.commercialAdditionPercentage;
                
                this.calculateTotalPrice();
            } else if (fieldId == 'financialAdditionPercentage') {
                this.addProduct.financialAdditionValue = 
                    this.isFilled(this.listTotalPrice) ?
                    this.calculateValue(this.addProduct.financialAdditionPercentage, this.listTotalPrice) :
                    this.addProduct.financialAdditionValue;
                
                this.calculateTotalPrice();
            } else if (fieldId == 'financialAdditionValue') {
                this.addProduct.financialAdditionPercentage = 
                    this.isFilled(this.listTotalPrice) ?
                    this.calculatePercentage(this.addProduct.financialAdditionValue, this.listTotalPrice) :
                    this.addProduct.financialAdditionPercentage;
                
                this.calculateTotalPrice();
            } else if (fieldId == 'financialDecreasePercentage') {
                this.addProduct.financialDecreaseValue = 
                    this.isFilled(this.listTotalPrice) ?
                    this.calculateValue(this.addProduct.financialDecreasePercentage, this.listTotalPrice) :
                    this.addProduct.financialDecreaseValue;
                
                this.calculateTotalPrice();
            } else if (fieldId == 'financialDecreaseValue') {
                this.addProduct.financialDecreasePercentage = 
                    this.isFilled(this.listTotalPrice) ?
                    this.calculatePercentage(this.addProduct.financialDecreaseValue, this.listTotalPrice) :
                    this.addProduct.financialDecreasePercentage;
                
                this.calculateTotalPrice();
            } else if (fieldId == 'dosage') {
                this.addProduct.quantity = this.addProduct.dosage * this.hectares;
                this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                this.calculateTotalPrice();
            } else if (fieldId == 'quantity') {
                this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                this.calculateTotalPrice();
                this.calculateDiscountOrAddition();
            }
        }
    }

    calculateTotalPrice() {
        this.addProduct.totalPrice = null;

        if (this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.listPrice)) {
            this.addProduct.totalPrice = this.addProduct.quantity * this.addProduct.listPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.commercialAdditionValue) ? (this.addProduct.totalPrice + Number(this.addProduct.commercialAdditionValue)) : this.addProduct.totalPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.commercialDiscountValue) ? (this.addProduct.totalPrice - Number(this.addProduct.commercialDiscountValue)) : this.addProduct.totalPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.financialAdditionValue) ? (this.addProduct.totalPrice + Number(this.addProduct.financialAdditionValue)) : this.addProduct.totalPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.financialDecreaseValue) ? (this.addProduct.totalPrice - Number(this.addProduct.financialDecreaseValue)) : this.addProduct.totalPrice;
        }
    }

    calculateDiscountOrAddition() {
        if (this.isFilled(this.addProduct.listPrice) && this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.unitPrice)) {
            this.addProduct.commercialAdditionValue = '0';
            this.addProduct.commercialDiscountValue = '0';
            this.addProduct.commercialAdditionPercentage = '0%';
            this.addProduct.commercialDiscountPercentage = '0%';
            let currentPrice = this.addProduct.unitPrice * this.addProduct.quantity;
            
            if (this.isFilled(currentPrice) && this.addProduct.unitPrice > this.addProduct.listPrice) {
                this.addProduct.commercialAdditionValue = (currentPrice - this.listTotalPrice).toFixed(4);
                this.addProduct.commercialAdditionPercentage = this.calculatePercentage(this.addProduct.commercialAdditionValue, this.listTotalPrice);
            } else if (this.isFilled(currentPrice) && this.addProduct.unitPrice < this.addProduct.listPrice) {
                this.addProduct.commercialDiscountValue = (this.listTotalPrice - currentPrice).toFixed(4);
                this.addProduct.commercialDiscountPercentage = this.calculatePercentage(this.addProduct.commercialDiscountValue, this.listTotalPrice);
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
        let prod = this.addProduct;
        if (this.checkRequiredFields(prod)) {
            let allProducts = JSON.parse(JSON.stringify(this.products));
            let margin = this.isFilled(this.costPrice) ? ((prod.totalPrice / prod.quantity) / this.costPrice).toFixed(2) : null;
            
            prod.commercialMarginPercentage = margin;
            prod.position = this.isFilled(this.products) ? this.products.length : 0
            allProducts.push(prod);

            // comissionValue
            console.log(JSON.stringify(allProducts));
            this.showIncludedProducts = true;
            this.addProduct = {};
            this.products = JSON.parse(JSON.stringify(allProducts));

            this.showToast('success', 'Sucesso!', 'Produto incluso.');
            // this._verifyFieldsToSave();

            this.createNewProduct = !this.createNewProduct;
        } else {
            this.showToast('error', 'Atenção!', 'Campos obrigatórios não preenchidos.');
        }
    }

    changeProduct() {
        let includedProducts = JSON.parse(JSON.stringify(this.products));
        for (let index = 0; index < includedProducts.length; index++) {
            if (includedProducts[index].position == this.productPosition) {
                if (this.checkRequiredFields(this.addProduct)) {
                    let margin = this.isFilled(this.costPrice) ? ((this.addProduct.totalPrice / this.addProduct.quantity) / this.costPrice).toFixed(2) : null;
                    this.addProduct.commercialMarginPercentage = margin;
                    includedProducts[index] = JSON.parse(JSON.stringify(this.addProduct));
                    break;
                } else {
                    this.showToast('error', 'Atenção!', 'Campos obrigatórios não preenchidos.');
                    return;
                }
            }
        }

        this.products = JSON.parse(JSON.stringify(includedProducts));
        this.updateProduct = !this.updateProduct;
        this.createNewProduct = !this.createNewProduct;
        this.showToast('success', 'Sucesso!', 'Produto alterado.');
        console.log(JSON.stringify(this.products));
    }

    handleRowActions(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'edit':
                this.editProduct(row.position);
            break;
        }
    }

    editProduct(position) {
        this.productPosition = position;
        let currentProduct = this.products.find(e => e.position == position);
        this.addProduct = {
            name: currentProduct.name,
            entryId: currentProduct.entryId,
            productId: currentProduct.productId,
            unity: currentProduct.unity,
            productGroup: currentProduct.productGroup,
            sapStatus: currentProduct.sapStatus,
            activePrinciple: currentProduct.activePrinciple,
            commercialDiscountPercentage: currentProduct.commercialDiscountPercentage,
            commercialAdditionPercentage: currentProduct.commercialAdditionPercentage,
            financialAdditionPercentage: currentProduct.financialAdditionPercentage,
            financialDecreasePercentage: currentProduct.financialDecreasePercentage,
            commercialDiscountValue: currentProduct.commercialDiscountValue,
            commercialAdditionValue: currentProduct.commercialAdditionValue,
            financialAdditionValue: currentProduct.financialAdditionValue,
            financialDecreaseValue: currentProduct.financialDecreaseValue,
            listPrice: currentProduct.listPrice,
            unitPrice: currentProduct.unitPrice,
            totalPrice: currentProduct.totalPrice,
            dosage: currentProduct.dosage,
            quantity: currentProduct.quantity,
            invoicedQuantity: currentProduct.invoicedQuantity
        }

        this.createNewProduct = !this.createNewProduct;
        this.updateProduct = !this.updateProduct;
    }

    checkRequiredFields(prod) {
        console.log('prod: ' + JSON.stringify(prod));
        if (this.isFilled(prod.name) && this.isFilled(prod.listPrice) && this.isFilled(prod.unitPrice) &&
            this.isFilled(prod.totalPrice) && this.isFilled(prod.commercialDiscountPercentage) &&
            this.isFilled(prod.commercialDiscountValue) && this.isFilled(prod.commercialAdditionPercentage) &&
            this.isFilled(prod.commercialAdditionValue) && this.isFilled(prod.financialAdditionPercentage) &&
            this.isFilled(prod.financialAdditionValue) && this.isFilled(prod.financialDecreasePercentage) &&
            this.isFilled(prod.financialDecreaseValue) && this.isFilled(prod.dosage) && this.isFilled(prod.quantity)) {
            return true;
        }
        return false;
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