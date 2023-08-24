
function applyComboOnProductLogicInclude(prod, comboDiscountPercent, prodRoot, allProducts, t){
    prod = t.applyComboOnProduct(prodRoot, comboDiscountPercent);

    let margin = t.isFilled(prodRoot.practicedCost) ? t.fixDecimalPlaces((1 - (Number(prodRoot.practicedCost) / (prod.totalPrice / prod.quantity))) * 100) : 0;
    prod.commercialMarginPercentage = margin;
    prod.costPrice = t.costPrice;
    prod.multiplicity = t.multiplicity > 0 ? t.multiplicity : 1;
    allProducts.push(prod);

    console.log(JSON.stringify(allProducts));
    t.showIncludedProducts = true;
    prodRoot = {};
    t.products = t.parseObject(allProducts);
    t.message = false;
}

function applyComboOnProductLogicChange(comboDiscountPercent, prodRoot, allProducts, index, t){
    prodRoot = t.applyComboOnProduct(prodRoot, comboDiscountPercent);

    let margin = t.isFilled(prodRoot.practicedCost) ? t.fixDecimalPlaces(((1 - (Number(prodRoot.practicedCost) / (Number(prodRoot.totalPrice) / Number(prodRoot.quantity)))) * 100)) : null;
    prodRoot.commercialMarginPercentage = t.headerData.IsOrderChild ? prodRoot.commercialMarginPercentage : margin;
    prodRoot.multiplicity = t.multiplicity > 0 ? t.multiplicity : 1;
    index = index ?? allProducts.indexOf(allProducts.find(e => e.productId == prodRoot.productId))
    allProducts[index] = t.parseObject(prodRoot);
}

//combos : uma lista de objetos(do tipo combo) para filtrar e gerar um objeto apenas com combos de condição totais
//comboTotalsData : retorno de uma lista de objetos { comboId, productIds, comboFull}
function createComboAndProductMap(combos){
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
    return comboTotalsData;
}
