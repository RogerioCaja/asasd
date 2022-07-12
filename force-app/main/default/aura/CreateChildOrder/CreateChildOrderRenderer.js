({

    rerender : function(component, helper) {
        this.superRerender();
        let recordTypeId = component.get("v.pageReference").state.recordTypeId;
        component.set("v.selectedRecordId", recordTypeId);
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
