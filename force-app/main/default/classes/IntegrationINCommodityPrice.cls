@RestResource(urlMapping='/commodityPrice/*')
global with sharing class IntegrationINCommodityPrice {

    @HttpPost
    global static CommodityPriceResponseModel upsertCommodityPrice(List<CommodityPriceINData> request) {
        CommodityPriceResponseModel response = new CommodityPriceResponseModel();
        try {
            Set<String> commoditiesExternalId = new Set<String>();
            for (CommodityPriceINData commodityPrice : request) {
                commoditiesExternalId.add(commodityPrice.derivativeContrSpecification);
            }

            Map<String, Commodity__c> commoditiesByExternalId = new Map<String, Commodity__c>();
            for (Commodity__c commodity : [
                SELECT Id,
                       ExternalId__c
                  FROM Commodity__c
                 WHERE ExternalId__c IN: commoditiesExternalId
            ]) {
                commoditiesByExternalId.put(commodity.ExternalId__c, commodity);
            }

            List<CommodityPrice__c> commodityPriceList = new List<CommodityPrice__c>();
            for (CommodityPriceINData commodityPrice : request) {
                Id commodityId = commoditiesByExternalId.get(commodityPrice.derivativeContrSpecification).Id;
                commodityPriceList.add(new CommodityPrice__c(
                    Commodity__c = commodityId,
                    CreatedByUser__c = commodityPrice.createdByUser,
                    Currency__c = commodityPrice.priceCurrency,
                    MarketIdentifierCode__c = commodityPrice.marketIdentifierCode,
                    MaturityKeyDate__c = commodityPrice.maturityKeyDate,
                    PriceQuotationCurrency__c = commodityPrice.priceQuotation,
                    PriceQuotationTime__c = commodityPrice.priceQuotationTime,
                    PriceQuotationType__c = commodityPrice.priceQuotationType,
                    QuotationDate__c = commodityPrice.priceQuotationDate,
                    TimeToMaturity__c = commodityPrice.timeToMaturity,
                    UnitOfMeasure__c = commodityPrice.unitOfMeasure,
                    ValidityStart_DateTime__c = commodityPrice.validityStartUtcDatetime,
                    ExternalId__c = commodityPrice.priceQuotationDate + '-' + commodityId + '-' + commodityPrice.marketIdentifierCode
                ));
            }

            Boolean hasErrors = false;
            List<Database.UpsertResult> upsertRecords = Database.upsert(commodityPriceList, false);
            for (Database.UpsertResult result : upsertRecords){
                if(!result.isSuccess()){
                    hasErrors = true;
                    for (Database.error error: result.getErrors()){
                        response.message += '\n' + error.getMessage();
                    }
                }
            }

            if (hasErrors) {
                IntegrationLog.createLog('Preço Commodities IN', 'IN', JSON.serialize(request), JSON.serialize(response), true);
            } else {
                response.message = 'Sucesso!';
                IntegrationLog.createLog('Preço Commodities IN', 'IN', JSON.serialize(request), JSON.serialize(response), false);
            }
        } catch (Exception ex) {
            response.message = 'Error: ' + ex.getMessage() + '   -   ' + ex.getStackTraceString();
            System.debug('response.message: ' + response.message);
            IntegrationLog.createLog('Preço Commodities IN', 'IN', JSON.serialize(request), response.message, true);
        }

        return response;
    }

    global class CommodityPriceINData {
        public Date     maturityKeyDate;
        public Date     priceQuotationDate;
        public Time     priceQuotationTime;
        public String   derivativeContrSpecification;
        public String   marketIdentifierCode;
        public String   priceQuotationType;
        public String   timeToMaturity;
        public String   unitOfMeasure;
        public String   priceCurrency;
        public String   createdByUser;
        public Decimal  priceQuotation;
        public Datetime validityStartUtcDatetime;
    }

    global class CommodityPriceResponseModel {
        public String message = '';
    }
}