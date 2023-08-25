
const applyComboOnProductLogicInclude = (prod, comboDiscountPercent, prodRoot, allProducts, t) =>{
    
    prod = t.applyComboOnProduct(prodRoot, comboDiscountPercent);

    let margin = t.isFilled(prodRoot.practicedCost) ? t.fixDecimalPlaces((1 - (Number(prodRoot.practicedCost) / (prod.totalPrice / prod.quantity))) * 100) : 0;
    prod.commercialMarginPercentage = margin;
    prod.costPrice = t.costPrice;
    prod.multiplicity = t.multiplicity > 0 ? t.multiplicity : 1;
    allProducts.push(prod);

    console.log(JSON.stringify(allProducts));
    t.showIncludedProducts = true;
    prodRoot = {};
    t.addProduct = {};
    t.products = t.parseObject(allProducts);
    t.message = false;
}

const applyComboOnProductLogicChange = (comboDiscountPercent, prodRoot, allProducts, index, t) =>{
    
    prodRoot = t.applyComboOnProduct(prodRoot, comboDiscountPercent);
    let margin = t.isFilled(prodRoot.practicedCost) ? t.fixDecimalPlaces(((1 - (Number(prodRoot.practicedCost) / (Number(prodRoot.totalPrice) / Number(prodRoot.quantity)))) * 100)) : null;
    prodRoot.commercialMarginPercentage = t.headerData.IsOrderChild ? prodRoot.commercialMarginPercentage : margin;
    prodRoot.multiplicity = t.multiplicity > 0 ? t.multiplicity : 1;
    index = index ?? allProducts.indexOf(allProducts.find(e => e.productId == prodRoot.productId))
    
    allProducts[index] = t.parseObject(prodRoot);
    t.products = t.parseObject(allProducts);
}

//combos : uma lista de objetos(do tipo combo) para filtrar e gerar um objeto apenas com combos de condição totais
//comboTotalsData : retorno de uma lista de objetos { comboId, productIds, comboFull}
const createComboAndProductMap = (combos, t) => {
    const comboTotalsData = combos.map((value) => {
        if(value.comboCondition == 'Total' && value.recTypeDevName == 'ProductMix'){
            return {comboId: value.comboId, 
                    productsIds: value.groupQuantities.map((e) => {return e.productId}), 
                    comboFull: value
                }
        }
    })
    
    console.log('comboTotalsData');
    console.log(comboTotalsData);
    if(comboTotalsData[0] == undefined){
        return null
    }
    const comboIds = t.products.map((e) => {return e.comboId})
    const comboData = comboTotalsData.map((e) => {return e.comboId})
    comboIds.forEach((e) => {
        if(comboData.includes(e)) t.existingCombosTotal = true;
    })
    return comboTotalsData;
}

const verifyComboAndPromotionTotal = (t) => {
    const productIds = t.products.map((prod) => {return prod.productId});
    if(productIds.indexOf(t.addProduct.productId) == -1){
        productIds.push(t.addProduct.productId);
    }
    let comboSelected = null;
    if(t.isFilled(t.comboTotalsData)){
        t.comboTotalsData.forEach((value) => {
            const hasAllElements = value.productsIds.every(elem => productIds.includes(elem));
            if(hasAllElements){
                comboSelected = value;
            }
        })
    }
    
    let productDiscount = [];
    if(t.isFilled(comboSelected)){
        //TO DO logica de aplicação de desconto
        let groupData =  comboSelected.comboFull.groupQuantities;
        
        for(let index = 0; index < productIds.length; index++){
            let productGroupCombo = groupData.find(e => e.productId == productIds[index]);
            let product = t.products.find(e => e.productId == productIds[index])
            product = product ?? t.addProduct
            if (t.isFilled(productGroupCombo) && product.quantity >= productGroupCombo.quantity) {
                productDiscount.push({productId: productIds[index], data: {discount: comboSelected.comboFull.comboDiscountPercentage,comboId: comboSelected.comboId,industryCombo: comboSelected.comboFull.comboType == 'Indústria',comboQuantity: Math.floor(product.quantity / productGroupCombo.quantity)}});
            }
        }
    }
    if(productDiscount.length > 0){
        t.existingCombosTotal = true;
        t.productIncludesInComboTotal = productDiscount.map((elem) => {return elem.productId});
        return productDiscount;
    }
    return null;
}

const applyLogics = (prod, comboDiscountPercent, t, isChange, index) => {
    if(!isChange){
        let allProducts = t.parseObject(t.products);
        let changeProduct = allProducts.map((elem) => {return elem.productId})
        if(Array.isArray(comboDiscountPercent)){
            comboDiscountPercent.forEach((comboDiscount) => {
                if(!changeProduct.includes(comboDiscount.productId)){
                    applyComboOnProductLogicInclude(prod, comboDiscount.data, t.addProduct, allProducts, t);
                }else{
                    applyComboOnProductLogicChange(comboDiscount.data, (t.products.find(e => e.productId == comboDiscount.productId) ?? t.addProduct), allProducts, null, t);
                }
            })
        }else{
            applyComboOnProductLogicInclude(prod, comboDiscountPercent, t.addProduct, allProducts, t);
        }
    }else{
        let includedProducts = t.parseObject(t.products);
        if(Array.isArray(comboDiscountPercent)){
            comboDiscountPercent.forEach((comboDiscount) => {
                includedProducts = t.parseObject(t.products);
                applyComboOnProductLogicChange(comboDiscount.data, (t.products.find(e => e.productId == comboDiscount.productId) ?? t.addProduct), includedProducts, null, t);
            })
        }else{
            applyComboOnProductLogicChange(comboDiscountPercent, t.addProduct, includedProducts, index, t);
        }
    
    }
}

export{ createComboAndProductMap, verifyComboAndPromotionTotal, applyLogics}
