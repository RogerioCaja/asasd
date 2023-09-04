
import fetchOrderRecords from '@salesforce/apex/CustomLookupController.fetchProductsRecords';
const totalCombosLogic = (t, combosAndPromotions, index, currentCombo) => {
    let productCombo = combosAndPromotions[index].groupQuantities.find(e => e.productId == currentCombo.prodId);

    if (t.isFilled(productCombo)) {
        combosAndPromotions[index].comboQuantity = currentCombo.quantity / productCombo.quantity;
        combosAndPromotions[index].comboAvailableQuantity = combosAndPromotions[index].comboAvailableQuantity == 0 ? combosAndPromotions[index].comboQuantity : combosAndPromotions[index].comboAvailableQuantity;
    }
    console.log(JSON.stringify(combosAndPromotions))
    return combosAndPromotions;
}

const isTotal = (combo) => {
    return (combo.comboCondition == 'Total' ?  true : false)
    
}

const loadComboMix = (currentCombo, mixTotal, prodsIds) => {
    for (let i = 0; i < currentCombo.groupQuantities.length; i++) {
        let mix = currentCombo.groupQuantities[i];
        mixTotal.push({productName: mix.productName, productId: mix.productId, productCode: mix.productCode, minQUantity: mix.quantity, discountPercentage: currentCombo.comboDiscountPercentage, comboId: currentCombo.comboId, comboQuantity:currentCombo.comboQuantity, industryCombo: currentCombo.comboType == 'Indústria'});
        prodsIds.push(mix.productId);
    }
    return {mixTotal: mixTotal, prodsIds: prodsIds}
}

const logicApplyCombo = (t, mixTotal, comboItens, counter, idsToRemove) => {
    for (let index = 0; index < mixTotal.length; index++) {
        let mixTotalQuantity = mixTotal[index].minQUantity * mixTotal[index].comboQuantity;
        let currentItem = t.products.find(e => e.productId == mixTotal[index].productId)
        if (t.isFilled(currentItem)) {
            currentItem.quantity = mixTotalQuantity;
            currentItem.dosage = mixTotalQuantity / t.hectares;
            currentItem.dosageFront = t.fixDecimalPlacesFront(currentItem.dosage);
            currentItem.comboId = mixTotal[index].comboId;
            currentItem.industryCombo = mixTotal[index].industryCombo;
            currentItem.containsCombo = true;
            currentItem.containsComboString = 'Sim';
            currentItem = t.emptyDiscounFields(currentItem);
            currentItem.comboDiscountPercent = mixTotal[index].discountPercentage + '%';
            for (let i = 0; i < t.products.length; i++) {
                if (currentItem.productId == mixTotal[index].productId) idsToRemove.push(currentItem.productId);
            }
            comboItens.push(currentItem);
        } else {
            let comboValues = {dosage: mixTotalQuantity / t.hectares, quantity: mixTotalQuantity, comboDiscount: mixTotal[index].discountPercentage, comboId: mixTotal[index].comboId, industryCombo: mixTotal[index].industryCombo, containsCombo: true, formerItem: false, benefitItem: false};
            let productInfos = t.getProductByPriority({Id: mixTotal[index].productId});
            let priorityPrice = {listPrice: productInfos.priorityPrice.listPrice, costPrice: productInfos.priorityPrice.costPrice, priceListCode: productInfos.priorityPrice.priceListCode};
            comboItens.push(t.createProduct(productInfos.productInfos, priorityPrice, comboValues, t.getCurrentProductPosition() + counter));
            counter++;
        }

    }
    return {comboItens : comboItens, idsToRemove: idsToRemove}
}

const loadComboProducts = (t, currentCombo) => {
    for (let i = 0; i < currentCombo.groupQuantities.length; i++) {
        if (currentCombo.comboQuantity > 0) t.comboProducts.mixTotal.push(currentCombo.groupQuantities[i].productId);
        else t.itensToRemove.push(currentCombo.groupQuantities[i]);
    }
}

const updateCommodities = (t) => {
    fetchOrderRecords(
        {searchString: '', 
        data: JSON.stringify(t.productParams), 
        isCommodity: true, 
        productsIds: t.commoditiesData.map((e) => {return e.productId}), 
        priceScreen: false, 
        getSeedPrices: t.showRoyaltyTsi, 
        isLimit: true})
    .then(result => {
        t.productsPriceMap = result.recordsDataMap;
        t.salesInfos = result.salesResult;
        let priorityInfos = t.getProductByPriority({Id: t.commoditiesData[0].productId}).priorityPrice;
        let currentCommodity = t.parseObject(t.commoditiesData[0])
        if(t.isFilled(priorityInfos)){
            if(currentCommodity.cotation != priorityInfos.listPrice){
                let oldPrice = currentCommodity.cotation
                let newPrice = priorityInfos.listPrice
                currentCommodity.cotation = t.isFilled(priorityInfos.listPrice) ? t.fixDecimalPlaces(priorityInfos.listPrice) : 0;
                currentCommodity.commodityPrice = t.isFilled(priorityInfos.listPrice) ? t.fixDecimalPlaces(priorityInfos.listPrice) : 0;
                let priceChangeMessage = 'O preço de lista da Commodity foi alterado de ' + oldPrice + ' para ' + newPrice + '.\n';
                t.showToast('warning', 'Alteração nos preços!', priceChangeMessage);
                t.commoditiesData = [];
                t.commoditiesData.push(currentCommodity);
            }
        }  
        t.recalculateCommodities();               
    })
}

export {totalCombosLogic, isTotal, loadComboMix, logicApplyCombo, loadComboProducts, updateCommodities}