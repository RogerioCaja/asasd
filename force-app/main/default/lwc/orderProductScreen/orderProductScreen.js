import {
    LightningElement,
    api,
    track
} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSafraInfos from '@salesforce/apex/OrderScreenController.getSafraInfos';
import getFinancialInfos from '@salesforce/apex/OrderScreenController.getFinancialInfos';
import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';


let actions = [];
export default class OrderProductScreen extends LightningElement {
    @track addProduct={};
    costPrice;
    multiplicity;
    listTotalPrice;
    productPosition;

    selectedColumns={
        columnUnity: true,
        columnListPrice: true,
        columnQuantity: true,
        columnUnitPrice: true,
        columnTotalPrice: true,
        columnProductGroupName: true,
        columnCommercialDiscountPercentage: true
    }

    companyResult=[];
    selectCompany = false;
    safraData={};
    paymentDate;
    hectares;
    salesConditionId;
    productParams={};
    productsPriceMap;
    salesInfos;

    baseProducts = [];
    showBaseProducts = false;
    showIncludedProducts = false;
    message = false;
    createNewProduct = false;
    updateProduct = false;
    recalculatePrice = false;
    showList = false;
    changeColumns = false;
    showProductDivision = false;
    barterSale = false;
    selectedProducts;
    columns = [];
    productName = '';
    currentDivisionProduct = {};
    divisionProducts = [];
    allDivisionProducts = [];
    financialInfos = {};
    
    selectCommodityScreen = false;
    // commodityScreens = ['chooseCommodity', 'fillCommodity', 'negotiationDetails', 'haScreen'];
    commodityScreens = ['chooseCommodity', 'fillCommodity', 'negotiationDetails'];
    currentScreen = 'chooseCommodity';
    
    commodities = [];
    // commoditiesData = [];
    chooseCommodities = false;
    showCommodities = false;
    commoditySelected = false;
    summaryScreen = false;
    commodityColumns = [
        {label: 'Produto', fieldName: 'product'},
        {label: 'Dose', fieldName: 'desage'},
        {label: 'Área', fieldName: 'area'},
        {label: 'Quantidade', fieldName: 'quantity'},
        {label: 'Desconto', fieldName: 'discount'},
        {label: 'Margem', fieldName: 'margin'},
        {label: 'Entrega Total', fieldName: 'totalDelivery'}
    ];

    // haScreen = false;
    /* haData = [{
        productSubGroup: 'productSubGroup',
        totalQuantity: 'totalQuantity',
        haCost: 'haCost',
        haPotential: 'haPotential',
        customerShare: 'customerShare'
    }];
    haColumns = [
        {label: 'Sub Grupo de Produto', fieldName: 'productSubGroup'},
        {label: 'Quantidade Total', fieldName: 'totalQuantity'},
        {label: 'Custo/HA', fieldName: 'haCost'},
        {label: 'Potencial/HA', fieldName: 'haPotential'},
        {label: 'Customer Share', fieldName: 'customerShare'}
    ]; */
    
    @track products = [];
    @track commoditiesData = [];

    @api productData;
    @api commodityData;
    @api divisionData;
    @api accountData;
    @api headerData;
    @api cloneData;
    
    connectedCallback(event) {
        this.paymentDate = this.headerData.data_pagamento;
        this.hectares = this.headerData.hectares;
        this.salesConditionId = this.headerData.condicao_venda.Id;
        this.barterSale = this.headerData.tipo_venda == 'Venda Barter' ? true : false;
        this.commoditiesData = this.isFilled(this.commodityData) ? this.commodityData : [];

        if (this.cloneData.cloneOrder) {
            this.products = this.isFilled(this.productData) ? this.productData : [];
            this.allDivisionProducts = [];
        } else {
            this.products = this.isFilled(this.productData) ? this.productData : [];
            this.allDivisionProducts = this.isFilled(this.divisionData) ? this.divisionData : [];
        }

        actions = [];
        if (this.headerData.pedido_mae_check) actions.push({ label: 'Editar', name: 'edit' }, { label: 'Excluir', name: 'delete' });
        else actions.push({ label: 'Editar', name: 'edit' }, { label: 'Divisão de Remessas', name: 'shippingDivision' }, { label: 'Excluir', name: 'delete' });

        this.showIncludedProducts = this.products.length > 0;
        this.applySelectedColumns(event);

        let getCompanyData = {
            ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
            accountId: this.accountData.Id != null ? this.accountData.Id : '',
            approvalNumber: 1
        }

        getAccountCompanies({data: JSON.stringify(getCompanyData)})
        .then((result) => {
            this.companyResult = JSON.parse(result).listCompanyInfos;
            if (this.companyResult.length == 0) {
                this.showToast('warning', 'Atenção!', 'Não foi encontrado Área de Vendas no SAP. Contate o administrador do sistema.');
            } if (this.companyResult.length == 1) {
                this.selectedCompany = this.companyResult[0];
                this.onSelectCompany();
            } else if (this.companyResult.length > 1) {
                this.selectCompany = true;
            }
        });
    }

    chooseCompany(event) {
        let oldCompanyId;
        let companies = this.companyResult;
        if (this.isFilled(this.selectedCompany)) {
            oldCompanyId = this.isFilled(this.selectedCompany) ? this.selectedCompany.companyId : null;
            for (let index = 0; index < companies.length; index++) {
                if (companies[index].companyId == oldCompanyId) {
                    companies[index].selected = false;
                    this.selectedCompany = {};
                } else if (companies[index].companyId == event.target.dataset.targetId) {
                    companies[index].selected = true;
                    this.selectedCompany = companies[index];
                }
            }
        } else {
            for (let index = 0; index < companies.length; index++) {
                if (companies[index].companyId == event.target.dataset.targetId) {
                    companies[index].selected = true;
                    this.selectedCompany = companies[index];
                }
            }
        }
        this.companyResult = JSON.parse(JSON.stringify(companies));
    }

    onSelectCompany() {
        this.selectCompany = !this.selectCompany;
        if (this.isFilled(this.headerData.safra.Id)) {
            getSafraInfos({safraId: this.headerData.safra.Id})
            .then((result) => {
                let safraResult = JSON.parse(result);
                this.safraData = {
                    initialDate: safraResult.initialDate,
                    endDate: safraResult.endDate
                };

                this.productParams = {
                    salesConditionId: this.headerData.condicao_venda.Id,
                    accountId: this.accountData.Id,
                    ctvId: this.headerData.ctv_venda.Id,
                    safra: this.headerData.safra.Id,
                    productCurrency: this.headerData.moeda,
                    culture: this.headerData.cultura.Id,
                    orderType: this.headerData.tipo_venda,
                    supplierCenter: this.selectedCompany.supplierCenter,
                    salesOrgId: this.selectedCompany.salesOrgId != null ? this.selectedCompany.salesOrgId : '',
                    salesOfficeId: this.selectedCompany.salesOfficeId != null ? this.selectedCompany.salesOfficeId : '',
                    salesTeamId: this.selectedCompany.salesTeamId != null ? this.selectedCompany.salesTeamId : ''
                };

                let orderData = {
                    paymentDate: this.headerData.data_pagamento != null ? this.headerData.data_pagamento : '',
                    salesOrg: this.selectedCompany.salesOrgId != null ? this.selectedCompany.salesOrgId : '',
                    salesOffice: this.selectedCompany.salesOfficeId != null ? this.selectedCompany.salesOfficeId : '',
                    salesTeam: this.selectedCompany.salesTeamId != null ? this.selectedCompany.salesTeamId : '',
                    safra: this.headerData.safra.Id != null ? this.headerData.safra.Id : '',
                    culture: this.headerData.cultura.Id != null ? this.headerData.cultura.Id : ''
                };

                if (!this.headerData.IsOrderChild) {
                    getFinancialInfos({data: JSON.stringify(orderData)})
                    .then((result) => {
                        this.financialInfos = JSON.parse(result);
                        if (this.products.length > 0) {
                            let showPriceChange = false;
                            let priceChangeMessage = '';
                            let currentProducts = this.products;
                            
                            for (let index = 0; index < currentProducts.length; index++) {
                                this.recalculatePrice = true;
                                this.editProduct(currentProducts[index].position, true);
                                let oldPrice = currentProducts[index].unitPrice;
                                this.calculateTotalPrice(true);
                                let newPrice = this.changeProduct();
                                if (oldPrice != newPrice) {
                                    showPriceChange = true;
                                    priceChangeMessage += 'O preço do ' + currentProducts[index].name + ' foi alterado de ' + oldPrice + ' para ' + newPrice + '.\n';
                                }
                            }
                            this.recalculatePrice = false;

                            if (showPriceChange) {
                                if (currentProducts.length > 1) {
                                    priceChangeMessage = 'Os preços foram recalculados devido a alteração de data de pagamento. Verifique-os.';
                                }
                                this.showToast('warning', 'Alteração nos preços!', priceChangeMessage);
                            }
                        }
                    })
                }
            })
        }
    }

    getProductByPriority(selectedProduct) {
        let key1 = this.accountData.Id + '-' + selectedProduct.Id;
        let key2 = this.salesInfos.segmento + '-' + selectedProduct.Id;
        let key3 = this.headerData.cultura.Id + '-' + this.salesInfos.salesTeamId + '-' + selectedProduct.Id;
        let key4 = this.salesInfos.salesTeamId + '-' + selectedProduct.Id;
        let key5 = this.salesInfos.salesOfficeId + '-' + selectedProduct.Id;
        let key6 = selectedProduct.productGroupId;
        let key7 = selectedProduct.Id;

        let productsPrice = this.productsPriceMap;
        let priorityPrice;
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
        } else if (this.isFilled(productsPrice[key7])) {
            priorityPrice = productsPrice[key7];
        }

        return priorityPrice;
    }

    showProductModal(event) {
        this.createNewProduct = !this.createNewProduct;

        if (this.createNewProduct) {
            let existProduct = this.products.find(e => e.productId == event.target.dataset.targetId);

            if (this.isFilled(existProduct)) {
                this.createNewProduct = false;
                this.editProduct(existProduct.position, false);
            } else {
                let currentProduct = this.baseProducts.find(e => e.Id == event.target.dataset.targetId);
                let priorityInfos = this.getProductByPriority(currentProduct);
                console.log('priorityInfos: ' + JSON.stringify(priorityInfos));
    
                this.multiplicity = currentProduct.multiplicity;
                this.costPrice = priorityInfos.costPrice;
                this.addProduct = {
                    entryId: currentProduct.entryId,
                    productId: currentProduct.Id,
                    name: currentProduct.Name,
                    unity: currentProduct.unity,
                    listPrice: this.isFilled(priorityInfos.listPrice) ? this.fixDecimalPlaces(priorityInfos.listPrice) : 0,
                    listCost: this.isFilled(priorityInfos.costPrice) ? this.fixDecimalPlaces(priorityInfos.costPrice) : 0,
                    practicedCost: this.isFilled(priorityInfos.costPrice) ? this.fixDecimalPlaces(priorityInfos.costPrice) : 0,
                    dosage: currentProduct.dosage,
                    quantity: null,
                    unitPrice: this.isFilled(priorityInfos.listPrice) ? this.fixDecimalPlaces(priorityInfos.listPrice) : 0,
                    totalPrice: null,
                    initialTotalValue: null,
                    commercialDiscountPercentage: null,
                    commercialDiscountValue: null,
                    commercialAdditionPercentage: null,
                    commercialAdditionValue: null,
                    financialAdditionPercentage: null,
                    financialAdditionValue: null,
                    financialDecreasePercentage: null,
                    financialDecreaseValue: null,
                    invoicedQuantity: currentProduct.invoicedQuantity,
                    motherAvailableQuantity: currentProduct.motherAvailableQuantity,
                    activePrinciple: currentProduct.activePrinciple != null ? currentProduct.activePrinciple : '',
                    productGroupId: currentProduct.productGroupId != null ? currentProduct.productGroupId : '',
                    productGroupName: currentProduct.productGroupName != null ? currentProduct.productGroupName : '',
                    productSubgroupName: currentProduct.productSubgroupName != null ? currentProduct.productSubgroupName : '',
                    sapStatus: currentProduct.sapStatus != null ? currentProduct.sapStatus : '',
                    sapProductCode: currentProduct.sapProductCode != null ? currentProduct.sapProductCode : ''
                };
            }
        }
    }

    changeTableColumns(event) {
        let field = event.target.dataset.targetId;
        this.selectedColumns[field] = this.isFilled(this.selectedColumns[field]) ? !this.selectedColumns[field] : true;
    }

    applySelectedColumns(event) {
        let selectedColumns = [{label: 'Produto', fieldName: 'name'}];
        if (this.isSelected(this.selectedColumns.columnUnity)) selectedColumns.push({label: 'Unidade de Medida', fieldName: 'unity'})
        if (this.isSelected(this.selectedColumns.columnListPrice)) selectedColumns.push({label: 'Preço Lista (un)', fieldName: 'listPrice'})
        if (this.isSelected(this.selectedColumns.columnDosage)) selectedColumns.push({label: 'Dosagem', fieldName: 'dosage'})
        if (this.isSelected(this.selectedColumns.columnQuantity)) selectedColumns.push({label: 'Qtd', fieldName: 'quantity'})
        if (this.isSelected(this.selectedColumns.columnUnitPrice)) selectedColumns.push({label: 'Preço Praticado (un)', fieldName: 'unitPrice'})
        if (this.isSelected(this.selectedColumns.columnTotalPrice)) selectedColumns.push({label: 'Preço Total', fieldName: 'totalPrice'})
        if (this.isSelected(this.selectedColumns.columnCommercialDiscountPercentage)) selectedColumns.push({label: '% Desconto Comercial', fieldName: 'commercialDiscountPercentage'})
        if (this.isSelected(this.selectedColumns.columnCommercialDiscountValue)) selectedColumns.push({label: 'Valor de Desconto Comercial', fieldName: 'commercialDiscountValue'})
        if (this.isSelected(this.selectedColumns.columnCommercialAdditionPercentage)) selectedColumns.push({label: '% Acréscimo Comercial', fieldName: 'commercialAdditionPercentage'})
        if (this.isSelected(this.selectedColumns.columnCommercialAdditionValue)) selectedColumns.push({label: 'Valor de Acréscimo Comercial', fieldName: 'commercialAdditionValue'})
        if (this.isSelected(this.selectedColumns.columnFinancialAdditionPercentage)) selectedColumns.push({label: '% Acréscimo Financeiro', fieldName: 'financialAdditionPercentage'})
        if (this.isSelected(this.selectedColumns.columnFinancialAdditionValue)) selectedColumns.push({label: 'Valor de Acréscimo Financeiro', fieldName: 'financialAdditionValue'})
        if (this.isSelected(this.selectedColumns.columnFinancialDecreasePercentage)) selectedColumns.push({label: '% Decréscimo Financeiro', fieldName: 'financialDecreasePercentage'})
        if (this.isSelected(this.selectedColumns.columnFinancialDecreaseValue)) selectedColumns.push({label: 'Valor de Decréscimo Financeiro', fieldName: 'financialDecreaseValue'})
        if (this.isSelected(this.selectedColumns.columnInvoicedQuantity)) selectedColumns.push({label: 'Quantidade Faturada', fieldName: 'invoicedQuantity'})
        if (this.isSelected(this.selectedColumns.columnActivePrinciple)) selectedColumns.push({label: 'Princípio Ativo', fieldName: 'activePrinciple'})
        if (this.isSelected(this.selectedColumns.columnGroup)) selectedColumns.push({label: 'Grupo do Produto', fieldName: 'productGroupName'})
        if (this.isSelected(this.selectedColumns.columnproductSubgroupName)) selectedColumns.push({label: 'Subgrupo do Produto', fieldName: 'productSubgroupName'})

        if (selectedColumns.length >= 2) {
            selectedColumns.push({
                type: 'action',
                typeAttributes: {
                    rowActions: actions,
                    menuAlignment: 'auto'
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
                this.recalculateValuesByUnitPrice();
                this.calculateTotalPrice(false);
            } else if (fieldId == 'commercialDiscountPercentage') {
                this.addProduct.commercialDiscountPercentage = this.addProduct.commercialDiscountPercentage == '' ? '0%' : this.addProduct.commercialDiscountPercentage;
                this.addProduct.commercialDiscountValue = 
                    this.isFilled(this.addProduct.totalPrice) ?
                    this.calculateValue(this.addProduct.commercialDiscountPercentage, this.addProduct.totalPrice) :
                    this.addProduct.commercialDiscountValue;
                
                this.calculateTotalPrice(true);
            } else if (fieldId == 'commercialDiscountValue') {
                this.addProduct.commercialDiscountValue = this.addProduct.commercialDiscountValue == '' ? 0 : this.fixDecimalPlaces(Number(this.addProduct.commercialDiscountValue));
                this.addProduct.commercialDiscountPercentage = 
                    this.isFilled(this.addProduct.totalPrice) ?
                    this.calculatePercentage(this.addProduct.commercialDiscountValue, this.addProduct.totalPrice) :
                    this.addProduct.commercialDiscountPercentage;
                
                this.calculateTotalPrice(true);
            } else if (fieldId == 'commercialAdditionPercentage') {
                this.addProduct.commercialAdditionPercentage = this.addProduct.commercialAdditionPercentage == '' ? '0%' : this.addProduct.commercialAdditionPercentage;
                this.addProduct.commercialAdditionValue = 
                    this.isFilled(this.addProduct.totalPrice) ?
                    this.calculateValue(this.addProduct.commercialAdditionPercentage, this.addProduct.totalPrice) :
                    this.addProduct.commercialAdditionValue;
                
                this.calculateTotalPrice(true);
            } else if (fieldId == 'commercialAdditionValue') {
                this.addProduct.commercialAdditionValue = this.addProduct.commercialAdditionValue == '' ? 0 : this.fixDecimalPlaces(Number(this.addProduct.commercialAdditionValue));
                this.addProduct.commercialAdditionPercentage = 
                    this.isFilled(this.addProduct.totalPrice) ?
                    this.calculatePercentage(this.addProduct.commercialAdditionValue, this.addProduct.totalPrice) :
                    this.addProduct.commercialAdditionPercentage;
                
                this.calculateTotalPrice(true);
            } else if (fieldId == 'dosage') {
                if (this.isFilled(this.hectares)) {
                    this.addProduct.quantity = this.calculateMultiplicity(this.addProduct.dosage * this.hectares);
                    this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                    this.calculateDiscountOrAddition();
                    this.calculateTotalPrice(true);
                }
            } else if (fieldId == 'quantity') {
                this.addProduct.quantity = this.calculateMultiplicity(this.addProduct.quantity);
                if (!this.headerData.IsOrderChild) {
                    this.addProduct.dosage = this.isFilled(this.hectares) ? this.addProduct.quantity / this.hectares : 0
                    this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                    this.calculateDiscountOrAddition();
                    this.calculateTotalPrice(true);
                } else {
                    this.addProduct.totalPrice = this.fixDecimalPlaces((this.addProduct.listPrice * this.addProduct.quantity));
                }
            }
        }
    }

    calculateMultiplicity(quantity) {
        if (this.isFilled(this.multiplicity)) {
            let remainder = quantity % this.multiplicity;
            if (this.headerData.IsOrderChild && this.addProduct.motherAvailableQuantity != null && quantity > this.addProduct.motherAvailableQuantity) {
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

    calculateTotalPrice(recalculateUnitPrice) {
        this.addProduct.totalPrice = null;

        if (this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.listPrice)) {
            let inicialTotalPrice = this.addProduct.quantity * this.addProduct.listPrice;

            if (!this.isFilled(this.addProduct.initialTotalValue)) {
                this.addProduct.initialTotalValue = this.fixDecimalPlaces(inicialTotalPrice);
                this.calculateFinancialInfos();
                this.addProduct.initialTotalValue = this.fixDecimalPlaces(this.addProduct.totalPrice);
            } else {
                this.addProduct.totalPrice = this.addProduct.quantity * this.addProduct.listPrice;
                this.addProduct.financialAdditionValue = this.calculateValue(this.addProduct.financialAdditionPercentage, this.addProduct.totalPrice);
                this.addProduct.financialDecreaseValue = this.calculateValue(this.addProduct.financialDecreasePercentage, this.addProduct.totalPrice);
            }
            
            this.addProduct.totalPrice = this.isFilled(this.addProduct.financialAdditionValue) ? (this.addProduct.totalPrice + Number(this.addProduct.financialAdditionValue)) : this.addProduct.totalPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.financialDecreaseValue) ? (this.addProduct.totalPrice - Number(this.addProduct.financialDecreaseValue)) : this.addProduct.totalPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.commercialAdditionValue) ? (this.addProduct.totalPrice + Number(this.addProduct.commercialAdditionValue)) : this.addProduct.totalPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.commercialDiscountValue) ? this.fixDecimalPlaces((this.addProduct.totalPrice - Number(this.addProduct.commercialDiscountValue))) : this.fixDecimalPlaces(this.addProduct.totalPrice);

            if (recalculateUnitPrice) {
                this.addProduct.unitPrice = this.fixDecimalPlaces((this.addProduct.totalPrice / this.addProduct.quantity));
            }
        }
    }

    calculateDiscountOrAddition() {
        if (this.isFilled(this.addProduct.listPrice) && this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.unitPrice)) {
            this.addProduct.commercialAdditionValue = this.isFilled(this.addProduct.commercialAdditionValue) ? this.addProduct.commercialAdditionValue : '0';
            this.addProduct.commercialDiscountValue = this.isFilled(this.addProduct.commercialDiscountValue) ? this.addProduct.commercialDiscountValue : '0';
            this.addProduct.commercialAdditionPercentage = this.isFilled(this.addProduct.commercialAdditionPercentage) ? this.addProduct.commercialAdditionPercentage : '0%';
            this.addProduct.commercialDiscountPercentage = this.isFilled(this.addProduct.commercialDiscountPercentage) ? this.addProduct.commercialDiscountPercentage : '0%';
            let currentPrice = this.addProduct.unitPrice * this.addProduct.quantity;
            this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
            
            if (this.isFilled(currentPrice) && this.addProduct.unitPrice > this.addProduct.listPrice) {
                this.addProduct.commercialAdditionValue = this.calculateValue(this.addProduct.commercialAdditionPercentage, this.listTotalPrice);
            } else if (this.isFilled(currentPrice) && this.addProduct.unitPrice < this.addProduct.listPrice) {
                this.addProduct.commercialDiscountValue = this.calculateValue(this.addProduct.commercialDiscountPercentage, this.listTotalPrice);
            }
        }
    }

    recalculateValuesByUnitPrice() {
        if (this.isFilled(this.addProduct.listPrice) && this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.unitPrice)) {
            let currentPrice = this.addProduct.unitPrice * this.addProduct.quantity;
            let totalPrice = Number(this.addProduct.totalPrice) - Number(this.addProduct.commercialAdditionValue) + Number(this.addProduct.commercialDiscountValue);
            
            if (this.isFilled(currentPrice) && Number(currentPrice) > Number(totalPrice)) {
                this.addProduct.commercialAdditionValue = this.fixDecimalPlaces((currentPrice - totalPrice));
                this.addProduct.commercialAdditionPercentage = this.calculatePercentage(this.addProduct.commercialAdditionValue, totalPrice);
            } else if (this.isFilled(currentPrice) && Number(currentPrice) < Number(totalPrice)) {
                this.addProduct.commercialDiscountValue = this.fixDecimalPlaces((totalPrice - currentPrice));
                this.addProduct.commercialDiscountPercentage = this.calculatePercentage(this.addProduct.commercialDiscountValue, totalPrice);
            }
        }
    }

    fixDecimalPlaces(value) {
        return (+(Math.trunc(+(value + 'e' + 2)) + 'e' + -2)).toFixed(2);
    }

    calculatePercentage(valueToBeCalculated, total) {
        let percentageValue = this.fixDecimalPlaces(((valueToBeCalculated * 100) / total)) + '%';
        percentageValue = percentageValue.includes('.') ? percentageValue.replace('.', ',') : percentageValue;
        return percentageValue;
    }

    calculateValue(percentage, total) {
        percentage = percentage.includes(',') ? percentage.replace(',', '.').replace('%', '') : percentage.replace('%', '');
        let value = this.fixDecimalPlaces(((parseFloat(percentage) / 100) * total));
        return value;
    }

    calculateFinancialInfos() {
        this.addProduct.totalPrice = this.addProduct.quantity * this.addProduct.listPrice;
        if (this.isFilled(this.addProduct.totalPrice)) {
            if (this.headerData.IsOrderChild) {
                this.addProduct.financialAdditionPercentage = '0%';
                this.addProduct.financialDecreasePercentage = '0%';
                this.addProduct.financialAdditionValue = 0;
                this.addProduct.financialDecreaseValue = 0;
                return;
            }

            let defaultKey = this.financialInfos.salesOrg + '-' + this.headerData.safra.Id;
            let key1 = defaultKey + '-' + this.headerData.cultura.Id + '-' + this.addProduct.productId;
            let key2 = defaultKey + '-' + this.financialInfos.salesOffice + '-' + this.addProduct.productId;
            let key3 = defaultKey + '-' + this.financialInfos.salesOffice;
            let key4 = defaultKey + '-' + this.addProduct.productGroupId;
            
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

            let totalValue = this.isFilled(this.headerData.id) ? this.addProduct.quantity * this.addProduct.unitPrice : this.addProduct.totalPrice;

            currentDiscountOrAddition = (currentDiscountOrAddition / 30) * (this.financialInfos.dayDifference < 0 ? (this.financialInfos.dayDifference * -1) : this.financialInfos.dayDifference);
            this.addProduct.financialAdditionPercentage = this.financialInfos.correctPayment ? '0%' : this.fixDecimalPlaces(((this.financialInfos.isDiscount ? 0 : currentDiscountOrAddition))) + '%';
            this.addProduct.financialDecreasePercentage = this.financialInfos.correctPayment ? '0%' : this.fixDecimalPlaces(((this.financialInfos.isDiscount ? currentDiscountOrAddition : 0))) + '%';
            this.addProduct.financialAdditionValue = this.calculateValue(this.addProduct.financialAdditionPercentage, totalValue);
            this.addProduct.financialDecreaseValue = this.calculateValue(this.addProduct.financialDecreasePercentage, totalValue);
            
            if (!this.financialInfos.correctPayment) {
                if (this.financialInfos.isDiscount) {
                    this.addProduct.practicedCost = this.fixDecimalPlaces((Number(this.addProduct.listCost) - (Number(this.addProduct.listCost) * (Number(currentDiscountOrAddition) / 100))));
                } else {
                    this.addProduct.practicedCost = this.fixDecimalPlaces((Number(this.addProduct.listCost) + (Number(this.addProduct.listCost) * (Number(currentDiscountOrAddition) / 100))));
                }
            }
        }
    }

    isFilled(field) {
        return ((field !== undefined && field != null && field != '') || field == 0);
    }

    greaterThanZero(field) {
        return ((field !== undefined && field != null && field > 0));
    }

    isSelected(field) {
        return (field !== undefined && field != null && field != '' && field == true);
    }

    includeProduct() {
        console.log('this.addProduct: ' + JSON.stringify(this.addProduct));
        let prod = this.addProduct;
        if (this.checkRequiredFields(prod)) {
            let allProducts = JSON.parse(JSON.stringify(this.products));
            let margin = this.isFilled(this.addProduct.practicedCost) ? (1 - this.fixDecimalPlaces(Number(this.addProduct.practicedCost)) / (prod.totalPrice / prod.quantity)) * 100 : 0;
            
            prod.commercialMarginPercentage = margin;
            prod.costPrice = this.costPrice;
            prod.multiplicity = this.multiplicity;
            prod.position = this.isFilled(this.products) ? this.products.length : 0
            allProducts.push(prod);

            console.log(JSON.stringify(allProducts));
            this.showIncludedProducts = true;
            this.addProduct = {};
            this.products = JSON.parse(JSON.stringify(allProducts));
            this.message = false

            this.showToast('success', 'Sucesso!', 'Produto incluído.');
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
                    let margin = this.isFilled(this.addProduct.practicedCost) ? this.fixDecimalPlaces(((1 - (Number(this.addProduct.practicedCost) / (Number(this.addProduct.totalPrice) / Number(this.addProduct.quantity)))) * 100)) : null;
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
        if (this.recalculatePrice) {
            this._verifyFieldsToSave();
            return this.addProduct.unitPrice;
        } else {
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
                let pushValue = true;
                if (this.isFilled(checkFields.quantity) && this.isFilled(checkFields.deliveryDate)) {
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
                if (filledDivisions[index].productPosition == this.productPosition) {
                    filledDivisions[index].orderItemKey = this.currentDivisionProduct.productId + '-' + this.fixDecimalPlaces(Number(this.currentDivisionProduct.quantity)) + '-' + this.fixDecimalPlaces(Number(this.currentDivisionProduct.unitPrice));
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
                this.editProduct(row.position, false);
            break;
            case 'shippingDivision':
                this.productDivision(row.position);
            break;
            case 'delete':
                this.deleteProduct(row.position);
            break;
        }
    }

    editProduct(position, recalculateFinancialValues) {
        this.productPosition = position;
        let currentProduct = this.products.find(e => e.position == position);
        console.log('currentProduct: ' + JSON.stringify(currentProduct));
        this.multiplicity = currentProduct.multiplicity;

        this.addProduct = {
            orderItemId: currentProduct.orderItemId,
            name: currentProduct.name,
            entryId: currentProduct.entryId,
            productId: currentProduct.productId,
            unity: currentProduct.unity,
            productGroupId: currentProduct.productGroupId,
            productGroupName: currentProduct.productGroupName,
            productSubgroupName: currentProduct.productSubgroupName,
            sapStatus: currentProduct.sapStatus,
            sapProductCode: currentProduct.sapProductCode,
            activePrinciple: currentProduct.activePrinciple,
            commercialDiscountPercentage: this.headerData.IsOrderChild ? '0%' : currentProduct.commercialDiscountPercentage,
            commercialAdditionPercentage: this.headerData.IsOrderChild ? '0%' : currentProduct.commercialAdditionPercentage,
            financialAdditionPercentage: this.headerData.IsOrderChild ? '0%' : currentProduct.financialAdditionPercentage,
            financialDecreasePercentage: this.headerData.IsOrderChild ? '0%' : currentProduct.financialDecreasePercentage,
            commercialDiscountValue: this.headerData.IsOrderChild ? 0 : currentProduct.commercialDiscountValue,
            commercialAdditionValue: this.headerData.IsOrderChild ? 0 : currentProduct.commercialAdditionValue,
            financialAdditionValue: this.headerData.IsOrderChild ? 0 : currentProduct.financialAdditionValue,
            financialDecreaseValue: this.headerData.IsOrderChild ? 0 : currentProduct.financialDecreaseValue,
            listPrice: currentProduct.listPrice,
            unitPrice: this.headerData.IsOrderChild ? currentProduct.listPrice : currentProduct.unitPrice,
            totalPrice: this.headerData.IsOrderChild ? this.fixDecimalPlaces((currentProduct.listPrice * currentProduct.quantity)) : currentProduct.totalPrice,
            costPrice: currentProduct.listCost,
            listCost: currentProduct.listCost,
            practicedCost: currentProduct.practicedCost,
            initialTotalValue: currentProduct.initialTotalValue,
            dosage: currentProduct.dosage,
            quantity: currentProduct.quantity,
            motherAvailableQuantity: currentProduct.motherAvailableQuantity,
            invoicedQuantity: currentProduct.invoicedQuantity,
            position: currentProduct.position
        }
        console.log('this.addProduct: ' + this.addProduct.listCost);
        console.log('this.addProduct: ' + JSON.stringify(this.addProduct));

        if (recalculateFinancialValues) {
            this.calculateFinancialInfos();
        } else {
            this.createNewProduct = !this.createNewProduct;
            this.updateProduct = !this.updateProduct;
        }
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
            showRed : availableQuantity < 0 ? true : false,
            dontAllowChange : this.isFilled(this.headerData.codigo_sap) ? true : false
        };

        console.log('this.currentDivisionProduct: ' + JSON.stringify(this.currentDivisionProduct));
        this.showProductDivision = !this.showProductDivision;

        if (!this.currentDivisionProduct.dontAllowChange) {
            this.newFields();
        }
    }

    deleteProduct(position) {
        let excludeProduct = JSON.parse(JSON.stringify(this.products));
        excludeProduct.splice(position, 1);
        this.products = JSON.parse(JSON.stringify(excludeProduct));

        if (this.products.length == 0) {
            this.showIncludedProducts = false;
        }

        this._setData();
        this.showToast('success', 'Produto removido!', '');
    }

    newFields() {
        let allDivisions = JSON.parse(JSON.stringify(this.divisionProducts));
        let divPosition = this.isFilled(allDivisions) ? allDivisions.length : 0;
        let deliveryId = 'deliveryId-' + divPosition;
        let quantityId = 'quantityId-' + divPosition;
        let orderItemKey = this.currentDivisionProduct.productId + '-' + this.fixDecimalPlaces(Number(this.currentDivisionProduct.quantity)) + '-' + this.fixDecimalPlaces(Number(this.currentDivisionProduct.unitPrice));
        
        allDivisions.push({productId: this.currentDivisionProduct.productId, deliveryDate: null, quantity: null, position: divPosition, deliveryId: deliveryId, quantityId: quantityId, orderItemKey: orderItemKey, productPosition: this.productPosition, showInfos: true});
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
        if (this.isFilled(prod.name) && this.isFilled(prod.listPrice) && this.isFilled(prod.unitPrice) &&
            this.isFilled(prod.totalPrice) && this.isFilled(prod.commercialDiscountPercentage) &&
            this.isFilled(prod.commercialDiscountValue) && this.isFilled(prod.commercialAdditionPercentage) &&
            this.isFilled(prod.commercialAdditionValue) && this.greaterThanZero(prod.dosage) && this.isFilled(prod.quantity)) {
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

    _setCommodityData() {
        const setHeaderData = new CustomEvent('setcommoditydata');
        setHeaderData.data = this.commoditiesData;
        this.dispatchEvent(setHeaderData);
    }

    showResults(event){
        this.showBaseProducts = event.showResults;
        this.baseProducts = event.results.recordsDataList;
        this.productsPriceMap = event.results.recordsDataMap;
        this.salesInfos = event.results.salesResult;
        this.message = this.baseProducts.length > 0 ? false : event.message;
    }

    openCommodities(event) {
        this.showCommodities = true;
        this.selectCommodityScreen = true;
        this.currentScreen = 'chooseCommodity';
        this.chooseCommodities = !this.chooseCommodities;
    }

    showCommodityResults(event){
        this.commodities = event.results.recordsDataList;
    }

    selectCommodity(event) {
        this.nextScreen();
        let totalProducts = 0;
        for (let index = 0; index < this.products.length; index++) {
            totalProducts += this.products[index].quantity;
        }

        let chooseCommodity = this.commodities.find(e => e.id == event.target.dataset.targetId);
        let marginPercent = (1 - this.products[0].commercialMarginPercentage) * 100;

        this.selectedCommodity = {
            id: chooseCommodity.Id,
            name: chooseCommodity.Name,
            cotation: chooseCommodity.listPrice,
            startDate: null,
            endDate: null,
            deliveryQuantity: this.fixDecimalPlaces((totalProducts / chooseCommodity.listPrice)) + ' sacas',
            ptax: chooseCommodity.productCurrency + chooseCommodity.listPrice,
            commodityPrice: chooseCommodity.listPrice,
            deliveryAddress: '',
            commission: 'R$' + ((chooseCommodity.commissionPercentage * totalProducts) / 100),
            totalMarginPercent: this.fixDecimalPlaces(marginPercent) + '%',
            totalMarginValue: this.fixDecimalPlaces(((this.products[0].totalPrice * marginPercent) / 100))
        };
    }

    fillCommodity(event) {
        this.summaryScreen = true;
        for (let index = 0; index < this.commoditiesData.length; index++) {
            if (this.commoditiesData[index].saved == false) {
                return;
            }
        }

        console.log('this.selectedCommodity: ' + JSON.stringify(this.selectedCommodity));
        this.commoditiesData.push({
            product: this.selectedCommodity.name,
            productId: this.selectedCommodity.id,
            commodityPrice: this.selectedCommodity.commodityPrice,
            desage: this.products[0].dosage,
            area: this.headerData.hectares,
            quantity: this.products[0].quantity,
            discount: 'R$' + this.products[0].commercialDiscountValue,
            margin: this.fixDecimalPlaces(this.products[0].commercialMarginPercentage),
            totalDelivery: this.selectedCommodity.deliveryQuantity,
            saved: false
        });
        console.log('this.commoditiesData: ' + JSON.stringify(this.commoditiesData));
    }

    closeCommodityModal(event) {
        console.log('this.commoditiesData.length: ' + this.commoditiesData.length);
        for (let index = 0; index < this.commoditiesData.length; index++) {
            console.log('event.target.dataset.targetId: ' + event.target.dataset.targetId);
            if (event.target.dataset.targetId == 'saveButton') {
                this.commoditiesData[index].saved = true;
                console.log('this.commoditiesData[index]: ' + JSON.stringify(this.commoditiesData[index]));
                this._setCommodityData();
            } else if (this.commoditiesData[index].saved == false) {
                this.commoditiesData.splice(index, 1);
            }
        }
        
        this.showCommodities = false;
        this.chooseCommodities = false;
        this.commoditySelected = false;
        this.summaryScreen = false;
        // this.haScreen = false;
    }

    commodityChange(event) {
        if (this.isFilled(event.target.value)) {
            this.selectedCommodity[event.target.dataset.targetId] = event.target.value;
        }
    }

    nextScreen(event) {
        this.selectCommodityScreen = false;
        this.chooseCommodities = false;
        this.commoditySelected = false;
        this.summaryScreen = false;
        // this.haScreen = false;

        this.currentScreen = this.commodityScreens[this.commodityScreens.indexOf(this.currentScreen) + 1];
        if (this.currentScreen == 'chooseCommodity') {this.selectCommodityScreen = true;this.chooseCommodities = true;}
        if (this.currentScreen == 'fillCommodity') this.commoditySelected = true;
        if (this.currentScreen == 'negotiationDetails') this.fillCommodity();
        // if (this.currentScreen == 'haScreen') this.haScreen = true;
    }

    backScreen(event) {
        this.selectCommodityScreen = false;
        this.commoditySelected = false;
        this.summaryScreen = false;
        // this.haScreen = false;

        this.currentScreen = this.commodityScreens[this.commodityScreens.indexOf(this.currentScreen) - 1];
        if (this.currentScreen == 'chooseCommodity') {this.selectCommodityScreen = true;this.chooseCommodities = true;}
        if (this.currentScreen == 'fillCommodity') this.commoditySelected = true;
        if (this.currentScreen == 'negotiationDetails') this.summaryScreen = true;
        // if (this.currentScreen == 'haScreen') this.haScreen = true;
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