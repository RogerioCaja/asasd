public without sharing class CalloutOrder {
    private static Boolean errorIntegration;

    static{
        errorIntegration = false;
    }
    
    public CalloutOrder() { }

    @future(callout = true)
    public static void callIntegration(Id orderId){
        processIntegration(orderId);
    }

    public static IntegrationUtils.CalloutResponse processIntegration(Id orderId){
        errorIntegration = false;
		Order parentOrder = [SELECT Id, CodigoSap__c, ShippingAccount__r.ExternalId__c, Company__r.SupplierCenter__c, Account.ExternalId__c, Type, SalesOrg__r.SalesOrganizationCode__c, SalesOrg__r.Name, DistributionChannel__c, DistributionChannel__r.Codigo__c, SalesCondition__r.ExternalId__c, SalesCondition__r.Name, Company__r.salesOffice__r.Codigo__c,  CompanyReceiver__c, CompanyReceiver__r.SupplierCenter__c, 
                            ActivitySector__c, ACMContract__c, ActivitySector__r.Codigo__c, PaymentCondition__r.CashPayment__c, Incoterms__c, Incoterms2__c, PaymentCondition__r.Code__c, OrderReason__c , SalesCTV__r.CodigoSap__c, PaymentDate__c,EffectiveDate, OrderReference__r.CodigoSap__c, Company__r.salesTeam__r.ExternalId__c, BPStorage__r.ExternalId__c,
                            OrderNumber, Crop__r.Name, Crop__r.Code__c, Crop__r.StartDateOrderInsertion__c, Crop__r.EndDateInsertionOrders__c ,Culture__r.Codigo__c, EndDate, TotalAmount, PaymentForm__c, OrderReference__c, CustomerOrderNumber__c, SalesCTV__r.SellerType__c, EffectiveOrderDate__c, NumeroPedidoApp__c, FreightValue__c, MTO__c, ShippingDate__c,
                            Currency__c,IsDisableSendIntegration__c, Crop__r.PaymentBaseDate__c,IsOrderMother__c, RecordTypeId,Description,DescriptionBillingSale__c, DistributionCenter__r.Code__c, RecordType.DeveloperName, (SELECT Id FROM OrderItems) 
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
			
            for(Messages message : resp.responses.ET_RETURN.item){
                if(message.TYPE != 'S' && message.TYPE != 'W' && message.TYPE != 'I'){
                    calloutResponse.success = false;
                    calloutResponse.errorMessage = (calloutResponse.errorMessage != null ? calloutResponse.errorMessage : '') + message.MESSAGE + '\n';
                }
            }
            if(!calloutResponse.success || resp.responses.ET_RETURN.item == null || errorIntegration){
                allOrders[0].ErrorIntegrationSAP__c = calloutResponse.errorMessage;
                allOrders[0].IsDisableSendIntegration__c = false;
                orderList.add(allOrders[0]);
            }

            if(calloutResponse.success){
                if(allOrders[0].CodigoSap__c == null){
                    allOrders[0].CodigoSap__c = resp.responses.EV_SALES_DOC;
                    allOrders[0].StatusSF__c = 'Integrado';
                    allOrders[0].Status =  resp.responses.EV_STATUS;
                    allOrders[0].ErrorIntegrationSAP__c = '';
                    allOrders[0].IsDisableSendIntegration__c = true;
                }else{
                    allOrders[0].ACMContract__c = resp.responses.EV_SALES_DOC;
                    allOrders[0].IsDisableSendIntegration__c = true;
                }
                orderList.add(allOrders[0]);
            }
            
			if (!orderList.isEmpty()) {
                OrderHelper.disableTrigger();
                Database.SaveResult[] upsResult = Database.update(orderList, false);
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
        return auth.access_token;
    }

    public class AuthToken{
        public String access_token;
    }

	public static IntegrationUtils.CalloutResponse sendOrder(List<Order> orders) {
			
        Integration__c integrationOUT = Integration__c.getInstance('Pedidos OUT SAP');
        if(integrationOUT != null && integrationOUT.IsInactive__c){
            IntegrationLog.createLog('Pedido OUT SAP', 'OUT', '', 'Integração INATIVA', true);
			return new IntegrationUtils.CalloutResponse('Integração INATIVA');
        }
		// RequestParameters request = new RequestParameters(orders[0]);
        Object result = manageConstruction(orders[0]);
		String payload = JSON.serialize(result);
        payload = payload.replace('TYPE_CURRENCY', 'CURRENCY');
        System.debug(JSON.serializePretty(result));

		//Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
		String accessToken = !Test.isRunningTest() ? getAccessToken() : 'testeToken';
		
		//Path geralmente cadastrado dentro de ua customSettings
		String endpoint = (!Test.isRunningTest() ? integrationOUT.Url__c : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', 'Bearer '+ accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap);

		if (responseObject.success) {

			HttpResponse response = responseObject.response;
            String title = 'Pedido OUT - SAP';
            if(payload.contains('"IV_TYPE":"B"')){ title += ' - Contrato Barter';}

            if(response.getBody().contains('"TYPE":"E"') || response.getBody().contains('An internal server error') || response.getBody().contains('Read timed out')){
                errorIntegration = true;
                IntegrationLog.createLog(title, 'OUT', response.getBody(), payload, true);
            }else{
                IntegrationLog.createLog(title, 'OUT', response.getBody(), payload, false);
            }
			try {

				ResponseParametersWrapper responses = (ResponseParametersWrapper) JSON.deserialize(response.getBody(), ResponseParametersWrapper.class);
				return new IntegrationUtils.CalloutResponse(new ResponseParameters(responses));
			} catch (Exception e) {
				errorIntegration = true;
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

				return new IntegrationUtils.CalloutResponse(defaultErrorMessage);
			}
		} else {
            errorIntegration = true;
            IntegrationLog.createLog('Pedido OUT - SAP', 'OUT', responseObject.exceptionObject.getMessage(), payload, true);
			return new IntegrationUtils.CalloutResponse(responseObject.exceptionObject.getMessage());
		}
    }

    public static Object manageConstruction(Order order){
        FactoryBuilder.Director director = new FactoryBuilder.Director();
        FactoryBuilder.Builder builder;
        String orderTypeName = Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosById().get(order.RecordTypeId).getName();
        if(order.SalesOrg__r.SalesOrganizationCode__c == '1700' && !(orderTypeName == 'Venda Barter')){
            builder = (FactoryBuilder.Builder) new FactoryBuilder.RequestSeedsBuilder();
            director.constructRequestSeed(builder, order);
        }else if(order.SalesOrg__r.SalesOrganizationCode__c == '1700' && (orderTypeName == 'Venda Barter')){
            builder = (FactoryBuilder.Builder) new FactoryBuilder.RequestBarterSeedsBuilder();
            director.constructRequestBarterSeeds(builder, order);
        }else if(orderTypeName == 'Venda Barter' && order.CodigoSap__c != null){
            builder = (FactoryBuilder.Builder) new FactoryBuilder.RequestBarterBuilder();
            director.constructRequestBarter(builder, order);
        }else{
            builder = (FactoryBuilder.Builder) new FactoryBuilder.RequestBuilder();
            director.constructRequestBasic(builder, order);
        }
        return builder.getResult();
       
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