public without sharing class CalloutOrderDatalake {
    public CalloutOrderDatalake() {

    }
    @future(callout = true)
    public static void callIntegration(Id orderId){
        processIntegration(orderId);
    }


    ////
    public static IntegrationUtils.CalloutDatalakeResponse processIntegration(Id orderId){

        Order parentOrder = [SELECT CodigoSap__c, Id, NumeroPedidoApp__c,  
        Pricebook2Id, ShippingAccount__r.ExternalId__c,
        ShippingAccount__c, Account.ExternalId__c, AccountId,  
        Crop__r.Code__c, Crop__c, Culture__r.Codigo__c, Culture__c,  
        SalesOrg__r.SalesOrganizationCode__c, SalesOrg__c,  
        SalesCTV__c, PaymentCondition__c, OrderReference__c,OrderReference__r.CodigoSap__c, OrderReason__c,
        OrderNumber, DistributionChannel__c, ActivitySector__c, PaymentDate__c,  
        EffectiveDate, ShippingDate__c, Status, StatusRecusa__c, Type,  
        CustomerOrderNumber__c, PaymentForm__c, StatusSF__c, Currency__c,  
        Incoterms__c, Incoterms2__c, Description, DescriptionBillingSale__c,  
        FinalTotalValue__c, Hectare__c, OrderMargin__c, OrderType__c, SalesCondition__c,  
        IsOrderMother__c, Company__c, RecordTypeId, TotalAmount, StatusSAP__c,Culture__r.Name,SalesOrg__r.Name,Crop__r.Name,
        SalesCTV__r.CodigoSap__c,PaymentCondition__r.Code__c, CompanyReceiver__r.SupplierCenter__c, Company__r.SupplierCenter__c, Company__r.SalesOffice__r.Codigo__c, Company__r.SalesTeam__r.ExternalId__c,
        DistributionChannel__r.Codigo__c,ActivitySector__r.Codigo__c, PaymentCondition__r.Name,EndDate,
        SalesCondition__r.ExternalId__c,SalesCondition__r.Name, Company__r.ExternalID__c,ACMContract__c,MTO__c, (SELECT Id FROM OrderItems) 
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
                // update orderList;
                OrderHelper.enableTrigger();
            }
        }
        
        return calloutResponse;
    }

    public static IntegrationUtils.CalloutDatalakeResponse sendOrder(List<Order> orders) {
            
        List<RequestParameters> request = new List<RequestParameters>();
        
        Integration__c integrationOUT = Integration__c.getInstance('Pedidos OUT');
        if(integrationOUT != null && integrationOUT.IsInactive__c){
            IntegrationLog.createLog('Pedido OUT Lake', 'OUT', '', 'Integração INATIVA', true);
			return new IntegrationUtils.CalloutDatalakeResponse('Integração INATIVA');
        }

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
		String endpoint = (!Test.isRunningTest() ? integrationOUT.Url__c : 'http://callout.My_Named_Credential.com/some/path');
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
            Set<Id> orderIds = new Set<Id>();
            List<CalloutOrderDatalake.ScheduleParameters> scheduleList = new List<CalloutOrderDatalake.ScheduleParameters>();
            List<CalloutOrderDatalake.OrderItemParameters> orderItemList = new List<CalloutOrderDatalake.OrderItemParameters>();
            List<CalloutOrderDatalake.OrderCommoditiesParameters> commodityList = new List<CalloutOrderDatalake.OrderCommoditiesParameters>();
            for(OrderItem orderItem : order.OrderItems){
                orderItemIds.add(orderItem.Id);
            }
            
            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>([
                SELECT Id, OrderId, Product2.ExternalId__c, PricebookEntryId,
                ExternalId__c, Quantity, UnitMeasure__c,
                PercentComission__c, DiscountPercent__c, ComissionValue__c,
                CommercialMargin__c, DiscountValue__c, FinalTotalValue__c,
                FinancialDiscountPercent__c, FinancialDiscountValue__c, FinancialAdditionPercent__c,
                FinancialAdditionValue__c, CommercialAdditionPercent__c, CommercialAdditionValue__c,
                Dosage__c, ListCost__c, NumeroSap__c, PracticedCost__c, PracticedPrice__c, UnitPrice, ReasonRefuse__c, AmountUsed__c,ItemBalance__c
                FROM OrderItem
                WHERE Id IN: orderItemIds
            ]);

            for(OrderItem ordItemForCommodity: orderItemMap.values()){
                orderIds.add(ordItemForCommodity.OrderId);
            }

           

            Map<String, String> orderPayment = new Map<String, String>();
                Schema.DescribeFieldResult objFieldDescribe = Schema.Order.PaymentForm__c.getDescribe();
                List<Schema.PicklistEntry> lstPickListValues = objFieldDescribe.getPickListValues();
                for (Schema.PicklistEntry objPickList : lstPickListValues) {
                    orderPayment.put(objPickList.getValue(), objPickList.getLabel());
                }
                System.debug(orderPayment.get('B'));
			
            Map<String, String> statusDesc = new Map<String, String>();
                Schema.DescribeFieldResult stsFieldDescribe = Schema.Order.Status.getDescribe();
                List<Schema.PicklistEntry> statusPickListValues = stsFieldDescribe.getPickListValues();
                for (Schema.PicklistEntry stsPickList : statusPickListValues) {
                    statusDesc.put(stsPickList.getValue(), stsPickList.getLabel());
                }
                System.debug(statusDesc.get('1'));
            
            Map<String, String> orderMTODesc = new Map<String, String>();
            Schema.DescribeFieldResult ordMtoValues = Schema.Order.MTO__c.getDescribe();
            List<Schema.PicklistEntry> listOrdMtoValues = ordMtoValues.getPicklistValues();
            for( Schema.PicklistEntry ordMtoPickList: listOrdMtoValues){
                orderMTODesc.put(ordMtoPickList.getValue(), ordMtoPickList.getLabel());
            }

            List<OrderCommodity__c> commoditiesList = [SELECT Id, Name, Product__c, CommodityPrice__c, BagQuantity__c, BagMargin__c, Order__c, StartDate__c, EndDate__c, DeliveryAddress__c, Product__r.ProductCode FROM OrderCommodity__c WHERE Order__c IN: orderIds];  
            List<ShippingDivison__c> divisonList = [SELECT Id,Name, DeliveryDate__c, Quantity__c, OrderItem__c, ExternalId__c, SapNumber__c FROM ShippingDivison__c WHERE OrderItem__c IN: orderItemIds];
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
                        scheduleList.add(new CalloutOrderDatalake.ScheduleParameters(orderItem, sd));
                    }
                }
                orderItemList.add(new CalloutOrderDatalake.OrderItemParameters(orderItem, shippingCodesList));
                //System.debug('order' + orders);
            }

            for(OrderCommodity__c orderCommodity : commoditiesList){
                commodityList.add(new CalloutOrderDatalake.OrderCommoditiesParameters(orderCommodity));
            }
            System.debug('order ' + order.CodigoSap__c);
            if(order.CodigoSap__c == null){
            
                CalloutOrderDatalake.HeaderInsert header = new CalloutOrderDatalake.HeaderInsert();
                
                
                //Campos Lookups 
                header.shippingAccount = order.ShippingAccount__r.ExternalId__c; // Já está adicionado na query
                header.acmContract = order.ACMContract__c;
                header.paymentAccount = order.Account.ExternalId__c;  // Já está adicionado na query
                header.crop = order.Crop__r.Code__c;  // Já está adicionado na query
                header.cropName = order.Crop__r.Name; // Já está adicionado na query
                header.culture = order.Culture__r.Codigo__c; // Já está adicionado na query
                header.cultureName = order.Culture__r.Name; // Já está adicionado na query
                header.salesOrg = order.SalesOrg__r.SalesOrganizationCode__c; // Já está adicionado na query
                header.salesOrgName = order.SalesOrg__r.Name; // Já está adicionado na query
                
                header.salesCTV = order.SalesCTV__r.CodigoSap__c; // Já está adicionado na query
                header.paymentCondition = order.PaymentCondition__r.Code__c; // Já está adicionado na query
                header.distributionChannel = order.DistributionChannel__r.Codigo__c; // Já está adicionado na query
                header.activitySector = order.ActivitySector__r.Codigo__c; // Já está adicionado na query
                header.salesCondition = order.SalesCondition__r.ExternalId__c; // Já está adicionado na query
                header.company = order.Company__r.ExternalID__c; // Já está adicionado na query
				header.statusDesc = statusDesc.get(order.Status);
                header.orderCodeSf = order.OrderNumber;
                header.salesConditionName = order.SalesCondition__r.Name;
                
                header.paymentFormName = orderPayment.get(order.PaymentForm__c);
                header.paymentConditionName = order.PaymentCondition__r.Name;
                header.centroFornecedor = order.CompanyReceiver__r.SupplierCenter__c == null ? order.Company__r.SupplierCenter__c : order.CompanyReceiver__r.SupplierCenter__c;
                header.escritorioVendas = order.Company__r.SalesOffice__r.Codigo__c;
                header.equipeVendas = order.Company__r.SalesTeam__r.ExternalId__c;

                header.codigoSap = order.CodigoSap__c;
                header.numeroPedidoApp = order.NumeroPedidoApp__c;
                //header.pricebook2 = order.Pricebook2Id;
                header.orderReference = order.OrderReference__r.CodigoSap__c;
                header.paymentDate = order.PaymentDate__c;
                header.effectiveDate = order.EffectiveDate;
                header.shippingDate = order.ShippingDate__c;
                header.status = order.Status;
                header.statusRecusa = order.StatusRecusa__c;
                header.type = order.Type;
                header.customerOrderNumber = order.CustomerOrderNumber__c;
                header.paymentForm = order.PaymentForm__c;
                header.statusSF = order.StatusSF__c;
                header.currencyOrder = order.Currency__c;
                header.incoterms = order.Incoterms__c;
                header.incoterms2 = order.Incoterms2__c;
                header.description  = order.Description;
                header.descriptionBillingSale  = order.DescriptionBillingSale__c;
                header.finalTotalValue  = order.FinalTotalValue__c;
                header.hectare  = order.Hectare__c;
                header.orderMargin = order.OrderMargin__c;
                header.orderType = order.OrderType__c;
                header.isOrderMother = order.IsOrderMother__c;
                header.orderMTO = order.MTO__c;
                header.orderMTODescription = orderMTODesc.get(order.MTO__c);
                header.recordType = Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosById().get(order.RecordTypeId).getName();

                header.orderItemList = orderItemList;
                header.scheduleList = scheduleList;
                header.commodityList = commodityList;
                this.header = header;

                

                system.debug('header' + header);
                system.debug('Order' + order);
                //orderDatalake.salesCTV = AccountId.ShippingAccount__c.SalesCTV__c; --> Verificar CTV
            }
            else {
                CalloutOrderDatalake.HeaderUpdate header = new CalloutOrderDatalake.HeaderUpdate();
                header.shippingAccount = order.ShippingAccount__r.ExternalId__c; // Já está adicionado na query
                header.acmContract = order.ACMContract__c;
                header.paymentAccount = order.Account.ExternalId__c;  // Já está adicionado na query
                header.crop = order.Crop__r.Code__c;  // Já está adicionado na query
                header.cropName = order.Crop__r.Name; // Já está adicionado na query
                header.culture = order.Culture__r.Codigo__c; // Já está adicionado na query
                header.cultureName = order.Culture__r.Name; // Já está adicionado na query
                header.salesOrg = order.SalesOrg__r.SalesOrganizationCode__c; // Já está adicionado na query
                header.salesOrgName = order.SalesOrg__r.Name; // Já está adicionado na query
                
                header.salesCTV = order.SalesCTV__r.CodigoSap__c; // Já está adicionado na query
                header.paymentCondition = order.PaymentCondition__r.Code__c; // Já está adicionado na query
                header.distributionChannel = order.DistributionChannel__r.Codigo__c; // Já está adicionado na query
                header.activitySector = order.ActivitySector__r.Codigo__c; // Já está adicionado na query
                header.salesCondition = order.SalesCondition__r.ExternalId__c; // Já está adicionado na query
                header.company = order.Company__r.ExternalID__c; // Já está adicionado na query
				header.statusDesc = statusDesc.get(order.Status);
                header.orderCodeSf = order.OrderNumber;
                header.salesConditionName = order.SalesCondition__r.Name;
                
                header.paymentFormName = orderPayment.get(order.PaymentForm__c);
                header.paymentConditionName = order.PaymentCondition__r.Name;
                header.centroFornecedor = order.CompanyReceiver__r.SupplierCenter__c == null ? order.Company__r.SupplierCenter__c : order.CompanyReceiver__r.SupplierCenter__c;
                header.escritorioVendas = order.Company__r.SalesOffice__r.Codigo__c;
                header.equipeVendas = order.Company__r.SalesTeam__r.ExternalId__c;

                header.codigoSap = order.CodigoSap__c;
                header.numeroPedidoApp = order.NumeroPedidoApp__c;
                //header.pricebook2 = order.Pricebook2Id;
                header.orderReference = order.OrderReference__r.CodigoSap__c;
                header.paymentDate = order.PaymentDate__c;
                header.effectiveDate = order.EffectiveDate;
                header.shippingDate = order.ShippingDate__c;
                header.status = order.Status;
                header.statusRecusa = order.StatusRecusa__c;
                header.type = order.Type;
                header.customerOrderNumber = order.CustomerOrderNumber__c;
                header.paymentForm = order.PaymentForm__c;
                header.statusSF = order.StatusSF__c;
                header.currencyOrder = order.Currency__c;
                header.incoterms = order.Incoterms__c;
                header.incoterms2 = order.Incoterms2__c;
                header.description  = order.Description;
                header.descriptionBillingSale  = order.DescriptionBillingSale__c;
                header.finalTotalValue  = order.FinalTotalValue__c;
                header.hectare  = order.Hectare__c;
                header.orderMargin = order.OrderMargin__c;
                header.orderType = order.OrderType__c;
                header.isOrderMother = order.IsOrderMother__c;
                header.orderMTO = order.MTO__c;
                header.orderMTODescription = orderMTODesc.get(order.MTO__c);
                header.recordType = Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosById().get(order.RecordTypeId).getName();

                header.orderItemList = orderItemList;
                header.scheduleList = scheduleList;
                header.commodityList = commodityList;
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
        public String orderCodeSf;
        public String acmContract;
        public String paymentConditionName;
        public String centroFornecedor;
        public String escritorioVendas;
        public String equipeVendas;
		public String statusDesc;
        public String salesConditionName;
        public String codigoSap; 
        public String numeroPedidoApp; 
        //public String pricebook2; 
        public String shippingAccount; 
        public String paymentAccount; 
        public String crop; 
        public String culture; 
        public String salesOrg; 
        public String salesCTV;
        public String cropName;
        public String cultureName; 
        public String salesOrgName; 
        public String paymentCondition; 
        public String orderReference; 
        public String distributionChannel; 
        public String activitySector; 
        public Date paymentDate; 
        public Date effectiveDate; 
        public Date shippingDate; 
        public String status; 
        public String statusRecusa; 
        public String type; 
        public String customerOrderNumber; 
        public String paymentForm; 
        public String paymentFormName;
        public String statusSF; 
        public String currencyOrder; 
        public String incoterms; 
        public String incoterms2; 
        public String description;  
        public String descriptionBillingSale;  
        public Decimal finalTotalValue;  
        public Decimal hectare;  
        public Decimal orderMargin; 
        public String orderType; 
        public String salesCondition; 
        public Boolean isOrderMother; 
        public String company; 
        public String recordType; 
        public String orderMTO;
        public String orderMTODescription;
        public List<CalloutOrderDatalake.ScheduleParameters> scheduleList;
        public List<CalloutOrderDatalake.OrderItemParameters> orderItemList;
        public List<CalloutOrderDatalake.OrderCommoditiesParameters> commodityList;
        public HeaderInsert(){}
    }

    public class HeaderUpdate{
        public String orderCodeSf;
        public String acmContract;
        public String paymentConditionName;
        public String centroFornecedor;
        public String escritorioVendas;
        public String equipeVendas;
		public String statusDesc;
        public String salesConditionName;
        public String codigoSap; 
        public String numeroPedidoApp; 
        //public String pricebook2; 
        public String shippingAccount; 
        public String paymentAccount; 
        public String crop; 
        public String culture; 
        public String salesOrg; 
        public String salesCTV;
        public String cropName;
        public String cultureName; 
        public String salesOrgName; 
        public String paymentCondition; 
        public String orderReference; 
        public String distributionChannel; 
        public String activitySector; 
        public Date paymentDate; 
        public Date effectiveDate; 
        public Date shippingDate; 
        public String status; 
        public String statusRecusa; 
        public String type; 
        public String customerOrderNumber; 
        public String paymentForm; 
        public String paymentFormName;
        public String statusSF; 
        public String currencyOrder; 
        public String incoterms; 
        public String incoterms2; 
        public String description;  
        public String descriptionBillingSale;  
        public Decimal finalTotalValue;  
        public Decimal hectare;  
        public Decimal orderMargin; 
        public String orderType; 
        public String salesCondition; 
        public Boolean isOrderMother; 
        public String company; 
        public String recordType; 
        public String orderMTO;
        public String orderMTODescription;

        public List<CalloutOrderDatalake.ScheduleParameters> scheduleList;
        public List<CalloutOrderDatalake.OrderItemParameters> orderItemList;
        public List<CalloutOrderDatalake.OrderCommoditiesParameters> commodityList;

        //public OrderUpdate(){}
    }

    public class ScheduleParameters{
        public String orderItemCode;
        public String orderItem;
        public String material;
        public String divisaoRemessa;
        //public String numeroDivisaoRemessa;
        public Date deliveryDate;
        public Decimal quantityItem;
        public String shippingExternalId;
        public ScheduleParameters(OrderItem orderItem, ShippingDivison__c shippingDivision){
            this.orderItemCode = orderItem.NumeroSap__c; 
            this.material = orderItem.Product2.ExternalId__c;
            this.orderItem = orderItem.ExternalId__c;
            this.divisaoRemessa = shippingDivision.SapNumber__c;
            this.shippingExternalId = shippingDivision.ExternalId__c; 
            this.quantityItem = shippingDivision.Quantity__c; // Quantity__c
            this.deliveryDate = shippingDivision.DeliveryDate__c; // DeliveryDate__c
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

    public class OrderCommoditiesParameters{
        public String commodityName;
        public String material;
        public Decimal commodityPrice;
        public Decimal bagQuantity;
        public Decimal bagMargin;
        public Date startDate;
        public Date endDate;
        public String deliveryAddress;

        public OrderCommoditiesParameters(OrderCommodity__c orderCommodity){
            this.commodityName = orderCommodity.Name;
            this.material = orderCommodity.Product__r.ProductCode;
            this.commodityPrice = orderCommodity.CommodityPrice__c;
            this.bagQuantity = orderCommodity.BagQuantity__c;
            this.bagMargin = orderCommodity.BagMargin__c;
            this.startDate = orderCommodity.StartDate__c;
            this.endDate = orderCommodity.EndDate__c;
            this.deliveryAddress = orderCommodity.DeliveryAddress__c;
        }
    }

    public class OrderItemParameters{
        public String orderId;
        public String material;
        //public String pricebookEntryId;
        //public String orderExternalId;
        public Decimal quantityItem;
        public String unitMeasure;
        public Decimal percentComission;
        public Decimal discountPercent;
        public Decimal comissionValue;
        public Decimal commercialMargin;
        public Decimal discountValue;
        public Decimal finalTotalValue;
        public Decimal financialDiscountPercent;
        public Decimal financialDiscountValue;
        public Decimal financialAdditionPercent;
        public Decimal financialAdditionValue;
        public Decimal commercialAdditionPercent;
        public Decimal commercialAdditionValue;
        public Decimal dosage;
        public Decimal listCost;
        public String orderItemCode; //Numero SAP
        public Decimal practicedCost;
        public Decimal practicedPrice;
        public Decimal unitPrice;
        public String motivoRecusa;
        public String descMotivoRecusa;
        public Decimal quantidadeUtilizada;
        public Decimal saldoItem;



        public OrderItemParameters(OrderItem orderItem, List<Integer> shippingDivison){
            Map<String, String> motivoRecusa = new Map<String, String>();
            Schema.DescribeFieldResult mtrecusaFieldDescribe = Schema.OrderItem.ReasonRefuse__c.getDescribe();
            List<Schema.PicklistEntry> motivoRecusaPickListValues = mtrecusaFieldDescribe.getPickListValues();
            for(Schema.PicklistEntry mtrPickList : motivoRecusaPickListValues){
                motivoRecusa.put(mtrPickList.getValue(), mtrPickList.getLabel());
            }
            this.orderId = orderItem.OrderId;
            this.material = orderItem.Product2.ExternalId__c;
            //this.orderExternalId = orderItem.ExternalId__c;
            this.quantityItem = orderItem.Quantity;
            this.unitMeasure = orderItem.UnitMeasure__c;
            this.percentComission = orderItem.PercentComission__c;
            this.discountPercent = orderItem.DiscountPercent__c;
            this.comissionValue = orderItem.ComissionValue__c;
            this.commercialMargin = orderItem.CommercialMargin__c;
            this.discountValue = orderItem.DiscountValue__c;
            this.finalTotalValue = orderItem.FinalTotalValue__c;
            this.financialDiscountPercent = orderItem.FinancialDiscountPercent__c;
            this.financialDiscountValue = orderItem.FinancialDiscountValue__c;
            this.financialAdditionPercent = orderItem.FinancialAdditionPercent__c;
            this.financialAdditionValue = orderItem.FinancialAdditionValue__c;
            this.commercialAdditionPercent = orderItem.CommercialAdditionPercent__c;
            this.commercialAdditionValue = orderItem.CommercialAdditionValue__c;
            this.dosage = orderItem.Dosage__c;
            this.listCost = orderItem.ListCost__c;
            this.orderItemCode = orderItem.NumeroSap__c;
            this.practicedCost = orderItem.PracticedCost__c;
            this.practicedPrice = orderItem.PracticedPrice__c;
            this.unitPrice = orderItem.UnitPrice;
            this.motivoRecusa = orderItem.ReasonRefuse__c;
            this.descMotivoRecusa = motivoRecusa.get(orderItem.ReasonRefuse__c);
            this.quantidadeUtilizada = orderItem.AmountUsed__c;
            this.saldoItem = orderItem.ItemBalance__c;
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
        Integration__c data = Integration__c.getInstance('Pedidos OUT');
        String payloadToken = 'grant_type=client_credentials';
        String endpointToken = (!Test.isRunningTest() ? data.UrlToken__c : 'http://callout.My_Named_Credential.com/some/path');
        Map<String, String> headersMapToken = new Map<String, String>();
        headersMapToken.put('Content-type', 'application/x-www-form-urlencoded');
        headersMapToken.put('Authorization', !Test.isRunningTest() ? data.Token__c : 'testeToken');
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