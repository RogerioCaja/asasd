public with sharing class CalloutOrderDatalake {
    public CalloutOrderDatalake() {

    }
    @future(callout = true)
    public static void callIntegration(Id orderId){
        processIntegration(orderId);
    }

    public static IntegrationUtils.CalloutDatalakeResponse processIntegration(Id orderId){

		Order parentOrder = [SELECT Id, CodigoSap__c, ShippingAccount__r.ExternalId__c, Account.ExternalId__c, Type, SalesOrg__r.SalesOrganizationCode__c, DistributionChannel__c, 
                            ActivitySector__c, Incoterms__c, Incoterms2__c, PaymentCondition__c, OrderReason__c , 
                            OrderNumber, Crop__r.Code__c, Culture__r.Codigo__c, EndDate, TotalAmount, 
                            Currency__c, StatusSAP__c, AccountId, (SELECT Id FROM OrderItems) 
                            FROM Order WHERE Id = :orderId];
		System.debug('parentOrder' + parentOrder);
		List<Order> allOrders = new List<Order>{parentOrder};
        
		
		IntegrationUtils.CalloutDatalakeResponse calloutResponse = sendOrder(allOrders);

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
                    //ord.StatusSAP__c = respWrapper.DetalhesPedido[0].StatusSap;
                    // ord.TypeMessage__c = respWrapper.Mensagens[0].Tipo;
                    // ord.Message__c = respWrapper.Mensagens[0].Mensagem;
					orderList.add(ord);
				}
			}

			if (!orderList.isEmpty()) {
                OrderHelper.disableTrigger();
				update orderList;
                OrderHelper.enableTrigger();
			}
		}
		
		return calloutResponse;
	}

	public static IntegrationUtils.CalloutDatalakeResponse sendOrder(List<Order> orders) {
			
		List<RequestParameters> request = new List<RequestParameters>();
        
		for (Order ord : orders) {
			request.add(new RequestParameters(ord));
		}
        System.debug('request' + request);
		String payload = JSON.serialize(request);
        System.debug('payload' + payload);
		//Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
		String code = (!Test.isRunningTest() ? getAcessCode() : 'acessToken');
        String accessToken = code;
		


		//Path geralmente cadastrado dentro de ua customSettings
		String endpoint = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/gtw/sales-order/v1/webhook/order' : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> ordersMap = new Map<String, String>();
		ordersMap.put('Content-type', 'application/json');
		ordersMap.put('Authorization', 'Bearer '+ accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, ordersMap);

		if (responseObject.success) {

			HttpResponse response = responseObject.response;

            IntegrationLog.createLog('Pedido OUT', 'OUT', response.getBody(), payload, false);
			// .WSLog('Pedido', 'OUTBOUND', response.getBody(), payload, false);
			try {

				List<ResponseParametersWrapper> responses = (List<ResponseParametersWrapper>) JSON.deserialize(response.getBody(), List<ResponseParametersWrapper>.class);
				return new IntegrationUtils.CalloutDatalakeResponse(new ResponseParameters(responses));
			} catch (Exception e) {
				
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

				return new IntegrationUtils.CalloutDatalakeResponse(defaultErrorMessage);
			}
		} else {

            IntegrationLog.createLog('Pedido OUT - DataLake', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
			return new IntegrationUtils.CalloutDatalakeResponse(responseObject.exceptionObject.getMessage());
		}
    }

    //! Preparing data to Callout
    public class RequestParameters{
        
        public Object header; 
        

        public RequestParameters(Order order){
            System.debug('orders' + order);
            

            Set<Id> orderItemIds = new Set<Id>();
            List<CalloutOrderDatalake.ScheduleParameters> scheduleList = new List<CalloutOrderDatalake.ScheduleParameters>();
            List<CalloutOrderDatalake.OrderItemParameters> orderItemList = new List<CalloutOrderDatalake.OrderItemParameters>();
            for(OrderItem orderItem : order.OrderItems){
                orderItemIds.add(orderItem.Id);
            }
            
            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>([
                SELECT Id, NumeroSap__c, Product2.ExternalId__c, Product2.DistributionCenter__r.Code__c, Quantity
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
                        scheduleList.add(new CalloutOrderDatalake.ScheduleParameters(Integer.valueOf(sd.Name), sd.Quantity__c, sd.DeliveryDate__c));
                    }
                }
                orderItemList.add(new CalloutOrderDatalake.OrderItemParameters(orderItem, shippingCodesList));
                //System.debug('order' + orders);
            }

            if(order.CodigoSap__c != null){
                CalloutOrderDatalake.HeaderInsert header = new CalloutOrderDatalake.HeaderInsert();
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
                if(order.Culture__c != null){
                    header.culture = Integer.valueOf(order.Culture__r.Codigo__c);
                }else{
                    header.culture = null;
                }
                header.orderType = order.Type;
                header.codSalesforce = order.OrderNumber;
                header.expiredDate = order.EndDate;
                header.paymentAccount = order.AccountId;
                header.shippingAccount = order.ShippingAccount__c;
                header.orderItemList = orderItemList;
                header.scheduleList = scheduleList;
                this.header = header;

                

                system.debug('header' + header);
                system.debug('Order' + order);
                //orderDatalake.salesCTV = AccountId.ShippingAccount__c.SalesCTV__c; --> Verificar CTV
            }
            else {
                CalloutOrderDatalake.HeaderUpdate header = new CalloutOrderDatalake.HeaderUpdate();
                header.codSap = order.CodigoSap__c;
                header.codSalesforce = order.OrderNumber;
                header.expiredDate = order.EndDate;
                this.header = header;
            }

            
            
            //condition.add(new CalloutOrderDatalake.ConditionParameters(Integer.valueOf(order.Culture__r.Codigo__c), 'PR00', order.TotalAmount, order.Currency__c)); 
            //this.orders = orders;
            //this.condition = condition;
            //this.Shipping = Shipping;
            //this.orderItemList = orderItemList;
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
        public String salesCTV;
        public String paymentAccount;
        public String shippingAccount;
        public List<CalloutOrderDatalake.ScheduleParameters> scheduleList;
        public List<CalloutOrderDatalake.OrderItemParameters> orderItemList;
        public HeaderInsert(){}
    }

    public class HeaderUpdate{
        public String codSap;
        public String codSalesforce;
        public Date  expiredDate;

        //public OrderUpdate(){}
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
        //public String StatusSap;
        public String NumeroOrdemVenda;
    }

//Método para atualizar access token
    public static String getAcessCode(){
        String payloadToken = 'grant_type=client_credentials';
        String endpointToken = (!Test.isRunningTest() ? 'https://apim.agrogalaxy.com.br/identityserver/oauth2/token' : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMapToken = new Map<String, String>();
        headersMapToken.put('Content-type', 'application/x-www-form-urlencoded');
        headersMapToken.put('Authorization', 'Basic dEQxV2M0bWtXdnRWNWVtRXZSOHlVRF9iUFZvYTpmZmVJQUs5SmdPNXNsbXI1UzVMUXNNcTBOME1h');
        IntegrationUtils.RequestResponseObject responseObject2 = IntegrationUtils.executeCallout(endpointToken, payloadToken, headersMapToken);
        System.debug('responseObject2: '+ responseObject2);
        if (responseObject2.success) {
            HttpResponse response = responseObject2.response;
            ResponseParametersToken responses = (ResponseParametersToken) JSON.deserialize(response.getBody(), ResponseParametersToken.class);
            System.debug('responses: '+ responses);
            return responses.access_token;
        } else {
            return null;
        }
    }

    public class ResponseParametersToken {
        public String access_token;
        public String scope;
        public String token_type;
        public Decimal expires_in;
    }
}
