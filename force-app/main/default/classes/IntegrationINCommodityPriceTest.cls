@isTest
public class IntegrationINCommodityPriceTest {
    @testSetup public static void makeData() {
        Commodity__c commodity = new Commodity__c(
            ExternalId__c = '123456'
        );
        insert commodity;
    }

    @isTest public static void upsertCommodityPriceSuccessTest() {
        String data = '[{"validityStartUtcDatetime":"2022-04-14T19:00:19.778Z","unitOfMeasure":"BU","timeToMaturity":"JAN","priceQuotationType":"09","priceQuotationTime":null,"priceQuotationDate":"2022-04-17","priceQuotation":18.74,"priceCurrency":"USD","maturityKeyDate":"2022-04-14","marketIdentifierCode":"XCBOT","derivativeContrSpecification":"123456","createdByUser":null}]';
        TemplateDataIntegrationFields.CommodityPriceResponseModel response = IntegrationINCommodityPrice.upsertCommodityPrice(data);
        System.assertEquals('Sucesso!', response.message);
    }

    @isTest public static void upsertCommodityPriceErrorTest() {
        String data = '[{"validityStartUtcDatetime":"2022-04-14T19:00:19.778Z","unitOfMeasure":"BU","timeToMaturity":"JAN","priceQuotationType":"09","priceQuotationTime":null,"priceQuotationDate":"2022-04-17","priceQuotation":18.74,"priceCurrency":"USD","maturityKeyDate":"2022-04-14","marketIdentifierCode":"XCBOT","derivativeContrSpecification":"12345","createdByUser":null}]';
        TemplateDataIntegrationFields.CommodityPriceResponseModel response = IntegrationINCommodityPrice.upsertCommodityPrice(data);
        System.assertNotEquals('Sucesso!', response.message);
    }
}