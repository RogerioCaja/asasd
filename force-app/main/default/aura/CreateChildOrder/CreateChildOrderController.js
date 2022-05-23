({
    navigateToeDiscoverySearchCmp : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:orderScreen",
            componentAttributes: {
                recordId: component.get("v.recordId"),
                originScreen: window.location.pathname,
                recordTypeId: '',
                clone: {cloneOrder: false, pricebookListId: ''},
                childOrder: true
            }
        });
        evt.fire();
    }
})