const reloadProducts = (t) => {
    try{
        let permissionAndProduct = comboPermission(t)
        t.checkComboPermission = permissionAndProduct.hasElements;
        let currentProducts = t.products;
        t.canReload = false;
        t.recalculatePrice = true;
        currentProducts.forEach(element => {
            t.editProduct(element.position, null, true);
            t.changeProduct(t.addProduct);
        });
        t.recalculatePrice = false;
        t.canReload = true;
    }catch(err){
        console.log(err)
    }
    
}

const comboPermission = (t) => {
    let hasAllElements = false;
    let productOfCombo;
    if(t.isFilled(t.combosData)){
        let currentCombos = t.combosData;
        const comboTotalsData = currentCombos.map((value) => {
            if(value.comboCondition == 'Total' && value.recTypeDevName == 'ProductMix'){
                return {comboId: value.comboId, 
                        productsIds: value.groupQuantities.map((e) => {return e.productId}), 
                        quantities: value.groupQuantities,
                        comboFull: value
                    }
            }
        })
        const productIds = t.products.map((e) => {return e.productId});
        
        comboTotalsData.forEach((value) => {
            hasAllElements = value.productsIds.every(elem => productIds.includes(elem));
            value.quantities.forEach((elem) => {
                let product = t.products.find(e => e.productId == elem.productId);
                if(t.isFilled(product)){
                    if(product.quantity < elem.quantity) hasAllElements = false;
                }
            })
            if(hasAllElements) productOfCombo = value.productsIds;
            
        }) 
    }

    return {hasElements: hasAllElements, products: productOfCombo};
}

export{ reloadProducts };