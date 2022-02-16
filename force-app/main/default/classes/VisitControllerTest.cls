
@isTest
public with sharing class VisitControllerTest {
    public VisitControllerTest() {}

    @isTest
    public static void verifyDateFormat(){
        String dateTest = VisitController.getDatetime();

        System.assert((String.isNotBlank(dateTest) && String.isNotEmpty(dateTest)), 'Os dados resultaram em falha');
    }
}
