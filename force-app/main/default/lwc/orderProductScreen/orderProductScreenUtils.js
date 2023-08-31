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

export {totalCombosLogic, isTotal, loadComboMix, logicApplyCombo, loadComboProducts}