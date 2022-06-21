({
    sendIntegration : function(component, event, helper) {
        var action = component.get("c.sendToIntegrationTest");
        action.setParams({ orderId : component.get("v.recordId") });
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('this state' + state);
            if(response.getReturnValue() == ''){
                component.set('v.responseData', 'Você não é administrador do Sistema, logo não é permitido essa ação');
            }
            else{
                component.set('v.responseData', response.getReturnValue());
            }
            
        });
        $A.enqueueAction(action);
    }
})
