public with sharing class CalloutOrderDatalake {
    public CalloutOrderDatalake() {

    }
    @future(callout = true)
    public static void callIntegration(Id orderId){
        processIntegration(orderId);
    }

    public static IntegrationUtils.CalloutResponse processIntegration(Id orderId){

		Order parentOrder = [SELECT Id, CodigoSap__c, ShippingAccount__r.ExternalId__c, Account.ExternalId__c, Type, SalesOrg__r.SalesOrganizationCode__c, DistributionChannel__c, 
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
		String endpoint = (!Test.isRunningTest() ? 'https://e2d5f427-4632-4314-aac5-4801fbbe25db.mock.pstmn.io//OrderUpsert' : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> ordersMap = new Map<String, String>();
		ordersMap.put('Content-type', 'application/json');
		// ordersMap.put('Authorization', 'Bearer '+ accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, ordersMap);

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
        public Object orders;
        //public List<CalloutOrderDatalake.PartnerParameters> partner;
        public List<CalloutOrder.ScheduleParameters> schedule;
        public List<CalloutOrder.ConditionParameters> condition;
        public List<CalloutOrder.OrderItemParameters> orderItems;

        public RequestParameters(Order order){

            //partner = new List<CalloutOrder.PartnerParameters>();
            schedule = new List<CalloutOrder.ScheduleParameters>();
            orderItems = new List<CalloutOrder.OrderItemParameters>();
            condition = new List<CalloutOrder.ConditionParameters>();
            //partner.add(new CalloutOrder.PartnerParameters(order.Account.ExternalId__c, 'EO'));
            //partner.add(new CalloutOrder.PartnerParameters(order.ShippingAccount__r.ExternalId__c, 'RM'));

            Set<Id> orderItemIds = new Set<Id>();

            if(order.CodigoSap__c == null){
                CalloutOrder.OrderInsert order = new CalloutOrder.OrderInsert();
                order.orderSalesType = order.Type; // Não esquecer de mudar isso
                order.salesOrg = order.SalesOrg__r.SalesOrganizationCode__c;
                order.distributionChannel = order.DistributionChannel__c;
                order.activitySector = order.ActivitySector__c;
                order.incoterms1 = order.Incoterms__c;
                order.incoterms2 = order.Incoterms2__c;
                order.paymentCondition = order.PaymentCondition__c;
                order.orderReason = order.OrderReason__c;
                order.codSap = order.OrderNumber;
                order.crop = order.Crop__r.Code__c;
                order.culture = Integer.valueOf(order.Culture__r.Codigo__c);
                order.orderType = order.Type;
                order.codSalesforce = order.OrderNumber;
                order.expiredDate = order.EndDate;
                order.salesCTV = AccountId.ShippingAccount__c.SalesCTV__c;
            }
            else {
                CalloutOrderDatalake.orderUpdate order = new CalloutOrderDatalake.orderUpdate();
                order.codSap = order.CodigoSap__c;
                order.codSalesforce = order.OrderNumber;
                order.expiredDate = order.EndDate;
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
                if(!divisionMap.isEmpty())
                {
                    for(ShippingDivison__c sd : divisionMap.get(orderItem.Id)){
                        shippingCodesList.add(Integer.valueOf(sd.Name));
                        schedule.add(new CalloutOrder.ScheduleParameters(Integer.valueOf(sd.Name), sd.Quantity__c, sd.DeliveryDate__c));
                    }
                }
                orderItems.add(new CalloutOrder.OrderItemParameters(orderItem, shippingCodesList));
            }

            condition.add(new CalloutOrder.ConditionParameters(Integer.valueOf(order.Culture__r.Codigo__c), 'PR00', order.TotalAmount, order.Currency__c)); 
        }
    }

    public class OrderInsert{
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
        public String salesCTV;

        public OrderInsert(){}
    }

    public class OrderUpdate{
        public String codSap;
        public String codSalesforce;
        public Date  expiredDate;

        public OrderUpdate(){}
    }
/*
    public class PartnerParameters{
        public String partnerFunc;
        public String partnerCode;

        public PartnerParameters(String partnerCode, String partnerFunc){
            this.partnerCode = partnerCode;
            this.partnerFunc = partnerFunc;
        }
    } 
*/
    public class ShippingParameters{
        public Integer incrementItem;
        public Decimal quantityItem;
        public Date deliveryDate;

        public ShippingParameters(Integer incrementItem, Decimal quantityItem, Date deliveryDate){
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
