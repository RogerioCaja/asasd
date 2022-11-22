import {
    LightningElement,
    api,
    track
} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isSeedSale from '@salesforce/apex/OrderScreenController.isSeedSale';
import getSafraInfos from '@salesforce/apex/OrderScreenController.getSafraInfos';
import getFinancialInfos from '@salesforce/apex/OrderScreenController.getFinancialInfos';
import getSpecificCombos from '@salesforce/apex/OrderScreenController.getSpecificCombos';
import checkQuotaQuantity from '@salesforce/apex/OrderScreenController.checkQuotaQuantity';
import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';
import getMixAndConditionCombos from '@salesforce/apex/OrderScreenController.getMixAndConditionCombos';
import fetchOrderRecords from '@salesforce/apex/CustomLookupController.fetchProductsRecords';

let actions = [];
let commodityActions = [{label: 'Excluir', name: 'delete'}];
export default class OrderProductScreen extends LightningElement {
    @track addProduct={};
    costPrice;
    multiplicity;
    listTotalPrice;
    productPosition;
    currentDate;
    @api seedSale;
    verifyQuota;
    allProductQuotas = [];

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
    selectedCompany;
    safraData={};
    paymentDate;
    hectares;
    salesConditionId;
    productParams={};
    productsPriceMap;
    salesInfos;
    hideChooseColumns = false;

    baseProducts = [];
    showBaseProducts = false;
    showArrows = false;
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
    
    showRoyaltyTsi = false;
    dontGetSeeds = false;
    selectCommodityScreen = false;
    // commodityScreens = ['chooseCommodity', 'fillCommodity', 'negotiationDetails', 'haScreen'];
    commodityScreens = ['chooseCommodity', 'fillCommodity', 'negotiationDetails'];
    currentScreen = 'chooseCommodity';
    
    commodities = [];
    showCommodityData = false;
    openCommoditiesData = false;
    // commoditiesData = [];
    chooseCommodities = false;
    showCommodities = false;
    commoditySelected = false;
    summaryScreen = false;
    commodityColumns = [
        {label: 'Produto', fieldName: 'product'},
        {label: 'Dose', fieldName: 'desage'},
        {label: 'Área', fieldName: 'area'},
        // {label: 'Quantidade', fieldName: 'quantity'},
        {label: 'Desconto', fieldName: 'discountFront'},
        {label: 'Margem', fieldName: 'marginFront'},
        {label: 'Entrega Total', fieldName: 'totalDeliveryFront'}
    ];
    visualizeCommodityColumns = [];

    disabled=false;
    disableSearch=false;
    unitPriceDisabled=false;
    numberOfRowsToSkip=0;
    showLoading=true;
    combosIds = [];
    comboProductsAndQuantities = [];

    combosData;
    showCombos=false;
    checkCombo=false;
    comboRowsToSkip=0;
    comboProducts = {
        formerIds: [],
        benefitsIds: []
    }

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
    @api childOrder;
    @api excludedItems;
    @api formsOfPayment;
    @api combosSelecteds;

    connectedCallback(event) {
        if (!this.isFilled(this.combosSelecteds)) this.combosSelecteds=[];
        
        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let yyyy = today.getFullYear();

        this.currentDate = yyyy + '-' + mm + '-' + dd;
        this.paymentDate = this.headerData.data_pagamento;
        this.hectares = this.headerData.hectares.toString().includes(',') ? Number(this.headerData.hectares.toString().replace(',', '.')) : Number(this.headerData.hectares);
        this.salesConditionId = this.headerData.condicao_venda.Id;
        this.commoditiesData = this.isFilled(this.commodityData) ? this.commodityData : [];
        this.barterSale = this.headerData.tipo_venda == 'Venda Barter' && this.commoditiesData.length == 0 ? true : false;

        if (this.cloneData.cloneOrder) {
            this.products = this.isFilled(this.productData) ? this.productData : [];
            this.allDivisionProducts = [];
        } else {
            this.products = this.isFilled(this.productData) ? this.productData : [];
            this.allDivisionProducts = this.isFilled(this.divisionData) ? this.divisionData : [];
        }
        
        let allProducts = JSON.parse(JSON.stringify(this.products));
        let newProducts = [];
        let combosIds = [];
        let comboProductsAndQuantities = [];
        for (let index = 0; index < allProducts.length; index++) {
            if (allProducts[index].comboId != null) {
                combosIds.push(allProducts[index].comboId);
                comboProductsAndQuantities.push(
                    {
                        combo: allProducts[index].comboId,
                        quantity: allProducts[index].quantity,
                        prodId: allProducts[index].productId,
                    }
                );
            }

            newProducts.push(this.newProduct(allProducts[index]));
        }

        this.products = JSON.parse(JSON.stringify(newProducts));
        this.combosIds = JSON.parse(JSON.stringify(combosIds));
        this.comboProductsAndQuantities = JSON.parse(JSON.stringify(comboProductsAndQuantities));

        if(this.headerData.IsOrderChild) {
            this.disableSearch = true;
            this._setData();
        }

        if (this.headerData.status_pedido == 'Em aprovação - Gerente Filial' || this.headerData.status_pedido == 'Em aprovação - Gerente Regional' ||
            this.headerData.status_pedido == 'Em aprovação - Diretor' || this.headerData.status_pedido == 'Em aprovação - Comitê Margem' || this.headerData.status_pedido == 'Em aprovação - Mesa de Grãos') {
            this.disabled = true;
            this.disableSearch = true;
            this.unitPriceDisabled = true;
        }

        if (this.isFilled(this.commoditiesData) && this.commoditiesData.length > 0) this.showCommodityData = true;
        this.visualizeCommodityColumns = JSON.parse(JSON.stringify(this.commodityColumns));
        this.visualizeCommodityColumns.push({
            type: 'action',
            typeAttributes: {
                rowActions: commodityActions,
                menuAlignment: 'auto'
            }
        });

        actions = [];
        if (this.disabled) actions.push({ label: 'Visualizar', name: 'visualize' })
        else if(this.headerData.IsOrderChild) actions.push({ label: 'Editar', name: 'edit' }, { label: 'Divisão de Remessas', name: 'shippingDivision' }, { label: 'Excluir', name: 'delete' });
        else if (this.headerData.pedido_mae_check) actions.push({ label: 'Editar', name: 'edit' }, { label: 'Excluir', name: 'delete' });
        else actions.push({ label: 'Editar', name: 'edit' }, { label: 'Divisão de Remessas', name: 'shippingDivision' }, { label: 'Excluir', name: 'delete' });

        this.showIncludedProducts = this.products.length > 0;
        if (this.headerData.tipo_venda == 'Venda Barter') {
            this.hideChooseColumns = true;
            let barterColumns = [
                {label: 'Produto', fieldName: 'name'},
                {label: 'Unidade de Medida', fieldName: 'unity'},
                {label: 'Qtd', fieldName: 'quantity'}
            ]

            barterColumns.push({
                type: 'action',
                typeAttributes: {
                    rowActions: actions,
                    menuAlignment: 'auto'
                }
            });
            this.columns = barterColumns;
            this.changeColumns = false;
        } else {
            this.applySelectedColumns(event);
        }

        this.headerData = JSON.parse(JSON.stringify(this.headerData));
        let getCompanyData = {
            ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
            accountId: this.accountData.Id != null ? this.accountData.Id : '',
            orderType: this.headerData.tipo_venda,
            approvalNumber: 1
        }

        if (!this.headerData.IsOrderChild && !this.isFilled(this.headerData.codigo_sap)) {
            this.getCombos();
        } else {
            this.getCompanies(getCompanyData);
        }
    }

    getCompanies(getCompanyData) {
        this.showLoading = true;
        getAccountCompanies({data: JSON.stringify(getCompanyData), isHeader: false, verifyUserType: false, priceScreen: false, childOrder: this.childOrder})
        .then((result) => {
            this.companyResult = JSON.parse(result).listCompanyInfos;
            if (this.headerData.companyId != null) {
                for (let index = 0; index < this.companyResult.length; index++) {
                    if (this.companyResult[index].companyId == this.headerData.companyId) {
                        this.selectedCompany = this.companyResult[index];
                        this.onSelectCompany();
                        break;
                    }
                }
            } else {
                if (this.companyResult.length == 0) {
                    this.showToast('warning', 'Atenção!', 'Não foi encontrado Área de Vendas no SAP. Contate o administrador do sistema.');
                    this.showLoading = false;
                } else if (this.companyResult.length == 1) {
                    this.selectedCompany = this.companyResult[0];
                    this.headerData.companyId = this.selectedCompany.companyId;
                    this.onSelectCompany();
                } else if (this.companyResult.length > 1) {
                    this.selectCompany = true;
                    this.showLoading = false;
                }
            }
        });
    }

    newProduct(currentProduct) {
        let tTotalPrice = this.headerData.IsOrderChild ? this.fixDecimalPlaces((currentProduct.tListPrice * currentProduct.quantity)) : (this.isFilled(currentProduct.tsiTotalPrice) ? currentProduct.tsiTotalPrice : 0)
        let rTotalPrice = this.headerData.IsOrderChild ? this.fixDecimalPlaces((currentProduct.rListPrice * currentProduct.quantity)) : (this.isFilled(currentProduct.royaltyTotalPrice) ? currentProduct.royaltyTotalPrice : 0)
        let newProduct = {
            orderItemId: currentProduct.orderItemId,
            name: currentProduct.name,
            entryId: currentProduct.entryId,
            productId: currentProduct.productId,
            unity: currentProduct.unity,
            productGroupId: currentProduct.productGroupId,
            productGroupName: currentProduct.productGroupName,
            productSubgroupName: currentProduct.productSubgroupName,
            productHierarchyId: currentProduct.productHierarchyId,
            sapStatus: currentProduct.sapStatus,
            sapProductCode: currentProduct.sapProductCode,
            activePrinciple: currentProduct.activePrinciple,
            commercialDiscountPercentage: currentProduct.commercialDiscountPercentage,
            commercialDiscountPercentageFront: this.headerData.IsOrderChild ? '0%' : this.fixDecimalPlacesPercentage(currentProduct.commercialDiscountPercentage),
            commercialAdditionPercentage: currentProduct.commercialAdditionPercentage,
            commercialAdditionPercentageFront: this.headerData.IsOrderChild ? '0%' : this.fixDecimalPlacesPercentage(currentProduct.commercialAdditionPercentage),
            financialAdditionPercentage: currentProduct.financialAdditionPercentage,
            financialAdditionPercentageFront: this.headerData.IsOrderChild ? '0%' : this.fixDecimalPlacesPercentage(currentProduct.financialAdditionPercentage),
            financialDecreasePercentage: currentProduct.financialDecreasePercentage,
            financialDecreasePercentageFront: this.headerData.IsOrderChild ? '0%' : this.fixDecimalPlacesPercentage(currentProduct.financialDecreasePercentage),
            commercialDiscountValue: currentProduct.commercialDiscountValue,
            commercialDiscountValueFront: this.headerData.IsOrderChild ? 0 : this.fixDecimalPlacesFront(currentProduct.commercialDiscountValue),
            commercialAdditionValue: currentProduct.commercialAdditionValue,
            commercialAdditionValueFront: this.headerData.IsOrderChild ? 0 : this.fixDecimalPlacesFront(currentProduct.commercialAdditionValue),
            financialAdditionValue: currentProduct.financialAdditionValue,
            financialAdditionValueFront: this.headerData.IsOrderChild ? 0 : this.fixDecimalPlacesFront(currentProduct.financialAdditionValue),
            financialDecreaseValue: currentProduct.financialDecreaseValue,
            financialDecreaseValueFront: this.headerData.IsOrderChild ? 0 : this.fixDecimalPlacesFront(currentProduct.financialDecreaseValue),
            listPrice: currentProduct.listPrice,
            listPriceFront: this.fixDecimalPlacesFront(currentProduct.listPrice),
            unitPrice: currentProduct.unitPrice,
            unitPriceFront: this.fixDecimalPlacesFront(currentProduct.unitPrice),
            totalPrice: this.headerData.IsOrderChild ? this.fixDecimalPlaces((currentProduct.unitPrice * currentProduct.quantity)) : currentProduct.totalPrice,
            totalPriceFront: this.headerData.IsOrderChild ? this.fixDecimalPlacesFront((currentProduct.unitPrice * currentProduct.quantity)) : this.fixDecimalPlacesFront(currentProduct.totalPrice),
            totalPriceWithBrokerage: this.headerData.IsOrderChild ? this.fixDecimalPlaces((currentProduct.unitPrice * currentProduct.quantity)) : currentProduct.totalPriceWithBrokerage,
            totalPriceWithBrokerageFront: this.headerData.IsOrderChild ? this.fixDecimalPlacesFront((currentProduct.unitPrice * currentProduct.quantity)) : this.fixDecimalPlacesFront(currentProduct.totalPriceWithBrokerage),
            costPrice: currentProduct.listCost,
            listCost: currentProduct.listCost,
            practicedCost: currentProduct.practicedCost,
            initialTotalValue: currentProduct.initialTotalValue,
            dosage: this.headerData.emptyHectar ? currentProduct.quantity : (this.isFilled(currentProduct.dosage) ? currentProduct.dosage : currentProduct.quantity / this.hectares),
            dosageFront: this.isFilled(currentProduct.dosage) ? this.fixDecimalPlacesFront(currentProduct.dosage) : '',
            brokerage: this.isFilled(currentProduct.brokerage) ? currentProduct.brokerage : 0,
            brokerageFront: this.isFilled(currentProduct.brokerage) ? this.fixDecimalPlacesFront(currentProduct.brokerage) : 0,
            quantity: currentProduct.quantity,
            motherAvailableQuantity: currentProduct.motherAvailableQuantity,
            invoicedQuantity: this.isFilled(currentProduct.invoicedQuantity) ? currentProduct.invoicedQuantity : 0,
            multiplicity: currentProduct.multiplicity,
            position: currentProduct.position,
            commercialMarginPercentage: currentProduct.commercialMarginPercentage,
            productSubgroupId: currentProduct.productSubgroupId,
            productSubgroupName: currentProduct.productSubgroupName,
            orderId: currentProduct.orderId,
            serviceDate: currentProduct.serviceDate,
            comissionValue: currentProduct.comissionValue,
            ptaProduct: currentProduct.ptaProduct,
            priceListCode: currentProduct.priceListCode,
            sieve: this.isFilled(currentProduct.sieve) ? currentProduct.sieve : '',
            productClass: this.isFilled(currentProduct.productClass) ? currentProduct.productClass : '',
            comboDiscountPercent: this.isFilled(currentProduct.comboDiscountPercent) ? currentProduct.comboDiscountPercent : '0%',
            comboDiscountValue: this.isFilled(currentProduct.comboDiscountValue) ? currentProduct.comboDiscountValue : 0,
            comboId: this.isFilled(currentProduct.comboId) ? currentProduct.comboId : null,
            industryCombo: this.isFilled(currentProduct.comboId) ? currentProduct.industryCombo : false,
            containsCombo: this.isFilled(currentProduct.containsCombo) ? currentProduct.containsCombo : false,
            tListPrice: this.isFilled(currentProduct.tListPrice) ? currentProduct.tListPrice : 0,
            tListPriceFront: this.isFilled(currentProduct.tListPrice) ? 'R$' + this.fixDecimalPlacesFront(currentProduct.tListPrice) : 'R$0',
            tsiTotalPrice: tTotalPrice,
            tsiTotalPriceFront: 'R$' + this.fixDecimalPlacesFront(tTotalPrice),
            rListPrice: this.isFilled(currentProduct.rListPrice) ? currentProduct.rListPrice : 0,
            rListPriceFront: this.isFilled(currentProduct.rListPrice) ? 'R$' + this.fixDecimalPlacesFront(currentProduct.rListPrice) : 'R$0',
            royaltyTotalPrice: rTotalPrice,
            royaltyTotalPriceFront: 'R$' + this.fixDecimalPlacesFront(rTotalPrice)
        };
        if (this.isFilled(newProduct.comboId)) {
            this.disabled = true;
            this.unitPriceDisabled = true;
        } else {
            this.disabled = false;
        }

        return newProduct;
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
        if (!this.isFilled(this.headerData.companyId)) {
            this.selectCompany = !this.selectCompany;
            this.headerData.companyId = this.selectedCompany.companyId;
        }
        this._setHeaderValues();
        
        isSeedSale({salesOrgId: this.selectedCompany.salesOrgId, productGroupName: null})
        .then((result) => {
            this.seedSale = result;
            
            if (this.isFilled(this.selectedCompany.activitySectorName) &&
                (this.selectedCompany.activitySectorName.toUpperCase() == 'SEMENTES' || this.selectedCompany.activitySectorName.toUpperCase() == 'SEMENTE')) {
                this.showRoyaltyTsi = result;
            }
            if (this.seedSale && this.isFilled(this.selectedCompany.activitySectorName) &&
                (this.selectedCompany.activitySectorName.toUpperCase() == 'INSUMOS' || this.selectedCompany.activitySectorName.toUpperCase() == 'INSUMO')) {
                this.dontGetSeeds = true;
            }

            this.productParams = {
                salesConditionId: this.headerData.condicao_venda.Id,
                accountId: this.accountData.Id,
                ctvId: this.headerData.ctv_venda.Id,
                safra: this.headerData.safra.Id,
                productCurrency: this.headerData.moeda,
                culture: this.headerData.cultura.Id,
                orderType: this.headerData.tipo_venda,
                supplierCenter: this.selectedCompany.supplierCenter,
                activitySectorName: this.selectedCompany.activitySectorName,
                salesOrgId: this.selectedCompany.salesOrgId != null ? this.selectedCompany.salesOrgId : '',
                salesOfficeId: this.selectedCompany.salesOfficeId != null ? this.selectedCompany.salesOfficeId : '',
                salesTeamId: this.selectedCompany.salesTeamId != null ? this.selectedCompany.salesTeamId : '',
                numberOfRowsToSkip: this.numberOfRowsToSkip,
                dontGetSeeds: this.isFilled(this.dontGetSeeds) ? this.dontGetSeeds : false
            };

            let prodsIds = [];
            for (let index = 0; index < this.products.length; index++) {
                prodsIds.push(this.products[index].productId);
            }

            let formerItens = [];
            let benefitItens = [];
            for (let index = 0; index < this.combosSelecteds.length; index++) {
                let currentCombo = this.combosSelecteds[index];
                if (this.isFilled(currentCombo)) {
                    for (let i = 0; i < currentCombo.formerItems.length; i++) {
                        formerItens.push({
                            productName: currentCombo.formerItems[i].productName,
                            productId: currentCombo.formerItems[i].productId,
                            productCode: currentCombo.formerItems[i].productCode,
                            minQUantity: currentCombo.formerItems[i].minQUantity,
                            discountPercentage: currentCombo.formerItems[i].discountPercentage,
                            comboId: currentCombo.formerItems[i].comboId,
                            comboQuantity: currentCombo.comboQuantity,
                            industryCombo: currentCombo.comboType == 'Indústria'
                        });
                        prodsIds.push(currentCombo.formerItems[i].productId);
                    }
    
                    for (let i = 0; i < currentCombo.benefitItems.length; i++) {
                        benefitItens.push({
                            productName: currentCombo.benefitItems[i].productName,
                            productId: currentCombo.benefitItems[i].productId,
                            productCode: currentCombo.benefitItems[i].productCode,
                            minQUantity: currentCombo.benefitItems[i].minQUantity,
                            discountPercentage: currentCombo.benefitItems[i].discountPercentage,
                            comboId: currentCombo.benefitItems[i].comboId,
                            comboQuantity: currentCombo.comboQuantity,
                            industryCombo: currentCombo.comboType == 'Indústria'
                        });
                        prodsIds.push(currentCombo.benefitItems[i].productId);
                    }
                }
            }

            if (this.seedSale && this.headerData.tipo_pedido != 'Pedido Filho' && !this.headerData.IsOrderChild) {
                this.verifyQuota = true;
                if (prodsIds.length > 0) {
                    let quoteData = {
                        cropId: this.headerData.safra.Id,
                        sellerId: this.headerData.ctv_venda.Id,
                        productsIds: prodsIds
                    };
            
                    if (this.verifyQuota) {
                        checkQuotaQuantity({data: JSON.stringify(quoteData)})
                        .then((result) => {
                            this.allProductQuotas = JSON.parse(result);
                        });
                    }
                }
            } else {
                this.verifyQuota = false;
            }

            if (this.isFilled(this.headerData.safra.Id)) {
                getSafraInfos({
                    safraId: this.headerData.safra.Id,
                    salesConditionId: this.salesConditionId,
                    salesOrgId: this.headerData.organizacao_vendas.Id
                })
                .then((result) => {
                    let safraResult = JSON.parse(result);
                    this.safraData = {
                        initialDate: safraResult.initialDate,
                        endDate: safraResult.endDateBilling
                    };

                    let orderData = {
                        paymentDate: this.headerData.data_pagamento != null ? this.headerData.data_pagamento : '',
                        salesOrg: this.selectedCompany.salesOrgId != null ? this.selectedCompany.salesOrgId : '',
                        salesOffice: this.selectedCompany.salesOfficeId != null ? this.selectedCompany.salesOfficeId : '',
                        salesTeam: this.selectedCompany.salesTeamId != null ? this.selectedCompany.salesTeamId : '',
                        salesCondition: this.salesConditionId != null ? this.salesConditionId : '',
                        safra: this.headerData.safra.Id != null ? this.headerData.safra.Id  : '',
                        culture: this.headerData.cultura.Id != null ? this.headerData.cultura.Id : ''
                    };

                    let allowChange = (this.headerData.tipo_pedido != 'Pedido Filho' && !this.headerData.IsOrderChild && this.isFilled(this.headerData.codigo_sap)) ||
                                    (this.headerData.tipo_pedido == 'Pedido Filho' && this.isFilled(this.headerData.codigo_sap)) ? false : true;
                            
                    if (this.headerData.pre_pedido && (allowChange || this.checkCombo)) {
                        fetchOrderRecords({
                            searchString: '',
                            data: JSON.stringify(this.productParams),
                            isCommodity: false,
                            productsIds: prodsIds,
                            priceScreen: false,
                            getSeedPrices: this.showRoyaltyTsi
                        })
                        .then(result => {
                            this.productsPriceMap = result.recordsDataMap;
                            this.salesInfos = result.salesResult;
                            let orderProducts = [];
                            let listPriceChange = false;
                            let productsWithoutPrice = '';
                            let itemToExclude = [];
                            let counter = 0;
                            let comboItens = [];
                            
                            for (let index = 0; index < formerItens.length; index++) {
                                let formerProductQuantity = formerItens[index].minQUantity * formerItens[index].comboQuantity;
                                let currentItem = this.products.find(e => e.productId == formerItens[index].productId)
                                
                                if (this.isFilled(currentItem)) {
                                    currentItem.quantity = formerProductQuantity;
                                    currentItem.dosage = formerProductQuantity / this.hectares;
                                    currentItem.dosageFront = this.fixDecimalPlacesFront(currentItem.dosage);
                                    comboItens.push(currentItem);

                                    for (let index = 0; index < this.products.length; index++) {
                                        if (currentItem.productId == formerItens[index].productId) {
                                            this.products.splice(index, 1);
                                        }
                                    }
                                } else {
                                    let comboValues = {
                                        dosage: formerProductQuantity / this.hectares,
                                        quantity: formerProductQuantity,
                                        comboDiscount: 0,
                                        comboId: formerItens[index].comboId,
                                        industryCombo: formerItens[index].industryCombo,
                                        containsCombo: true
                                    }
    
                                    let productInfos = this.getProductByPriority({Id: formerItens[index].productId});
                                    let priorityPrice = {
                                        listPrice: productInfos.listPrice,
                                        costPrice: productInfos.costPrice,
                                        priceListCode: productInfos.priceListCode
                                    };
                                    
                                    comboItens.push(this.createProduct(productInfos, priorityPrice, comboValues, counter));
                                    counter++;
                                }
                            }
                
                            for (let index = 0; index < benefitItens.length; index++) {
                                let benefitProductQuantity = benefitItens[index].minQUantity * benefitItens[index].comboQuantity;
                                let currentItem = this.products.find(e => e.productId == benefitItens[index].productId)
                                
                                if (this.isFilled(currentItem)) {
                                    currentItem.quantity = benefitProductQuantity;
                                    currentItem.dosage = benefitProductQuantity / this.hectares;
                                    currentItem.dosageFront = this.fixDecimalPlacesFront(currentItem.dosage);
                                    currentItem.comboDiscountPercent = benefitItens[index].discountPercentage + '%';
                                    comboItens.push(currentItem);

                                    for (let index = 0; index < this.products.length; index++) {
                                        if (currentItem.productId == benefitItens[index].productId) {
                                            this.products.splice(index, 1);
                                        }
                                    }
                                } else {
                                    let comboValues = {
                                        dosage: benefitProductQuantity / this.hectares,
                                        quantity: benefitProductQuantity,
                                        comboDiscount: benefitItens[index].discountPercentage,
                                        comboId: benefitItens[index].comboId,
                                        industryCombo: benefitItens[index].industryCombo,
                                        containsCombo: true
                                    }

                                    let productInfos = this.getProductByPriority({Id: benefitItens[index].productId});
                                    let priorityPrice = {
                                        listPrice: productInfos.listPrice,
                                        costPrice: productInfos.costPrice,
                                        priceListCode: productInfos.priceListCode
                                    };

                                    comboItens.push(this.createProduct(productInfos, priorityPrice, comboValues, counter));
                                    counter++;
                                }
                            }
                            comboItens.push.apply(comboItens, this.products);
                            this.products = JSON.parse(JSON.stringify(comboItens));

                            for (let index = 0; index < this.products.length; index++) {
                                this.addProduct = this.products[index];
                                let priorityInfos = this.getProductByPriority(this.addProduct);
                                
                                if (this.isFilled(priorityInfos)) {
                                    if (priorityInfos.listPrice != this.addProduct.listPrice || priorityInfos.costPrice != this.addProduct.listCost || this.checkCombo) {
                                        this.addProduct.listPrice = this.isFilled(priorityInfos.listPrice) ? this.fixDecimalPlaces(priorityInfos.listPrice) : 0;
                                        this.addProduct.listPriceFront = this.isFilled(priorityInfos.listPrice) ? this.fixDecimalPlacesFront(priorityInfos.listPrice) : 0;
                                        this.addProduct.listCost = this.isFilled(priorityInfos.costPrice) ? this.fixDecimalPlaces(priorityInfos.costPrice) : 0;
                                        this.addProduct.practicedCost = this.isFilled(priorityInfos.costPrice) ? this.fixDecimalPlaces(priorityInfos.costPrice) : 0;
                                        this.addProduct.priceListCode = priorityInfos.priceListCode;
                                        
                                        this.addProduct.tListPrice = this.isFilled(priorityInfos.tListPrice) ? priorityInfos.tListPrice : 0;
                                        this.addProduct.tListPriceFront = this.isFilled(priorityInfos.tListPrice) ? 'R$' + this.fixDecimalPlacesFront(priorityInfos.tListPrice) : 'R$0';
                                        
                                        this.addProduct.rListPrice = this.isFilled(priorityInfos.rListPrice) ? priorityInfos.rListPrice : 0;
                                        this.addProduct.rListPriceFront = this.isFilled(priorityInfos.rListPrice) ? 'R$' + this.fixDecimalPlacesFront(priorityInfos.rListPrice) : 'R$0';
                                        
                                        if (this.addProduct.commercialAdditionPercentage != '0%') {
                                            this.addProduct.unitPrice = this.addProduct.listPrice + this.calculateValue(this.addProduct.commercialAdditionPercentage, this.addProduct.listPrice);
                                        } else if (this.addProduct.commercialDiscountPercentage != '0%') {
                                            this.addProduct.unitPrice = this.addProduct.listPrice - this.calculateValue(this.addProduct.commercialDiscountPercentage, this.addProduct.listPrice);
                                        }
                                        this.addProduct.unitPriceFront = this.fixDecimalPlacesFront(this.addProduct.unitPrice);

                                        this.calculateDiscountOrAddition();
                                        this.calculateTotalPrice(true, this.addProduct.commercialDiscountValue > 0);

                                        let margin = this.isFilled(this.addProduct.practicedCost) ? this.fixDecimalPlaces((1 - (Number(this.addProduct.practicedCost) / (this.addProduct.totalPrice / this.addProduct.quantity))) * 100) : 0;
                                        this.addProduct.commercialMarginPercentage = margin;
                                        listPriceChange = true;
                                    }

                                    orderProducts.push(this.addProduct);
                                } else {
                                    productsWithoutPrice = productsWithoutPrice != '' ? productsWithoutPrice + ', ' + this.addProduct.name : this.addProduct.name;
                                    itemToExclude.push(this.addProduct.orderItemId)
                                }
                            }

                            this.products = JSON.parse(JSON.stringify(orderProducts));
                            this.showIncludedProducts = this.products.length > 0;
                            this.excludedItems = this.isFilled(this.excludedItems) ? this.excludedItems : JSON.parse(JSON.stringify(itemToExclude));
                            this._setExcludedesItems();
                            this._setData();
                            if (listPriceChange && !this.checkCombo) {
                                this.showToast('warning', 'Alteração na lista de preço!', 'Os preços foram ajustados de acordo com os valores da lista de preço. Verifique-os.');
                            }

                            if (productsWithoutPrice != '') {
                                this.showToast('warning', 'Produtos sem preço!', 'Os produtos ' + productsWithoutPrice + ' foram removidos do pedido.');
                            }
                        });
                    }

                    if (!this.headerData.IsOrderChild && allowChange) {
                        getFinancialInfos({data: JSON.stringify(orderData)})
                        .then((result) => {
                            console.log(JSON.stringify(result));
                            this.financialInfos = JSON.parse(result);
                            
                            if (this.products.length > 0) {
                                let showPriceChange = false;
                                let showQuantityChange = false;
                                let priceChangeMessage = '';
                                let currentProducts = this.products;
                                
                                for (let index = 0; index < currentProducts.length; index++) {
                                    this.recalculatePrice = true;
                                    this.editProduct(currentProducts[index].position, true);
                                    let oldQUantity = currentProducts[index].quantity;
                                    this.addProduct.quantity = this.calculateMultiplicity(this.addProduct.dosage * this.hectares, false);
                                    
                                    if (this.addProduct.quantity != oldQUantity) {
                                        showQuantityChange = true;
                                    }

                                    let oldPrice = currentProducts[index].unitPrice;
                                    this.calculateTotalPrice(true);
                                    let newPrice = this.changeProduct(this.addProduct);
                                    
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

                                if (showQuantityChange) {
                                    this.showToast('warning', 'Alteração nas quantidades!', 'As quantidades foram recalculados devido a alteração no hectar. Verifique-os.');
                                }

                                if ((showPriceChange || showQuantityChange) && this.headerData.tipo_venda == 'Venda Barter') {
                                    this.recalculateCommodities();
                                }
                                this.showLoading = false;
                            } else {
                                this.showLoading = false;
                            }

                            this._setData();
                        })
                    } else {
                        this.showLoading = false;
                    }
                    
                    if (!this.headerData.IsOrderChild && !this.isFilled(this.headerData.codigo_sap)) {
                        let headerValues = {
                            cropId: this.headerData.safra.Id,
                            salesOrgId: this.selectedCompany.salesOrgId,
                            salesTeamId: this.selectedCompany.salesTeamId,
                            salesOfficeId: this.selectedCompany.salesOfficeId,
                            salesConditionId: this.headerData.condicao_venda.Id
                        }

                        getMixAndConditionCombos({data: JSON.stringify(headerValues)})
                        .then((result) => {
                            let combosAndPromotions = JSON.parse(result);
                            if (combosAndPromotions.length > 0) {
                                this.combosData = combosAndPromotions;
                            }
                        });
                    }
                })
            } else {
                this.showLoading = false;
            }
        });
    }

    getProductByPriority(selectedProduct) {
        let priorityPrice = {
            costPrice: 0,
            listPrice: 0,
            priceListCode: 0,
            rCostPrice: 0,
            rListPrice: 0,
            rPriceListCode: 0,
            tCostPrice: 0,
            tListPrice: 0,
            tPriceListCode: 0
        };

        let productsPrice = this.productsPriceMap;
        let productId = this.isFilled(selectedProduct.Id) ? selectedProduct.Id : selectedProduct.productId;

        let counter = 1;
        let counterMax = this.showRoyaltyTsi ? 3 : 1;
        while (counter <= counterMax) {
            let prefix;
            if (counter == 1) prefix = 'G-';
            if (counter == 2) prefix = 'R-';
            if (counter == 3) prefix = 'T-';

            let key1 = prefix + this.accountData.Id + '-' + productId;
            let key2 = prefix + this.salesInfos.segmento + '-' + productId;
            let key3 = prefix + this.headerData.cultura.Id + '-' + this.salesInfos.salesTeamId + '-' + productId;
            let key4 = prefix + this.salesInfos.salesTeamId + '-' + productId;
            let key5 = prefix + this.salesInfos.salesOfficeId + '-' + productId;
            let key6 = prefix + selectedProduct.productGroupId;
            let key7 = prefix + productId;

            let currentPrice;
            if (this.isFilled(productsPrice[key1])) {
                currentPrice = productsPrice[key1];
            } else if (this.isFilled(productsPrice[key2])) {
                currentPrice = productsPrice[key2];
            } else if (this.isFilled(productsPrice[key3])) {
                currentPrice = productsPrice[key3];
            } else if (this.isFilled(productsPrice[key4])) {
                currentPrice = productsPrice[key4];
            } else if (this.isFilled(productsPrice[key5])) {
                currentPrice = productsPrice[key5];
            } else if (this.isFilled(productsPrice[key6])) {
                currentPrice = productsPrice[key6];
            } else if (this.isFilled(productsPrice[key7])) {
                currentPrice = productsPrice[key7];
            }

            if (this.isFilled(currentPrice)) {
                if (counter == 1) {
                    priorityPrice.costPrice = currentPrice.costPrice;
                    priorityPrice.listPrice = currentPrice.listPrice;
                    priorityPrice.priceListCode = currentPrice.priceListCode;
                } else if (counter == 2) {
                    priorityPrice.rCostPrice = currentPrice.costPrice;
                    priorityPrice.rListPrice = currentPrice.listPrice;
                    priorityPrice.rPriceListCode = currentPrice.priceListCode;
                } else if (counter == 3) {
                    priorityPrice.tCostPrice = currentPrice.costPrice;
                    priorityPrice.tListPrice = currentPrice.listPrice;
                    priorityPrice.tPriceListCode = currentPrice.priceListCode;
                }
            }
            
            counter++;
        }

        return priorityPrice;
    }

    showProductModal(event) {
        let productId = event.target.dataset.targetId;
        let productValidation = this.baseProducts.find(e => e.Id == productId);
        let quoteData = {
            cropId: this.headerData.safra.Id,
            sellerId: this.headerData.ctv_venda.Id,
            productsIds: [productValidation.Id]
        };

        if (this.verifyQuota) {
            this.showLoading = true;
            checkQuotaQuantity({data: JSON.stringify(quoteData)})
            .then((result) => {
                let allQuotas = JSON.parse(JSON.stringify(this.allProductQuotas));
                let productQuota = JSON.parse(result);

                let currentQuota;
                if (allQuotas.length > 0) {
                    currentQuota = allQuotas.find(e => e.individualQuotaId == productQuota.individualQuotaId);
                }
                
                if (!this.isFilled(currentQuota) && productQuota.length > 0) {
                    allQuotas.push(productQuota[0]);
                }
                this.allProductQuotas = JSON.parse(JSON.stringify(allQuotas));

                if (productQuota.length == 0 || productQuota[0].balance == 0) {
                    this.showLoading = false;
                    this.showToast('warning', 'Quantidade indisponível', 'Cota indisponível para o produto nos parâmetros atuais');
                } else {
                    this.showLoading = false;
                    this.openModalLogic(productValidation, productId);
                }
            });
        } else {
            this.openModalLogic(productValidation, productId);
        }
        
    }

    openModalLogic(productValidation, productId) {
        isSeedSale({salesOrgId: this.selectedCompany.salesOrgId, productGroupName: productValidation.productGroupName})
        .then((result) => {
            this.seedSale = result;
        });

        this.createNewProduct = !this.createNewProduct;

        if (this.createNewProduct) {
            let existProduct = this.products.find(e => e.productId == productId);

            if (this.isFilled(existProduct)) {
                this.createNewProduct = false;
                this.editProduct(existProduct.position, false);
            } else {
                console.log('this.baseProducts: ' + JSON.stringify(this.baseProducts));
                let currentProduct = this.baseProducts.find(e => e.Id == productId);
                let priorityInfos = this.getProductByPriority(currentProduct);
    
                this.multiplicity = this.isFilled(currentProduct.multiplicity) ? currentProduct.multiplicity : 1;
                this.costPrice = priorityInfos.costPrice;
                this.addProduct = this.createProduct(currentProduct, priorityInfos);
            }
        }
    }

    createProduct(currentProduct, priorityInfos, comboValues, counter) {
        let newProductData = {
            entryId: currentProduct.entryId,
            productId: currentProduct.Id,
            name: currentProduct.Name,
            unity: currentProduct.unity,
            listPrice: this.isFilled(priorityInfos.listPrice) ? this.fixDecimalPlaces(priorityInfos.listPrice) : 0,
            listPriceFront: this.isFilled(priorityInfos.listPrice) ? this.fixDecimalPlacesFront(priorityInfos.listPrice) : 0,
            listCost: this.isFilled(priorityInfos.costPrice) ? this.fixDecimalPlaces(priorityInfos.costPrice) : 0,
            practicedCost: this.isFilled(priorityInfos.costPrice) ? this.fixDecimalPlaces(priorityInfos.costPrice) : 0,
            dosage: this.isFilled(comboValues) ? comboValues.dosage : (this.isFilled(currentProduct.dosage) ? currentProduct.dosage : ''),
            dosageFront: this.isFilled(comboValues) ? comboValues.dosage : (this.isFilled(currentProduct.dosage) ? this.fixDecimalPlacesFront(currentProduct.dosage) : ''),
            brokerage: 0,
            brokerageFront: 0,
            quantity: this.isFilled(comboValues) ? comboValues.quantity : null,
            unitPrice: this.isFilled(priorityInfos.listPrice) ? this.fixDecimalPlaces(priorityInfos.listPrice) : 0,
            unitPriceFront: this.isFilled(priorityInfos.listPrice) ? this.fixDecimalPlacesFront(priorityInfos.listPrice) : 0,
            totalPrice: null,
            totalPriceFront: null,
            totalPriceWithBrokerage: null,
            totalPriceWithBrokerageFront: null,
            initialTotalValue: null,
            commercialDiscountPercentage: this.isFilled(comboValues) ? '0%' : null,
            commercialDiscountPercentageFront: this.isFilled(comboValues) ? '0%' : null,
            commercialDiscountValue: this.isFilled(comboValues) ? 0 : null,
            commercialDiscountValueFront: this.isFilled(comboValues) ? 0 : null,
            commercialAdditionPercentage: this.isFilled(comboValues) ? '0%' : null,
            commercialAdditionPercentageFront: this.isFilled(comboValues) ? '0%' : null,
            commercialAdditionValue: this.isFilled(comboValues) ? 0 : null,
            commercialAdditionValueFront: this.isFilled(comboValues) ? 0 : null,
            financialAdditionPercentage: this.isFilled(comboValues) ? '0%' : null,
            financialAdditionPercentageFront: this.isFilled(comboValues) ? '0%' : null,
            financialAdditionValue: this.isFilled(comboValues) ? 0 : null,
            financialAdditionValueFront: this.isFilled(comboValues) ? 0 : null,
            financialDecreasePercentage: this.isFilled(comboValues) ? '0%' : null,
            financialDecreasePercentageFront: this.isFilled(comboValues) ? '0%' : null,
            financialDecreaseValue: this.isFilled(comboValues) ? 0 : null,
            financialDecreaseValueFront: this.isFilled(comboValues) ? 0 : null,
            invoicedQuantity: this.isFilled(currentProduct.invoicedQuantity) ? currentProduct.invoicedQuantity : 0,
            motherAvailableQuantity: currentProduct.motherAvailableQuantity,
            activePrinciple: currentProduct.activePrinciple != null ? currentProduct.activePrinciple : '',
            productGroupId: currentProduct.productGroupId != null ? currentProduct.productGroupId : '',
            productGroupName: currentProduct.productGroupName != null ? currentProduct.productGroupName : '',
            productSubgroupName: currentProduct.productSubgroupName != null ? currentProduct.productSubgroupName : '',
            productHierarchyId: currentProduct.productHierarchyId != null ? currentProduct.productHierarchyId : '',
            sapStatus: currentProduct.sapStatus != null ? currentProduct.sapStatus : '',
            sapProductCode: currentProduct.sapProductCode != null ? currentProduct.sapProductCode : '',
            ptaProduct: currentProduct.ptaProduct,
            priceListCode: priorityInfos.priceListCode,
            sieve: this.isFilled(currentProduct.sieve) ? currentProduct.sieve : '',
            productClass: this.isFilled(currentProduct.productClass) ? currentProduct.productClass : '',
            comboDiscountPercent: this.isFilled(comboValues) ? comboValues.comboDiscount + '%' : '0%',
            comboDiscountValue: 0,
            comboId: this.isFilled(comboValues) ? comboValues.comboId : null,
            industryCombo: this.isFilled(comboValues) ? comboValues.industryCombo : false,
            position: this.isFilled(counter) ? counter : null,
            containsCombo: this.isFilled(comboValues) ? comboValues.containsCombo : (this.isFilled(currentProduct.containsCombo) ? currentProduct.containsCombo : false),
            tListPrice: this.isFilled(priorityInfos.tListPrice) ? priorityInfos.tListPrice : 0,
            tListPriceFront: this.isFilled(priorityInfos.tListPrice) ? 'R$' + this.fixDecimalPlacesFront(priorityInfos.tListPrice) : 'R$0',
            tsiTotalPrice: 0,
            tsiTotalPriceFront: 0,
            rListPrice: this.isFilled(priorityInfos.rListPrice) ? priorityInfos.rListPrice : 0,
            rListPriceFront: this.isFilled(priorityInfos.rListPrice) ? 'R$' + this.fixDecimalPlacesFront(priorityInfos.rListPrice) : 'R$0',
            royaltyTotalPrice: 0,
            royaltyTotalPriceFront: 0
        };
        if (this.isFilled(currentProduct.comboId)) {
            this.disabled = true;
            this.unitPriceDisabled = true;
        } else {
            this.disabled = false;
        }
        return newProductData;
    }

    changeTableColumns(event) {
        let field = event.target.dataset.targetId;
        this.selectedColumns[field] = this.isFilled(this.selectedColumns[field]) ? !this.selectedColumns[field] : true;
    }

    applySelectedColumns(event) {
        let selectedColumns = [{label: 'Produto', fieldName: 'name'}];
        if (this.isSelected(this.selectedColumns.columnUnity)) selectedColumns.push({label: 'Unidade de Medida', fieldName: 'unity'})
        if (this.isSelected(this.selectedColumns.columnListPrice)) selectedColumns.push({label: 'Preço Lista (un)', fieldName: 'listPriceFront'})
        if (this.isSelected(this.selectedColumns.columnDosage)) selectedColumns.push({label: 'Dosagem', fieldName: 'dosage'})
        if (this.isSelected(this.selectedColumns.columnBrokerage)) selectedColumns.push({label: 'Corretagem', fieldName: 'brokerage'})
        if (this.isSelected(this.selectedColumns.columnQuantity)) selectedColumns.push({label: 'Qtd', fieldName: 'quantity'})
        if (this.isSelected(this.selectedColumns.columnUnitPrice)) selectedColumns.push({label: 'Preço Praticado (un)', fieldName: 'unitPriceFront'})
        if (this.isSelected(this.selectedColumns.columnTotalPrice)) selectedColumns.push({label: 'Preço Total', fieldName: this.seedSale ? 'totalPriceWithBrokerageFront' : 'totalPriceFront'})
        if (this.isSelected(this.selectedColumns.columnCommercialDiscountPercentage)) selectedColumns.push({label: '% Desconto Comercial', fieldName: 'commercialDiscountPercentageFront'})
        if (this.isSelected(this.selectedColumns.columnCommercialDiscountValue)) selectedColumns.push({label: 'Valor de Desconto Comercial', fieldName: 'commercialDiscountValueFront'})
        if (this.isSelected(this.selectedColumns.columnCommercialAdditionPercentage)) selectedColumns.push({label: '% Acréscimo Comercial', fieldName: 'commercialAdditionPercentageFront'})
        if (this.isSelected(this.selectedColumns.columnCommercialAdditionValue)) selectedColumns.push({label: 'Valor de Acréscimo Comercial', fieldName: 'commercialAdditionValueFront'})
        if (this.isSelected(this.selectedColumns.columnFinancialAdditionPercentage)) selectedColumns.push({label: '% Acréscimo Financeiro', fieldName: 'financialAdditionPercentageFront'})
        if (this.isSelected(this.selectedColumns.columnFinancialAdditionValue)) selectedColumns.push({label: 'Valor de Acréscimo Financeiro', fieldName: 'financialAdditionValueFront'})
        if (this.isSelected(this.selectedColumns.columnFinancialDecreasePercentage)) selectedColumns.push({label: '% Decréscimo Financeiro', fieldName: 'financialDecreasePercentageFront'})
        if (this.isSelected(this.selectedColumns.columnFinancialDecreaseValue)) selectedColumns.push({label: 'Valor de Decréscimo Financeiro', fieldName: 'financialDecreaseValueFront'})
        if (this.isSelected(this.selectedColumns.columnInvoicedQuantity)) selectedColumns.push({label: 'Quantidade Faturada', fieldName: 'invoicedQuantity'})
        if (this.isSelected(this.selectedColumns.columnActivePrinciple)) selectedColumns.push({label: 'Princípio Ativo', fieldName: 'activePrinciple'})
        if (this.isSelected(this.selectedColumns.columnGroup)) selectedColumns.push({label: 'Grupo do Produto', fieldName: 'productGroupName'})
        if (this.isSelected(this.selectedColumns.columnproductSubgroupName)) selectedColumns.push({label: 'Subgrupo do Produto', fieldName: 'productSubgroupName'})
        if (this.isSelected(this.selectedColumns.columnSieve)) selectedColumns.push({label: 'Peneira', fieldName: 'sieve'})
        if (this.isSelected(this.selectedColumns.columnProductClass)) selectedColumns.push({label: 'Classe/Categoria', fieldName: 'productClass'})

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

    hideProductModal(){
        this.createNewProduct = !this.createNewProduct;
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
            fieldValue = fieldValue.toString().includes('.') ? fieldValue.toString().replace('.', '') : fieldValue;
            fieldValue = fieldValue.toString().includes(',') ? fieldValue.replace(',', '.') : fieldValue;
            this.addProduct[fieldId] = fieldValue;
            let priceWithFinancialValue = (this.addProduct.listPrice * this.addProduct.quantity) + Number(this.addProduct.financialAdditionValue) - Number(this.addProduct.financialDecreaseValue);

            if (fieldId == 'unitPrice') {
                this.recalculateValuesByUnitPrice();
                this.addProduct.unitPriceFront = this.fixDecimalPlacesFront(this.addProduct.unitPrice);
                this.calculateTotalPrice(false);
            } else if (fieldId == 'commercialDiscountPercentage') {
                this.addProduct.commercialDiscountPercentage = this.addProduct.commercialDiscountPercentage == '' ? '0%' : this.addProduct.commercialDiscountPercentage;
                this.addProduct.commercialDiscountPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialDiscountPercentage);
                this.addProduct.commercialDiscountValue = 
                    this.isFilled(priceWithFinancialValue) ?
                    this.calculateValue(this.addProduct.commercialDiscountPercentage, priceWithFinancialValue) :
                    this.addProduct.commercialDiscountValue;
                this.addProduct.commercialDiscountValueFront = this.fixDecimalPlacesFront(Number(this.addProduct.commercialDiscountValue));
                
                this.calculateTotalPrice(true, true);
            } else if (fieldId == 'commercialDiscountValue') {
                this.addProduct.commercialDiscountValue = this.addProduct.commercialDiscountValue == '' ? 0 : this.fixDecimalPlaces(Number(this.addProduct.commercialDiscountValue));
                this.addProduct.commercialDiscountValueFront = this.addProduct.commercialDiscountValue == '' ? 0 : this.fixDecimalPlacesFront(Number(this.addProduct.commercialDiscountValue));
                this.addProduct.commercialDiscountPercentage = 
                    this.isFilled(priceWithFinancialValue) ?
                    this.calculatePercentage(this.addProduct.commercialDiscountValue, priceWithFinancialValue) :
                    this.addProduct.commercialDiscountPercentage;
                this.addProduct.commercialDiscountPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialDiscountPercentage);
                
                this.calculateTotalPrice(true, true);
            } else if (fieldId == 'commercialAdditionPercentage') {
                this.addProduct.commercialAdditionPercentage = this.addProduct.commercialAdditionPercentage == '' ? '0%' : this.addProduct.commercialAdditionPercentage;
                this.addProduct.commercialAdditionPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialAdditionPercentage);
                this.addProduct.commercialAdditionValue = 
                    this.isFilled(priceWithFinancialValue) ?
                    this.calculateValue(this.addProduct.commercialAdditionPercentage, priceWithFinancialValue) :
                    this.addProduct.commercialAdditionValue;
                this.addProduct.commercialAdditionValueFront = this.fixDecimalPlacesFront(Number(this.addProduct.commercialAdditionValue));
                
                this.calculateTotalPrice(true, false);
            } else if (fieldId == 'commercialAdditionValue') {
                this.addProduct.commercialAdditionValue = this.addProduct.commercialAdditionValue == '' ? 0 : this.fixDecimalPlaces(Number(this.addProduct.commercialAdditionValue));
                this.addProduct.commercialAdditionValueFront = this.addProduct.commercialAdditionValue == '' ? 0 : this.fixDecimalPlacesFront(Number(this.addProduct.commercialAdditionValue));
                this.addProduct.commercialAdditionPercentage = 
                    this.isFilled(priceWithFinancialValue) ?
                    this.calculatePercentage(this.addProduct.commercialAdditionValue, priceWithFinancialValue) :
                    this.addProduct.commercialAdditionPercentage;
                this.addProduct.commercialAdditionPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialAdditionPercentage);
                
                this.calculateTotalPrice(true, false);
            } else if (fieldId == 'dosage') {
                if (this.isFilled(this.hectares)) {
                    this.addProduct.dosageFront = this.fixDecimalPlacesFront(this.addProduct.dosage);
                    this.addProduct.quantity = this.calculateMultiplicity(this.addProduct.dosage * this.hectares, false);
                    this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                    this.calculateDiscountOrAddition();
                    this.calculateTotalPrice(true);
                }
            } else if (fieldId == 'brokerage'){

                this.addProduct.brokerageFront = this.fixDecimalPlacesFront(this.addProduct.brokerage);
                this.calculateTotalPrice(true);

            } else if (fieldId == 'quantity') {
                this.addProduct.quantity = this.calculateMultiplicity(this.addProduct.quantity, false);
                if (!this.headerData.IsOrderChild) {
                    this.addProduct.dosage = this.isFilled(this.hectares) ? this.addProduct.quantity / this.hectares : 0;
                    this.addProduct.dosageFront = this.fixDecimalPlacesFront(this.addProduct.dosage);
                    this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                    this.calculateDiscountOrAddition();
                    this.calculateTotalPrice(true);
                } else {
                    this.addProduct.totalPrice = this.fixDecimalPlaces((this.addProduct.unitPrice * this.addProduct.quantity));
                    this.addProduct.totalPriceFront = this.fixDecimalPlacesFront((this.addProduct.unitPrice * this.addProduct.quantity));

                    if (this.seedSale) {
                        this.addProduct.totalPriceWithBrokerage = Number(this.addProduct.totalPrice) + Number(this.addProduct.brokerage);
                        this.addProduct.totalPriceWithBrokerageFront = this.fixDecimalPlacesFront(this.addProduct.totalPriceWithBrokerage);
                        this.addProduct.tsiTotalPrice = this.addProduct.tListPrice * this.addProduct.quantity;
                        this.addProduct.tsiTotalPriceFront = this.fixDecimalPlacesFront(this.addProduct.tsiTotalPrice);
                        this.addProduct.royaltyTotalPrice = this.addProduct.rListPrice * this.addProduct.quantity;
                        this.addProduct.royaltyTotalPriceFront = this.fixDecimalPlacesFront(this.addProduct.royaltyTotalPrice);
                    }
                }
            }
        }
    }

    calculateMultiplicity(quantity, isDivision) {
        if (this.isFilled(this.multiplicity)) {
            let remainder = (quantity * 100) % (this.multiplicity * 100);
            if (isDivision && quantity > this.currentDivisionProduct.availableQuantity) {
                this.showToast('warning', 'Atenção!', 'A quantidade não pode ultrapassar ' + this.currentDivisionProduct.availableQuantity + '.');
                return this.currentDivisionProduct.availableQuantity;
            } else if (!isDivision && this.headerData.IsOrderChild && this.addProduct.motherAvailableQuantity != null && quantity > this.addProduct.motherAvailableQuantity) {
                this.showToast('warning', 'Atenção!', 'A quantidade não pode ultrapassar ' + this.addProduct.motherAvailableQuantity + '.');
                return this.addProduct.motherAvailableQuantity;
            }

            if (remainder == 0) {
                return quantity;
            } else {
                quantity = this.fixDecimalPlacesFront(quantity);
                quantity = quantity.toString().includes(',') ? Number(quantity.replace(',', '.')) : quantity;
                quantity = Math.ceil(quantity / this.multiplicity) * this.multiplicity;
                this.showToast('warning', 'Atenção!', 'A quantidade foi arredondada para ' + quantity + '.');
                return quantity;
            }
        }
    }

    calculateTotalPrice(recalculateUnitPrice, isDiscount) {
        this.addProduct.totalPrice = null;
        this.addProduct.totalPriceWithBrokerage = null;

        this.addProduct.tsiTotalPrice = this.addProduct.tListPrice * this.addProduct.quantity;
        this.addProduct.tsiTotalPriceFront = this.fixDecimalPlacesFront(this.addProduct.tsiTotalPrice);
        this.addProduct.royaltyTotalPrice = this.addProduct.rListPrice * this.addProduct.quantity;
        this.addProduct.royaltyTotalPriceFront = this.fixDecimalPlacesFront(this.addProduct.royaltyTotalPrice);

        if (this.isFilled(isDiscount)) {
            if (isDiscount && this.addProduct.commercialDiscountValue > 0) {
                this.addProduct.commercialAdditionValue = 0;
                this.addProduct.commercialAdditionValueFront = 0;
                this.addProduct.commercialAdditionPercentage = '0%';
                this.addProduct.commercialAdditionPercentageFront = '0%';
            } else if (!isDiscount && this.addProduct.commercialAdditionValue > 0) {
                this.addProduct.commercialDiscountValue = 0;
                this.addProduct.commercialDiscountValueFront = 0;
                this.addProduct.commercialDiscountPercentage = '0%';
                this.addProduct.commercialDiscountPercentageFront = '0%';
            }
        }

        if (this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.listPrice)) {
            let inicialTotalPrice = this.addProduct.quantity * this.addProduct.listPrice;

            if (!this.isFilled(this.addProduct.initialTotalValue)) {
                this.addProduct.initialTotalValue = this.fixDecimalPlaces(inicialTotalPrice);
                this.calculateFinancialInfos();
                this.addProduct.initialTotalValue = this.fixDecimalPlaces(this.addProduct.totalPrice);
            } else {
                this.addProduct.totalPrice = this.addProduct.quantity * this.addProduct.listPrice;
                this.addProduct.financialAdditionValue = this.calculateValue(this.addProduct.financialAdditionPercentage, this.addProduct.totalPrice);
                this.addProduct.financialAdditionValueFront = this.fixDecimalPlacesFront(this.addProduct.financialAdditionValue);
                this.addProduct.financialDecreaseValue = this.calculateValue(this.addProduct.financialDecreasePercentage, this.addProduct.totalPrice);
                this.addProduct.financialDecreaseValueFront = this.fixDecimalPlacesFront(this.addProduct.financialDecreaseValue);
            }
            
            this.addProduct.totalPrice = this.isFilled(this.addProduct.financialAdditionValue) ? (this.addProduct.totalPrice + Number(this.addProduct.financialAdditionValue)) : this.addProduct.totalPrice;
            this.addProduct.totalPrice = this.isFilled(this.addProduct.financialDecreaseValue) ? (this.addProduct.totalPrice - Number(this.addProduct.financialDecreaseValue)) : this.addProduct.totalPrice;
            
            if (this.addProduct.comboDiscountPercent != '0%') {
                this.addProduct.comboDiscountValue = this.calculateValue(this.addProduct.comboDiscountPercent, this.addProduct.totalPrice);
                this.addProduct.totalPrice = this.isFilled(this.addProduct.comboDiscountValue) ? (this.addProduct.totalPrice - Number(this.addProduct.comboDiscountValue)) : this.addProduct.totalPrice;
            } else {
                this.addProduct.totalPrice = this.isFilled(this.addProduct.commercialAdditionValue) ? (this.addProduct.totalPrice + Number(this.addProduct.commercialAdditionValue)) : this.addProduct.totalPrice;
                this.addProduct.totalPrice = this.isFilled(this.addProduct.commercialDiscountValue) ? this.fixDecimalPlaces((this.addProduct.totalPrice - Number(this.addProduct.commercialDiscountValue))) : this.fixDecimalPlaces(this.addProduct.totalPrice);
            }
            
            this.addProduct.totalPriceFront = this.fixDecimalPlacesFront(this.addProduct.totalPrice);
            this.addProduct.totalPriceWithBrokerage = Number(this.addProduct.totalPrice) + Number(this.addProduct.brokerage);
            this.addProduct.totalPriceWithBrokerageFront = this.fixDecimalPlacesFront(this.addProduct.totalPriceWithBrokerage);
            
            if (recalculateUnitPrice) {
                this.addProduct.unitPrice = this.fixDecimalPlaces((this.addProduct.totalPrice / this.addProduct.quantity));
                this.addProduct.unitPriceFront = this.fixDecimalPlacesFront((this.addProduct.totalPrice / this.addProduct.quantity));
            }
        }
    }

    calculateDiscountOrAddition() {
        if (this.isFilled(this.addProduct.listPrice) && this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.unitPrice)) {
            this.addProduct.commercialAdditionValue = this.isFilled(this.addProduct.commercialAdditionValue) ? this.addProduct.commercialAdditionValue : '0';
            this.addProduct.commercialAdditionValueFront = this.fixDecimalPlacesFront(this.addProduct.commercialAdditionValue);
            this.addProduct.commercialDiscountValue = this.isFilled(this.addProduct.commercialDiscountValue) ? this.addProduct.commercialDiscountValue : '0';
            this.addProduct.commercialDiscountValueFront = this.fixDecimalPlacesFront(this.addProduct.commercialDiscountValue);

            this.addProduct.commercialAdditionPercentage = this.isFilled(this.addProduct.commercialAdditionPercentage) ? this.addProduct.commercialAdditionPercentage : '0%';
            this.addProduct.commercialAdditionPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialAdditionPercentage);
            this.addProduct.commercialDiscountPercentage = this.isFilled(this.addProduct.commercialDiscountPercentage) ? this.addProduct.commercialDiscountPercentage : '0%';
            this.addProduct.commercialDiscountPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialDiscountPercentage);
            let currentPrice = this.addProduct.unitPrice * this.addProduct.quantity;
            this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
            
            if (this.isFilled(currentPrice) && this.addProduct.unitPrice > this.addProduct.listPrice) {
                this.addProduct.commercialAdditionValue = this.calculateValue(this.addProduct.commercialAdditionPercentage, this.listTotalPrice);
                this.addProduct.commercialAdditionValueFront = this.fixDecimalPlacesFront(this.addProduct.commercialAdditionValue);
            } else if (this.isFilled(currentPrice) && this.addProduct.unitPrice < this.addProduct.listPrice) {
                this.addProduct.commercialDiscountValue = this.calculateValue(this.addProduct.commercialDiscountPercentage, this.listTotalPrice);
                this.addProduct.commercialDiscountValueFront = this.fixDecimalPlacesFront(this.addProduct.commercialDiscountValue);
            }
        }
    }

    recalculateValuesByUnitPrice() {
        if (this.isFilled(this.addProduct.listPrice) && this.isFilled(this.addProduct.quantity) && this.isFilled(this.addProduct.unitPrice)) {
            let currentPrice = this.addProduct.unitPrice * this.addProduct.quantity;
            let totalPrice = Number(this.addProduct.totalPrice) - Number(this.addProduct.commercialAdditionValue) + Number(this.addProduct.commercialDiscountValue);

            this.addProduct.commercialAdditionValue = 0;
            this.addProduct.commercialAdditionValueFront = 0;
            this.addProduct.commercialAdditionPercentage = '0%';
            this.addProduct.commercialAdditionPercentageFront = '0%';
            this.addProduct.commercialDiscountValue = 0;
            this.addProduct.commercialDiscountValueFront = 0;
            this.addProduct.commercialDiscountPercentage = '0%';
            this.addProduct.commercialDiscountPercentageFront = '0%';
            
            if (this.isFilled(currentPrice) && Number(currentPrice) > Number(totalPrice)) {
                this.addProduct.commercialAdditionValue = this.fixDecimalPlaces((currentPrice - totalPrice));
                this.addProduct.commercialAdditionValueFront = this.fixDecimalPlacesFront((currentPrice - totalPrice));
                this.addProduct.commercialAdditionPercentage = this.calculatePercentage(this.addProduct.commercialAdditionValue, totalPrice);
                this.addProduct.commercialAdditionPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialAdditionPercentage);
            } else if (this.isFilled(currentPrice) && Number(currentPrice) < Number(totalPrice)) {
                this.addProduct.commercialDiscountValue = this.fixDecimalPlaces((totalPrice - currentPrice));
                this.addProduct.commercialDiscountValueFront = this.fixDecimalPlacesFront((totalPrice - currentPrice));
                this.addProduct.commercialDiscountPercentage = this.calculatePercentage(this.addProduct.commercialDiscountValue, totalPrice);
                this.addProduct.commercialDiscountPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialDiscountPercentage);
            }
        }
    }

    fixDecimalPlacesFront(value, frontOrigin) {
        let formatNumber = new Intl.NumberFormat('de-DE').format(Number(Math.round(value + 'e' + 2) + 'e-' + 2));
        return formatNumber;
    }

    fixDecimalPlacesPercentage(value) {
        value = value.toString().includes(',') ? value.toString().replace(',', '.') : value.toString();
        value = value.includes('%') ? Number(value.replace('%', '')) : Number(value);
        return Number(Math.round(value + 'e' + 2) + 'e-' + 2).toString().replace('.', ',') + '%';
    }

    fixDecimalPlaces(value) {
        return (+(Math.trunc(+(value + 'e' + 6)) + 'e' + -6)).toFixed(6);
    }

    calculatePercentage(valueToBeCalculated, total) {
        let percentageValue = this.fixDecimalPlaces(((valueToBeCalculated * 100) / total)) + '%';
        percentageValue = percentageValue.includes('.') ? percentageValue.replace('.', ',') : percentageValue;
        return percentageValue;
    }

    calculateValue(percentage, total) {
        percentage = percentage.includes(',') ? percentage.replace(',', '.').replace('%', '') : percentage.replace('%', '');
        percentage = percentage != '' ? percentage : 0;
        let value = this.fixDecimalPlaces(((parseFloat(percentage) / 100) * total));
        return value;
    }

    calculateFinancialInfos() {
        this.addProduct.totalPrice = this.addProduct.quantity * this.addProduct.listPrice;
        if (this.isFilled(this.addProduct.totalPrice) && this.isFilled(this.financialInfos)) {
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
            this.addProduct.financialAdditionPercentageFront = this.financialInfos.correctPayment ? '0%' : this.fixDecimalPlacesFront(((this.financialInfos.isDiscount ? 0 : currentDiscountOrAddition))) + '%';
            this.addProduct.financialDecreasePercentage = this.financialInfos.correctPayment ? '0%' : this.fixDecimalPlaces(((this.financialInfos.isDiscount ? currentDiscountOrAddition : 0))) + '%';
            this.addProduct.financialDecreasePercentageFront = this.financialInfos.correctPayment ? '0%' : this.fixDecimalPlacesFront(((this.financialInfos.isDiscount ? currentDiscountOrAddition : 0))) + '%';
            this.addProduct.financialAdditionValue = this.calculateValue(this.addProduct.financialAdditionPercentage, totalValue);
            this.addProduct.financialAdditionValueFront = this.fixDecimalPlacesFront(this.addProduct.financialAdditionValue);
            this.addProduct.financialDecreaseValue = this.calculateValue(this.addProduct.financialDecreasePercentage, totalValue);
            this.addProduct.financialDecreaseValueFront = this.fixDecimalPlacesFront(this.addProduct.financialDecreaseValue);
            
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

        if (this.verifyQuota) {
            let availableQuota = this.verifyProductQuota(prod);
            if (!availableQuota) return;
        }

        if (this.checkRequiredFields(prod)) {
            let allProducts = JSON.parse(JSON.stringify(this.products));
            let margin = this.isFilled(this.addProduct.practicedCost) ? this.fixDecimalPlaces((1 - (Number(this.addProduct.practicedCost) / (prod.totalPrice / prod.quantity))) * 100) : 0;
            let comboDiscountPercent = this.verifyComboAndPromotion(prod.quantity);
            
            if (prod.commercialDiscountPercentageFront == '0%' && prod.comboDiscountPercent == '0%' && comboDiscountPercent != null) {
                prod.comboId = comboDiscountPercent.comboId;
                prod.comboDiscountPercent = comboDiscountPercent.discount + '%';
                prod.comboDiscountValue = this.calculateValue(comboDiscountPercent.discount + '%', prod.totalPrice);
                prod.totalPrice = prod.totalPrice - prod.comboDiscountValue;
                prod.totalPriceFront = this.fixDecimalPlacesFront(prod.totalPrice);
                prod.industryCombo = comboDiscountPercent.industryCombo;
                prod.unitPrice = this.fixDecimalPlaces(prod.totalPrice / prod.quantity);
                prod.unitPriceFront = this.fixDecimalPlacesFront(prod.unitPrice);
                prod.containsCombo = true;
                
                let allCombos = JSON.parse(JSON.stringify(this.combosSelecteds));
                let currentCombo = allCombos.find(e => e.comboId == comboDiscountPercent.comboId);
                if (this.isFilled(currentCombo)) {
                    currentCombo.productQuantity = prod.quantity;
                } else {
                    allCombos.push({
                        comboId: comboDiscountPercent.comboId,
                        comboQuantity: comboDiscountPercent.comboQuantity,
                        productQuantity: prod.quantity,
                        productId: prod.productId,
                        specificItemCombo: false
                    })
                }
                this.combosSelecteds = JSON.parse(JSON.stringify(allCombos));
                this._setcombosSelecteds();
            }

            prod.commercialMarginPercentage = margin;
            prod.costPrice = this.costPrice;
            prod.multiplicity = this.multiplicity;
            prod.position = this.isFilled(this.products) ? this.products.length : 0
            allProducts.push(prod);

            console.log(JSON.stringify(allProducts));
            this.showIncludedProducts = true;
            this.addProduct = {};
            this.products = JSON.parse(JSON.stringify(allProducts));
            this.message = false;

            this.showToast('success', 'Sucesso!', 'Produto incluído.');
            this._verifyFieldsToSave();

            this.createNewProduct = !this.createNewProduct;
        } else {
            this.showToast('error', 'Atenção!', 'Campos obrigatórios não preenchidos.');
        }
        
        this.recalculateCommodities();
    }

    verifyComboAndPromotion(quantity) {
        if (this.isFilled(this.combosData)) {
            let combos = JSON.parse(JSON.stringify(this.combosData));
            for (let index = 0; index < combos.length; index++) {
                let groupsData = combos[index].groupQuantities;
                
                if (this.isFilled(groupsData)) {
                    let productGroupCombo = groupsData.find(e => e.productGroupId == this.addProduct.productGroupId);
                    if (this.isFilled(productGroupCombo) && quantity >= productGroupCombo.quantity && combos[index].recTypeDevName == 'ProductMix') {
                        return {
                            discount: combos[index].comboDiscountPercentage,
                            comboId: combos[index].comboId,
                            industryCombo: combos[index].comboType.comboType == 'Indústria',
                            comboQuantity: Math.floor(quantity / productGroupCombo.quantity)
                        };
                    }
                }
            }

            let paymentConditionCombo = combos.find(e => e.paymentConditionId == this.headerData.condicao_pagamento.Id);
            if (this.isFilled(paymentConditionCombo) && paymentConditionCombo.recTypeDevName == 'PaymentCondition') {
                return {
                    discount: paymentConditionCombo.comboDiscountPercentage,
                    comboId: paymentConditionCombo.comboId,
                    industryCombo: paymentConditionCombo.comboType.comboType == 'Indústria',
                    comboQuantity: 1
                };
            }
        }

        return null;
    }

    changeComboQuantity(event) {
        let combos = JSON.parse(JSON.stringify(this.combosData));
        let value = Number(event.target.value);

        for (let index = 0; index < combos.length; index++) {
            if (combos[index].comboId == event.target.dataset.targetId) {
                if (value < 0) {
                    combos[index].comboQuantity = 0;
                    this.showToast('warning', 'Atenção!', 'Não é possível selecionar uma quantidade abaixo de 0.');
                } else if (value > combos[index].comboAvailableQuantity) {
                    combos[index].comboQuantity = combos[index].comboAvailableQuantity;
                    this.showToast('warning', 'Atenção!', 'A quantidade de combos disponível é de ' + combos[index].comboAvailableQuantity + '.');
                } else {
                    combos[index].comboQuantity = value;
                }
                this.changeSelectedComboData(combos[index]);
            }
        }
        this.combosData = JSON.parse(JSON.stringify(combos));
    }

    addOne(event) {
        this.incrementCombo(event.target.dataset.targetId, true);
    }

    lessOne(event) {
        this.incrementCombo(event.target.dataset.targetId, false);
    }

    incrementCombo(comboId, addOne) {
        let combos = JSON.parse(JSON.stringify(this.combosData));
        for (let index = 0; index < combos.length; index++) {
            if (combos[index].comboId == comboId) {
                if (!addOne && combos[index].comboQuantity == 0) this.showToast('warning', 'Atenção!', 'Não é possível selecionar uma quantidade abaixo de 0.');
                else if (addOne && combos[index].comboQuantity == combos[index].comboAvailableQuantity) this.showToast('warning', 'Atenção!', 'A quantidade de combos disponível é de ' + combos[index].comboAvailableQuantity + '.');
                else combos[index].comboQuantity = addOne ? combos[index].comboQuantity + 1 : combos[index].comboQuantity - 1;

                this.changeSelectedComboData(combos[index]);
                break;
            }
        }
        this.combosData = JSON.parse(JSON.stringify(combos));
    }

    changeSelectedComboData(combo) {
        let allCombosSelecteds = JSON.parse(JSON.stringify(this.combosSelecteds));
        let constainsCombo = allCombosSelecteds.find(e => e.comboId == combo.comboId);
        if (this.isFilled(constainsCombo)) {
            for (let i = 0; i < allCombosSelecteds.length; i++) {
                if (allCombosSelecteds[i].comboId == combo.comboId) {
                    allCombosSelecteds[i].comboQuantity = combo.comboQuantity;
                }
            }                
        } else {
            allCombosSelecteds.push(combo);
        }

        this.combosSelecteds = JSON.parse(JSON.stringify(allCombosSelecteds));
        this._setcombosSelecteds();
    }

    verifyProductQuota(actualProduct) {
        let allQuotas = JSON.parse(JSON.stringify(this.allProductQuotas));
        let currentQuota = allQuotas.find(e => e.productId == actualProduct.productId);
        if (Number(actualProduct.quantity) > Number(currentQuota.balance)) {
            this.showToast('warning', 'Atenção!', 'Você inseriu a quantidade ' + actualProduct.quantity + '. Existem apenas ' + currentQuota.balance + ' do item ' + actualProduct.name + ' disponíveis para venda.');
            return false;
        } else {
            return true;
        }
    }

    changeProduct() {
        let includedProducts = JSON.parse(JSON.stringify(this.products));
        for (let index = 0; index < includedProducts.length; index++) {
            if (includedProducts[index].position == this.productPosition) {
                if (this.checkRequiredFields(this.addProduct)) {
                    if (this.verifyQuota) {
                        let availableQuota = this.verifyProductQuota(this.addProduct);
                        if (!availableQuota) return;
                    }

                    let comboDiscountPercent = this.verifyComboAndPromotion(includedProducts[index].quantity);
                    if (includedProducts[index].comboDiscountPercent == '0%' && comboDiscountPercent != null) {
                        includedProducts[index].comboId = comboDiscountPercent.comboId;
                        includedProducts[index].comboDiscountPercent = comboDiscountPercent.discount + '%';
                        includedProducts[index].comboDiscountValue = this.calculateValue(comboDiscountPercent.discount + '%', includedProducts[index].totalPrice);
                        includedProducts[index].totalPrice = includedProducts[index].totalPrice - includedProducts[index].comboDiscountValue;
                        includedProducts[index].totalPriceFront = this.fixDecimalPlacesFront(includedProducts[index].totalPrice);
                        includedProducts[index].industryCombo = comboDiscountPercent.industryCombo;
                        includedProducts[index].unitPrice = this.fixDecimalPlaces(includedProducts[index].totalPrice / includedProducts[index].quantity);
                        includedProducts[index].unitPriceFront = this.fixDecimalPlacesFront(includedProducts[index].unitPrice);
                        
                        let allCombos = JSON.parse(JSON.stringify(this.combosSelecteds));
                        let currentCombo = allCombos.find(e => e.comboId == comboDiscountPercent.comboId);
                        if (this.isFilled(currentCombo)) {
                            currentCombo.productQuantity = includedProducts[index].quantity;
                        } else {
                            allCombos.push({
                                comboId: comboDiscountPercent.comboId,
                                comboQuantity: 1,
                                productQuantity: includedProducts[index].quantity,
                                productId: includedProducts[index].productId,
                                specificItemCombo: false
                            })
                        }
                        this.combosSelecteds = JSON.parse(JSON.stringify(allCombos));
                        this._setcombosSelecteds();
                    }

                    let margin = this.isFilled(this.addProduct.practicedCost) ? this.fixDecimalPlaces(((1 - (Number(this.addProduct.practicedCost) / (Number(this.addProduct.totalPrice) / Number(this.addProduct.quantity)))) * 100)) : null;
                    this.addProduct.commercialMarginPercentage = this.headerData.IsOrderChild ? this.addProduct.commercialMarginPercentage : margin;
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
            this.updateProduct = false;
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
        this.recalculateCommodities();
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
                    filledDivisions[index].orderItemKey = this.currentDivisionProduct.productId;
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
            case 'visualize':
                this.editProduct(row.position, false);
            break;
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
        isSeedSale({salesOrgId: this.selectedCompany.salesOrgId, productGroupName: currentProduct.productGroupName})
        .then((result) => {
            this.seedSale = result;
        });
        this.multiplicity = this.isFilled(currentProduct.multiplicity) ? currentProduct.multiplicity : 1;

        this.addProduct = this.newProduct(currentProduct);
        console.log('this.addProduct: ' + JSON.stringify(this.addProduct));

        if (recalculateFinancialValues) {
            this.calculateFinancialInfos();
        } else {
            this.createNewProduct = !this.createNewProduct;
            this.updateProduct = true;
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
        let availableQuantity = Number(currentProduct.quantity) - Number(distributedQuantity);

        this.productPosition = position;
        this.multiplicity = this.isFilled(currentProduct.multiplicity) ? currentProduct.multiplicity : 1;
        let allowChange = (this.headerData.tipo_pedido != 'Pedido Filho' && !this.headerData.IsOrderChild && this.isFilled(this.headerData.codigo_sap)) ||
                          (this.headerData.tipo_pedido == 'Pedido Filho' && this.isFilled(this.headerData.codigo_sap)) ? true : false;
        this.currentDivisionProduct = {
            productId: currentProduct.productId,
            unitPrice: currentProduct.unitPrice,
            position: position,
            name: currentProduct.name,
            quantity: currentProduct.quantity,
            availableQuantity: availableQuantity,
            showRed : availableQuantity < 0 ? true : false,
            dontAllowChange : allowChange
        };

        this.showProductDivision = !this.showProductDivision;

        if (!this.currentDivisionProduct.dontAllowChange) {
            this.newFields();
        }
    }

    deleteProduct(position) {
        let excludeProduct = JSON.parse(JSON.stringify(this.products));
        let excludedProducts = this.isFilled(this.excludedItems) ? JSON.parse(JSON.stringify(this.excludedItems)) : [];
        
        let counter;
        for (let index = 0; index < excludeProduct.length; index++) {
            if (excludeProduct[index].position == position) {
                counter = index;
            }
        }
        
        excludedProducts.push(excludeProduct[counter].orderItemId);
        excludeProduct.splice(counter, 1);
        
        if(excludeProduct.lenght - 1 != position){
            excludeProduct.forEach((product) => {
                if(product.position > position) product.position -= 1
            })
        }
        this.products = JSON.parse(JSON.stringify(excludeProduct));

        if (this.products.length == 0) {
            this.showIncludedProducts = false;

            if (this.commoditiesData.length > 0) {
                this.commoditiesData = [];
                this.commodities = [];
                this.barterSale = true;
                this.showCommodityData = false;
                this._setCommodityData();
                this.showToast('warning', 'As commodities foram removidas por conta da falta de produtos!', '');
            }
        } else {
            this.recalculateCommodities()  ;
        }

        this.excludedItems = this.isFilled(excludedProducts) ? excludedProducts : [];
        this._setExcludedesItems();
        this._setData();
        this.showToast('success', 'Produto removido!', '');
    }

    newFields() {
        let allDivisions = JSON.parse(JSON.stringify(this.divisionProducts));
        let divPosition = this.isFilled(allDivisions) ? allDivisions.length : 0;
        let deliveryId = 'deliveryId-' + divPosition;
        let quantityId = 'quantityId-' + divPosition;
        let orderItemKey = this.currentDivisionProduct.productId;
        
        allDivisions.push({productId: this.currentDivisionProduct.productId, deliveryDate: null, quantity: null, position: divPosition, deliveryId: deliveryId, quantityId: quantityId, orderItemKey: orderItemKey, productPosition: this.productPosition, showInfos: true});
        this.divisionProducts = JSON.parse(JSON.stringify(allDivisions));
    }

    divisionChange(event) {
        let allDivisions = JSON.parse(JSON.stringify(this.divisionProducts));
        let fieldId = event.target.dataset.targetId;
        let fieldValue = event.target.value;
        let currentProduct;

        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let yyyy = today.getFullYear();
        let currentDate = yyyy + '-' + mm + '-' + dd;

        if (this.isFilled(fieldValue)) {
            if (fieldId.includes('deliveryId-')) {
                currentProduct = allDivisions.find(e => e.deliveryId == fieldId);
                if (fieldValue >= currentDate && fieldValue >= this.safraData.initialDate && fieldValue <= this.safraData.endDate) {
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
                    if (allDivisions[index].productPosition == this.currentDivisionProduct.position && allDivisions[index].quantityId != fieldId) {
                        productQuantity = productQuantity + (Number(allDivisions[index].quantity));
                    }
                }

                currentProduct = allDivisions.find(e => e.quantityId == fieldId);
                this.currentDivisionProduct.availableQuantity = Number(this.currentDivisionProduct.quantity) - ((Number(productQuantity)));
                if ((parseFloat(fieldValue) + parseFloat(productQuantity)) <= parseFloat(this.currentDivisionProduct.quantity)) {
                    currentProduct.quantity = this.calculateMultiplicity(fieldValue, true);
                } else {
                    currentProduct.quantity = this.currentDivisionProduct.quantity - Number(productQuantity);
                    this.showToast('warning', 'Atenção!', 'A quantidade foi arredondada para ' + currentProduct.quantity + ' para não exceder.');
                }

                this.currentDivisionProduct.availableQuantity = Number(this.currentDivisionProduct.quantity) - ((Number(productQuantity) + Number(currentProduct.quantity)));
                if (this.currentDivisionProduct.availableQuantity < 0) {
                    this.currentDivisionProduct.showRed = true;
                } else {
                    this.currentDivisionProduct.showRed = false;
                }
            }

            this.divisionProducts = JSON.parse(JSON.stringify(allDivisions));
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

    _setHeaderValues() {
        const setHeaderValues = new CustomEvent('setheadervalues');
        setHeaderValues.data = this.headerData;
        this.dispatchEvent(setHeaderValues);
    }

    _setExcludedesItems() {
        const setItems = new CustomEvent('setexcludedesitems');
        setItems.data = this.excludedItems;
        this.dispatchEvent(setItems);
    }

    _setcombosSelecteds() {
        const setItems = new CustomEvent('setcombosselecteds');
        setItems.data = this.combosSelecteds;
        this.dispatchEvent(setItems);
    }

    _setHideFooterButtons(hideButton) {
        const setItems = new CustomEvent('sethidefooterbuttons');
        setItems.data = hideButton;
        this.dispatchEvent(setItems);
    }

    handlePrevious(event) {
        const setItems = new CustomEvent('sethandleprevious');
        setItems.data = false;
        this.dispatchEvent(setItems);
    }

    @api
    handleNext(event) {
        this.showCombos = false;
        const setItems = new CustomEvent('sethandlenext');
        setItems.data = false;
        this.dispatchEvent(setItems);

        let allCombos = JSON.parse(JSON.stringify(this.combosSelecteds));
        this.comboProducts.formerIds = [];
        this.comboProducts.benefitsIds = [];
        
        for (let index = 0; index < allCombos.length; index++) {
            let currentCombo = allCombos[index];
            for (let i = 0; i < currentCombo.formerItems.length; i++) {
                this.comboProducts.formerIds.push(currentCombo.formerItems[i].productId);
            }

            for (let i = 0; i < currentCombo.benefitItems.length; i++) {
                this.comboProducts.benefitsIds.push(currentCombo.benefitItems[i].productId);
            }
        }

        let getCompanyData = {
            ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
            accountId: this.accountData.Id != null ? this.accountData.Id : '',
            orderType: this.headerData.tipo_venda,
            approvalNumber: 1
        }

        if ((this.isFilled(this.comboProducts.formerIds) && this.comboProducts.formerIds.length > 0) ||
            (this.isFilled(this.comboProducts.benefitsIds) && this.comboProducts.benefitsIds.length > 0)) {
            this.checkCombo = true;
            this.unitPriceDisabled = true;
        }

        this.getCompanies(getCompanyData);
    }

    showResults(event){
        this.showBaseProducts = event.showResults;
        this.baseProducts = event.results.recordsDataList;
        this.productsPriceMap = event.results.recordsDataMap;
        this.salesInfos = event.results.salesResult;
        this.message = this.baseProducts.length > 0 ? false : event.message;
        if (this.baseProducts.length >= 9) {
            this.showArrows = true;
        }
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
        let orderTotalCost = 0;
        let productsQuantity = 0;
        let totalDiscount = 0;

        for (let index = 0; index < this.products.length; index++) {
            totalProducts += Number(this.products[index].totalPrice);
            orderTotalCost += Number(this.products[index].practicedCost) * Number(this.products[index].quantity);
            productsQuantity += Number(this.products[index].quantity);
            totalDiscount += Number(this.products[index].commercialDiscountValue);
        }

        let chooseCommodity = this.commodities.find(e => e.Id == event.target.dataset.targetId);
        let marginPercent = ((1 - (orderTotalCost / totalProducts)) * 100);

        this.selectedCommodity = {
            id: chooseCommodity.Id,
            name: chooseCommodity.Name,
            cotation: chooseCommodity.listPrice,
            startDate: null,
            endDate: null,
            deliveryQuantity: Math.ceil((totalProducts / chooseCommodity.listPrice)) + ' sacas',
            deliveryQuantityFront: Math.ceil((totalProducts / chooseCommodity.listPrice)) + ' sacas',
            ptax: chooseCommodity.productCurrency + chooseCommodity.listPrice,
            commodityPrice: chooseCommodity.listPrice,
            deliveryAddress: '',
            commission: 'R$' + ((chooseCommodity.commissionPercentage * totalProducts) / 100),
            totalMarginPercent: this.fixDecimalPlaces(marginPercent) + '%',
            totalMarginPercentFront: this.fixDecimalPlacesFront(marginPercent) + '%',
            totalMarginValue: this.fixDecimalPlaces(((totalProducts * marginPercent) / 100) / chooseCommodity.listPrice) + ' sacas',
            totalMarginValueFront: this.fixDecimalPlacesFront(((totalProducts * marginPercent) / 100) / chooseCommodity.listPrice) + ' sacas',
            quantity: productsQuantity,
            totalDiscountValue: this.fixDecimalPlaces(totalDiscount / chooseCommodity.listPrice) + ' sacas',
            totalDiscountValueFront: this.fixDecimalPlacesFront(totalDiscount / chooseCommodity.listPrice) + ' sacas'
        };
    }

    fillCommodity(event) {
        this.summaryScreen = true;
        for (let index = 0; index < this.commoditiesData.length; index++) {
            if (this.commoditiesData[index].saved == false) {
                return;
            }
        }

        this.commoditiesData.push({
            product: this.selectedCommodity.name,
            productId: this.selectedCommodity.id,
            commodityPrice: this.selectedCommodity.commodityPrice,
            area: this.headerData.hectares,
            quantity: this.selectedCommodity.quantity,
            discount: this.selectedCommodity.totalDiscountValue,
            discountFront: this.selectedCommodity.totalDiscountValueFront,
            margin: this.selectedCommodity.totalMarginPercent,
            marginFront: this.selectedCommodity.totalMarginPercentFront,
            marginValue: this.selectedCommodity.totalMarginValue,
            marginValueFront: this.selectedCommodity.totalMarginValueFront,
            totalDelivery: this.selectedCommodity.deliveryQuantity,
            totalDeliveryFront: this.selectedCommodity.deliveryQuantityFront,
            cotation: this.selectedCommodity.cotation,
            startDate: this.selectedCommodity.startDate,
            endDate: this.selectedCommodity.endDate,
            deliveryAddress : this.selectedCommodity.deliveryAddress,
            saved: false
        });
    }

    closeCommodityModal(event) {
        for (let index = 0; index < this.commoditiesData.length; index++) {
            if (event.target.dataset.targetId == 'saveButton') {
                this.commoditiesData[index].saved = true;
                this.showCommodityData = true;
                this.barterSale = false;
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

    openCommodityData(event) {
        this.openCommoditiesData = !this.openCommoditiesData;
    }

    commodityChange(event) {
        if (this.isFilled(event.target.value)) {
            this.selectedCommodity[event.target.dataset.targetId] = event.target.value;
        }
    }

    verifyConditions(startDate, endDate, deliveryAddress){
        if((this.isFilled(startDate)  && startDate != "") && (this.isFilled(endDate) && endDate != "")){
            var start = new Date(startDate);
            var end = new Date(endDate);
            if(end.getTime() < start.getTime()) {
                this.showToast('warning', 'Atenção', 'Intervalo de datas não permitido.');
                return false;
            }
        }else {
            this.showToast('warning', 'Atenção', 'Campos Obrigatórios não preenchidos.');
            return false;
        }


        if(deliveryAddress.trim() == "") {
            this.showToast('warning', 'Atenção', 'Campos Obrigatórios não preenchidos.');
            return false;
        }

        return true;
    }

    nextScreen(event) {
        this.selectCommodityScreen = false;
        this.chooseCommodities = false;
        this.commoditySelected = false;
        this.summaryScreen = false;
        // this.haScreen = false;

        //Validation
        if(this.currentScreen== 'fillCommodity' && this.commodityScreens[this.commodityScreens.indexOf(this.currentScreen) + 1] == 'negotiationDetails'){
            if(!this.verifyConditions(this.selectedCommodity.startDate, this.selectedCommodity.endDate, this.selectedCommodity.deliveryAddress)){
                this.commoditySelected = true;
                return;
            }
        }

        this.currentScreen = this.commodityScreens[this.commodityScreens.indexOf(this.currentScreen) + 1];
        if (this.currentScreen == 'chooseCommodity') {this.selectCommodityScreen = true;this.chooseCommodities = true;}
        if (this.currentScreen == 'fillCommodity')  this.commoditySelected = true;
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

    recalculateCommodities() {
        if (this.isFilled(this.commoditiesData) && this.commoditiesData.length > 0) {
            let totalProducts = 0;
            let orderTotalCost = 0;
            let productsQuantity = 0;
            let totalDiscount = 0;
            
            for (let index = 0; index < this.products.length; index++) {
                totalProducts += Number(this.products[index].totalPrice);
                orderTotalCost += Number(this.products[index].practicedCost) * Number(this.products[index].quantity);
                productsQuantity += Number(this.products[index].quantity);
                totalDiscount += Number(this.products[index].commercialDiscountValue);
            }
    
            let marginPercent = ((1 - (orderTotalCost / totalProducts)) * 100);
            let currentCommodityValues = JSON.parse(JSON.stringify(this.commoditiesData[0]));
            
            currentCommodityValues.area = this.headerData.hectares;
            currentCommodityValues.quantity = productsQuantity;
            currentCommodityValues.discount = this.fixDecimalPlaces(totalDiscount / Number(currentCommodityValues.cotation)) + ' sacas';
            currentCommodityValues.discountFront = this.fixDecimalPlacesFront(totalDiscount / Number(currentCommodityValues.cotation)) + ' sacas';
            currentCommodityValues.margin = this.fixDecimalPlaces(marginPercent) + '%';
            currentCommodityValues.marginFront = this.fixDecimalPlacesFront(marginPercent) + '%';
            currentCommodityValues.marginValue = this.fixDecimalPlaces(((totalProducts * marginPercent) / 100) / Number(currentCommodityValues.cotation)) + ' sacas';
            currentCommodityValues.marginValueFront = this.fixDecimalPlacesFront(((totalProducts * marginPercent) / 100) / Number(currentCommodityValues.cotation)) + ' sacas';
            currentCommodityValues.totalDelivery = Math.ceil((totalProducts / currentCommodityValues.cotation)) + ' sacas';
            currentCommodityValues.totalDeliveryFront = Math.ceil((totalProducts / currentCommodityValues.cotation)) + ' sacas';
            
            this.commoditiesData = [];
            this.commoditiesData.push(currentCommodityValues);

            this._setCommodityData();
            this.showToast('warning', 'Atenção!', 'Os valores da commodity foram alterados de acordo com a alteração/inclusão de um produto.');
        }
    }

    handleCommodityActions(event) {
        const actionName = event.detail.action.name;
        switch (actionName) {
            case 'delete':
                this.commoditiesData = [];
                this.commodities = [];
                this.barterSale = true;
                this.showCommodityData = false;
                this._setCommodityData();
                this.openCommodityData();
                this.showToast('success', 'Sucesso!', 'Commodity removida.');
            break;
        }
    }

    backProductScreen(event) {
        this.productParams.numberOfRowsToSkip = this.productParams.numberOfRowsToSkip > 0 ? this.productParams.numberOfRowsToSkip - 9 : 0;
        this.getProducts();
    }

    nextProductScreen(event) {
        if (this.baseProducts.length == 9) {
            this.productParams.numberOfRowsToSkip += 9;
            this.getProducts();
        }
    }

    getProducts() {
        fetchOrderRecords({
            searchString: this.salesInfos.searchString,
            data: JSON.stringify(this.productParams),
            isCommodity: false,
            productsIds: [],
            priceScreen: false,
            getSeedPrices: this.showRoyaltyTsi
        })
        .then(result => {
            this.showBaseProducts = result.recordsDataList.length > 0;
            this.baseProducts = result.recordsDataList;
            this.productsPriceMap = result.recordsDataMap;
            this.salesInfos = result.salesResult;
            this.message = this.baseProducts.length > 0 ? false : result.message;
            if (this.baseProducts.length >= 9) {
                this.showArrows = true;
            }
        });
    }

    backComboScreen(event) {
        this.comboRowsToSkip = this.comboRowsToSkip > 0 ? this.comboRowsToSkip - 4 : 0;
        this.getCombos();
    }

    nextComboScreen(event) {
        if (this.combosData.length == 4) {
            this.comboRowsToSkip += 4;
            this.getCombos();
        }
    }

    getCombos() {
        this.showLoading = true;
        let headerValues = {
            cropId: this.headerData.safra.Id,
            rowsToSkip: this.comboRowsToSkip,
            salesConditionId: this.headerData.condicao_venda.Id
        }

        let getCompanyData = {
            ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
            accountId: this.accountData.Id != null ? this.accountData.Id : '',
            orderType: this.headerData.tipo_venda,
            approvalNumber: 1
        }

        let productParams = {
            salesConditionId: this.headerData.condicao_venda.Id,
            accountId: this.accountData.Id,
            ctvId: this.headerData.ctv_venda.Id,
            safra: this.headerData.safra.Id,
            productCurrency: this.headerData.moeda,
            culture: this.headerData.cultura.Id,
            orderType: this.headerData.tipo_venda,
            numberOfRowsToSkip: 0,
            dontGetSeeds: this.isFilled(this.dontGetSeeds) ? this.dontGetSeeds : false
        };

        getSpecificCombos({data: JSON.stringify(headerValues), companyData: JSON.stringify(getCompanyData), productData: JSON.stringify(productParams), childOrder: this.childOrder, existingCombosIds: this.combosIds})
        .then((result) => {
            this.showLoading = false;
            let combosAndPromotions = JSON.parse(result);
            if (this.isFilled(combosAndPromotions) && combosAndPromotions.length > 0) {
                this._setHideFooterButtons(true);
                this.showCombos = true;

                let existingCombos = JSON.parse(JSON.stringify(this.combosSelecteds));
                for (let index = 0; index < combosAndPromotions.length; index++) {
                    let currentCombo = existingCombos.find(e => e.comboId == combosAndPromotions[index].comboId);
                    if (this.isFilled(currentCombo)) {
                        combosAndPromotions[index].comboQuantity = currentCombo.comboQuantity;
                    } else {
                        currentCombo = this.comboProductsAndQuantities.find(e => e.combo == combosAndPromotions[index].comboId);
                        if (this.isFilled(currentCombo)) {
                            let formerItem = combosAndPromotions[index].formerItems.find(e => e.productId == currentCombo.prodId);
                            let benefitItem = combosAndPromotions[index].benefitItems.find(e => e.productId == currentCombo.prodId);
                            
                            if (this.isFilled(formerItem)) {
                                combosAndPromotions[index].comboQuantity = currentCombo.quantity / formerItem.minQUantity;
                                combosAndPromotions[index].comboAvailableQuantity = combosAndPromotions[index].comboAvailableQuantity == 0 ? combosAndPromotions[index].comboQuantity : combosAndPromotions[index].comboAvailableQuantity;
                            }
                            if (this.isFilled(benefitItem)) {
                                combosAndPromotions[index].comboQuantity = currentCombo.quantity / benefitItem.minQUantity;
                                combosAndPromotions[index].comboAvailableQuantity = combosAndPromotions[index].comboAvailableQuantity == 0 ? combosAndPromotions[index].comboQuantity : combosAndPromotions[index].comboAvailableQuantity;
                            }
                        }
                    }
                }

                this.combosData = combosAndPromotions;
            } else {
                let getCompanyData = {
                    ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',
                    accountId: this.accountData.Id != null ? this.accountData.Id : '',
                    orderType: this.headerData.tipo_venda,
                    approvalNumber: 1
                }
        
                this.getCompanies(getCompanyData);
            }
        });
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