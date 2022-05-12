public with sharing class Product2Helper {
    public Product2Helper() {

    }
    private static boolean isEnabled;

    @TestVisible
    private static final Id STANDARD_PRICEBOOK_ID;

    static {
        STANDARD_PRICEBOOK_ID = Pricebook2DAO.getStandardPricebook(new Set<String>{'Id'}).Id;

        isEnabled = true;
    }

    public static Boolean  isTriggerEnabled(){
        return isEnabled;
    }

    public static Boolean disableTrigger(){
        return isEnabled = false;
    }
    public static Boolean enableTrigger(){
        return isEnabled = true;
    }


    public static void (List<Product2> newRecordList){
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        for(Product2 product2 : newRecordList){
            pricebookEntryList.add(
                new PriceBookEntry(
                    pricebook2Id = STANDARD_PRICEBOOK_ID,
                    product2Id = product2.id,
                    unitPrice = 0,
                    CurrencyIsoCode = 'BRL'
                )
            );  
        }
        if(!pricebookEntryList.isEmpty()){
            insert pricebookEntryList;
        }
    }
}
