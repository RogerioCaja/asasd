({
    navigateToeDiscoverySearchCmp : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:orderScreen",
            componentAttributes: {
                recordId: component.get("v.recordId"),
                originScreen: window.location.pathname,
                recordTypeId: component.get("v.pageReference").state.recordTypeId,
                clone: {cloneOrder: false, pricebookListId: ''}
            }
        });
        evt.fire();
    }
})