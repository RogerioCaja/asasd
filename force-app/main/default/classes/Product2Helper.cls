public without sharing class Product2Helper {
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


    public static void createStandardEntries(List<Product2> newRecordList){
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        for(Product2 product2 : newRecordList){
            pricebookEntryList.add(
                new PriceBookEntry(
                    pricebook2Id = STANDARD_PRICEBOOK_ID,
                    product2Id = product2.id,
                    unitPrice = 0,
                    IsActive = true,
                    CurrencyIsoCode = 'BRL'
                )
            );  
            pricebookEntryList.add(
                new PriceBookEntry(
                    pricebook2Id = STANDARD_PRICEBOOK_ID,
                    product2Id = product2.id,
                    unitPrice = 0,
                    IsActive = true,
                    CurrencyIsoCode = 'USD'
                )
            );  
        }
        if(!pricebookEntryList.isEmpty()){
            insert pricebookEntryList;
        }
    }

    public static void updateStandardEntries(Map<Id, Product2> newMap){
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        
        List<PricebookEntry> priceBookEntry = [SELECT Id, CurrencyIsoCode, ProductCode FROM PricebookEntry WHERE CurrencyIsoCode != null AND Product2Id IN: newMap.keySet() ORDER BY ProductCode ASC];
        System.debug(priceBookEntry);
        
        Map<String, Set<String>> priceEntries = new Map<String, Set<String>>();
        
        for(PricebookEntry price : priceBookEntry){
            if(!priceEntries.containsKey(price.ProductCode)){
                priceEntries.put(price.ProductCode, new Set<String>());
            }
            priceEntries.get(price.ProductCode).add(price.CurrencyIsoCode);
        }
        
        System.debug(priceEntries);
        
        for(Product2 product : newMap.values()){
            Set<String> currencies = priceEntries.get(product.ProductCode);
            System.debug(currencies);
            if(!currencies.contains('BRL')){
                pricebookEntryList.add(
                        new PriceBookEntry(
                            pricebook2Id = STANDARD_PRICEBOOK_ID,
                            product2Id = product.id,
                            unitPrice = 0,
                            IsActive = true,
                            CurrencyIsoCode = 'BRL'
                        )
                    );    
            }
            if(!currencies.contains('USD')){
                pricebookEntryList.add(
                        new PriceBookEntry(
                            pricebook2Id = STANDARD_PRICEBOOK_ID,
                            product2Id = product.id,
                            unitPrice = 0,
                            IsActive = true,
                            CurrencyIsoCode = 'USD'
                        )
                    );    
            }
            System.debug(pricebookEntryList);
        }

        if(!pricebookEntryList.isEmpty()){
            Upsert pricebookEntryList;
        }
    }
}