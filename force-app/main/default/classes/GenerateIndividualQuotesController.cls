public without sharing class GenerateIndividualQuotesController {
    @AuraEnabled
    public static String getQuoteData(Id generalQuoteId) {
        GeneralQuotas__c quote = [
            SELECT Id,
                   Crop__c,
                   Crop__r.Name,
                   Cultivate__c,
                   Cultivate__r.Name,
                   Balance__c,
                   Consumed__c,
                   Quantity__c
              FROM GeneralQuotas__c
             WHERE Id =: generalQuoteId
        ];

        QuoteData quoteData = new QuoteData();
        quoteData.quoteId = quote.Id;
        quoteData.cropId = quote.Crop__c;
        quoteData.cropName = quote.Crop__r.Name;
        quoteData.cultivateId = quote.Cultivate__c;
        quoteData.cultivateName = quote.Cultivate__r.Name;
        quoteData.quantity = quote.Quantity__c;
        quoteData.consumed = 0;
        quoteData.balance = quote.Balance__c;
        System.debug('quoteData: ' + generalQuoteId);
        
        return JSON.serialize(quoteData);
    }

    @AuraEnabled
    public static String createIndividualQuote(String individualQuoteData) {
        try {
            QuoteData quoteData = (QuoteData) JSON.deserialize(individualQuoteData, QuoteData.class);
            System.debug('quoteData: ' + quoteData);
            String sellerName = [SELECT Id, Name FROM User WHERE Id =: quoteData.sellerId].Name;

            IndividualQuotas__c individualQuote = new IndividualQuotas__c();
            individualQuote.Name = quoteData.cultivateName + '/' + quoteData.cropName + '/' + sellerName;
            individualQuote.GeneralQuotas__c = quoteData.quoteId;
            individualQuote.Crop__c = quoteData.cropId;
            individualQuote.Seller__c = quoteData.sellerId;
            individualQuote.Cultivate__c = quoteData.cultivateId;
            individualQuote.Quantity__c = quoteData.quantity;
            individualQuote.Consumed__c = quoteData.consumed;
            individualQuote.Balance__c = quoteData.balance;
            
            insert individualQuote;
            return individualQuote.Id;
        } catch (Exception ex) {
            System.debug('Erro: ' + ex.getMessage() + '   -   ' + ex.getStackTraceString());
            return 'Erro: ' + ex.getMessage() + '   -   ' + ex.getStackTraceString();
        }
    }

    public class QuoteData {
        public String  quoteId;
        public String  cropId;
        public String  cropName;
        public String  sellerId;
        public String  cultivateId;
        public String  cultivateName;
        public Decimal balance;
        public Decimal consumed;
        public Decimal quantity;
    }
}
