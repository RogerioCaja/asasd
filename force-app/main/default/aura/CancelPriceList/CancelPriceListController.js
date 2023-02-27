({
    doInit : function(component, event, helper) {
        let action = component.get("c.cancelPriceList");
        action.setParams({recordId : component.get("v.recordId")});
        
        action.setCallback(this, function(response){
            console.log('response.getReturnValue(): ' + response.getReturnValue());
            if (response.getReturnValue()) {
                helper.showToast('success', 'Sucesso', 'Lista de preço desativada!')
            } else {
                helper.showToast('error', 'Erro', 'Lista de preço não pode ser desativada.')
            }
        });
        $A.enqueueAction(action);
    }
})