public without sharing class CalloutOrder {
    public CalloutOrder() {
        
    }



    @future(callout = true)
    public static void callIntegration(Id orderId){
        processIntegration(orderId);
    }

    public static IntegrationUtils.CalloutResponse processIntegration(Id orderId){

		Order parentOrder = [SELECT Id, CodigoSap__c, ShippingAccount__r.ExternalId__c, Company__r.SupplierCenter__c, Account.ExternalId__c, Type, SalesOrg__r.SalesOrganizationCode__c, DistributionChannel__c, DistributionChannel__r.Codigo__c, SalesCondition__r.ExternalId__c,
                            ActivitySector__c, ActivitySector__r.Codigo__c, PaymentCondition__r.CashPayment__c, Incoterms__c, Incoterms2__c, PaymentCondition__r.Code__c, OrderReason__c , SalesCTV__r.CodigoSap__c, PaymentDate__c,EffectiveDate, OrderReference__r.CodigoSap__c,
                            OrderNumber, Crop__r.Code__c, Crop__r.StartDateOrderInsertion__c, Crop__r.EndDateInsertionOrders__c ,Culture__r.Codigo__c, EndDate, TotalAmount, PaymentForm__c, OrderReference__c, CustomerOrderNumber__c, SalesCTV__r.SellerType__c, EffectiveOrderDate__c, NumeroPedidoApp__c,
                            Currency__c, Crop__r.PaymentBaseDate__c,IsOrderMother__c, RecordTypeId,Description,DescriptionBillingSale__c, DistributionCenter__r.Code__c, RecordType.DeveloperName, (SELECT Id FROM OrderItems) 
                            FROM Order WHERE Id = :orderId];
		
		List<Order> allOrders = new List<Order>{parentOrder};
		
		IntegrationUtils.CalloutResponse calloutResponse = sendOrder(allOrders);

		if (calloutResponse.success) {
			
			ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponse;
			Map<String, Order> orderMap = new Map<String, Order>();

			for (Order ord : allOrders) {
				orderMap.put(ord.OrderNumber, ord);
			}

			List<Order> orderList = new List<Order>();
            //test
			
            for(Messages message : resp.responses.ET_RETURN.item){
                if(message.TYPE != 'S' && message.TYPE != 'W'){
                    calloutResponse.success = false;
                    calloutResponse.errorMessage = message.MESSAGE;
                }
            }
            if(calloutResponse.success){
                allOrders[0].CodigoSap__c = resp.responses.EV_SALES_DOC;
                allOrders[0].StatusSF__c = 'Integrado';
                allOrders[0].Status =  resp.responses.EV_STATUS;
                orderList.add(allOrders[0]);
            }
            
			if (!orderList.isEmpty()) {
                OrderHelper.disableTrigger();
                Database.SaveResult[] upsResult = Database.update(orderList, false);
                OrderHelper.enableTrigger();
                // if(upsResult[0].isSuccess())
                //     CalloutOrderDatalake.processIntegration(orderId);
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

	public static IntegrationUtils.CalloutResponse sendOrder(List<Order> orders) {
			
        Integration__c integrationOUT = Integration__c.getInstance('Pedidos OUT');
        if(integrationOUT != null && integrationOUT.IsInactive__c){
            IntegrationLog.createLog('Pedido OUT SAP', 'OUT', '', 'Integração INATIVA', true);
			return new IntegrationUtils.CalloutResponse('Integração INATIVA');
        }
		RequestParameters request = new RequestParameters(orders[0]);

		// for (Order ord : orders) {
		// 	request.add(new RequestParameters(ord));
		// }

		String payload = JSON.serialize(request);
        payload = payload.replace('TYPE_CURRENCY', 'CURRENCY');
        System.debug(JSON.serializePretty(request));

		//Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
		String accessToken = !Test.isRunningTest() ? getAccessToken() : 'testeToken';
		
		//Path geralmente cadastrado dentro de ua customSettings
		String endpoint = (!Test.isRunningTest() ? 'https://agrogalaxy-prd-01.it-cpi008-rt.cfapps.br10.hana.ondemand.com/http/SI_CRIA_OV_OUT' : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', 'Bearer '+ accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap);

		if (responseObject.success) {

			HttpResponse response = responseObject.response;

            IntegrationLog.createLog('Pedido OUT - SAP', 'OUT', response.getBody(), payload, false);
			// .WSLog('Pedido', 'OUTBOUND', response.getBody(), payload, false);
			try {

				ResponseParametersWrapper responses = (ResponseParametersWrapper) JSON.deserialize(response.getBody(), ResponseParametersWrapper.class);
				return new IntegrationUtils.CalloutResponse(new ResponseParameters(responses));
			} catch (Exception e) {
				
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

				return new IntegrationUtils.CalloutResponse(defaultErrorMessage);
			}
		} else {

            IntegrationLog.createLog('Pedido OUT', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
			return new IntegrationUtils.CalloutResponse(responseObject.exceptionObject.getMessage());
		}
    }

    public static String getCodeTypeOrder(String typeOrder, Boolean isOrderMother){

        String orderType = typeOrder + (isOrderMother ? 'PedidoMae' : '');

        RecordTypes__mdt recordType = RecordTypes__mdt.getInstance(orderType);

        if(recordType != null) return recordType.Code__c;
        else return '';
    }

    public static Object addPaymentForm(Order order, CalloutOrder.Header payload){
        List<FormPayment__c> formPaymentList = [SELECT Amount__c, PaymentDate__c, PaymentType__c FROM FormPayment__c WHERE Order__c =: order.Id LIMIT 10];
        Map<String, Object> mapStringHeader = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payload));
        for(Integer i = 0; i<formPaymentList.size(); i++){
            mapStringHeader.put(('ZZDTAPAG' + i), String.valueOf(formPaymentList[i].PaymentDate__c).replace('-', ''));
            mapStringHeader.put(('ZZVLRPAG' + i), String.valueOf(formPaymentList[i].Amount__c));
            mapStringHeader.put(('ZZITMPAG' + i), String.valueOf(formPaymentList[i].PaymentType__c));
        }
        String header = JSON.serialize(mapStringHeader);
        return JSON.deserialize(header, CalloutOrder.Header.class);
    }

    public static Decimal isNotation(Decimal value){
        if(value == 0) return 0;
        else return value;
    }

    //! Preparing data to Callout
    public class RequestParameters{
        public String IV_TYPE;
        CalloutOrder.Header IS_HEADER_IN;
        public List<CalloutOrder.PartnerParameters> IT_PARTNERS;
        public List<CalloutOrder.ScheduleParameters> IT_ORDER_SCHEDULES_IN;
        public List<CalloutOrder.ConditionParameters> IT_CONDITIONS_IN;
        public List<CalloutOrder.OrderItemParameters> IT_ITEMS_IN;

        public RequestParameters(Order order){

            Decimal valueAmount = 0;
            Decimal valueDiscount = 0;
            Decimal valueInterest = 0;

            IT_PARTNERS = new List<CalloutOrder.PartnerParameters>();
            IT_ORDER_SCHEDULES_IN = new List<CalloutOrder.ScheduleParameters>();
            IT_ITEMS_IN = new List<CalloutOrder.OrderItemParameters>();
            IT_CONDITIONS_IN = new List<CalloutOrder.ConditionParameters>();

            IT_PARTNERS.add(new CalloutOrder.PartnerParameters(order.Account.ExternalId__c, 'AG'));
            IT_PARTNERS.add(new CalloutOrder.PartnerParameters(order.ShippingAccount__r.ExternalId__c, 'RM'));
            IT_PARTNERS.add(new CalloutOrder.PartnerParameters(order.SalesCTV__r.CodigoSap__c, 'ZC'));

            Set<Id> orderItemIds = new Set<Id>();

            IS_HEADER_IN = new CalloutOrder.Header();
            
            IV_TYPE = order.IsOrderMother__c != false ? 'G' : 'C';

            String dateF;

            Map<String, String> statusSeller = new Map<String, String>();
            statusSeller.put('CTV', 'CT');
            statusSeller.put('Franqueado', 'FR');

            if(order.Crop__r.StartDateOrderInsertion__c < System.today() && IV_TYPE == 'G' ){
                dateF = String.valueOf(order.EffectiveDate).replace('-', '');
            }
            else{
                dateF = String.valueOf(order.Crop__r.StartDateOrderInsertion__c).replace('-', '');
            }
            
            IS_HEADER_IN.DOC_TYPE = getCodeTypeOrder(String.valueOf(order.RecordType.DeveloperName), IV_TYPE == 'G' ? true : false); 
            if(IS_HEADER_IN.DOC_TYPE == 'ZVNO' && order.PaymentCondition__r.CashPayment__c) IS_HEADER_IN.DOC_TYPE = 'ZVAB';
            IS_HEADER_IN.SALES_ORG = order.SalesOrg__r.SalesOrganizationCode__c;
            IS_HEADER_IN.DISTR_CHAN =order.DistributionChannel__r.Codigo__c;
            IS_HEADER_IN.DIVISION = order.ActivitySector__r.Codigo__c;
            IS_HEADER_IN.INCOTERMS1 = order.Incoterms__c;
            IS_HEADER_IN.INCOTERMS2 = order.Incoterms2__c;
            IS_HEADER_IN.PMNTTRMS = order.PaymentCondition__r.Code__c;
            IS_HEADER_IN.PYMT_METH = order.PaymentForm__c;
            
            IS_HEADER_IN.CT_VALID_F = IV_TYPE == 'G'  ? dateF :  '';
            IS_HEADER_IN.CT_VALID_T = IV_TYPE == 'G' ? String.valueOf(order.Crop__r.EndDateInsertionOrders__c).replace('-', '') : '';

            IS_HEADER_IN.PURCH_NO_C = order.CustomerOrderNumber__c;
            IS_HEADER_IN.ORD_REASON = order.OrderReason__c;
            IS_HEADER_IN.ZZSAFRA = order.Crop__r.Code__c;
            IS_HEADER_IN.ZZCOD_CULTURA = order.Culture__r.Codigo__c;
            IS_HEADER_IN.ZZPED_CRM = order.OrderNumber;
            IS_HEADER_IN.ZZDATA_CARENCIA = String.valueOf(order.Crop__r.PaymentBaseDate__c).replace('-', '');
            IS_HEADER_IN.ZZDATA_VENCTO = String.valueOf(order.PaymentDate__c).replace('-', '');
            IS_HEADER_IN.PRICE_LIST = String.valueOf(order.SalesCondition__r.ExternalId__c).leftPad(2, '0');
            if(order.OrderReference__c != null){
                Order orderReference = [SELECT EffectiveOrderDate__c, EffectiveDate FROM Order WHERE Id =: order.OrderReference__c LIMIT 1];
                if(orderReference != null){
                    IS_HEADER_IN.PRICE_DATE = orderReference.EffectiveOrderDate__c == null ? String.valueOf(orderReference.EffectiveDate).replace('-', '') : String.valueOf(orderReference.EffectiveOrderDate__c).replace('-', '');
                }
            }
            else{
                IS_HEADER_IN.PRICE_DATE = order.EffectiveOrderDate__c == null ? String.valueOf(order.EffectiveDate).replace('-', '') : String.valueOf(order.EffectiveOrderDate__c).replace('-', '');
            }
            IS_HEADER_IN.REF_DOC = order.OrderReference__c != null ? order.OrderReference__r.CodigoSap__c : '';
            IS_HEADER_IN.CSTCNDGRP1 = statusSeller.get(order.SalesCTV__r.SellerType__c);

            IS_HEADER_IN.PO_METHOD = order.NumeroPedidoApp__c != null ? 'APP' : 'SFOR';
            
            //Add fields to descriptions
            if(order.Description != null) order.Description = order.Description.replace('1n73gr4ção N3sc4r4 5F x 4PP', '');
            IS_HEADER_IN.TEXT_ADICIONAL = order.Description != null ? order.Description : '';
            IS_HEADER_IN.TEXT_DANFE = order.DescriptionBillingSale__c != null ? order.DescriptionBillingSale__c : '';

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
                FinancialAdditionPercent__c, FinancialDiscountPercent__c, CommercialMargin__c, DiscountPercent__c, CommercialAdditionPercent__c, ListPrice__c, Class__c, Sieve__c
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
                    if(divisionMap.containsKey(orderItem.Id)){
                        for(ShippingDivison__c sd : divisionMap.get(orderItem.Id)){
                            IT_ORDER_SCHEDULES_IN.add(new CalloutOrder.ScheduleParameters(String.valueOf(orderItem.NumeroSap__c).leftPad(6, '0'), String.valueOf(sd.Quantity__c), String.valueOf(sd.DeliveryDate__c)));
                        }
                    }
                }
                
                IT_ITEMS_IN.add(new CalloutOrder.OrderItemParameters(orderItem, referenceItemMotherMap.containsKey(orderItem.Product2.ExternalId__c) ?  referenceItemMotherMap.get(orderItem.Product2.ExternalId__c) : '', order.DistributionCenter__r.Code__c == null ? order.Company__r.SupplierCenter__c : order.DistributionCenter__r.Code__c));
                if(orderItem.CommercialAdditionPercent__c > 0){
                    IT_CONDITIONS_IN.add(new CalloutOrder.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZDEC', (CalloutOrder.isNotation(orderItem.CommercialAdditionPercent__c)).toPlainString(), ''));
                }
                else{
                    IT_CONDITIONS_IN.add(new CalloutOrder.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZDEC', (CalloutOrder.isNotation(orderItem.DiscountPercent__c)*-1).toPlainString(), ''));
                }
                
                if(IS_HEADER_IN.PRICE_LIST == '99'){
                    IT_CONDITIONS_IN.add(new CalloutOrder.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZPR0', String.valueOf(CalloutOrder.isNotation(orderItem.ListPrice__c)), ''));
                }
               
                // IT_CONDITIONS_IN.add(new CalloutOrder.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZPRS', String.valueOf(CalloutOrder.isNotation(orderItem.ListCost__c)), order.Currency__c));
                // IT_CONDITIONS_IN.add(new CalloutOrder.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZJUR', String.valueOf(CalloutOrder.isNotation(orderItem.FinancialAdditionPercent__c)), '%'));
                // IT_CONDITIONS_IN.add(new CalloutOrder.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZDAN', String.valueOf(CalloutOrder.isNotation(orderItem.FinancialDiscountPercent__c)), '%'));
                IT_CONDITIONS_IN.add(new CalloutOrder.ConditionParameters(orderItem.NumeroSap__c.leftPad(6, '0'), 'ZMAR', String.valueOf(CalloutOrder.isNotation(orderItem.CommercialMargin__c)), ''));
            }
            IS_HEADER_IN = (CalloutOrder.Header)addPaymentForm(order, IS_HEADER_IN);
        }
    }

    public class Header{
        
        public String DOC_TYPE; // orderSalesType;
        public String SALES_ORG; //salesOrg;
        public String DISTR_CHAN;// distributionChannel;
        public String DIVISION; // activitySector;
        public String INCOTERMS1;
        public String INCOTERMS2;
        public String PMNTTRMS; // paymentCondition;
        public String PYMT_METH; //forma de pagamento
        public String CT_VALID_F; // Data inicio(Pedido Mãe)
        public String CT_VALID_T; // Data inicio(Pedido Mãe)
        public String ORD_REASON; //orderReason;
        public String PURCH_NO_C; // Customer;
        public String ZZSAFRA; //crop;
        public String ZZCOD_CULTURA; //culture;
        public String ZZPED_CRM; //orderType;
        public String ZZDATA_CARENCIA;
        public String ZZDATA_VENCTO;
        public String REF_DOC;
        public String PRICE_LIST;
        public String PRICE_DATE;
        public String CSTCNDGRP1;
        public String PO_METHOD;
        public String TEXT_ADICIONAL;
        public String TEXT_DANFE;
        public String ZZDTAPAG0;
        public String ZZVLRPAG0;
        public String ZZITMPAG0;
        public String ZZDTAPAG1;
        public String ZZVLRPAG1;
        public String ZZITMPAG1;
        public String ZZDTAPAG2;
        public String ZZVLRPAG2;
        public String ZZITMPAG2;
        public String ZZDTAPAG3;
        public String ZZVLRPAG3;
        public String ZZITMPAG3;
        public String ZZDTAPAG4;
        public String ZZVLRPAG4;
        public String ZZITMPAG4;
        public String ZZDTAPAG5;
        public String ZZVLRPAG5;
        public String ZZITMPAG5;
        public String ZZDTAPAG6;
        public String ZZVLRPAG6;
        public String ZZITMPAG6;
        public String ZZDTAPAG7;
        public String ZZVLRPAG7;
        public String ZZITMPAG7;
        public String ZZDTAPAG8;
        public String ZZVLRPAG8;
        public String ZZITMPAG8;
        public String ZZDTAPAG9;
        public String ZZVLRPAG9;
        public String ZZITMPAG9;
        
        public Header(){}
    }


    public class PartnerParameters{
        public String PARTN_ROLE;
        public String PARTN_NUMB;

        public PartnerParameters(String partnerCode, String partnerFunc){
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
        public String TARGET_QTY;
        public String REF_DOC_IT;
        public String ZZPENEIRA;
        public String ZZCLAS_CAT;


        public OrderItemParameters(OrderItem orderItem, String numReference, String plant){
            this.ITM_NUMBER = String.valueOf(orderItem.NumeroSap__c).leftPad(6, '0');
            this.MATERIAL = orderItem.Product2.ExternalId__c;
            this.PLANT = plant;
            this.TARGET_QTY =  String.valueOf(orderItem.Quantity);
            this.REF_DOC_IT = numReference != '' ? numReference.leftPad(6, '0') : '';
            this.ZZPENEIRA = orderItem.Sieve__c;
            this.ZZCLAS_CAT = orderItem.Class__c;
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
        public String EV_STATUS;
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