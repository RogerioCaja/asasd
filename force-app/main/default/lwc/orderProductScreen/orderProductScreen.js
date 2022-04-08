import {
    LightningElement,
    api,
    track
} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSafraInfos from '@salesforce/apex/OrderScreenController.getSafraInfos';
import getFinancialInfos from '@salesforce/apex/OrderScreenController.getFinancialInfos';


let actions = [];
export default class OrderProductScreen extends LightningElement {
    @track addProduct={};
    costPrice;
    multiplicity;
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

    safraData={}
    paymentDate;hectares;priceBookListId;

    baseProducts = [];
    showBaseProducts = false;
    showIncludedProducts = false;
    message = false;
    createNewProduct = false;
    updateProduct = false;
    showList = false;
    changeColumns = false;
    showProductDivision = false;
    selectedProducts;
    columns = [];
    productName = '';
    currentDivisionProduct = {};
    divisionProducts = [];
    allDivisionProducts = [];
    financialInfos = {};
    
    @track products = [];
    @api productData;
    @api divisionData;
    @api accountData;
    @api headerData;
    @api cloneData;
    
    connectedCallback(event) {
        this.paymentDate = this.headerData.data_pagamento;
        this.hectares = this.headerData.hectares;
        this.priceBookListId = this.headerData.lista_precos.Id;

        if (this.cloneData.cloneOrder && this.cloneData.pricebookListId != this.priceBookListId) {
            this.products = []
            this.allDivisionProducts = [];
        } else {
            this.products = this.isFilled(this.productData) ? this.productData : [];
            this.allDivisionProducts = this.isFilled(this.divisionData) ? this.divisionData : [];
        }

        if (this.headerData.pedido_mae_check) actions.push({ label: 'Editar', name: 'edit' });
        else actions.push({ label: 'Editar', name: 'edit' },{ label: 'Divisão de Remessas', name: 'shippingDivision' });

        this.showIncludedProducts = this.products.length > 0;
        this.applySelectedColumns(event);

        if (this.isFilled(this.headerData.safra.Id)) {
            getSafraInfos({safraId: this.headerData.safra.Id})
            .then((result) => {
                let safraResult = JSON.parse(result);
                this.safraData = {
                    initialDate: safraResult.initialDate,
                    endDate: safraResult.endDate
                };

                let orderData = {
                    paymentDate: this.headerData.data_pagamento != null ? this.headerData.data_pagamento : '',
                    accountId: this.accountData.Id != null ? this.accountData.Id : '',
                    salesOrg: this.headerData.salesOrg != null ? this.headerData.salesOrg : '',
                    pricebookId: this.headerData.lista_precos.Id != null ? this.headerData.lista_precos.Id : '',
                    safra: this.headerData.safra.Id != null ? this.headerData.safra.Id : '',
                    ctv: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
                    culture: this.headerData.cultura.Id != null ? this.headerData.cultura.Id : ''
                };

                getFinancialInfos({data: JSON.stringify(orderData)})
                .then((result) => {
                    this.financialInfos = JSON.parse(result);
                    console.log('this.financialInfos: ' + JSON.stringify(this.financialInfos));
                })
            })
        }
    }

    showProductModal(event) {
        this.createNewProduct = !this.createNewProduct;

        if (this.createNewProduct) {
            let currentProduct = this.baseProducts.find(e => e.Id == event.target.dataset.targetId);
            this.multiplicity = currentProduct.multiplicity;
            this.costPrice = currentProduct.costPrice;
            this.addProduct = {
                entryId: currentProduct.entryId,
                productId: currentProduct.Id,
                name: currentProduct.Name,
                unity: currentProduct.unity,
                listPrice: currentProduct.listPrice,
                dosage: currentProduct.dosage,
                quantity: null,
                unitPrice: currentProduct.listPrice,
                totalPrice: null,
                commercialDiscountPercentage: '',
                commercialDiscountValue: null,
                commercialAdditionPercentage: '',
                commercialAdditionValue: null,
                financialAdditionPercentage: '',
                financialAdditionValue: null,
                financialDecreasePercentage: '',
                financialDecreaseValue: null,
                invoicedQuantity: currentProduct.invoicedQuantity,
                motherAvailableQuantity: currentProduct.motherAvailableQuantity,
                activePrinciple: currentProduct.activePrinciple != null ? currentProduct.activePrinciple : '',
                productGroupId: currentProduct.productGroupId != null ? currentProduct.productGroupId : '',
                productGroupName: currentProduct.productGroupName != null ? currentProduct.productGroupName : '',
                sapStatus: currentProduct.sapStatus != null ? currentProduct.sapStatus : '',
                sapProductCode: currentProduct.sapProductCode != null ? currentProduct.sapProductCode : ''
            };
        }
    }

    changeTableColumns(event) {
        let field = event.target.dataset.targetId;
        this.selectedColumns[field] = this.isFilled(this.selectedColumns[field]) ? !this.selectedColumns[field] : true;
    }

    applySelectedColumns(event) {
        let selectedColumns = [{label: 'Nome', fieldName: 'name'}];
        if (this.isSelected(this.selectedColumns.columnUnity)) selectedColumns.push({label: 'Unidade de Medida', fieldName: 'unity'})
        if (this.isSelected(this.selectedColumns.columnListPrice)) selectedColumns.push({label: 'Preço da Lista', fieldName: 'listPrice'})
        if (this.isSelected(this.selectedColumns.columnDosage)) selectedColumns.push({label: 'Dosagem', fieldName: 'dosage'})
        if (this.isSelected(this.selectedColumns.columnQuantity)) selectedColumns.push({label: 'Quantidade', fieldName: 'quantity'})
        if (this.isSelected(this.selectedColumns.columnUnitPrice)) selectedColumns.push({label: 'Preço Unitário', fieldName: 'unitPrice'})
        if (this.isSelected(this.selectedColumns.columnTotalPrice)) selectedColumns.push({label: 'Preço Total', fieldName: 'totalPrice'})
        if (this.isSelected(this.selectedColumns.columnCommercialDiscountPercentage)) selectedColumns.push({label: 'Percentual de Desconto Comercial', fieldName: 'commercialDiscountPercentage'})
        if (this.isSelected(this.selectedColumns.columnCommercialDiscountValue)) selectedColumns.push({label: 'Valor de Desconto Comercial', fieldName: 'commercialDiscountValue'})
        if (this.isSelected(this.selectedColumns.columnCommercialAdditionPercentage)) selectedColumns.push({label: 'Percentual de Acréscimo Comercial', fieldName: 'commercialAdditionPercentage'})
        if (this.isSelected(this.selectedColumns.columnCommercialAdditionValue)) selectedColumns.push({label: 'Valor de Acréscimo Comercial', fieldName: 'commercialAdditionValue'})
        if (this.isSelected(this.selectedColumns.columnFinancialAdditionPercentage)) selectedColumns.push({label: 'Percentual de Acréscimo Financeiro', fieldName: 'financialAdditionPercentage'})
        if (this.isSelected(this.selectedColumns.columnFinancialAdditionValue)) selectedColumns.push({label: 'Valor de Acréscimo Financeiro', fieldName: 'financialAdditionValue'})
        if (this.isSelected(this.selectedColumns.columnFinancialDecreasePercentage)) selectedColumns.push({label: 'Percentual de Decréscimo Financeiro', fieldName: 'financialDecreasePercentage'})
        if (this.isSelected(this.selectedColumns.columnFinancialDecreaseValue)) selectedColumns.push({label: 'Valor de Decréscimo Financeiro', fieldName: 'financialDecreaseValue'})
        if (this.isSelected(this.selectedColumns.columnInvoicedQuantity)) selectedColumns.push({label: 'Quantidade Faturada', fieldName: 'invoicedQuantity'})
        if (this.isSelected(this.selectedColumns.columnActivePrinciple)) selectedColumns.push({label: 'Princípio Ativo', fieldName: 'activePrinciple'})
        if (this.isSelected(this.selectedColumns.columnGroup)) selectedColumns.push({label: 'Grupo do Produto', fieldName: 'productGroupName'})
        if (this.isSelected(this.selectedColumns.columnSapStatus)) selectedColumns.push({label: 'Status SAP', fieldName: 'sapStatus'})

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
            } /* else if (fieldId == 'financialAdditionPercentage') {
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
            } */ else if (fieldId == 'dosage') {
                if (this.isFilled(this.hectares)) {
                    this.addProduct.quantity = this.calculateMultiplicity(this.addProduct.dosage * this.hectares);
                    this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                    this.calculateDiscountOrAddition();
                    this.calculateTotalPrice();
                }
            } else if (fieldId == 'quantity') {
                this.addProduct.quantity = this.calculateMultiplicity(this.addProduct.quantity);
                this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                this.calculateDiscountOrAddition();
                this.calculateTotalPrice();
            }
        }
    }

    calculateMultiplicity(quantity) {
        if (this.isFilled(this.multiplicity)) {
            let remainder = quantity % this.multiplicity;
            if (this.addProduct.motherAvailableQuantity != null &&  quantity > this.addProduct.motherAvailableQuantity) {
                this.showToast('warning', 'Atenção!', 'A quantidade não pode ultrapassar ' + this.addProduct.motherAvailableQuantity + '.');
                return this.addProduct.motherAvailableQuantity;
            }

            if (remainder == 0) {
                return quantity;
            } else {
                quantity = Math.ceil(quantity / this.multiplicity) * this.multiplicity;
                this.showToast('warning', 'Atenção!', 'A quantidade foi arredondada para ' + quantity + '.');
                return quantity;
            }
        }
    }

    calculateTotalPrice() {
        this.addProduct.totalPrice = null;

        if (this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.listPrice)) {
            this.addProduct.totalPrice = this.addProduct.quantity * this.addProduct.listPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.commercialAdditionValue) ? (this.addProduct.totalPrice + Number(this.addProduct.commercialAdditionValue)) : this.addProduct.totalPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.commercialDiscountValue) ? (this.addProduct.totalPrice - Number(this.addProduct.commercialDiscountValue)) : this.addProduct.totalPrice;

            this.calculateFinancialInfos();
            this.addProduct.totalPrice = this.isFilled(this.addProduct.financialAdditionValue) ? (this.addProduct.totalPrice + Number(this.addProduct.financialAdditionValue)) : this.addProduct.totalPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.financialDecreaseValue) ? (this.addProduct.totalPrice - Number(this.addProduct.financialDecreaseValue)) : this.addProduct.totalPrice;

            this.addProduct.unitPrice = (this.addProduct.totalPrice / this.addProduct.quantity).toFixed(4);
        }
    }

    calculateDiscountOrAddition() {
        if (this.isFilled(this.addProduct.listPrice) && this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.unitPrice)) {
            this.addProduct.commercialAdditionValue = '0';
            this.addProduct.commercialDiscountValue = '0';
            this.addProduct.commercialAdditionPercentage = '0%';
            this.addProduct.commercialDiscountPercentage = '0%';
            let currentPrice = this.addProduct.unitPrice * this.addProduct.quantity;
            this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
            
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

    calculateFinancialInfos() {
        if (this.isFilled(this.addProduct.totalPrice)) {
            let defaultKey = this.financialInfos.salesOrg + '-' + this.headerData.safra.Id;
            let key1 = defaultKey + '-' + this.headerData.cultura.Id + '-' + this.addProduct.productId;
            let key2 = defaultKey + '-' + this.financialInfos.salesOffice + '-' + this.addProduct.productId;
            let key3 = defaultKey + '-' + this.financialInfos.salesOffice;
            let key4 = defaultKey + '-' + this.addProduct.productGroupId;
            
            let currentDiscountOrAddition = 0;
            let financialValues = this.financialInfos.financialValues;
            if (this.isFilled(financialValues[key1])) {
                currentDiscountOrAddition = financialValues[key1]
            } else if (this.isFilled(financialValues[key2])) {
                currentDiscountOrAddition = financialValues[key2]
            } else if (this.isFilled(financialValues[key3])) {
                currentDiscountOrAddition = financialValues[key3]
            } else if (this.isFilled(financialValues[key4])) {
                currentDiscountOrAddition = financialValues[key4]
            } else if (this.isFilled(financialValues[defaultKey])) {
                currentDiscountOrAddition = financialValues[defaultKey]
            }

            this.addProduct.financialAdditionPercentage = (this.financialInfos.isDiscount ? 0 : currentDiscountOrAddition) + '%';
            this.addProduct.financialDecreasePercentage = (this.financialInfos.isDiscount ? currentDiscountOrAddition : 0) + '%';
            this.addProduct.financialAdditionValue = this.calculateValue(this.addProduct.financialAdditionPercentage, this.addProduct.totalPrice);
            this.addProduct.financialDecreaseValue = this.calculateValue(this.addProduct.financialDecreasePercentage, this.addProduct.totalPrice);
        }
    }

    isFilled(field) {
        return ((field !== undefined && field != null && field != '') || field == 0);
    }

    isSelected(field) {
        return (field !== undefined && field != null && field != '' && field == true);
    }

    includeProduct() {
        let prod = this.addProduct;
        if (this.checkRequiredFields(prod)) {
            let allProducts = JSON.parse(JSON.stringify(this.products));
            let margin = this.isFilled(this.costPrice) ? (this.costPrice).toFixed(2) / (prod.totalPrice / prod.quantity) : 0;
            
            prod.commercialMarginPercentage = margin;
            prod.multiplicity = this.multiplicity;
            prod.position = this.isFilled(this.products) ? this.products.length : 0
            allProducts.push(prod);

            console.log(JSON.stringify(allProducts));
            this.showIncludedProducts = true;
            this.addProduct = {};
            this.products = JSON.parse(JSON.stringify(allProducts));

            this.showToast('success', 'Sucesso!', 'Produto incluso.');
            this._verifyFieldsToSave();

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
                    let margin = this.isFilled(this.costPrice) ? (this.costPrice / (this.addProduct.totalPrice / this.addProduct.quantity)).toFixed(2) : null;
                    this.addProduct.commercialMarginPercentage = margin;
                    this.addProduct.multiplicity = this.multiplicity;
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

        let allDivisions = JSON.parse(JSON.stringify(this.allDivisionProducts));
        if (allDivisions.length > 0) {
            let allDivisionQuantitys = 0;
            for (let index = 0; index < allDivisions.length; index++) {
                let existingProductDivision = allDivisions[index];
                if (existingProductDivision.productPosition == this.productPosition) {
                    allDivisionQuantitys += Number(existingProductDivision.quantity);
                }
            }

            if (allDivisionQuantitys > Number(this.addProduct.quantity)) {
                this.showToast('warning', 'Atenção!', 'A soma das quantidades não pode ultrapassar ' + this.addProduct.quantity + '.');
                this.productDivision(this.productPosition);
            } else {
                this.showToast('success', 'Sucesso!', 'Produto alterado.');
            }
        } else {
            this.showToast('success', 'Sucesso!', 'Produto alterado.');
        }

        this._verifyFieldsToSave();
        console.log(JSON.stringify(this.products));
    }

    showDivisionModal() {
        let quantityError = this.quantityExceed();
        if (quantityError) {
            this.showToast('warning', 'Atenção!', 'A soma das quantidades não pode ultrapassar ' + this.currentDivisionProduct.quantity + '.');
        } else {
            this.showProductDivision = !this.showProductDivision;
        }
    }

    quantityExceed() {
        let allDivisions = JSON.parse(JSON.stringify(this.divisionProducts));
        if (allDivisions.length > 0) {
            let allDivisionQuantitys = 0;
            for (let index = 0; index < allDivisions.length; index++) {
                let existingProductDivision = allDivisions[index];
                if (existingProductDivision.productPosition == this.productPosition) {
                    allDivisionQuantitys += Number(existingProductDivision.quantity);
                }
            }

            if (allDivisionQuantitys > Number(this.currentDivisionProduct.quantity)) {
                return true;
            } else {
                return false;
            }
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
                if (this.isFilled(checkFields.quantity) && this.isFilled(checkFields.deliveryDate)) {
                    filledDivisions.push(checkFields);
                }
            }

            for (let index = 0; index < filledDivisions.length; index++) {
                if (filledDivisions[index].productPosition == this.productPosition) {
                    filledDivisions[index].orderItemKey = this.currentDivisionProduct.productId + '-' + Number(this.currentDivisionProduct.quantity).toFixed(2) + '-' + Number(this.currentDivisionProduct.unitPrice).toFixed(2);
                }
            }

            this.allDivisionProducts = JSON.parse(JSON.stringify(filledDivisions));
            this.showProductDivision = !this.showProductDivision;
            
            this.showToast('success', 'Sucesso!', 'Remessas salvas.');
            this._setDivisionData();
        }
    }

    handleRowActions(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'edit':
                this.editProduct(row.position);
            break;
            case 'shippingDivision':
                this.productDivision(row.position);
            break;
        }
    }

    editProduct(position) {
        this.productPosition = position;
        let currentProduct = this.products.find(e => e.position == position);
        this.multiplicity = currentProduct.multiplicity;
        this.addProduct = {
            orderItemId: currentProduct.orderItemId,
            name: currentProduct.name,
            entryId: currentProduct.entryId,
            productId: currentProduct.productId,
            unity: currentProduct.unity,
            productGroupId: currentProduct.productGroupId,
            productGroupName: currentProduct.productGroupName,
            sapStatus: currentProduct.sapStatus,
            sapProductCode: currentProduct.sapProductCode,
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
            motherAvailableQuantity: currentProduct.motherAvailableQuantity,
            invoicedQuantity: currentProduct.invoicedQuantity,
            position: currentProduct.position
        }
        console.log('this.addProduct: ' + JSON.stringify(this.addProduct));

        this.createNewProduct = !this.createNewProduct;
        this.updateProduct = !this.updateProduct;
    }

    productDivision(position) {
        let distributedQuantity = 0;
        this.divisionProducts = this.isFilled(this.allDivisionProducts) ? JSON.parse(JSON.stringify(this.allDivisionProducts)) : [];
        for (let index = 0; index < this.divisionProducts.length; index++) {
            if (this.divisionProducts[index].productPosition == position) {
                this.divisionProducts[index].showInfos = true;
                distributedQuantity += Number(this.divisionProducts[index].quantity);
            } else {
                this.divisionProducts[index].showInfos = false;
            }
        }

        let currentProduct = this.products.find(e => e.position == position);
        let availableQuantity = currentProduct.quantity - distributedQuantity;

        this.productPosition = position;
        this.multiplicity = currentProduct.multiplicity;
        this.currentDivisionProduct = {
            productId: currentProduct.productId,
            unitPrice: currentProduct.unitPrice,
            position: position,
            name: currentProduct.name,
            quantity: currentProduct.quantity,
            availableQuantity: availableQuantity,
            showRed : availableQuantity < 0 ? true : false
        };

        console.log('this.currentDivisionProduct: ' + JSON.stringify(this.currentDivisionProduct));
        this.showProductDivision = !this.showProductDivision;
        this.newFields();
    }

    newFields() {
        let allDivisions = JSON.parse(JSON.stringify(this.divisionProducts));
        let divPosition = this.isFilled(allDivisions) ? allDivisions.length : 0;
        let deliveryId = 'deliveryId-' + divPosition;
        let quantityId = 'quantityId-' + divPosition;
        let orderItemKey = this.currentDivisionProduct.productId + '-' + Number(this.currentDivisionProduct.quantity).toFixed(2) + '-' + Number(this.currentDivisionProduct.unitPrice).toFixed(2);
        
        allDivisions.push({deliveryDate: null, quantity: null, position: divPosition, deliveryId: deliveryId, quantityId: quantityId, orderItemKey: orderItemKey, productPosition: this.productPosition, showInfos: true});
        this.divisionProducts = JSON.parse(JSON.stringify(allDivisions));
    }

    divisionChange(event) {
        let allDivisions = JSON.parse(JSON.stringify(this.divisionProducts));
        let fieldId = event.target.dataset.targetId;
        let fieldValue = event.target.value;
        let currentProduct;

        if (this.isFilled(fieldValue)) {
            if (fieldId.includes('deliveryId-')) {
                currentProduct = allDivisions.find(e => e.deliveryId == fieldId);
                if (fieldValue >= this.safraData.initialDate && fieldValue <= this.safraData.endDate) {
                    currentProduct.deliveryDate = fieldValue;
                } else {
                    currentProduct.deliveryDate = null;
                    let formatInitialDate = this.safraData.initialDate.split('-')[2] + '/' + this.safraData.initialDate.split('-')[1] + '/' + this.safraData.initialDate.split('-')[0];
                    let formatEndDate = this.safraData.endDate.split('-')[2] + '/' + this.safraData.endDate.split('-')[1] + '/' + this.safraData.endDate.split('-')[0];
                    this.showToast('warning', 'Atenção!', 'A data tem que estar na vigêngia da safra(' + formatInitialDate + '-' + formatEndDate + ').');
                }
            } else if (fieldId.includes('quantityId-')) {
                let productQuantity = 0;
                for (let index = 0; index < allDivisions.length; index++) {
                    if (allDivisions[index].productPosition == this.currentDivisionProduct.position && allDivisions[index].quantityId != fieldId) {
                        productQuantity = productQuantity + (Number(allDivisions[index].quantity));
                    }
                }

                currentProduct = allDivisions.find(e => e.quantityId == fieldId);
                if ((Number(productQuantity) + Number(fieldValue)) <= this.currentDivisionProduct.quantity) {
                    currentProduct.quantity = this.calculateMultiplicity(fieldValue);
                } else {
                    currentProduct.quantity = this.currentDivisionProduct.quantity - Number(productQuantity);
                    this.showToast('warning', 'Atenção!', 'A quantidade foi arredondada para ' + currentProduct.quantity + ' para não exceder.');
                }

                this.currentDivisionProduct.availableQuantity = this.currentDivisionProduct.quantity - ((Number(productQuantity) + Number(currentProduct.quantity)));
                if (this.currentDivisionProduct.availableQuantity < 0) {
                    this.currentDivisionProduct.showRed = true;
                } else {
                    this.currentDivisionProduct.showRed = false;
                }
            }

            this.divisionProducts = JSON.parse(JSON.stringify(allDivisions));
            console.log('this.divisionProducts: ' + JSON.stringify(this.divisionProducts));
        }
    }

    checkRequiredFields(prod) {
        /* if (this.isFilled(prod.name) && this.isFilled(prod.listPrice) && this.isFilled(prod.unitPrice) &&
            this.isFilled(prod.totalPrice) && this.isFilled(prod.commercialDiscountPercentage) &&
            this.isFilled(prod.commercialDiscountValue) && this.isFilled(prod.commercialAdditionPercentage) &&
            this.isFilled(prod.commercialAdditionValue) && this.isFilled(prod.financialAdditionPercentage) &&
            this.isFilled(prod.financialAdditionValue) && this.isFilled(prod.financialDecreasePercentage) &&
            this.isFilled(prod.financialDecreaseValue) && this.isFilled(prod.dosage) && this.isFilled(prod.quantity)) {
            return true;
        } */
        if (this.isFilled(prod.name) && this.isFilled(prod.listPrice) && this.isFilled(prod.unitPrice) &&
            this.isFilled(prod.totalPrice) && this.isFilled(prod.commercialDiscountPercentage) &&
            this.isFilled(prod.commercialDiscountValue) && this.isFilled(prod.commercialAdditionPercentage) &&
            this.isFilled(prod.commercialAdditionValue) && this.isFilled(prod.dosage) && this.isFilled(prod.quantity)) {
            return true;
        }
        return false;
    }

    @api
    _verifyFieldsToSave() {
        this._setData();
        return true;
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

    _setDivisionData() {
        const setHeaderData = new CustomEvent('setdivisiondata');
        setHeaderData.data = this.allDivisionProducts;
        this.dispatchEvent(setHeaderData);
    }

    showResults(event){
        this.showBaseProducts = event.showResults;
        this.baseProducts = event.results;
        console.log('this.baseProducts: ' + JSON.stringify(this.baseProducts));
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