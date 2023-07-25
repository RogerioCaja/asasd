@IsTest
public with sharing class CancelOrderPopUpControllerTest {
   @TestSetup
   static void makeData(){
        TemplateDefaultFields t = new TemplateDefaultFields();
        t.packageTest();

        CancelReason__c cancel = new CancelReason__c(
            Name = 'Cancelar Já',
            IsActive__c = true,
            DescriptionMandatory__c = true
        );

        insert cancel;

        CancelReason__c cancel2 = new CancelReason__c(
            Name = 'Cancelar Já',
            IsActive__c = false,
            DescriptionMandatory__c = true
        );

        insert cancel2;
   }


   @IsTest 
   static void getCancelReasonsTest(){
        
        Test.startTest();
        List<CancelOrderPopUpController.CancelReasonWrapper> result = CancelOrderPopUpController.getCancelReasons();
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Deveria vir uma unidade');

   }

   @IsTest 
   static void saveOrderTest(){
        Id orderId = [SELECT Id FROM Order LIMIT 1][0].Id;
        Id reasonId = [SELECT Id FROM CancelReason__c WHERE IsActive__c = true LIMIT 1][0].Id;

        CancelOrderPopUpController.CancelOrderWrapper cancelOrderWrapper = new CancelOrderPopUpController.CancelOrderWrapper();
        cancelOrderWrapper.recordId = String.valueOf(orderId);
        cancelOrderWrapper.reasonId = String.valueOf(reasonId);
        cancelOrderWrapper.description = 'Apenas uma descrição';

        Test.startTest();
        CancelOrderPopUpController.saveOrder(JSON.serialize(cancelOrderWrapper));
        Test.stopTest();
   }

   @IsTest 
   static void getOrderByIdTest(){
		Id orderId = [SELECT Id FROM Order LIMIT 1][0].Id;

		Test.startTest();
		Order order = CancelOrderPopUpController.getOrderById(orderId);
		Test.stopTest();

		Assert.areEqual(orderId, order.Id, 'Deveria trazer o mesmo pedido coletado antes do teste');
   }
}