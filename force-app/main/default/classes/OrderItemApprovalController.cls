public without sharing class OrderItemApprovalController {
    public Id recordId {get;set;}
    
    public List<OrderItem> getorderItems() {
        List<OrderItem> orderItems = [
            SELECT Id,
                   Product2.Name,
                   Quantity,
                   UnitMeasure__c,
                   PracticedPrice__c,
                   ListPrice__c,
                   DiscountValue__c,
                   DiscountPercent__c,
                   CommercialMargin__c
              FROM OrderItem
             WHERE Id =: recordId
        ];
        return orderItems;
    }
}