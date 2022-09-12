public class CallExcludePageController {
    public String orderItemId {get;set;}
    
    public CallExcludePageController(ApexPages.StandardController controller) {
        orderItemId = ApexPages.currentPage().getParameters().get('id');
    }
}