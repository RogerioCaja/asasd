public with sharing class CalloutOrderUpdate {
    public CalloutOrderUpdate() {

    }

    @future(callout = true)
    public static void callIntegration(Id orderId, String rmCode, String agCode, String zcCode){
        processIntegration(orderId, rmCode, agCode, zcCode);
    }

    public static IntegrationUtils.CalloutUpdateResponse processIntegration(Id orderId, String rmCode, String agCode, String zcCode){

		Order parentOrder = [SELECT Id, CodigoSap__c, ShippingAccount__r.ExternalId__c, Account.ExternalId__c, Type, SalesOrg__r.SalesOrganizationCode__c, DistributionChannel__c, 
                            ActivitySector__c, Incoterms__c, Incoterms2__c, PaymentCondition__r.Code__c, OrderReason__c , SalesCTV__r.CodigoSap__c, PaymentDate__c, EffectiveDate,
                            OrderNumber, Crop__r.Code__c,  Crop__r.StartDateOrderInsertion__c, Crop__r.EndDateInsertionOrders__c,  Culture__r.Codigo__c, EndDate, TotalAmount, PaymentForm__c, OrderReference__c, CustomerOrderNumber__c, ShippingDate__c,
                            Currency__c,  Crop__r.PaymentBaseDate__c, IsOrderMother__c, RecordTypeId, (SELECT Id FROM OrderItems) 
                            FROM Order WHERE Id = :orderId];
		
		List<Order> allOrders = new List<Order>{parentOrder};
		
		IntegrationUtils.CalloutUpdateResponse calloutResponse = sendOrder(allOrders, rmCode, agCode, zcCode);

		if (calloutResponse.success) {
			
			ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponse;
			Map<String, Order> orderMap = new Map<String, Order>();

			for (Order ord : allOrders) {
				orderMap.put(ord.OrderNumber, ord);
			}

			List<Order> orderList = new List<Order>();

			
            for(Messages message : resp.responses.ET_RETURN.item){
                if(message.TYPE != 'S' && message.TYPE != 'W'){
                    calloutResponse.success = false;
                    calloutResponse.errorMessage = message.MESSAGE;
                }
            }
            if(calloutResponse.success){
                allOrders[0].CodigoSap__c = resp.responses.EV_SALES_DOC;
                allOrders[0].StatusSF__c = 'Integrado';
                orderList.add(allOrders[0]);
            }
            
			if (!orderList.isEmpty()) {
                OrderHelper.disableTrigger();
				update orderList;
                OrderHelper.enableTrigger();
			}
		}
		
		return calloutResponse;
	}

    public static String getAccessToken(){
        
        String payload = 'grant_type=client_credentials';
        String endpoint = 'callout:TokenSap/oauth/token';
        Map<String, String> headersMap = new Map<String, String>();

        IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap);
        AuthToken auth = (AuthToken)JSON.deserialize(responseObject.response.getBody(), AuthToken.class);
        System.debug(responseObject);
        return auth.access_token;
    }

    public class AuthToken{
        public String access_token;
    }

	public static IntegrationUtils.CalloutUpdateResponse sendOrder(List<Order> orders,  String rmCode, String agCode, String zcCode) {
			
		RequestParameters request = new RequestParameters(orders[0], rmCode, agCode, zcCode);

		// for (Order ord : orders) {
		// 	request.add(new RequestParameters(ord));
		// }

		String payload = JSON.serialize(request);
        System.debug(JSON.serializePretty(request));

		//Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
		String accessToken = !Test.isRunningTest() ? getAccessToken() : 'testeToken';

		//Path geralmente cadastrado dentro de ua customSettings
		String endpoint = (!Test.isRunningTest() ? 'https://agrogalaxy-qas-01.it-cpi008-rt.cfapps.br10.hana.ondemand.com/http/SI_ALTERA_OV_OUT' : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', 'Bearer '+ accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap);

		if (responseObject.success) {

			HttpResponse response = responseObject.response;

            IntegrationLog.createLog('Pedido OUT', 'OUT', response.getBody(), payload, false);
			// .WSLog('Pedido', 'OUTBOUND', response.getBody(), payload, false);
			try {

				ResponseParametersWrapper responses = (ResponseParametersWrapper) JSON.deserialize(response.getBody(), ResponseParametersWrapper.class);
				return new IntegrationUtils.CalloutUpdateResponse(new ResponseParameters(responses));
			} catch (Exception e) {
				
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

				return new IntegrationUtils.CalloutUpdateResponse(defaultErrorMessage);
			}
		} else {

            IntegrationLog.createLog('Pedido OUT - SAP', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
			return new IntegrationUtils.CalloutUpdateResponse(responseObject.exceptionObject.getMessage());
		}
    }
    public static Decimal isNotation(Decimal value){
        if(value == 0) return 0;
        else return value;
        
    }
    //! Preparing data to Callout
    public class RequestParameters{
        public String IV_SALES_DOC;
        public CalloutOrderUpdate.Header IS_HEADER_IN;
        public List<CalloutOrderUpdate.PartnerParameters> IT_PARTNERS;
        public List<CalloutOrderUpdate.ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        public List<CalloutOrderUpdate.ConditionParameters> IT_CONDITIONS_IN;
        public List<CalloutOrderUpdate.OrderItemParameters> IT_ITEMS_IN;

        public RequestParameters(Order order, String rmCode, String agCode, String zcCode){

            Decimal valueAmount = 0;
            Decimal valueDiscount = 0;
            Decimal valueInterest = 0;

            IT_PARTNERS = new List<CalloutOrderUpdate.PartnerParameters>();
            IT_ORDER_SCHEDULES_IN = new List<CalloutOrderUpdate.ScheduleParameters>();
            IT_ITEMS_IN = new List<CalloutOrderUpdate.OrderItemParameters>();
            // IT_CONDITIONS_IN = new List<CalloutOrderUpdate.ConditionParameters>();

          
            if(rmCode != order.ShippingAccount__r.ExternalId__c){
                
                IT_PARTNERS.add(new CalloutOrderUpdate.PartnerParameters(rmCode, 'RM', 'D'));
                IT_PARTNERS.add(new CalloutOrderUpdate.PartnerParameters(order.ShippingAccount__r.ExternalId__c, 'RM', 'I'));
            }
            if(agCode != order.Account.ExternalId__c){
                
                IT_PARTNERS.add(new CalloutOrderUpdate.PartnerParameters(agCode, 'AG', 'D'));
                IT_PARTNERS.add(new CalloutOrderUpdate.PartnerParameters(order.Account.ExternalId__c, 'AG', 'I'));
            }
            if(zcCode != order.SalesCTV__r.CodigoSap__c){
                
                IT_PARTNERS.add(new CalloutOrderUpdate.PartnerParameters(zcCode, 'ZC', 'D'));
                IT_PARTNERS.add(new CalloutOrderUpdate.PartnerParameters(order.SalesCTV__r.CodigoSap__c, 'ZC', 'I'));
            }

            Set<Id> orderItemIds = new Set<Id>();
            String IV_TYPE = order.IsOrderMother__c != false ? 'G' : 'C';

            String dateF;

            if(order.Crop__r.StartDateOrderInsertion__c < System.today() && IV_TYPE == 'G' ){
                dateF = String.valueOf(order.EffectiveDate).replace('-', '');
            }
            else{
                dateF = String.valueOf(order.Crop__r.StartDateOrderInsertion__c).replace('-', '');
            }
           
            IV_SALES_DOC = order.CodigoSap__c;
            IS_HEADER_IN = new CalloutOrderUpdate.Header();
            IS_HEADER_IN.REQ_DATE_H =  String.valueOf(order.ShippingDate__c).replace('-', '');
            IS_HEADER_IN.INCOTERMS1 = order.Incoterms__c;
            IS_HEADER_IN.INCOTERMS2 = order.Incoterms__c;
            IS_HEADER_IN.PMNTTRMS = order.PaymentCondition__r.Code__c;
            IS_HEADER_IN.PYMT_METH = order.PaymentForm__c;
            
            IS_HEADER_IN.CT_VALID_F = IV_TYPE == 'G'  ? dateF :  '';
            IS_HEADER_IN.CT_VALID_T = IV_TYPE == 'G' ? String.valueOf(order.Crop__r.EndDateInsertionOrders__c).replace('-', '') : '';
            
            IS_HEADER_IN.PURCH_NO_C = order.CustomerOrderNumber__c;
            
            IS_HEADER_IN.DLV_BLOCK = '';
            
            IS_HEADER_IN.ORD_REASON = order.OrderReason__c;
            IS_HEADER_IN.ZZSAFRA = order.Crop__r.Code__c;
            IS_HEADER_IN.ZZCOD_CULTURA = order.Culture__r.Codigo__c;
            IS_HEADER_IN.ZZPED_CRM = order.OrderNumber;
            IS_HEADER_IN.ZZDATA_CARENCIA = String.valueOf(order.Crop__r.PaymentBaseDate__c).replace('-', '');
            IS_HEADER_IN.ZZDATA_VENCTO = String.valueOf(order.PaymentDate__c).replace('-', '');
            IS_HEADER_IN.REF_DOC = order.OrderReference__c != null ? order.OrderReference__r.CodigoSap__c : '';

            Map<String, String> referenceItemMotherMap = new Map<String, String>();
            if(order.OrderReference__c != null){
                List<OrderItem> orderItemReferenceList = [SELECT Product2.ExternalId__c, NumeroSap__c FROM OrderItem WHERE OrderId =:  order.OrderReference__c];
                for(OrderItem orderItem : orderItemReferenceList){
                    referenceItemMotherMap.put(orderItem.Product2.ExternalId__c, orderItem.NumeroSap__c);
                }
            }   
          

            for(OrderItem orderItem : order.OrderItems){
                orderItemIds.add(orderItem.Id);
            }

            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>([
                SELECT Id, NumeroSap__c, Product2.ExternalId__c, Product2.DistributionCenter__r.Code__c, Quantity, UnitPrice, ListCost__c, DiscountValue__c, FinancialAdditionValue__c, FinancialDiscountValue__c, CommercialAdditionValue__c,
                FinancialAdditionPercent__c, FinancialDiscountPercent__c, CommercialMargin__c, DiscountPercent__c, CommercialAdditionPercent__c
                FROM OrderItem
                WHERE Id IN: orderItemIds
            ]);

      

            List<ShippingDivison__c> divisonList = [SELECT Id,Name, DeliveryDate__c, Quantity__c, OrderItem__c FROM ShippingDivison__c WHERE OrderItem__c IN: orderItemIds];
            Map<Id, List<ShippingDivison__c>> divisionMap = new  Map<Id, List<ShippingDivison__c>>();

            for(ShippingDivison__c sd : divisonList){
                if(!divisionMap.containsKey(sd.OrderItem__c)){
                    divisionMap.put(sd.OrderItem__c, new List<ShippingDivison__c>());
                }
                divisionMap.get(sd.OrderItem__c).add(sd);
            }

            List<Integer> shippingCodesList = new List<Integer>();
            for(OrderItem orderItem : orderItemMap.values()){

                if(!divisionMap.isEmpty())
                {
                    for(ShippingDivison__c sd : divisionMap.get(orderItem.Id)){
                        IT_ORDER_SCHEDULES_IN.add(new CalloutOrderUpdate.ScheduleParameters(String.valueOf(orderItem.NumeroSap__c).leftPad(6, '0'), String.valueOf(sd.Quantity__c), String.valueOf(sd.DeliveryDate__c)));
                    }
                }
                
                IT_ITEMS_IN.add(new CalloutOrderUpdate.OrderItemParameters(orderItem, referenceItemMotherMap.containsKey(orderItem.Product2.ExternalId__c) ?  referenceItemMotherMap.get(orderItem.Product2.ExternalId__c) : '' ));
                if(orderItem.FinancialAdditionValue__c > 0){
                    IT_CONDITIONS_IN.add(new CalloutOrderUpdate.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZDEC', String.valueOf(CalloutOrderUpdate.isNotation(orderItem.CommercialAdditionPercent__c)), ''));
                }
                else{
                    IT_CONDITIONS_IN.add(new CalloutOrderUpdate.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZDEC', String.valueOf(CalloutOrderUpdate.isNotation(orderItem.DiscountPercent__c)*-1), ''));
                }
                // IT_CONDITIONS_IN.add(new CalloutOrderUpdate.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZPRS', String.valueOf(CalloutOrderUpdate.isNotation(orderItem.ListCost__c)), order.Currency__c));
                // IT_CONDITIONS_IN.add(new CalloutOrderUpdate.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZPR0', String.valueOf(CalloutOrderUpdate.isNotation(orderItem.UnitPrice)), order.Currency__c));
                // IT_CONDITIONS_IN.add(new CalloutOrderUpdate.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZJUR', String.valueOf(CalloutOrderUpdate.isNotation(orderItem.FinancialAdditionPercent__c)), '%'));
                // IT_CONDITIONS_IN.add(new CalloutOrderUpdate.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZDAN', String.valueOf(CalloutOrderUpdate.isNotation(orderItem.FinancialDiscountPercent__c)), '%'));
                IT_CONDITIONS_IN.add(new CalloutOrderUpdate.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZMAR', String.valueOf(CalloutOrderUpdate.isNotation(orderItem.CommercialMargin__c)), '%'));
            }
        }
    }

    public class Header{
        
        public String REQ_DATE_H; // orderSalesType;
        public String INCOTERMS1;
        public String INCOTERMS2;
        public String PMNTTRMS; // paymentCondition;
        public String PYMT_METH; //forma de pagamento
        public String CT_VALID_F; // Data inicio(Pedido Mãe)
        public String CT_VALID_T; // Data inicio(Pedido Mãe)
        public String ORD_REASON; //orderReason;
        public String DLV_BLOCK; //orderReason;
        public String PURCH_NO_C; // Customer;
        public String ZZSAFRA; //crop;
        public String ZZCOD_CULTURA; //culture;
        public String ZZPED_CRM; //orderType;
        public String ZZDATA_CARENCIA;
        public String ZZDATA_VENCTO;
        public String REF_DOC;

    }

    public class PartnerParameters{
        public String UPDATEFLAG;
        public String PARTN_ROLE;
        public String PARTN_NUMB;

        public PartnerParameters(String partnerCode, String partnerFunc, String updateFlag){
            this.UPDATEFLAG = updateFlag;
            this.PARTN_ROLE = partnerFunc;
            this.PARTN_NUMB = partnerCode;
        }
    } 

    public class ScheduleParameters{
        public String ITM_NUMBER;
        public String REQ_QTY;
        public String REQ_DATE;

        public ScheduleParameters(String incrementItem, String quantityItem, String deliveryDate){
            this.ITM_NUMBER = incrementItem;
            this.REQ_QTY = quantityItem;
            this.REQ_DATE = deliveryDate.replace('-', '');
        }
    }

    public class ConditionParameters{
        public String ITM_NUMBER;
        public String COND_TYPE;
        public String COND_VALUE;
        public String TYPE_CURRENCY;

        public ConditionParameters(String incrementItem, String conditionType, String conditionValue, String conditionCurrency){
            this.ITM_NUMBER = incrementItem;
            this.COND_TYPE = conditionType;
            this.COND_VALUE = conditionValue;
            this.TYPE_CURRENCY = conditionCurrency;
        }
    }

 
    public class OrderItemParameters{
        public String ITM_NUMBER;
        public String MATERIAL;
        public String PLANT;
        public String REASON_REJ;
        public String TARGET_QTY;
        public String REF_DOC_IT;

        public OrderItemParameters(OrderItem orderItem, String numReference){
            this.ITM_NUMBER = String.valueOf(orderItem.NumeroSap__c).leftPad(6, '0');
            this.MATERIAL = orderItem.Product2.ExternalId__c;
            this.REASON_REJ = orderItem.ReasonRefuse__c;
            this.PLANT = orderItem.Product2.DistributionCenter__r.Code__c;
            this.TARGET_QTY =  String.valueOf(orderItem.Quantity);
            this.REF_DOC_IT = numReference != '' ? numReference.leftPad(6, '0') : '';
        }
    }

    //! Response part
    public class ResponseParameters {
        public ResponseParametersWrapper responses;

        public ResponseParameters(ResponseParametersWrapper responses) {
            this.responses = responses;
        }
    }

    public class ResponseParametersWrapper {
        public OrderDetails ET_RETURN;
        public String EV_SALES_DOC;
    }

    public class Messages{
        public String TYPE;
        public String CODE;
        public String MESSAGE;
        public String LOG_NO;
        public String LOG_MSG_NO;
        public String MESSAGE_V1;
        public String MESSAGE_V2;
        public String MESSAGE_V3;
        public String MESSAGE_V4;
    }

    public class OrderDetails{
        public List<Messages> item;
    }
}