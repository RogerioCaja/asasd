public with sharing class CalloutOrder {
    public CalloutOrder() {
        
    }

    public static IntegrationUtils.CalloutResponse processIntegration(Id orderId){

		Order parentOrder = [SELECT Id, CodigoSap__c, Type, SalesOrg__r.SalesOrganizationCode__c, DistributionChannel__c, 
                            ActivitySector__c, Incoterms__c, Incoterms2__c, PaymentCondition__c, OrderReason__c , 
                            OrderNumber, Crop__r.Code__c, Culture__r.Codigo__c, EndDate, TotalAmount, 
                            Currency__c, (SELECT Id FROM OrderItems) 
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

			for (ResponseParametersWrapper respWrapper : resp.responses) {
				if (orderMap.containsKey(respWrapper.OrderNumber)) {

					Order ord = orderMap.get(respWrapper.OrderNumber);
                    ord.CodigoSap__c = respWrapper.DetalhesPedido[0].NumeroOrdemVenda; 
                    ord.StatusSAP__c = respWrapper.DetalhesPedido[0].StatusSap;
                    // ord.TypeMessage__c = respWrapper.Mensagens[0].Tipo;
                    // ord.Message__c = respWrapper.Mensagens[0].Mensagem;
					orderList.add(ord);
				}
			}

			if (!orderList.isEmpty()) {
				update orderList;
			}
		}
		
		return calloutResponse;
	}

	public static IntegrationUtils.CalloutResponse sendOrder(List<Order> orders) {
			
		List<RequestParameters> request = new List<RequestParameters>();

		for (Order ord : orders) {
			request.add(new RequestParameters(ord));
		}

		String payload = JSON.serialize(request);

		//Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
		String accessToken = '';//! FALTA SABER A RESPOSTA DO SAP QUANTO A AUTENTICAÇÃO! F
		
		//Path geralmente cadastrado dentro de ua customSettings
		String endpoint = (!Test.isRunningTest() ? 'callout:HANA_Oncoprod/PrePedido_SFOut' : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', 'Bearer '+ accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap);

		if (responseObject.success) {

			HttpResponse response = responseObject.response;

            IntegrationLog.createLog('Pedido OUT', 'OUT', response.getBody(), payload, false);
			// .WSLog('Pedido', 'OUTBOUND', response.getBody(), payload, false);
			try {

				List<ResponseParametersWrapper> responses = (List<ResponseParametersWrapper>) JSON.deserialize(response.getBody(), List<ResponseParametersWrapper>.class);
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

    //! Preparing data to Callout
    public class RequestParameters{
        public Object header;
        public List<CalloutOrder.PartnerParameters> partner;
        public List<CalloutOrder.ScheduleParameters> schedule;
        public List<CalloutOrder.ConditionParameters> condition;
        public List<CalloutOrder.OrderItemParameters> orderItems;

        public RequestParameters(Order order){

            partner = new List<CalloutOrder.PartnerParameters>();
            schedule = new List<CalloutOrder.ScheduleParameters>();
            orderItems = new List<CalloutOrder.OrderItemParameters>();
            condition = new List<CalloutOrder.ConditionParameters>();
            partner.add(new CalloutOrder.PartnerParameters(order.AccountId, 'EO'));
            partner.add(new CalloutOrder.PartnerParameters(order.ShippingAccount__c, 'RM'));

            Set<Id> orderItemIds = new Set<Id>();

            if(order.CodigoSap__c == null){
                CalloutOrder.HeaderInsert header = new CalloutOrder.HeaderInsert();
                header.orderSalesType = order.Type; // Não esquecer de mudar isso
                header.salesOrg = order.SalesOrg__r.SalesOrganizationCode__c;
                header.distributionChannel = order.DistributionChannel__c;
                header.activitySector = order.ActivitySector__c;
                header.incoterms1 = order.Incoterms__c;
                header.incoterms2 = order.Incoterms2__c;
                header.paymentCondition = order.PaymentCondition__c;
                header.orderReason = order.OrderReason__c;
                header.codSap = order.OrderNumber;
                header.crop = order.Crop__r.Code__c;
                header.culture = Integer.valueOf(order.Culture__r.Codigo__c);
                header.orderType = order.Type;
                header.codSalesforce = order.OrderNumber;
                header.expiredDate = order.EndDate;
            }
            else {
                CalloutOrder.HeaderUpdate header = new CalloutOrder.HeaderUpdate();
                header.codSap = order.CodigoSap__c;
                header.codSalesforce = order.OrderNumber;
                header.expiredDate = order.EndDate;
            }

            for(OrderItem orderItem : order.OrderItems){
                orderItemIds.add(orderItem.Id);
            }

            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>([
                SELECT Id, Product2.ExternalId__c, Product2.DistributionCenter__r.Code__c, Quantity
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

                shippingCodesList.clear();
                for(ShippingDivison__c sd : divisionMap.get(orderItem.Id)){
                    shippingCodesList.add(Integer.valueOf(sd.Name));
                    schedule.add(new CalloutOrder.ScheduleParameters(Integer.valueOf(sd.Name), sd.Quantity__c, sd.DeliveryDate__c));
                }
                orderItems.add(new CalloutOrder.OrderItemParameters(orderItem, shippingCodesList));
            }

            condition.add(new CalloutOrder.ConditionParameters(Integer.valueOf(order.Culture__r.Codigo__c), 'PR00', order.TotalAmount, order.Currency__c)); 
        }
    }

    public class HeaderInsert{
        public String orderSalesType;
        public String salesOrg;
        public String distributionChannel;
        public String activitySector;
        public String incoterms1;
        public String incoterms2;
        public String paymentCondition;
        public String orderReason;
        public String codSap;
        public String crop;
        public Integer culture;
        public String orderType;
        public String codSalesforce;
        public Date  expiredDate;

        public HeaderInsert(){}
    }

    public class HeaderUpdate{
        public String codSap;
        public String codSalesforce;
        public Date  expiredDate;

        public HeaderUpdate(){}
    }

    public class PartnerParameters{
        public String partnerFunc;
        public String partnerCode;

        public PartnerParameters(String partnerCode, String partnerFunc){
            this.partnerCode = partnerCode;
            this.partnerFunc = partnerFunc;
        }
    } 

    public class ScheduleParameters{
        public Integer incrementItem;
        public Decimal quantityItem;
        public Date deliveryDate;

        public ScheduleParameters(Integer incrementItem, Decimal quantityItem, Date deliveryDate){
            this.incrementItem = incrementItem;
            this.quantityItem = quantityItem;
            this.deliveryDate = deliveryDate;
        }
    }

    public class ConditionParameters{
        public Integer incrementItem;
        public String conditionType;
        public Decimal conditionValue;
        public String conditionCurrency;

        public ConditionParameters(Integer incrementItem, String conditionType, Decimal conditionValue, String conditionCurrency){
            this.incrementItem = incrementItem;
            this.conditionType = conditionType;
            this.conditionValue = conditionValue;
            this.conditionCurrency = conditionCurrency;
        }
    }

    public class OrderItemParameters{
        public List<Integer> incrementItem;
        public String material;
        public String center;
        public Decimal quantityItem;

        public OrderItemParameters(OrderItem orderItem, List<Integer> shippingDivison){
            this.incrementItem = new List<Integer>(shippingDivison);
            this.material = orderItem.Product2.ExternalId__c;
            this.center = orderItem.Product2.DistributionCenter__r.Code__c;
            this.quantityItem = orderItem.Quantity;
        }
    }

    public class ResponseParameters {
        public List<ResponseParametersWrapper> responses;

        public ResponseParameters(List<ResponseParametersWrapper> responses) {
            this.responses = responses;
        }
    }


    //! Response part
    public class ResponseParametersWrapper {
        public String OrderNumber; 
        public List<OrderDetails> DetalhesPedido;
        public List<Messages> Mensagens; 
    }

    public class Messages{
        public String Tipo;
        public String Mensagem;
    }

    public class OrderDetails{
        public String StatusSap;
        public String NumeroOrdemVenda;
    }
}
