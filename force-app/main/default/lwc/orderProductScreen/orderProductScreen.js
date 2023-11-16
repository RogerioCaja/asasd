import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isSeedSale from '@salesforce/apex/OrderScreenController.isSeedSale';
import getSafraInfos from '@salesforce/apex/OrderScreenController.getSafraInfos';
import getFinancialInfos from '@salesforce/apex/OrderScreenController.getFinancialInfos';
import getSpecificCombos from '@salesforce/apex/OrderScreenController.getSpecificCombos';
import checkQuotaQuantity from '@salesforce/apex/OrderScreenController.checkQuotaQuantity';
import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';
import getMixAndConditionCombos from '@salesforce/apex/OrderScreenController.getMixAndConditionCombos';
import getTaxes from '@salesforce/apex/OrderScreenController.getTaxes';
import fetchOrderRecords from '@salesforce/apex/CustomLookupController.fetchProductsRecords';
import {totalCombosLogic, loadComboMix, logicApplyCombo, loadComboProducts, updateCommodities} from './orderProductScreenUtils';

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
    allProductQuotas=[];

    selectedColumns={
        columnUnity: true,
        columnListPrice: true,
        columnQuantity: true,
        columnUnitPrice: true,
        columnTotalPrice: true,
        columnProductGroupName: true,
        columnCommercialDiscountPercentage: true,
        columnContainsCombo: true
    }

    companyResult=[];
    selectCompany=false;
    selectedCompany;
    safraData={};
    paymentDate;
    hectares;
    salesConditionId;
    productParams={};
    productsPriceMap;
    salesInfos;
    hideChooseColumns=false;

    baseProducts=[];
    showBaseProducts=false;
    showArrows=false;
    showIncludedProducts=false;
    message=false;
    createNewProduct=false;
    updateProduct=false;
    recalculatePrice=false;
    showList=false;
    changeColumns=false;
    showProductDivision=false;
    barterSale=false;
    selectedProducts;
    columns=[];
    productName='';
    currentDivisionProduct={};
    divisionProducts=[];
    allDivisionProducts=[];
    financialInfos={};
    
    showRoyaltyTsi=false;
    dontGetSeeds=false;
    selectCommodityScreen=false;
    commodityScreens=['chooseCommodity', 'fillCommodity', 'negotiationDetails'];
    currentScreen='chooseCommodity';
    
    commodities=[];
    showCommodityData=false;
    openCommoditiesData=false;
    chooseCommodities=false;
    showCommodities=false;
    commoditySelected=false;
    summaryScreen=false;
    commodityColumns=[
        {label: 'Produto', fieldName: 'product'},
        {label: 'Dose', fieldName: 'desage'},
        {label: 'Área', fieldName: 'area'},
        {label: 'Desconto', fieldName: 'discountFront'},
        {label: 'Margem', fieldName: 'marginFront'},
        {label: 'Entrega Total', fieldName: 'totalDeliveryFront'}
    ];
    visualizeCommodityColumns=[];

    disabled=false;
    disableSearch=false;
    numberOfRowsToSkip=0;
    showLoading=true;
    combosIds=[];
    comboAndQuantities=[];

    combosData;
    showCombos=false;
    checkCombo=false;
    comboRowsToSkip=0;
    itensToRemove=[];
    comboProducts={formerIds: [], benefitsIds: [], mixTotal: []};
    hidePrices=false;

    @track products=[];
    @track commoditiesData=[];

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
    @api taxData;
    @api bpData;

    connectedCallback(event) {
        let t = this
        if (!t.isFilled(t.taxData)) t.taxData=[];
        if (!t.isFilled(t.combosSelecteds)) t.combosSelecteds=[];

        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let yyyy = today.getFullYear();
        t.currentDate = yyyy + '-' + mm + '-' + dd;

        t.paymentDate = t.headerData.data_pagamento;
        t.hectares = t.headerData.hectares.toString().includes(',') ? Number(t.headerData.hectares.toString().replace(',', '.')) : Number(t.headerData.hectares);
        t.salesConditionId = t.headerData.condicao_venda.Id;
        t.commoditiesData = t.isFilled(t.commodityData) ? t.commodityData : [];
        t.barterSale = t.headerData.tipo_venda == 'Venda Barter' && t.commoditiesData.length == 0 ? true : false;

        if (t.cloneData.cloneOrder) {
            t.products = t.isFilled(t.productData) ? t.productData : [];
            t.allDivisionProducts = [];
        } else {
            t.products = t.isFilled(t.productData) ? t.productData : [];
            t.allDivisionProducts = t.isFilled(t.divisionData) ? t.divisionData : [];
        }

        let combosIds = [];
        let newProducts = [];
        let comboAndQuantities = [];
        let allProducts = t.parseObject(t.products);

        for (let index = 0; index < allProducts.length; index++) {
            if (allProducts[index].comboId != null) {
                combosIds.push(allProducts[index].comboId);
                comboAndQuantities.push({combo: allProducts[index].comboId, quantity: allProducts[index].quantity, prodId: allProducts[index].productId});
            }
            newProducts.push(t.newProduct(allProducts[index]));
        }
        t.combosIds = t.parseObject(combosIds);
        t.products = t.parseObject(newProducts);
        t.comboAndQuantities = t.parseObject(comboAndQuantities);

        if (t.headerData.IsOrderChild) {
            t.disableSearch = true;
            t._setData();
        }

        let orderStatus = ['Em aprovação - Gerente Filial', 'Em aprovação - Gerente Regional', 'Em aprovação - Diretor', 'Em aprovação - Comitê Margem', 'Em aprovação - Mesa de Grãos', 'Em Aprovação - Diretor Torre'];
        if (orderStatus.includes(t.headerData.status_pedido)) {
            t.disabled = true;
            t.disableSearch = true;
        }

        if (t.isFilled(t.commoditiesData) && t.commoditiesData.length > 0) t.showCommodityData = true;
        t.visualizeCommodityColumns = t.parseObject(t.commodityColumns);
        t.visualizeCommodityColumns.push({
            type: 'action',
            typeAttributes: {
                rowActions: commodityActions,
                menuAlignment: 'auto'
            }
        });

        actions = [];
        if (t.disabled) actions.push({ label: 'Visualizar', name: 'visualize' })
        else if(t.headerData.IsOrderChild) actions.push({ label: 'Editar', name: 'edit' }, { label: 'Divisão de Remessas', name: 'shippingDivision' }, { label: 'Excluir', name: 'delete' });
        else if (t.headerData.pedido_mae_check) actions.push({ label: 'Editar', name: 'edit' }, { label: 'Excluir', name: 'delete' });
        else actions.push({ label: 'Editar', name: 'edit' }, { label: 'Divisão de Remessas', name: 'shippingDivision' }, { label: 'Excluir', name: 'delete' });

        t.showIncludedProducts = t.products.length > 0;
        if (t.headerData.tipo_venda == 'Venda Barter') {
            t.hideChooseColumns = true;
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
            t.columns = barterColumns;
            t.changeColumns = false;
        } else {
            t.applySelectedColumns(event);
        }

        t.headerData = t.parseObject(t.headerData);
        let getCompanyData = {
            ctvId: t.headerData.ctv_venda.Id != null ? t.headerData.ctv_venda.Id : '',
            accountId: t.accountData.Id != null ? t.accountData.Id : '',
            orderType: t.headerData.tipo_venda,
            approvalNumber: 1
        }
        if (!t.headerData.IsOrderChild && !t.isFilled(t.headerData.codigo_sap)) t.getCombos();
        else t.getCompanies(getCompanyData);
    }

    parseObject(obj) {
        return JSON.parse(JSON.stringify(obj));
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
                        this.headerData.companySector = this.selectedCompany.activitySectorName;
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
                    this.headerData.companySector = this.selectedCompany.activitySectorName;
                    this.onSelectCompany();
                } else if (this.companyResult.length > 1) {
                    this.selectCompany = true;
                    this.showLoading = false;
                }
            }
        });
    }

    newProduct(prod) {
        let tTotalPrice = this.headerData.IsOrderChild ? this.fixDecimalPlaces((prod.tListPrice * prod.quantity)) : (this.isFilled(prod.tsiTotalPrice) ? prod.tsiTotalPrice : 0)
        let rTotalPrice = this.headerData.IsOrderChild ? this.fixDecimalPlaces((prod.rListPrice * prod.quantity)) : (this.isFilled(prod.royaltyTotalPrice) ? prod.royaltyTotalPrice : 0)
        let newProduct = {
            orderItemId: prod.orderItemId,
            name: prod.name,
            entryId: prod.entryId,
            productId: prod.productId,
            unity: prod.unity,
            productGroupId: prod.productGroupId,
            productGroupName: prod.productGroupName,
            productSubgroupName: prod.productSubgroupName,
            productHierarchyId: prod.productHierarchyId,
            sapStatus: prod.sapStatus,
            sapProductCode: prod.sapProductCode,
            activePrinciple: prod.activePrinciple,
            brand: prod.brand,
            commercialDiscountPercentage: prod.commercialDiscountPercentage,
            commercialDiscountPercentageFront: this.headerData.IsOrderChild ? '0%' : this.fixDecimalPlacesPercentage(prod.commercialDiscountPercentage),
            commercialAdditionPercentage: prod.commercialAdditionPercentage,
            commercialAdditionPercentageFront: this.headerData.IsOrderChild ? '0%' : this.fixDecimalPlacesPercentage(prod.commercialAdditionPercentage),
            financialAdditionPercentage: prod.financialAdditionPercentage,
            financialAdditionPercentageFront: this.headerData.IsOrderChild ? '0%' : this.fixDecimalPlacesPercentage(prod.financialAdditionPercentage),
            financialDecreasePercentage: prod.financialDecreasePercentage,
            financialDecreasePercentageFront: this.headerData.IsOrderChild ? '0%' : this.fixDecimalPlacesPercentage(prod.financialDecreasePercentage),
            commercialDiscountValue: prod.commercialDiscountValue,
            commercialDiscountValueFront: this.headerData.IsOrderChild ? 0 : this.fixDecimalPlacesFront(prod.commercialDiscountValue),
            commercialAdditionValue: prod.commercialAdditionValue,
            commercialAdditionValueFront: this.headerData.IsOrderChild ? 0 : this.fixDecimalPlacesFront(prod.commercialAdditionValue),
            financialAdditionValue: prod.financialAdditionValue,
            financialAdditionValueFront: this.headerData.IsOrderChild ? 0 : this.fixDecimalPlacesFront(prod.financialAdditionValue),
            financialDecreaseValue: prod.financialDecreaseValue,
            financialDecreaseValueFront: this.headerData.IsOrderChild ? 0 : this.fixDecimalPlacesFront(prod.financialDecreaseValue),
            listPrice: prod.listPrice,
            listPriceFront: this.fixDecimalPlacesFront(prod.listPrice),
            unitPrice: prod.unitPrice,
            unitPriceFront: this.fixDecimalPlacesFront(prod.unitPrice),
            totalPrice: this.headerData.IsOrderChild ? this.fixDecimalPlaces((prod.unitPrice * prod.quantity)) : prod.totalPrice,
            totalPriceFront: this.headerData.IsOrderChild ? this.fixDecimalPlacesFront((prod.unitPrice * prod.quantity)) : this.fixDecimalPlacesFront(prod.totalPrice),
            totalPriceWithBrokerage: this.headerData.IsOrderChild ? this.fixDecimalPlaces((prod.unitPrice * prod.quantity + (prod.brokerage ?? 0))) : (this.isFilled(prod.totalPriceWithBrokerage) ? prod.totalPriceWithBrokerage : 0 ),
            totalPriceWithBrokerageFront: this.headerData.IsOrderChild ? this.fixDecimalPlacesFront((prod.unitPrice * prod.quantity + (prod.brokerage ?? 0))) : (this.isFilled(prod.totalPriceWithBrokerage) ? this.fixDecimalPlacesFront(prod.totalPriceWithBrokerage) : 0),
            costPrice: prod.listCost,
            listCost: prod.listCost,
            practicedCost: prod.practicedCost,
            initialTotalValue: prod.initialTotalValue,
            dosage: this.headerData.emptyHectar ? prod.quantity : (this.isFilled(prod.dosage) ? prod.dosage : prod.quantity / this.hectares),
            dosageFront: this.isFilled(prod.dosage) ? this.fixDecimalPlacesFront(prod.dosage) : '',
            brokerage: this.isFilled(prod.brokerage) ? prod.brokerage : 0,
            brokerageFront: this.isFilled(prod.brokerage) ? this.fixDecimalPlacesFront(prod.brokerage) : 0,
            quantity: prod.quantity,
            quantityFront: this.fixDecimalPlacesFront(prod.quantity),
            motherAvailableQuantity: prod.motherAvailableQuantity,
            invoicedQuantity: this.isFilled(prod.invoicedQuantity) ? prod.invoicedQuantity : 0,
            multiplicity: prod.multiplicity,
            position: prod.position,
            commercialMarginPercentage: prod.commercialMarginPercentage,
            productSubgroupId: prod.productSubgroupId,
            productSubgroupName: prod.productSubgroupName,
            orderId: prod.orderId,
            serviceDate: prod.serviceDate,
            comissionValue: prod.comissionValue,
            ptaProduct: prod.ptaProduct,
            priceListCode: prod.priceListCode,
            sieve: this.isFilled(prod.sieve) ? prod.sieve : '',
            productClass: this.isFilled(prod.productClass) ? prod.productClass : '',
            comboDiscountPercent: this.isFilled(prod.comboDiscountPercent) ? prod.comboDiscountPercent : '0%',
            comboDiscountValue: this.isFilled(prod.comboDiscountValue) ? prod.comboDiscountValue : 0,
            comboId: this.isFilled(prod.comboId) ? prod.comboId : null,
            industryCombo: this.isFilled(prod.comboId) ? prod.industryCombo : false,
            containsCombo: this.isFilled(prod.comboId) ? true : false,
            containsComboString: this.isFilled(prod.comboId) ? 'Sim' : 'Não',
            formerItem: this.isFilled(prod.formerItem) ? prod.formerItem : false,
            benefitItem: this.isFilled(prod.benefitItem) ? prod.benefitItem : false,
            tListPrice: this.isFilled(prod.tListPrice) ? prod.tListPrice : 0,
            tListPriceFront: this.isFilled(prod.tListPrice) ? 'R$' + this.fixDecimalPlacesFront(prod.tListPrice) : 'R$0',
            tsiTotalPrice: tTotalPrice,
            tsiTotalPriceFront: 'R$' + this.fixDecimalPlacesFront(tTotalPrice),
            rListPrice: this.isFilled(prod.rListPrice) ? prod.rListPrice : 0,
            rListPriceFront: this.isFilled(prod.rListPrice) ? 'R$' + this.fixDecimalPlacesFront(prod.rListPrice) : 'R$0',
            royaltyTotalPrice: rTotalPrice,
            royaltyTotalPriceFront: 'R$' + this.fixDecimalPlacesFront(rTotalPrice),
            brokeragePerUnit: this.isFilled(prod.brokeragePerUnit) ? prod.brokeragePerUnit : ''
        };
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
        this.companyResult = this.parseObject(companies);
    }

    getCurrentProductPosition() {
        let lastPosition = 0;
        for (let index = 0; index < this.products.length; index++) {
            if (this.products[index].position > lastPosition) lastPosition = this.products[index].position;
        }
        return lastPosition;
    }

    onSelectCompany() {
        let t = this
        if (!t.isFilled(t.headerData.companyId)) {
            t.selectCompany = !t.selectCompany;
            t.headerData.companyId = t.selectedCompany.companyId;
            t.headerData.companySector = t.selectedCompany.activitySectorName;
        }
        t._setHeaderValues();

        t.hidePrices = false;
        if (t.headerData.tipo_venda == 'Venda Barter') {
            t.hidePrices = !t.selectedCompany.showBarterPrices;
            getTaxes({accountId: t.accountData.Id, salesOrgId: t.selectedCompany.salesOrgId})
            .then((result) => {
                t.taxData = JSON.parse(result);
                console.log('t.taxData: ' + JSON.stringify(t.taxData));
            });
        }
        
        isSeedSale({salesOrgId: t.selectedCompany.salesOrgId, productGroupName: null})
        .then((result) => {
            
            t.seedSale = result;
            
            if (t.isFilled(t.selectedCompany.activitySectorName) && (t.selectedCompany.activitySectorName.toUpperCase() == 'SEMENTES' || t.selectedCompany.activitySectorName.toUpperCase() == 'SEMENTE')) {
                t.showRoyaltyTsi = result;
            }

            if (t.seedSale && t.isFilled(t.selectedCompany.activitySectorName) && (t.selectedCompany.activitySectorName.toUpperCase() == 'INSUMOS' || t.selectedCompany.activitySectorName.toUpperCase() == 'INSUMO')) {
                t.dontGetSeeds = true;
            }

            t.productParams = {
                salesConditionId: t.headerData.condicao_venda.Id,
                accountId: t.accountData.Id,
                ctvId: t.headerData.ctv_venda.Id,
                safra: t.headerData.safra.Id,
                productCurrency: t.headerData.moeda,
                culture: t.headerData.cultura.Id,
                orderType: t.headerData.tipo_venda,
                supplierCenter: t.headerData.supplierCenterDeliveredAccount,
                activitySectorName: t.selectedCompany.activitySectorName,
                salesOrgId: t.selectedCompany.salesOrgId != null ? t.selectedCompany.salesOrgId : '',
                salesOfficeId: t.selectedCompany.salesOfficeId != null ? t.selectedCompany.salesOfficeId : '',
                salesTeamId: t.selectedCompany.salesTeamId != null ? t.selectedCompany.salesTeamId : '',
                numberOfRowsToSkip: t.numberOfRowsToSkip,
                dontGetSeeds: t.isFilled(t.dontGetSeeds) ? t.dontGetSeeds : false,
                paymentDate: t.headerData.data_pagamento
            };

            let prodsIds = [];
            for (let index = 0; index < t.products.length; index++) {
                prodsIds.push(t.products[index].productId);
            }

            let formerItens = [];
            let benefitItens = [];
            let mixTotal = [];
            for (let index = 0; index < t.combosSelecteds.length; index++) {
                let currentCombo = t.combosSelecteds[index];
                if (t.isFilled(currentCombo) && currentCombo.comboQuantity > 0 && currentCombo.specificItemCombo) {
                    if (t.isFilled(currentCombo.formerItems) && currentCombo.formerItems.length > 0) {
                        for (let i = 0; i < currentCombo.formerItems.length; i++) {
                            let former = currentCombo.formerItems[i];
                            formerItens.push({productName: former.productName, productId: former.productId, productCode: former.productCode, minQUantity: former.minQUantity, discountPercentage: former.discountPercentage, comboId: former.comboId, comboQuantity: currentCombo.comboQuantity, industryCombo: currentCombo.comboType == 'Indústria'});
                            prodsIds.push(former.productId);
                        }
                    }

                    if (t.isFilled(currentCombo.benefitItems) && currentCombo.benefitItems.length > 0) {
                        for (let i = 0; i < currentCombo.benefitItems.length; i++) {
                            let benefit = currentCombo.benefitItems[i];
                            benefitItens.push({productName: benefit.productName, productId: benefit.productId, productCode: benefit.productCode, minQUantity: benefit.minQUantity, discountPercentage: benefit.discountPercentage, comboId: benefit.comboId, comboQuantity:currentCombo.comboQuantity, industryCombo: currentCombo.comboType == 'Indústria'});
                            prodsIds.push(benefit.productId);
                        }
                    }

                    
                }
                if (t.isFilled(currentCombo.groupQuantities) && currentCombo.comboQuantity > 0 && currentCombo.groupQuantities.length > 0) {
                    const data = loadComboMix(currentCombo, mixTotal, prodsIds);
                    mixTotal = data.mixTotal;
                    prodsIds = data.prodsIds;
                }
            }

            if (t.seedSale && t.headerData.tipo_pedido != 'Pedido Filho' && !t.headerData.IsOrderChild) {
                t.verifyQuota = true;
                if (prodsIds.length > 0) {
                    let quoteData = {cropId:t.headerData.safra.Id,sellerId:t.headerData.ctv_venda.Id,productsIds:prodsIds};
                    if (t.verifyQuota && t.showRoyaltyTsi) {
                        checkQuotaQuantity({data: JSON.stringify(quoteData)})
                        .then((result) => {
                            t.allProductQuotas = JSON.parse(result);
                        });
                    }
                }
            } else {
                t.verifyQuota = false;
            }

            if (t.isFilled(t.headerData.safra.Id)) {
                getSafraInfos({safraId: t.headerData.safra.Id, salesConditionId: t.salesConditionId, salesOrgId: t.headerData.organizacao_vendas.Id})
                .then((result) => {
                    
                    let safraResult = JSON.parse(result);
                    t.safraData = {initialDate:safraResult.initialDate,endDate:safraResult.endDateBilling};
                    let orderData = {paymentDate:t.headerData.data_pagamento != null ? t.headerData.data_pagamento : '',salesOrg:t.selectedCompany.salesOrgId != null ? t.selectedCompany.salesOrgId : '',salesOffice:t.selectedCompany.salesOfficeId != null ? t.selectedCompany.salesOfficeId : '',salesTeam:t.selectedCompany.salesTeamId != null ? t.selectedCompany.salesTeamId : '',salesCondition:t.salesConditionId != null ? t.salesConditionId : '',safra:t.headerData.safra.Id != null ? t.headerData.safra.Id : '',culture:t.headerData.cultura.Id != null ? t.headerData.cultura.Id : '',clientGroup: t.selectedCompany.clientGroup != null ? t.selectedCompany.clientGroup : ''};
                    let allowChange = (t.headerData.tipo_pedido != 'Pedido Filho' && !t.headerData.IsOrderChild && t.isFilled(t.headerData.codigo_sap)) || (t.headerData.tipo_pedido == 'Pedido Filho' && t.isFilled(t.headerData.codigo_sap)) ? false : true;
                    let checkFinancialInfos = true;

                    if (t.headerData.pre_pedido && (allowChange || t.checkCombo)) {
                        t.financialInfoLogic(orderData);
                        checkFinancialInfos = false;

                        fetchOrderRecords({searchString: '', data: JSON.stringify(t.productParams), isCommodity: false, productsIds: prodsIds, priceScreen: false, getSeedPrices: t.showRoyaltyTsi, isLimit: true})
                        .then(result => {
                            t.productsPriceMap = result.recordsDataMap;
                            t.salesInfos = result.salesResult;
                            let productsWithoutPrice = '';
                            let listPriceChange = false;
                            let orderProducts = [];
                            let itemToExclude = [];
                            let idsToRemove = [];
                            let comboItens = [];
                            let counter = 1;
                            
                            for (let index = 0; index < formerItens.length; index++) {
                                let formerProductQuantity = formerItens[index].minQUantity * formerItens[index].comboQuantity;
                                let currentItem = t.products.find(e => e.productId == formerItens[index].productId);
                                if (t.isFilled(currentItem)) {
                                    currentItem.quantity = formerProductQuantity;
                                    currentItem.dosage = formerProductQuantity / t.hectares;
                                    currentItem.dosageFront = t.fixDecimalPlacesFront(currentItem.dosage);
                                    currentItem.comboId = formerItens[index].comboId;
                                    currentItem.industryCombo = formerItens[index].industryCombo;
                                    currentItem.containsCombo = true;
                                    currentItem.containsComboString = 'Sim';
                                    currentItem.formerItem = true;
                                    currentItem = t.emptyDiscounFields(currentItem);
                                    comboItens.push(currentItem);

                                    for (let i = 0; i < t.products.length; i++) {
                                        if (currentItem.productId == formerItens[index].productId) idsToRemove.push(currentItem.productId);
                                    }
                                } else {
                                    let comboValues = {dosage: formerProductQuantity / t.hectares, quantity: formerProductQuantity, comboDiscount: 0, comboId: formerItens[index].comboId, industryCombo: formerItens[index].industryCombo, containsCombo: true, formerItem: true, benefitItem: false};
                                    let productInfos = t.getProductByPriority({Id: formerItens[index].productId});
                                    let priorityPrice = {listPrice: productInfos.priorityPrice.listPrice, costPrice: productInfos.priorityPrice.costPrice, priceListCode: productInfos.priorityPrice.priceListCode};
                                    comboItens.push(t.createProduct(productInfos.productInfos, priorityPrice, comboValues, t.getCurrentProductPosition() + counter));
                                    counter++;
                                }
                            }

                            for (let index = 0; index < benefitItens.length; index++) {
                                let benefitProductQuantity = benefitItens[index].minQUantity * benefitItens[index].comboQuantity;
                                let currentItem = t.products.find(e => e.productId == benefitItens[index].productId)
                                if (t.isFilled(currentItem)) {
                                    currentItem.quantity = benefitProductQuantity;
                                    currentItem.dosage = benefitProductQuantity / t.hectares;
                                    currentItem.dosageFront = t.fixDecimalPlacesFront(currentItem.dosage);
                                    currentItem.comboId = formerItens[index].comboId;
                                    currentItem.industryCombo = formerItens[index].industryCombo;
                                    currentItem.containsCombo = true;
                                    currentItem.containsComboString = 'Sim';
                                    currentItem.benefitItem = true;
                                    currentItem = t.emptyDiscounFields(currentItem);
                                    currentItem.comboDiscountPercent = benefitItens[index].discountPercentage + '%';
                                    comboItens.push(currentItem);
                                    for (let i = 0; i < t.products.length; i++) {
                                        if (currentItem.productId == benefitItens[index].productId) idsToRemove.push(currentItem.productId);
                                    }
                                } else {
                                    let comboValues = {dosage: benefitProductQuantity / t.hectares, quantity: benefitProductQuantity, comboDiscount: benefitItens[index].discountPercentage, comboId: benefitItens[index].comboId, industryCombo: benefitItens[index].industryCombo, containsCombo: true, formerItem: false, benefitItem: true};
                                    let productInfos = t.getProductByPriority({Id: benefitItens[index].productId});
                                    let priorityPrice = {listPrice: productInfos.priorityPrice.listPrice, costPrice: productInfos.priorityPrice.costPrice, priceListCode: productInfos.priorityPrice.priceListCode};
                                    comboItens.push(t.createProduct(productInfos.productInfos, priorityPrice, comboValues, t.getCurrentProductPosition() + counter));
                                    counter++;
                                }
                            }

                            const data1 = logicApplyCombo(t, mixTotal, comboItens, counter, idsToRemove);
                            comboItens = data1.comboItens;
                            idsToRemove = data1.idsToRemove;
                            let allProducts = [];
                            for (let index = 0; index < t.products.length; index++) {
                                if (!idsToRemove.includes(t.products[index].productId)) allProducts.push(t.products[index]);
                            }
                            comboItens.push.apply(comboItens, allProducts);
                            t.products = t.parseObject(comboItens);
                        
                            
                            for (let index = 0; index < t.products.length; index++) {
                                t.addProduct = t.products[index];
                                let priorityInfos = t.getProductByPriority({Id: t.addProduct.productId}).priorityPrice;
                                if (t.isFilled(priorityInfos)) {
                                    if (priorityInfos.listPrice != t.addProduct.listPrice || priorityInfos.costPrice != t.addProduct.listCost || t.checkCombo) {
                                        t.addProduct.listPrice = t.isFilled(priorityInfos.listPrice) ? t.fixDecimalPlaces(priorityInfos.listPrice) : 0;
                                        t.addProduct.listPriceFront = t.isFilled(priorityInfos.listPrice) ? t.fixDecimalPlacesFront(priorityInfos.listPrice) : 0;
                                        t.addProduct.listCost = t.isFilled(priorityInfos.costPrice) ? t.fixDecimalPlaces(priorityInfos.costPrice) : 0;
                                        t.addProduct.practicedCost = t.isFilled(priorityInfos.costPrice) ? t.fixDecimalPlaces(priorityInfos.costPrice) : 0;
                                        t.addProduct.priceListCode = priorityInfos.priceListCode;

                                        t.addProduct.tListPrice = t.isFilled(priorityInfos.tListPrice) ? priorityInfos.tListPrice : 0;
                                        t.addProduct.tListPriceFront = t.isFilled(priorityInfos.tListPrice) ? 'R$' + t.fixDecimalPlacesFront(priorityInfos.tListPrice) : 'R$0';
                                        t.addProduct.rListPrice = t.isFilled(priorityInfos.rListPrice) ? priorityInfos.rListPrice : 0;
                                        t.addProduct.rListPriceFront = t.isFilled(priorityInfos.rListPrice) ? 'R$' + t.fixDecimalPlacesFront(priorityInfos.rListPrice) : 'R$0';

                                        if (t.addProduct.commercialAdditionPercentage != '0%') t.addProduct.unitPrice = t.addProduct.listPrice + t.calculateValue(t.addProduct.commercialAdditionPercentage, t.addProduct.listPrice);
                                        else if (t.addProduct.commercialDiscountPercentage != '0%') t.addProduct.unitPrice = t.addProduct.listPrice - t.calculateValue(t.addProduct.commercialDiscountPercentage, t.addProduct.listPrice);

                                        t.addProduct.unitPriceFront = t.fixDecimalPlacesFront(t.addProduct.unitPrice);
                                        
                                        t.calculateDiscountOrAddition();
                                        t.calculateTotalPrice(true, t.addProduct.commercialDiscountValue > 0);
                                        let margin = t.isFilled(t.addProduct.practicedCost) ? t.fixDecimalPlaces((1 - (Number(t.addProduct.practicedCost) / (t.addProduct.totalPrice / t.addProduct.quantity))) * 100) : 0;
                                        t.addProduct.commercialMarginPercentage = margin;
                                        listPriceChange = true;
                                    }
                                    orderProducts.push(t.addProduct);
                                } else {
                                    productsWithoutPrice = productsWithoutPrice != '' ? productsWithoutPrice + ', ' + t.addProduct.name : t.addProduct.name;
                                    itemToExclude.push(t.addProduct.orderItemId)
                                }
                            }
                            t.products = t.parseObject(orderProducts);
                            t.showIncludedProducts = t.products.length > 0;
                            t.excludedItems = t.isFilled(t.excludedItems) ? t.excludedItems : t.parseObject(itemToExclude);
                            t._setExcludedesItems();
                            if (t.products.length > 0) t._setData();
                            if (listPriceChange && !t.checkCombo) t.showToast('warning', 'Alteração na lista de preço!', 'Os preços foram ajustados de acordo com os valores da lista de preço. Verifique-os.');
                            if (productsWithoutPrice != '') t.showToast('warning', 'Produtos sem preço!', 'Os produtos ' + productsWithoutPrice + ' foram removidos do pedido.');
                        });
                    }

                    if (!t.headerData.IsOrderChild && allowChange && checkFinancialInfos) t.financialInfoLogic(orderData);
                    else t.showLoading = false;

                    if (!t.headerData.IsOrderChild && !t.isFilled(t.headerData.codigo_sap)) {
                        let headerValues = {cropId:t.headerData.safra.Id,salesOrgId:t.selectedCompany.salesOrgId,salesTeamId:t.selectedCompany.salesTeamId,salesOfficeId:t.selectedCompany.salesOfficeId,salesConditionId:t.headerData.condicao_venda.Id, paymentConditionId:t.headerData.condicao_pagamento.Id};
                        getMixAndConditionCombos({data: JSON.stringify(headerValues)})
                        .then((result) => {
                            let combosAndPromotions = JSON.parse(result);
                            if (combosAndPromotions.length > 0) t.combosData = combosAndPromotions;
                        });
                    }
                })
            } else {
                t.showLoading = false;
            }
        });
    }

    emptyDiscounFields(item) {
        item.commercialDiscountPercentage = '0%';
        item.commercialDiscountPercentageFront = '0%';
        item.commercialDiscountValue = 0;
        item.commercialDiscountValueFront = 0;
        item.commercialAdditionPercentage = '0%';
        item.commercialAdditionPercentageFront = '0%';
        item.commercialAdditionValue = 0;
        item.commercialAdditionValueFront = 0;
        item.comboDiscountPercent = '0%';
        item.comboDiscountValue = 0;
        item.initialTotalValue = null;
        return item;
    }

    financialInfoLogic(orderData) {
        let t = this
        getFinancialInfos({data: JSON.stringify(orderData)})
        .then((result) => {
            t.financialInfos = JSON.parse(result);

            if (t.products.length > 0) {
                let showPriceChange = false;
                let showQuantityChange = false;
                let priceChangeMessage = '';
                let currentProducts = t.products;

                for (let index = 0; index < currentProducts.length; index++) {
                    t.recalculatePrice = true;
                    t.editProduct(currentProducts[index].position, true);
                    let oldQUantity = currentProducts[index].quantity;
                    t.addProduct.quantity = t.calculateMultiplicity(t.addProduct.dosage * t.hectares, false);
                    if (t.addProduct.quantity != oldQUantity) showQuantityChange = true;

                    let oldPrice = currentProducts[index].unitPrice;
                    t.calculateTotalPrice(true);
                    let newPrice = t.changeProduct(t.addProduct);

                    if (oldPrice != newPrice) {
                        showPriceChange = true;
                        priceChangeMessage += 'O preço do ' + currentProducts[index].name + ' foi alterado de ' + oldPrice + ' para ' + newPrice + '.\n';
                    }
                    t.addProduct.quantityFront = t.fixDecimalPlacesFront(t.addProduct.quantity);
                }

                t.recalculatePrice = false;
                if (showPriceChange) {
                    if (currentProducts.length > 1) priceChangeMessage = 'Os preços foram recalculados devido a alteração de data de pagamento. Verifique-os.';
                    t.showToast('warning', 'Alteração nos preços!', priceChangeMessage);
                }
                if (showQuantityChange) t.showToast('warning', 'Alteração nas quantidades!', 'As quantidades foram recalculados devido a alteração no hectar. Verifique-os.');
                if (t.headerData.tipo_venda == 'Venda Barter') {
                    updateCommodities(t);
                }
                t.showLoading = false;
                t._setData();
            } else {
                t.showLoading = false;
            }
        })
    }

    getProductByPriority(selectedProduct) {
        let t = this
        let productsPrice = t.productsPriceMap;
        let productId = t.isFilled(selectedProduct.Id) ? selectedProduct.Id : selectedProduct.productId;
        let priorityPrice = {Id: productId, costPrice: 0, listPrice: 0, priceListCode: 0, rCostPrice: 0, rListPrice: 0, rPriceListCode: 0, tCostPrice: 0, tListPrice: 0, tPriceListCode: 0};

        let counter = 1;
        let currentinfos;
        let counterMax = t.showRoyaltyTsi ? 3 : 1;

        while (counter <= counterMax) {
            let prefix;
            if (counter == 1) prefix = 'G-';
            if (counter == 2) prefix = 'R-';
            if (counter == 3) prefix = 'T-';

            let key1 = prefix + t.accountData.Id + '-' + productId;
            let key2 = prefix + t.salesInfos.segmento + '-' + productId;
            let key3 = prefix + t.headerData.cultura.Id + '-' + t.salesInfos.salesTeamId + '-' + productId;
            let key4 = prefix + t.salesInfos.salesTeamId + '-' + productId;
            let key5 = prefix + t.salesInfos.salesOfficeId + '-' + productId;
            let key6 = prefix + selectedProduct.productGroupId;
            let key7 = prefix + productId;

            let currentPrice;
            if (t.isFilled(productsPrice[key1])) currentPrice = productsPrice[key1];
            else if (t.isFilled(productsPrice[key2])) currentPrice = productsPrice[key2];
            else if (t.isFilled(productsPrice[key3])) currentPrice = productsPrice[key3];
            else if (t.isFilled(productsPrice[key4])) currentPrice = productsPrice[key4];
            else if (t.isFilled(productsPrice[key5])) currentPrice = productsPrice[key5];
            else if (t.isFilled(productsPrice[key6])) currentPrice = productsPrice[key6];
            else if (t.isFilled(productsPrice[key7])) currentPrice = productsPrice[key7];

            if (t.isFilled(currentPrice)) {
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
            currentinfos = currentPrice;
            counter++;
        }
        return {productInfos: currentinfos, priorityPrice: priorityPrice};
    }

    showProductModal(event) {
        let t = this
        let productId = event.target.dataset.targetId;
        let productValidation = t.baseProducts.find(e => e.Id == productId);
        let quoteData = {cropId:t.headerData.safra.Id,sellerId:t.headerData.ctv_venda.Id,productsIds:[productValidation.Id]};

        if (t.verifyQuota && t.showRoyaltyTsi) {
            t.showLoading = true;
            checkQuotaQuantity({data: JSON.stringify(quoteData)})
            .then((result) => {
                let allQuotas = t.parseObject(t.allProductQuotas);
                let productQuota = JSON.parse(result);
                let currentQuota;

                if (allQuotas.length > 0) currentQuota = allQuotas.find(e => e.individualQuotaId == productQuota.individualQuotaId);
                if (!t.isFilled(currentQuota) && productQuota.length > 0) allQuotas.push(productQuota[0]);

                t.allProductQuotas = t.parseObject(allQuotas);
                if (productQuota.length == 0 || productQuota[0].balance == 0) {
                    t.showLoading = false;
                    t.showToast('warning', 'Quantidade indisponível', 'Cota indisponível para o produto nos parâmetros atuais');
                } else {
                    t.showLoading = false;
                    t.openModalLogic(productValidation, productId);
                }
            });
        } else {
            t.openModalLogic(productValidation, productId);
        }
    }

    openModalLogic(productValidation, productId) {
        let t = this
        isSeedSale({salesOrgId: t.selectedCompany.salesOrgId, productGroupName: productValidation.productGroupName})
        .then((result) => {
            t.seedSale = result;
        });

        t.createNewProduct = !t.createNewProduct;
        if (t.createNewProduct) {
            let existProduct = t.products.find(e => e.productId == productId);
            if (t.isFilled(existProduct)) {
                t.createNewProduct = false;
                t.editProduct(existProduct.position, false);
            } else {
                let currentProduct = t.baseProducts.find(e => e.Id == productId);
                let priorityInfos = t.getProductByPriority(currentProduct);
                t.updateProduct = false;
                t.multiplicity = t.isFilled(currentProduct.multiplicity) && currentProduct.multiplicity > 0 ? currentProduct.multiplicity : 1;
                t.costPrice = priorityInfos.priorityPrice.costPrice;
                let currentPosition = t.getCurrentProductPosition() + 1;
                t.addProduct = t.createProduct(currentProduct, priorityInfos.priorityPrice, null, currentPosition);
            }
        }
    }

    createProduct(prod, prices, combos, counter) {
        let t = this
        let newProductData = {
            entryId: prod.entryId,
            productId: prod.Id,
            name: prod.Name,
            unity: prod.unity,
            listPrice: t.isFilled(prices.listPrice) ? t.fixDecimalPlaces(prices.listPrice) : 0,
            listPriceFront: t.isFilled(prices.listPrice) ? t.fixDecimalPlacesFront(prices.listPrice) : 0,
            listCost: t.isFilled(prices.costPrice) ? t.fixDecimalPlaces(prices.costPrice) : 0,
            practicedCost: t.isFilled(prices.costPrice) ? t.fixDecimalPlaces(prices.costPrice) : 0,
            dosage: t.isFilled(combos) ? combos.dosage : (t.isFilled(prod.dosage) ? prod.dosage : ''),
            dosageFront: t.isFilled(combos) ? combos.dosage : (t.isFilled(prod.dosage) ? t.fixDecimalPlacesFront(prod.dosage) : ''),
            brokerage: 0,
            brokerageFront: 0,
            quantity: t.isFilled(combos) ? combos.quantity : null,
            quantityFront: t.isFilled(combos) ? t.fixDecimalPlacesFront(combos.quantity) : null,
            unitPrice: t.isFilled(prices.listPrice) ? t.fixDecimalPlaces(prices.listPrice) : 0,
            unitPriceFront: t.isFilled(prices.listPrice) ? t.fixDecimalPlacesFront(prices.listPrice) : 0,
            totalPrice: null,
            totalPriceFront: null,
            totalPriceWithBrokerage: null,
            totalPriceWithBrokerageFront: null,
            initialTotalValue: null,
            commercialDiscountPercentage: t.isFilled(combos) ? '0%' : null,
            commercialDiscountPercentageFront: t.isFilled(combos) ? '0%' : null,
            commercialDiscountValue: t.isFilled(combos) ? 0 : null,
            commercialDiscountValueFront: t.isFilled(combos) ? 0 : null,
            commercialAdditionPercentage: t.isFilled(combos) ? '0%' : null,
            commercialAdditionPercentageFront: t.isFilled(combos) ? '0%' : null,
            commercialAdditionValue: t.isFilled(combos) ? 0 : null,
            commercialAdditionValueFront: t.isFilled(combos) ? 0 : null,
            financialAdditionPercentage: t.isFilled(combos) ? '0%' : null,
            financialAdditionPercentageFront: t.isFilled(combos) ? '0%' : null,
            financialAdditionValue: t.isFilled(combos) ? 0 : null,
            financialAdditionValueFront: t.isFilled(combos) ? 0 : null,
            financialDecreasePercentage: t.isFilled(combos) ? '0%' : null,
            financialDecreasePercentageFront: t.isFilled(combos) ? '0%' : null,
            financialDecreaseValue: t.isFilled(combos) ? 0 : null,
            financialDecreaseValueFront: t.isFilled(combos) ? 0 : null,
            invoicedQuantity: t.isFilled(prod.invoicedQuantity) ? prod.invoicedQuantity : 0,
            motherAvailableQuantity: prod.motherAvailableQuantity,
            activePrinciple: prod.activePrinciple != null ? prod.activePrinciple : '',
            brand: prod.brand != null ? prod.brand : '',
            productGroupId: prod.productGroupId != null ? prod.productGroupId : '',
            productGroupName: prod.productGroupName != null ? prod.productGroupName : '',
            productSubgroupId: prod.productSubgroupId != null ? prod.productSubgroupId : '',
            productSubgroupName: prod.productSubgroupName != null ? prod.productSubgroupName : '',
            productHierarchyId: prod.productHierarchyId != null ? prod.productHierarchyId : '',
            sapStatus: prod.sapStatus != null ? prod.sapStatus : '',
            sapProductCode: prod.sapProductCode != null ? prod.sapProductCode : '',
            ptaProduct: prod.ptaProduct,
            priceListCode: prices.priceListCode,
            sieve: t.isFilled(prod.sieve) ? prod.sieve : '',
            productClass: t.isFilled(prod.productClass) ? prod.productClass : '',
            comboDiscountPercent: t.isFilled(combos) ? combos.comboDiscount + '%' : '0%',
            comboDiscountValue: 0,
            comboId: t.isFilled(combos) ? combos.comboId : null,
            industryCombo: t.isFilled(combos) ? combos.industryCombo : false,
            position: t.isFilled(counter) ? counter : null,
            containsCombo: t.isFilled(combos) ? combos.containsCombo : (t.isFilled(prod.containsCombo) ? prod.containsCombo : false),
            formerItem: t.isFilled(combos) ? combos.formerItem : false,
            benefitItem: t.isFilled(combos) ? combos.benefitItem : false,
            tListPrice: t.isFilled(prices.tListPrice) ? prices.tListPrice : 0,
            tListPriceFront: t.isFilled(prices.tListPrice) ? 'R$' + t.fixDecimalPlacesFront(prices.tListPrice) : 'R$0',
            tsiTotalPrice: 0,
            tsiTotalPriceFront: 0,
            rListPrice: t.isFilled(prices.rListPrice) ? prices.rListPrice : 0,
            rListPriceFront: t.isFilled(prices.rListPrice) ? 'R$' + t.fixDecimalPlacesFront(prices.rListPrice) : 'R$0',
            royaltyTotalPrice: 0,
            royaltyTotalPriceFront: 0,
            brokeragePerUnit: t.isFilled(prod.brokeragePerUnit) ? prod.brokeragePerUnit : '',
            containsComboString: 'Não'
        };

        newProductData.containsComboString = newProductData.containsCombo ? 'Sim' : 'Não';
        return newProductData;
    }

    changeTableColumns(event) {
        let field = event.target.dataset.targetId;
        this.selectedColumns[field] = this.isFilled(this.selectedColumns[field]) ? !this.selectedColumns[field] : true;
    }

    applySelectedColumns(event) {
        let newColumns = [{label: 'Produto', fieldName: 'name'}];
        if (this.check(this.selectedColumns.columnUnity)) newColumns.push({label: 'Unidade de Medida', fieldName: 'unity'})
        if (this.check(this.selectedColumns.columnListPrice)) newColumns.push({label: 'Preço Lista (un)', fieldName: 'listPriceFront'})
        if (this.check(this.selectedColumns.columnDosage)) newColumns.push({label: 'Dosagem', fieldName: 'dosage'})
        if (this.check(this.selectedColumns.columnBrokerage)) newColumns.push({label: 'Corretagem', fieldName: 'brokerage'})
        if (this.check(this.selectedColumns.columnQuantity)) newColumns.push({label: 'Qtd', fieldName: 'quantity'})
        if (this.check(this.selectedColumns.columnUnitPrice)) newColumns.push({label: 'Preço Praticado (un)', fieldName: 'unitPriceFront'})
        if (this.check(this.selectedColumns.columnTotalPrice)) newColumns.push({label: 'Preço Total', fieldName: this.seedSale ? 'totalPriceWithBrokerageFront' : 'totalPriceFront'})
        if (this.check(this.selectedColumns.columnCommercialDiscountPercentage)) newColumns.push({label: '% Desconto Comercial', fieldName: 'commercialDiscountPercentageFront'})
        if (this.check(this.selectedColumns.columnCommercialDiscountValue)) newColumns.push({label: 'Valor de Desconto Comercial', fieldName: 'commercialDiscountValueFront'})
        if (this.check(this.selectedColumns.columnCommercialAdditionPercentage)) newColumns.push({label: '% Acréscimo Comercial', fieldName: 'commercialAdditionPercentageFront'})
        if (this.check(this.selectedColumns.columnCommercialAdditionValue)) newColumns.push({label: 'Valor de Acréscimo Comercial', fieldName: 'commercialAdditionValueFront'})
        if (this.check(this.selectedColumns.columnFinancialAdditionPercentage)) newColumns.push({label: '% Acréscimo Financeiro', fieldName: 'financialAdditionPercentageFront'})
        if (this.check(this.selectedColumns.columnFinancialAdditionValue)) newColumns.push({label: 'Valor de Acréscimo Financeiro', fieldName: 'financialAdditionValueFront'})
        if (this.check(this.selectedColumns.columnFinancialDecreasePercentage)) newColumns.push({label: '% Decréscimo Financeiro', fieldName: 'financialDecreasePercentageFront'})
        if (this.check(this.selectedColumns.columnFinancialDecreaseValue)) newColumns.push({label: 'Valor de Decréscimo Financeiro', fieldName: 'financialDecreaseValueFront'})
        if (this.check(this.selectedColumns.columnInvoicedQuantity)) newColumns.push({label: 'Quantidade Faturada', fieldName: 'invoicedQuantity'})
        if (this.check(this.selectedColumns.columnActivePrinciple)) newColumns.push({label: 'Princípio Ativo', fieldName: 'activePrinciple'})
        if (this.check(this.selectedColumns.columnGroup)) newColumns.push({label: 'Grupo do Produto', fieldName: 'productGroupName'})
        if (this.check(this.selectedColumns.columnproductSubgroupName)) newColumns.push({label: 'Subgrupo do Produto', fieldName: 'productSubgroupName'})
        if (this.check(this.selectedColumns.columnSieve)) newColumns.push({label: 'Peneira', fieldName: 'sieve'})
        if (this.check(this.selectedColumns.columnProductClass)) newColumns.push({label: 'Classe/Categoria', fieldName: 'productClass'})
        if (this.check(this.selectedColumns.columnContainsCombo)) newColumns.push({label: 'Produto Combo', fieldName: 'containsComboString'})
        if (newColumns.length >= 2) {
            newColumns.push({
                type: 'action',
                typeAttributes: {rowActions:actions,menuAlignment:'auto'}
            });
            this.columns = newColumns;
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
                this.addProduct.commercialDiscountValue = this.isFilled(priceWithFinancialValue) ? this.calculateValue(this.addProduct.commercialDiscountPercentage, priceWithFinancialValue) : this.addProduct.commercialDiscountValue;
                this.addProduct.commercialDiscountValueFront = this.fixDecimalPlacesFront(Number(this.addProduct.commercialDiscountValue));
                this.calculateTotalPrice(true, true);
            } else if (fieldId == 'commercialDiscountValue') {
                this.addProduct.commercialDiscountValue = this.addProduct.commercialDiscountValue == '' ? 0 : this.fixDecimalPlaces(Number(this.addProduct.commercialDiscountValue));
                this.addProduct.commercialDiscountValueFront = this.addProduct.commercialDiscountValue == '' ? 0 : this.fixDecimalPlacesFront(Number(this.addProduct.commercialDiscountValue));
                this.addProduct.commercialDiscountPercentage = this.isFilled(priceWithFinancialValue) ? this.calculatePercentage(this.addProduct.commercialDiscountValue, priceWithFinancialValue) : this.addProduct.commercialDiscountPercentage;
                this.addProduct.commercialDiscountPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialDiscountPercentage);
                this.calculateTotalPrice(true, true);
            } else if (fieldId == 'commercialAdditionPercentage') {
                this.addProduct.commercialAdditionPercentage = this.addProduct.commercialAdditionPercentage == '' ? '0%' : this.addProduct.commercialAdditionPercentage;
                this.addProduct.commercialAdditionPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialAdditionPercentage);
                this.addProduct.commercialAdditionValue = this.isFilled(priceWithFinancialValue) ? this.calculateValue(this.addProduct.commercialAdditionPercentage, priceWithFinancialValue) : this.addProduct.commercialAdditionValue;
                this.addProduct.commercialAdditionValueFront = this.fixDecimalPlacesFront(Number(this.addProduct.commercialAdditionValue));
                this.calculateTotalPrice(true, false);
            } else if (fieldId == 'commercialAdditionValue') {
                this.addProduct.commercialAdditionValue = this.addProduct.commercialAdditionValue == '' ? 0 : this.fixDecimalPlaces(Number(this.addProduct.commercialAdditionValue));
                this.addProduct.commercialAdditionValueFront = this.addProduct.commercialAdditionValue == '' ? 0 : this.fixDecimalPlacesFront(Number(this.addProduct.commercialAdditionValue));
                this.addProduct.commercialAdditionPercentage = this.isFilled(priceWithFinancialValue) ? this.calculatePercentage(this.addProduct.commercialAdditionValue, priceWithFinancialValue) : this.addProduct.commercialAdditionPercentage;
                this.addProduct.commercialAdditionPercentageFront = this.fixDecimalPlacesPercentage(this.addProduct.commercialAdditionPercentage);
                this.calculateTotalPrice(true, false);
            } else if (fieldId == 'dosage') {
                if (this.isFilled(this.hectares)) {
                    this.addProduct.dosageFront = this.fixDecimalPlacesFront(this.addProduct.dosage);
                    this.addProduct.quantity = this.calculateMultiplicity(this.addProduct.dosage * this.hectares, false);
                    this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                    this.calculateDiscountOrAddition();
                    this.calculateTotalPrice(true);
                    this.addProduct.quantityFront = this.fixDecimalPlacesFront(this.addProduct.quantity);
                }
            } else if (fieldId == 'brokerage'){
                if (!this.headerData.IsOrderChild) {
                    this.addProduct.brokerage = this.addProduct.brokerage != '' ? this.addProduct.brokerage : 0;
                    this.addProduct.brokerageFront = this.addProduct.brokerage != '' ? this.fixDecimalPlacesFront(this.addProduct.brokerage) : 0;
                    this.calculateTotalPrice(true);
                } else {
                    this.addProduct.brokerage = this.addProduct.brokerage != '' ? this.addProduct.brokerage : 0;
                    this.addProduct.brokerageFront = this.addProduct.brokerage != '' ? this.fixDecimalPlacesFront(this.addProduct.brokerage) : 0;
                    this.addProduct.totalPriceWithBrokerage = this.addProduct.totalPrice + this.addProduct.brokerage;
                    this.addProduct.totalPriceWithBrokerageFront = this.fixDecimalPlacesFront(this.addProduct.totalPriceWithBrokerage);
                }

            } else if (fieldId == 'quantity') {
                this.addProduct.quantity = this.calculateMultiplicity(this.addProduct.quantity, false);
                if (!this.headerData.IsOrderChild) {
                    this.addProduct.dosage = this.isFilled(this.hectares) ? this.addProduct.quantity / this.hectares : 0;
                    this.addProduct.dosageFront = this.fixDecimalPlacesFront(this.addProduct.dosage);
                    this.listTotalPrice = this.addProduct.listPrice * this.addProduct.quantity;
                    this.calculateDiscountOrAddition();
                    this.calculateTotalPrice(true);
                    this.addProduct.quantityFront = this.fixDecimalPlacesFront(this.addProduct.quantity);
                } else {
                    this.addProduct.totalPrice = this.fixDecimalPlaces((this.addProduct.unitPrice * this.addProduct.quantity));
                    this.addProduct.totalPriceFront = this.fixDecimalPlacesFront((this.addProduct.unitPrice * this.addProduct.quantity));
                    this.addProduct.quantityFront = this.fixDecimalPlacesFront(this.addProduct.quantity);
                    
                    if (this.seedSale) {
                        this.addProduct.brokerage =  this.addProduct.brokeragePerUnit != '' ? this.addProduct.quantity * Number(this.addProduct.brokeragePerUnit) : this.addProduct.brokerage;
                        this.addProduct.brokerageFront = this.isFilled(this.addProduct.brokerage) ? this.fixDecimalPlacesFront(this.addProduct.brokerage) : '0';
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
            this.multiplicity = this.multiplicity > 0 ? this.multiplicity : 1;
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
                this.showToast('warning', 'Atenção!', 'A quantidade foi arredondada para ' + this.fixDecimalPlacesFront(quantity) + '.');
                return quantity;
            }
        }
    }

    calculateTotalPrice(recalculateUnitPrice, isDiscount) {
        let t = this;
        t.addProduct.totalPrice = null;
        t.addProduct.totalPriceWithBrokerage = null;
        t.addProduct.tsiTotalPrice = t.addProduct.tListPrice * t.addProduct.quantity;
        t.addProduct.tsiTotalPriceFront = t.fixDecimalPlacesFront(t.addProduct.tsiTotalPrice);
        t.addProduct.royaltyTotalPrice = t.addProduct.rListPrice * t.addProduct.quantity;
        t.addProduct.royaltyTotalPriceFront = t.fixDecimalPlacesFront(t.addProduct.royaltyTotalPrice);

        if (t.isFilled(isDiscount)) {
            if (isDiscount && t.addProduct.commercialDiscountValue > 0) {
                t.addProduct.commercialAdditionValue = 0;
                t.addProduct.commercialAdditionValueFront = 0;
                t.addProduct.commercialAdditionPercentage = '0%';
                t.addProduct.commercialAdditionPercentageFront = '0%';
            } else if (!isDiscount && t.addProduct.commercialAdditionValue > 0) {
                t.addProduct.commercialDiscountValue = 0;
                t.addProduct.commercialDiscountValueFront = 0;
                t.addProduct.commercialDiscountPercentage = '0%';
                t.addProduct.commercialDiscountPercentageFront = '0%';
            }
        }

        if (t.isFilled(t.addProduct.quantity) && t.isFilled(t.addProduct.listPrice)) {
            let inicialTotalPrice = t.addProduct.quantity * t.addProduct.listPrice;
            if (!t.isFilled(t.addProduct.initialTotalValue)) {
                t.addProduct.initialTotalValue = t.fixDecimalPlaces(inicialTotalPrice);
                t.calculateFinancialInfos();
                t.addProduct.initialTotalValue = t.fixDecimalPlaces(t.addProduct.totalPrice);
            } else {
                t.addProduct.totalPrice = t.addProduct.quantity * t.addProduct.listPrice;
                t.addProduct.financialAdditionValue = t.calculateValue(t.addProduct.financialAdditionPercentage, t.addProduct.totalPrice);
                t.addProduct.financialAdditionValueFront = t.fixDecimalPlacesFront(t.addProduct.financialAdditionValue);
                t.addProduct.financialDecreaseValue = t.calculateValue(t.addProduct.financialDecreasePercentage, t.addProduct.totalPrice);
                t.addProduct.financialDecreaseValueFront = t.fixDecimalPlacesFront(t.addProduct.financialDecreaseValue);
            }

            t.addProduct.totalPrice = t.isFilled(t.addProduct.financialAdditionValue) ? (t.addProduct.totalPrice + Number(t.addProduct.financialAdditionValue)) : t.addProduct.totalPrice;
            t.addProduct.totalPrice = t.isFilled(t.addProduct.financialDecreaseValue) ? (t.addProduct.totalPrice - Number(t.addProduct.financialDecreaseValue)) : t.addProduct.totalPrice;
            if (t.addProduct.comboDiscountPercent != '0%') {
                t.addProduct.comboDiscountValue = t.calculateValue(t.addProduct.comboDiscountPercent, t.addProduct.totalPrice);
                t.addProduct.totalPrice = t.isFilled(t.addProduct.comboDiscountValue) ? (t.addProduct.totalPrice - Number(t.addProduct.comboDiscountValue)) : t.addProduct.totalPrice;
            } else {
                t.addProduct.totalPrice = t.isFilled(t.addProduct.commercialAdditionValue) ? (t.addProduct.totalPrice + Number(t.addProduct.commercialAdditionValue)) : t.addProduct.totalPrice;
                t.addProduct.totalPrice = t.isFilled(t.addProduct.commercialDiscountValue) ? t.fixDecimalPlaces((t.addProduct.totalPrice - Number(t.addProduct.commercialDiscountValue))) : t.fixDecimalPlaces(t.addProduct.totalPrice);
            }

            t.addProduct.totalPriceFront = t.fixDecimalPlacesFront(t.addProduct.totalPrice);
            t.addProduct.totalPriceWithBrokerage = Number(t.addProduct.totalPrice) + Number(t.addProduct.brokerage);
            t.addProduct.totalPriceWithBrokerageFront = t.fixDecimalPlacesFront(t.addProduct.totalPriceWithBrokerage);
            if (recalculateUnitPrice) {
                t.addProduct.unitPrice = t.fixDecimalPlaces((t.addProduct.totalPrice / t.addProduct.quantity));
                t.addProduct.unitPriceFront = t.fixDecimalPlacesFront((t.addProduct.totalPrice / t.addProduct.quantity));
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
            } else if (this.addProduct.commercialDiscountValue == '0.000000' && this.addProduct.commercialDiscountPercentage != '0%'){		 
                let priceWithFinancialValue = (this.addProduct.listPrice * this.addProduct.quantity) + Number(this.addProduct.financialAdditionValue) - Number(this.addProduct.financialDecreaseValue);		 
                 		 
                this.addProduct.commercialDiscountValue = this.isFilled(priceWithFinancialValue) ? this.calculateValue(this.addProduct.commercialDiscountPercentage, priceWithFinancialValue) : this.addProduct.commercialDiscountValue;		 
                this.addProduct.commercialDiscountValueFront = this.addProduct.commercialDiscountValue == '' ? 0 : this.fixDecimalPlacesFront(Number(this.addProduct.commercialDiscountValue));		 
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

    fixDecimalPlacesFront(value) {
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
            let key1 = defaultKey + '-' + this.financialInfos.clientGroup + '-' + this.addProduct.productId;
            let key2 = defaultKey + '-' + this.financialInfos.salesTeam + '-' + this.addProduct.productId;
            let key3 = defaultKey + '-' + this.financialInfos.salesTeam + '-' + this.addProduct.productGroupId;
            let key4 = defaultKey + '-' + this.addProduct.productGroupId;

            let currentDiscountOrAddition = 0;
            let financialValues = this.financialInfos.financialValues;
            if (this.isFilled(financialValues[key1])) currentDiscountOrAddition = financialValues[key1];
            else if (this.isFilled(financialValues[key2])) currentDiscountOrAddition = financialValues[key2];
            else if (this.isFilled(financialValues[key3])) currentDiscountOrAddition = financialValues[key3];
            else if (this.isFilled(financialValues[key4])) currentDiscountOrAddition = financialValues[key4];
            else if (this.isFilled(financialValues[defaultKey])) currentDiscountOrAddition = financialValues[defaultKey];

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
                if (this.financialInfos.isDiscount) this.addProduct.practicedCost = this.fixDecimalPlaces((Number(this.addProduct.listCost) - (Number(this.addProduct.listCost) * (Number(currentDiscountOrAddition) / 100))));
                else this.addProduct.practicedCost = this.fixDecimalPlaces((Number(this.addProduct.listCost) + (Number(this.addProduct.listCost) * (Number(currentDiscountOrAddition) / 100))));
            }
        }
    }

    isFilled(field) {
        return ((field !== undefined && field != null && field != '') || field == 0);
    }

    greaterThanZero(field) {
        return ((field !== undefined && field != null && field > 0));
    }

    check(field) {
        return (field !== undefined && field != null && field != '' && field == true);
    }

    includeProduct() {
        console.log('this.addProduct: ' + JSON.stringify(this.addProduct));
        let prod = this.addProduct;
        if (this.verifyQuota && this.showRoyaltyTsi) {
            let availableQuota = this.verifyProductQuota(prod);
            if (!availableQuota) return;
        }

        if (this.checkRequiredFields(prod)) {
            let allProducts = this.parseObject(this.products);
            let comboDiscountPercent = this.verifyComboAndPromotion(prod.quantity);
            prod = this.applyComboOnProduct(this.addProduct, comboDiscountPercent);

            let margin = this.isFilled(this.addProduct.practicedCost) ? this.fixDecimalPlaces((1 - (Number(this.addProduct.practicedCost) / (prod.totalPrice / prod.quantity))) * 100) : 0;
            prod.commercialMarginPercentage = margin;
            prod.costPrice = this.costPrice;
            prod.multiplicity = this.multiplicity > 0 ? this.multiplicity : 1;
            allProducts.push(prod);

            console.log(JSON.stringify(allProducts));
            this.showIncludedProducts = true;
            this.addProduct = {};
            this.products = this.parseObject(allProducts);
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
            let combos = this.parseObject(this.combosData);
            for (let index = 0; index < combos.length; index++) {
                if (combos[index].recTypeDevName == 'ProductMix' && combos[index].comboCondition == 'Parcial') {
                    let groupsData = combos[index].groupQuantities;

                    if (this.isFilled(groupsData)) {
                        let productGroupCombo = groupsData.find(e => e.productId == this.addProduct.productId);
                        if (this.isFilled(productGroupCombo) && quantity >= productGroupCombo.quantity && combos[index].recTypeDevName == 'ProductMix') {
                            return {discount: combos[index].comboDiscountPercentage,comboId: combos[index].comboId,industryCombo: combos[index].comboType == 'Indústria',comboQuantity: Math.floor(quantity / productGroupCombo.quantity)};
                        }
                    }
                }
            }

            let paymentConditionCombo = combos.find(e => e.paymentConditionId == this.headerData.condicao_pagamento.Id);
            if (this.isFilled(paymentConditionCombo) && paymentConditionCombo.recTypeDevName == 'PaymentCondition') {
                let groupsData = paymentConditionCombo.groupQuantities;
                if (this.isFilled(groupsData)) {
                    let productGroupCombo = groupsData.find(e => e.productGroupId == this.addProduct.productGroupId);
                    if (this.isFilled(productGroupCombo) && quantity >= productGroupCombo.quantity) {
                        return {discount:paymentConditionCombo.comboDiscountPercentage,comboId:paymentConditionCombo.comboId,industryCombo:paymentConditionCombo.comboType == 'Indústria',comboQuantity:Math.floor(quantity / productGroupCombo.quantity)};
                    }
                }
            }
        }

        return null;
    }

    applyComboOnProduct(prod, combo) {
        if ((prod.commercialDiscountPercentageFront == '0%' && prod.comboDiscountPercent == '0%' && combo != null) || (combo == null && prod.comboId != null)) {
            let removeCombo = combo == null && prod.comboId != null;
            let totalPrice = removeCombo ? Number(prod.totalPrice) + Number(prod.comboDiscountValue) : prod.totalPrice;

            prod.comboId = removeCombo ? null : combo.comboId;
            prod.comboDiscountPercent = removeCombo ? '0%' : combo.discount + '%';
            prod.comboDiscountValue = removeCombo ? 0 : this.calculateValue(combo.discount + '%', totalPrice);
            prod.totalPrice = removeCombo ? totalPrice : Number(totalPrice) - Number(prod.comboDiscountValue);
            prod.totalPriceFront = this.fixDecimalPlacesFront(prod.totalPrice);
            prod.industryCombo = removeCombo ? false : combo.industryCombo;
            prod.unitPrice = this.fixDecimalPlaces(prod.totalPrice / prod.quantity);
            prod.unitPriceFront = this.fixDecimalPlacesFront(prod.unitPrice);
            prod.containsCombo = removeCombo ? false : true;
            prod.containsComboString = removeCombo ? 'Não' : 'Sim';
            let allCombos = this.parseObject(this.combosSelecteds);
            let keepCombos = [];
            for (let index = 0; index < allCombos.length; index++) {
                if (removeCombo) {
                    for (let index = 0; index < allCombos.length; index++) {
                        if (allCombos[index].comboId != prod.comboId) keepCombos.push(allCombos[index]);
                    }
                } else {
                    let currentCombo = allCombos.find(e => e.comboId == combo.comboId);
                    if (this.isFilled(currentCombo)) currentCombo.productQuantity = prod.quantity;
                    else allCombos.push({comboId:combo.comboId,comboQuantity:combo.comboQuantity,productQuantity:prod.quantity,productId:prod.productId,specificItemCombo:false});
                }
            }

            this.combosSelecteds = removeCombo ? this.parseObject(keepCombos) : this.parseObject(allCombos);
            this._setcombosSelecteds();
        }

        return prod;
    }

    changeComboQuantity(event) {
        let combos = this.parseObject(this.combosData);
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
        this.combosData = this.parseObject(combos);
    }

    addOne(event) {
        this.incrementCombo(event.target.dataset.targetId, true);
    }

    lessOne(event) {
        this.incrementCombo(event.target.dataset.targetId, false);
    }

    incrementCombo(comboId, addOne) {
        let combos = this.parseObject(this.combosData);
        for (let index = 0; index < combos.length; index++) {
            if (combos[index].comboId == comboId) {
                if (!addOne && combos[index].comboQuantity == 0) this.showToast('warning', 'Atenção!', 'Não é possível selecionar uma quantidade abaixo de 0.');
                else if (addOne && combos[index].comboQuantity == combos[index].comboAvailableQuantity) this.showToast('warning', 'Atenção!', 'A quantidade de combos disponível é de ' + combos[index].comboAvailableQuantity + '.');
                else combos[index].comboQuantity = addOne ? combos[index].comboQuantity + 1 : combos[index].comboQuantity - 1;

                this.changeSelectedComboData(combos[index]);
                break;
            }
        }
        this.combosData = this.parseObject(combos);
    }

    changeSelectedComboData(combo) {
        let allCombosSelecteds = this.parseObject(this.combosSelecteds);
        let constainsCombo = allCombosSelecteds.find(e => e.comboId == combo.comboId);
        if (this.isFilled(constainsCombo)) {
            for (let i = 0; i < allCombosSelecteds.length; i++) {
                if (allCombosSelecteds[i].comboId == combo.comboId) allCombosSelecteds[i].comboQuantity = combo.comboQuantity;
            }
        } else {
            allCombosSelecteds.push(combo);
        }
        this.combosSelecteds = this.parseObject(allCombosSelecteds);
        this._setcombosSelecteds();
    }

    verifyProductQuota(actualProduct) {
        let allQuotas = this.parseObject(this.allProductQuotas);
        let currentQuota = allQuotas.find(e => e.productId == actualProduct.productId);
        if (Number(actualProduct.quantity) > Number(currentQuota.balance)) {
            this.showToast('warning', 'Atenção!', 'Você inseriu a quantidade ' + actualProduct.quantity + '. Existem apenas ' + currentQuota.balance + ' do item ' + actualProduct.name + ' disponíveis para venda.');
            return false;
        } else {
            return true;
        }
    }

    changeProduct() {
        let includedProducts = this.parseObject(this.products);
        for (let index = 0; index < includedProducts.length; index++) {
            if (includedProducts[index].position == this.productPosition) {
                if (this.checkRequiredFields(this.addProduct)) {
                    if (this.verifyQuota && this.showRoyaltyTsi) {
                        let availableQuota = this.verifyProductQuota(this.addProduct);
                        if (!availableQuota) return;
                    }

                    let comboDiscountPercent = this.verifyComboAndPromotion(this.addProduct.quantity);
                    this.addProduct = this.applyComboOnProduct(this.addProduct, comboDiscountPercent);

                    let margin = this.isFilled(this.addProduct.practicedCost) ? this.fixDecimalPlaces(((1 - (Number(this.addProduct.practicedCost) / (Number(this.addProduct.totalPrice) / Number(this.addProduct.quantity)))) * 100)) : null;
                    this.addProduct.commercialMarginPercentage = this.headerData.IsOrderChild ? this.addProduct.commercialMarginPercentage : margin;
                    this.addProduct.multiplicity = this.multiplicity > 0 ? this.multiplicity : 1;
                    includedProducts[index] = this.parseObject(this.addProduct);
                    break;
                } else {
                    this.showToast('error', 'Atenção!', 'Campos obrigatórios não preenchidos.');
                    return;
                }
            }
        }

        this.products = this.parseObject(includedProducts);
        if (this.recalculatePrice) {
            this._verifyFieldsToSave();
            return this.addProduct.unitPrice;
        } else {
            this.updateProduct = false;
            this.createNewProduct = !this.createNewProduct;
            let allDivisions = this.parseObject(this.allDivisionProducts);
            if (allDivisions.length > 0) {
                let allDivisionQuantitys = 0;
                for (let index = 0; index < allDivisions.length; index++) {
                    let existingProductDivision = allDivisions[index];
                    if (existingProductDivision.productPosition == this.productPosition)  allDivisionQuantitys += Number(existingProductDivision.quantity);
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
        if (quantityError) this.showToast('warning', 'Atenção!', 'A soma das quantidades não pode ultrapassar ' + this.currentDivisionProduct.quantity + '.');
        else this.showProductDivision = !this.showProductDivision;
    }

    quantityExceed() {
        let allDivisions = this.parseObject(this.divisionProducts);
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
                if (filledDivisions[index].productPosition == this.productPosition) filledDivisions[index].orderItemKey = this.currentDivisionProduct.productId;
            }

            this.allDivisionProducts = this.parseObject(filledDivisions);
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

        this.multiplicity = this.isFilled(currentProduct.multiplicity) && currentProduct.multiplicity > 0 ? currentProduct.multiplicity : 1;
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
        this.divisionProducts = this.isFilled(this.allDivisionProducts) ? this.parseObject(this.allDivisionProducts) : [];
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
        this.multiplicity = this.isFilled(currentProduct.multiplicity) && currentProduct.multiplicity > 0 ? currentProduct.multiplicity : 1;
        let allowChange = (this.headerData.tipo_pedido != 'Pedido Filho' && !this.headerData.IsOrderChild && this.isFilled(this.headerData.codigo_sap)) ||
                          (this.headerData.tipo_pedido == 'Pedido Filho' && this.isFilled(this.headerData.codigo_sap)) ? true : false;
        this.currentDivisionProduct = {productId:currentProduct.productId,unitPrice:currentProduct.unitPrice,position:position,name:currentProduct.name,quantity:currentProduct.quantity,availableQuantity:availableQuantity,showRed:availableQuantity < 0 ? true : false,dontAllowChange:allowChange};
        this.showProductDivision = !this.showProductDivision;
        if (!this.currentDivisionProduct.dontAllowChange) this.newFields();
    }

    deleteProduct(position) {
        let excludeProduct = this.parseObject(this.products);
        let excludedProducts = this.isFilled(this.excludedItems) ? this.parseObject(this.excludedItems) : [];
        let counter;
        let comboId;
        for (let index = 0; index < excludeProduct.length; index++) {
            if (excludeProduct[index].position == position) {
                counter = index;
                if(excludeProduct[index].containsCombo){
                    this.showToast('warning', 'Produtos combos não podem ser excluídos!');
                    return;
                }
                if (excludeProduct[index].containsCombo) comboId = excludeProduct[index].comboId;
            }
        }

        if (this.isFilled(comboId)) {
            for (let index = 0; index < excludeProduct.length; index++) {
                if (excludeProduct[index].comboId == comboId && (excludeProduct[index].formerItem || excludeProduct[index].benefitItem)) {
                    excludeProduct[index].totalPrice = Number(excludeProduct[index].totalPrice) + Number(excludeProduct[index].comboDiscountValue);
                    excludeProduct[index].unitPrice = excludeProduct[index].listPrice;
                    excludeProduct[index].unitPriceFront = this.fixDecimalPlacesFront(excludeProduct[index].unitPrice);
                    excludeProduct[index].comboDiscountPercent = '0%';
                    excludeProduct[index].comboDiscountValue = 0;
                    excludeProduct[index].comboId = null;
                    excludeProduct[index].industryCombo = false;
                    excludeProduct[index].containsCombo = false;
                    excludeProduct[index].containsComboString = 'Não';
                    excludeProduct[index].formerItem = false;
                    excludeProduct[index].benefitItem = false;
                }
            }

            let indexToRemove;
            let selectedCombos = this.parseObject(this.combosSelecteds);
            for (let index = 0; index < selectedCombos.length; index++) {
                if (selectedCombos[index].comboId == comboId) indexToRemove = index;
            }
            selectedCombos.splice(indexToRemove, 1);
            this.combosSelecteds = this.parseObject(selectedCombos);

            if (this.isFilled(this.combosData)) {
                let allCombos = this.parseObject(this.combosData);
                for (let index = 0; index < allCombos.length; index++) {
                    if (allCombos[index].comboId == comboId) allCombos[index].comboQuantity = 0;
                }

                this.combosData = this.parseObject(allCombos);
                this._setcombosSelecteds();
            }
        }

        excludedProducts.push(excludeProduct[counter].orderItemId);
        excludeProduct.splice(counter, 1);
        if (excludeProduct.lenght - 1 != position){
            excludeProduct.forEach((product) => {
                if (product.position > position) product.position -= 1
            })
        }
        this.products = this.parseObject(excludeProduct);

        let allDivisions = this.parseObject(this.allDivisionProducts);
        let currentDivisions = [];
        allDivisions.forEach((division) => {
            if (division.productPosition != position) {
                if (division.productPosition > position) division.productPosition -= 1
                currentDivisions.push(division);
            }
        })
        this.allDivisionProducts = this.parseObject(currentDivisions);

        if (this.products.length == 0) {
            this.showIncludedProducts = false;
            if (this.commoditiesData.length > 0) {
                this.commoditiesData = [];
                this.commodities = [];
                this.barterSale = true;
                this.showCommodityData = false;
                this.taxData = [];
                this._setCommodityData();
                this._setTaxData();
                this.showToast('warning', 'As commodities foram removidas por conta da falta de produtos!', '');
            }
        } else {
            this.recalculateCommodities();
        }

        this.excludedItems = this.isFilled(excludedProducts) ? excludedProducts : [];
        this._setExcludedesItems();
        this._setData();
        this._setDivisionData();
        this.showToast('success', 'Produto removido!', '');
    }

    newFields() {
        let allDivisions = this.parseObject(this.divisionProducts);
        let divPosition = this.isFilled(allDivisions) ? allDivisions.length : 0;
        let deliveryId = 'deliveryId-' + divPosition;
        let quantityId = 'quantityId-' + divPosition;
        let orderItemKey = this.currentDivisionProduct.productId;
        allDivisions.push({productId: this.currentDivisionProduct.productId, deliveryDate: null, quantity: null, position: divPosition, deliveryId: deliveryId, quantityId: quantityId, orderItemKey: orderItemKey, productPosition: this.productPosition, showInfos: true});
        this.divisionProducts = this.parseObject(allDivisions);
    }

    divisionChange(event) {
        let allDivisions = this.parseObject(this.divisionProducts);
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
                    currentProduct.quantity = this.calculateMultiplicity(fieldValue, true);
                } else {
                    currentProduct.quantity = this.currentDivisionProduct.quantity - Number(productQuantity);
                    this.showToast('warning', 'Atenção!', 'A quantidade foi arredondada para ' + currentProduct.quantity + ' para não exceder.');
                }

                this.currentDivisionProduct.availableQuantity = Number(this.currentDivisionProduct.quantity) - ((Number(productQuantity) + Number(currentProduct.quantity)));
                if (this.currentDivisionProduct.availableQuantity < 0) this.currentDivisionProduct.showRed = true;
                else this.currentDivisionProduct.showRed = false;
            }
            this.divisionProducts = this.parseObject(allDivisions);
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
        if (this.products !== undefined) return true;
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

    _setTaxData() {
        const setItems = new CustomEvent('settaxdata');
        setItems.data = this.taxData;
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

        let allCombos = this.parseObject(this.combosSelecteds);
        this.itensToRemove = [];
        this.comboProducts.formerIds = [];
        this.comboProducts.benefitsIds = [];
        this.comboProducts.mixTotal = [];

        for (let index = 0; index < allCombos.length; index++) {
            let currentCombo = allCombos[index];
            if (currentCombo.specificItemCombo) {
                for (let i = 0; i < currentCombo.formerItems.length; i++) {
                    if (currentCombo.comboQuantity > 0) this.comboProducts.formerIds.push(currentCombo.formerItems[i].productId);
                    else this.itensToRemove.push(currentCombo.formerItems[i]);
                }

                for (let i = 0; i < currentCombo.benefitItems.length; i++) {
                    if (currentCombo.comboQuantity > 0) this.comboProducts.benefitsIds.push(currentCombo.benefitItems[i].productId);
                    else this.itensToRemove.push(currentCombo.benefitItems[i]);
                }
            }else{
                loadComboProducts(this, currentCombo)
            }
        }

        let getCompanyData = {ctvId: this.headerData.ctv_venda.Id != null ? this.headerData.ctv_venda.Id : '',accountId: this.accountData.Id != null ? this.accountData.Id : '',orderType: this.headerData.tipo_venda,approvalNumber: 1};
        if ((this.isFilled(this.comboProducts.formerIds) && this.comboProducts.formerIds.length > 0) || (this.isFilled(this.comboProducts.benefitsIds) && this.comboProducts.benefitsIds.length > 0) || (this.isFilled(this.comboProducts.mixTotal) && this.comboProducts.mixTotal.length > 0)) {
            this.checkCombo = true;
        }

        let currentProducts = [];
        for (let index = 0; index < this.products.length; index++) {
            let itemToExclude = this.itensToRemove.find(e => e.productId == this.products[index].productId);
            if (!this.isFilled(itemToExclude)) currentProducts.push(this.products[index]);
        }
        this.products = this.parseObject(currentProducts);
        this._setData();
        this.getCompanies(getCompanyData);
    }

    showResults(event){
        this.showBaseProducts = event.showResults;
        this.baseProducts = event.results.recordsDataList;
        this.productsPriceMap = event.results.recordsDataMap;
        this.salesInfos = event.results.salesResult;
        this.message = this.baseProducts.length > 0 ? false : event.message;
        if (this.baseProducts.length >= 9) this.showArrows = true;
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

    calculateTaxes(totalValue, commodityId) {
        let totalTaxes = 0;
        let taxes = this.parseObject(this.taxData);
        for (let i = 0; i < taxes.length; i++) {
            if (taxes[i].taxProduct == commodityId) {
                taxes[i].taxValue = totalValue * (taxes[i].taxPercentage / 100);
                totalTaxes += taxes[i].taxValue;
            } else {
                taxes[i].taxValue = 0;
            }
        }
        this.taxData = this.parseObject(taxes);
        return totalTaxes;
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

        let marginPercent = ((1 - (orderTotalCost / totalProducts)) * 100);
        let chooseCommodity = this.commodities.find(e => e.Id == event.target.dataset.targetId);
        let commodityPrice = chooseCommodity.listPrice - this.calculateTaxes(chooseCommodity.listPrice, chooseCommodity.Id);

        this.selectedCommodity = {
            id: chooseCommodity.Id,
            name: chooseCommodity.Name,
            cotation: chooseCommodity.listPrice,
            startDate: null,
            endDate: null,
            deliveryQuantity: Math.ceil((totalProducts / commodityPrice)) + ' sacas',
            deliveryQuantityFront: Math.ceil((totalProducts / commodityPrice)) + ' sacas',
            ptax: chooseCommodity.productCurrency + chooseCommodity.listPrice,
            commodityPrice: chooseCommodity.listPrice,
            commission: 'R$' + ((chooseCommodity.commissionPercentage * totalProducts) / 100),
            totalMarginPercent: this.fixDecimalPlaces(marginPercent) + '%',
            totalMarginPercentFront: this.fixDecimalPlacesFront(marginPercent) + '%',
            totalMarginValue: this.fixDecimalPlaces(((totalProducts * marginPercent) / 100) / commodityPrice) + ' sacas',
            totalMarginValueFront: this.fixDecimalPlacesFront(((totalProducts * marginPercent) / 100) / commodityPrice) + ' sacas',
            quantity: productsQuantity,
            totalDiscountValue: this.fixDecimalPlaces(totalDiscount / commodityPrice) + ' sacas',
            totalDiscountValueFront: this.fixDecimalPlacesFront(totalDiscount / commodityPrice) + ' sacas'
        };
        this._setTaxData();
    }

    fillCommodity(event) {
        this.summaryScreen = true;
        for (let index = 0; index < this.commoditiesData.length; index++) {
            if (this.commoditiesData[index].saved == false) return;
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
                this._setTaxData();
            } else if (this.commoditiesData[index].saved == false) {
                this.commoditiesData.splice(index, 1);
            }
        }

        this.showCommodities = false;
        this.chooseCommodities = false;
        this.commoditySelected = false;
        this.summaryScreen = false;
    }

    openCommodityData(event) {
        this.openCommoditiesData = !this.openCommoditiesData;
    }

    commodityChange(event) {
        if (this.isFilled(event.target.value)) this.selectedCommodity[event.target.dataset.targetId] = event.target.value;
    }

    verifyConditions(startDate, endDate){
        if ((this.isFilled(startDate)  && startDate != "") && (this.isFilled(endDate) && endDate != "")){
            var start = new Date(startDate);
            var end = new Date(endDate);
            if (end.getTime() < start.getTime()) {
                this.showToast('warning', 'Atenção', 'Intervalo de datas não permitido.');
                return false;
            }
        } else {
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
        if (this.currentScreen== 'fillCommodity' && this.commodityScreens[this.commodityScreens.indexOf(this.currentScreen) + 1] == 'negotiationDetails'){
            if (!this.verifyConditions(this.selectedCommodity.startDate, this.selectedCommodity.endDate)){
                this.commoditySelected = true;
                return;
            }
        }

        this.currentScreen = this.commodityScreens[this.commodityScreens.indexOf(this.currentScreen) + 1];
        if (this.currentScreen == 'chooseCommodity') {this.selectCommodityScreen = true;this.chooseCommodities = true;}
        if (this.currentScreen == 'fillCommodity')  this.commoditySelected = true;
        if (this.currentScreen == 'negotiationDetails') this.fillCommodity();
    }

    backScreen(event) {
        this.selectCommodityScreen = false;
        this.commoditySelected = false;
        this.summaryScreen = false;
        this.currentScreen = this.commodityScreens[this.commodityScreens.indexOf(this.currentScreen) - 1];
        if (this.currentScreen == 'chooseCommodity') {this.selectCommodityScreen = true;this.chooseCommodities = true;}
        if (this.currentScreen == 'fillCommodity') this.commoditySelected = true;
        if (this.currentScreen == 'negotiationDetails') this.summaryScreen = true;
    }

    recalculateCommodities() {
        let t = this
        if (t.isFilled(t.commoditiesData) && t.commoditiesData.length > 0 && !t.headerData.IsOrderChild) {
            let totalProducts = 0;
            let orderTotalCost = 0;
            let productsQuantity = 0;
            let totalDiscount = 0;
            for (let index = 0; index < t.products.length; index++) {
                totalProducts += Number(t.products[index].totalPrice);
                orderTotalCost += Number(t.products[index].listCost) * Number(t.products[index].quantity);
                productsQuantity += Number(t.products[index].quantity);
                totalDiscount += Number(t.products[index].commercialDiscountValue);
            }
            let marginPercent = ((1 - (orderTotalCost / totalProducts)) * 100);

            let currentCommodityValues = t.parseObject(t.commoditiesData[0]);
            let commodityPrice = currentCommodityValues.cotation - t.calculateTaxes(currentCommodityValues.cotation, currentCommodityValues.productId);
            
            currentCommodityValues.area = t.headerData.hectares;
            currentCommodityValues.quantity = productsQuantity;
            currentCommodityValues.discount = t.fixDecimalPlaces(totalDiscount / Number(commodityPrice)) + ' sacas';
            currentCommodityValues.discountFront = t.fixDecimalPlacesFront(totalDiscount / Number(commodityPrice)) + ' sacas';
            currentCommodityValues.margin = t.fixDecimalPlaces(marginPercent) + '%';
            currentCommodityValues.marginFront = t.fixDecimalPlacesFront(marginPercent) + '%';
            currentCommodityValues.marginValue = t.fixDecimalPlaces(((totalProducts * marginPercent) / 100) / Number(commodityPrice)) + ' sacas';
            currentCommodityValues.marginValueFront = t.fixDecimalPlacesFront(((totalProducts * marginPercent) / 100) / Number(commodityPrice)) + ' sacas';
            currentCommodityValues.totalDelivery = Math.ceil((totalProducts / commodityPrice)) + ' sacas';
            currentCommodityValues.totalDeliveryFront = Math.ceil((totalProducts / commodityPrice)) + ' sacas';
            
            t.commoditiesData = [];
            t.commoditiesData.push(currentCommodityValues);
            t._setCommodityData();
            t._setTaxData();
            t.showToast('warning', 'Atenção!', 'Os valores da commodity foram alterados de acordo com a alteração/inclusão de um produto.');
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
                this._setTaxData();
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
            getSeedPrices: this.showRoyaltyTsi,
            isLimit: false
        })
        .then(result => {
            this.showBaseProducts = result.recordsDataList.length > 0;
            this.baseProducts = result.recordsDataList;
            this.productsPriceMap = result.recordsDataMap;
            this.salesInfos = result.salesResult;
            this.message = this.baseProducts.length > 0 ? false : result.message;
            if (this.baseProducts.length >= 9) this.showArrows = true;
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
        let t  = this
        t.showLoading = true;
        let headerValues = {cropId: t.headerData.safra.Id,rowsToSkip: t.comboRowsToSkip,salesConditionId: t.headerData.condicao_venda.Id,paymentConditionId:t.headerData.condicao_pagamento.Id};
        let getCompanyData = {ctvId: t.headerData.ctv_venda.Id != null ? t.headerData.ctv_venda.Id : '',accountId: t.accountData.Id != null ? t.accountData.Id : '',orderType: t.headerData.tipo_venda,approvalNumber: 1};
        let productParams = {
            salesConditionId: t.headerData.condicao_venda.Id,
            accountId: t.accountData.Id,
            ctvId: t.headerData.ctv_venda.Id,
            safra: t.headerData.safra.Id,
            productCurrency: t.headerData.moeda,
            culture: t.headerData.cultura.Id,
            orderType: t.headerData.tipo_venda,
            numberOfRowsToSkip: 0,
            dontGetSeeds: t.isFilled(t.dontGetSeeds) ? t.dontGetSeeds : false,
            paymentDate: t.headerData.data_pagamento
        };
        
        getSpecificCombos({data: JSON.stringify(headerValues), companyData: JSON.stringify(getCompanyData), productData: JSON.stringify(productParams), childOrder: t.childOrder, existingCombosIds: t.combosIds})
        .then((result) => {
            t.showLoading = false;
            let combosAndPromotions = JSON.parse(result);
            if (t.isFilled(combosAndPromotions) && combosAndPromotions.length > 0) {
                t._setHideFooterButtons(true);
                t.showCombos = true;
                let existingCombos = t.parseObject(t.combosSelecteds);

                for (let index = 0; index < combosAndPromotions.length; index++) {
                    let currentCombo = existingCombos.find(e => e.comboId == combosAndPromotions[index].comboId);
                    if (t.isFilled(currentCombo)) {
                        combosAndPromotions[index].comboQuantity = currentCombo.comboQuantity;
                    } else {
                        currentCombo = t.comboAndQuantities.find(e => e.combo == combosAndPromotions[index].comboId);
                        if (t.isFilled(currentCombo) && combosAndPromotions[index].specificItemCombo) {
                            let formerItem = combosAndPromotions[index].formerItems.find(e => e.productId == currentCombo.prodId);
                            let benefitItem = combosAndPromotions[index].benefitItems.find(e => e.productId == currentCombo.prodId);
                            if (t.isFilled(formerItem)) {
                                combosAndPromotions[index].comboQuantity = currentCombo.quantity / formerItem.minQUantity;
                                combosAndPromotions[index].comboAvailableQuantity = combosAndPromotions[index].comboAvailableQuantity == 0 ? combosAndPromotions[index].comboQuantity : combosAndPromotions[index].comboAvailableQuantity;
                            }
                            if (t.isFilled(benefitItem)) {
                                combosAndPromotions[index].comboQuantity = currentCombo.quantity / benefitItem.minQUantity;
                                combosAndPromotions[index].comboAvailableQuantity = combosAndPromotions[index].comboAvailableQuantity == 0 ? combosAndPromotions[index].comboQuantity : combosAndPromotions[index].comboAvailableQuantity;
                            }
                        }
                        if(t.isFilled(currentCombo) && combosAndPromotions[index].comboCondition == 'Total') {combosAndPromotions = totalCombosLogic(this, combosAndPromotions, index, currentCombo)}
                        if(t.combosIds.includes(combosAndPromotions[index].comboId)) t.changeSelectedComboData(combosAndPromotions[index])
                    }
                }
                t.combosData = combosAndPromotions;
            } else {
                let getCompanyData = {ctvId: t.headerData.ctv_venda.Id != null ? t.headerData.ctv_venda.Id : '', accountId: t.accountData.Id != null ? t.accountData.Id : '', orderType: t.headerData.tipo_venda, approvalNumber: 1};
                t.getCompanies(getCompanyData);
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