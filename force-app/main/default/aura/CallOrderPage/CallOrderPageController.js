({
    navigateToeDiscoverySearchCmp : function(component, event, helper) {
        let originScreen = component.get("v.origin") !== undefined ? component.get("v.origin") : window.location.pathname;
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:orderScreen",
            componentAttributes: {
                recordId: component.get("v.recordId"),
                originScreen: originScreen,
                recordTypeId: component.get("v.pageReference").state.recordTypeId,
                clone: {cloneOrder: false, pricebookListId: ''}
            }
        });
        evt.fire();
    }
})