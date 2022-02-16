({
    navigateToeDiscoverySearchCmp : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:orderScreen",
            componentAttributes: {
                recordId: component.get("v.recordId"),
                originScreen: System.URL.getCurrentRequestUrl().GetPath()
            }
        });
        evt.fire();
    }
})
