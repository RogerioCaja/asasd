({
    doInit : function(component, event, helper) {
        let action = component.get("c.cancelOrder");
        action.setParams({recordId : component.get("v.recordId")});
        
        action.setCallback(this, function(response){
            console.log('response.getReturnValue(): ' + response.getReturnValue());
            if (response.getReturnValue()) {
                helper.showToast('success', 'Sucesso', 'Pedido cancelado com sucesso!')
            } else {
                helper.showToast('error', 'Erro', 'Pedido não pode ser cancelado.')
            }
        });
        $A.enqueueAction(action);
    }
})