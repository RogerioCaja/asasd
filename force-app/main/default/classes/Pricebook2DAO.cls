public with sharing class Pricebook2DAO {
    public Pricebook2DAO() {

    }

    public static Pricebook2 getStandardPricebook(Set<String> pricebook2UsedFields){
        
        String query = new Q(Pricebook2.SObjectType)
        .selectFields(pricebook2UsedFields)
        .add(Q.condition('isStandard').equalsTo(true))
        .addLimit(1)
        .build();

        return Test.isRunningTest() ? new Pricebook2(Id = Test.getStandardPricebookId()) : Database.query(query);
    }

}
