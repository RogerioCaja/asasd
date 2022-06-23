({

    rerender : function(component, helper) {
        this.superRerender();
        let recordTypeId = component.get("v.pageReference").state.recordTypeId;
        component.set("v.selectedRecordId", recordTypeId);
        var evt = $A.get("e.force:navigateToComponent");
        console.log(JSON.stringify(component.get("v.pageReference").state))
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
