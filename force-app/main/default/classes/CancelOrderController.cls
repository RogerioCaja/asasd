public without sharing class CancelOrderController {
    @AuraEnabled
    public static Boolean cancelOrder(Id recordId) {
        Order order = [SELECT Id, Status FROM Order WHERE Id =: recordId LIMIT 1];
        if (order.Status == '0') {
            order.Status = 'X';
            update order;
            return true;
        }
        return false;
    }
}