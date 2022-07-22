global without sharing class IntegrationINOrderItemAppdigital {
    public IntegrationINOrderItemAppdigital() {

    }
    // Integração do OrderItem Upsert
    //@HttpPost 
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertOrderItem(List<TemplateDataIntegrationFields.OrderItemINData> request) {
        // Guarda as relações de order e product de preço com OrderItem
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> orderLookups = new Set<String>();
        Set<String> productLookups = new Set<String>();
        // Guarda um mapa com uma lista de respostas
        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        // Guarda uma lista com os OrderItem para fazer o upsert
        List<OrderItem> orderItemListToUpsert = new List<OrderItem>();

        List<String> idsOrderItem = new List<String>();
        //Application of business rules
        for(TemplateDataIntegrationFields.OrderItemINData OrderItemINData : request){

            // Pega a relação do OrderItem com Order
            //Getting order parameters to search
            orderLookups.add(OrderItemINData.orderExternalId);

            // Pega a relação do Product com o OrderItem
            //Getting product parameters to search
            productLookups.add(OrderItemINData.material);
            
            idsOrderItem.add(OrderItemINData.orderExternalId + '|' + OrderItemINData.orderItemCode);
        }
        // Pega o produto com base no ExternalID recebido
        //Product2 search based on ExternalId__c field sent

        Map<String, OrderItem> orderItemsIdsMap = new Map<String, OrderItem>();
        List<OrderItem> orderItemSelectList = new List<OrderItem>([SELECT Id, Order.CodigoSap__c, Product2.ProductCode__c, Product2Id, OrderId,
        Quantity, UnitMeasure__c, PercentComission__c, DiscountPercent__c, ComissionValue__c,
        CommercialMargin__c, DiscountValue__c, ExternalId__c, FinalTotalValue__c, FinancialDiscountPercent__c,
        FinancialDiscountValue__c, FinancialAdditionPercent__c, FinancialAdditionValue__c,
        CommercialAdditionPercent__c, CommercialAdditionValue__c, Dosage__c, ListCost__c, NumeroSap__c,
        PracticedCost__c, PracticedPrice__c, UnitPrice FROM OrderItem WHERE ExternalId__c IN: idsOrderItem]);
        
        for(OrderItem ordItem : orderItemSelectList){
            orderItemsIdsMap.put(ordItem.ExternalId__c, ordItem);
            
        }
        for (TemplateDataIntegrationFields.OrderItemINData orderItem : request){
            if(orderItem.orderItemECalendariazacao == true){
            OrderItem ordItem = orderItemsIdsMap.get(orderItem.orderExternalId + '|' + orderItem.orderItemCode);
  
           if(orderItem.orderExternalId == null){
                
               if(ordItem.OrderId != null){
                    orderItem.orderExternalId = ordItem.OrderId; 
                    lookups.put('Order' + ordItem.Order.CodigoSap__c, ordItem.OrderId);
               }
            }
            
            if(orderItem.material == null || orderItem.orderItemECalendariazacao == true){

                if(ordItem.Product2Id != null){
                    orderItem.material = ordItem.Product2.ProductCode__c;
                    lookups.put('PricebookEntry' + ordItem.Product2.ProductCode__c, ordItem.Product2Id);
                } 
            }
            
            if(orderItem.material == null || orderItem.orderItemECalendariazacao == true){
                if(ordItem.Product2Id != null){
                    orderItem.material = ordItem.Product2.ProductCode__c;
                    lookups.put('Product2' + ordItem.Product2.ProductCode__c, ordItem.Product2Id);
                } 
            }
                                    
            if(orderItem.quantidade == null || orderItem.orderItemECalendariazacao == true){
                orderItem.quantidade = ordItem.Quantity;
            }

            if(orderItem.unidadeMedida == null || orderItem.orderItemECalendariazacao == true){
                orderItem.unidadeMedida = ordItem.UnitMeasure__c;
            }

            if(orderItem.porcentagemComissao == null || orderItem.orderItemECalendariazacao == true){
                orderItem.porcentagemComissao = ordItem.PercentComission__c;
            }

            if(orderItem.porcentagemDesconto == null || orderItem.orderItemECalendariazacao == true){
                orderItem.porcentagemDesconto = ordItem.DiscountPercent__c;
            }

            if(orderItem.comissaoValor == null || orderItem.orderItemECalendariazacao == true){
                orderItem.comissaoValor = ordItem.ComissionValue__c;
            }

            if(orderItem.margemComercial == null || orderItem.orderItemECalendariazacao == true){
                orderItem.margemComercial = ordItem.CommercialMargin__c;
            }

            if(orderItem.descontoValor == null || orderItem.orderItemECalendariazacao == true){
                orderItem.descontoValor = ordItem.DiscountValue__c;
            }

            if(orderItem.valorTotal == null || orderItem.orderItemECalendariazacao == true){
                orderItem.valorTotal = ordItem.FinalTotalValue__c;
            }

            if(orderItem.porcentagemDescontoFin == null || orderItem.orderItemECalendariazacao == true){
                orderItem.porcentagemDescontoFin = ordItem.FinancialDiscountPercent__c;
            }

            if(orderItem.valorDescontoFin == null || orderItem.orderItemECalendariazacao == true){
                orderItem.valorDescontoFin = ordItem.FinancialDiscountValue__c;
            }

            if(orderItem.porcentagemAcrescFin == null || orderItem.orderItemECalendariazacao == true){
                orderItem.porcentagemAcrescFin = ordItem.FinancialAdditionPercent__c;
            }

            if(orderItem.valorAcrescFin == null || orderItem.orderItemECalendariazacao == true){
                orderItem.valorAcrescFin = ordItem.FinancialAdditionValue__c;
            }

            if(orderItem.porcentagemAcrescComercial == null || orderItem.orderItemECalendariazacao == true){
                orderItem.porcentagemAcrescComercial = ordItem.CommercialAdditionPercent__c;
            }

            if(orderItem.valorAcrescComercial == null || orderItem.orderItemECalendariazacao == true){
               orderItem.valorAcrescComercial = ordItem.CommercialAdditionValue__c;
            }

            if(orderItem.dosagem == null || orderItem.orderItemECalendariazacao == true){
               orderItem.dosagem = ordItem.Dosage__c;
            }

            if(orderItem.custoLista == null || orderItem.orderItemECalendariazacao == true){
                orderItem.custoLista = ordItem.ListCost__c;
            }

            if(orderItem.orderItemCode == null || orderItem.orderItemECalendariazacao == true){
               orderItem.orderItemCode = ordItem.NumeroSap__c;
            }

            if(orderItem.custoPreco == null || orderItem.orderItemECalendariazacao == true){
                orderItem.custoPreco = ordItem.PracticedCost__c;
            }

            if(orderItem.precoPraticado == null || orderItem.orderItemECalendariazacao == true){
                orderItem.precoPraticado = ordItem.PracticedPrice__c;
            }

            if(orderItem.precoUnitario == null || orderItem.orderItemECalendariazacao == true){
                orderItem.precoUnitario = ordItem.UnitPrice;
            }
        }

        }
        for (Product2 product : [SELECT Id,ProductCode FROM Product2 WHERE ProductCode IN: productLookups ]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Product2' + product.ProductCode, product.Id);
        }
        // Pega o pedido com base no ExternalId recebido
        //Order search based on ExternalId__c field sent
        for (Order order : [SELECT Id, NumeroPedidoApp__c FROM Order WHERE NumeroPedidoApp__c IN : orderLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Order' + order.NumeroPedidoApp__c, order.Id);
        }

        for (Order order : [SELECT Id, CodigoSap__c FROM Order WHERE CodigoSap__c IN : orderLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Order' + order.CodigoSap__c, order.Id);
        }
       
        for (PricebookEntry pricebookEntry : [SELECT Id, Product2Id, ProductCode, Pricebook2.isStandard FROM PricebookEntry ]){
            lookups.put('Product2' + pricebookEntry.ProductCode, pricebookEntry.Product2Id);
            lookups.put('PricebookEntry' + pricebookEntry.ProductCode, pricebookEntry.Id); //Arrumar, puxar o productCode
        }
        
        // Associa as respostas do OrderItem com Order
        //OrderItem ExternalId Map to Order ExternalId for association of responses
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.OrderItemINData orderItem : request) {
            // como estava = parentMapKeys.put(ORDEREXTERNALID + '|' + ORDERITEMEXTERNALID, lookups.containsKey('Order'+ORDEREXTERNALID) ? lookups.get('Order'+ORDEREXTERNALID) : ORDEREXTERNALID);
            parentMapKeys.put(orderItem.orderExternalId + '|' + orderItem.orderItemCode, lookups.containsKey('Order'+orderItem.orderExternalId) ? String.valueOf(lookups.get('Order'+orderItem.orderExternalId)) : orderItem.orderExternalId);
            System.debug('orderItem.orderExternalId ' + orderItem.orderExternalId);
        }
        
        // Valida e adiciona os OrderItem na lista para o upsert
        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObjectChild(
            new OrderItem(), 
            'IN', 
            request, 
            responseMap, 
            orderItemListToUpsert, 
            lookups, 
            parentMapKeys
        );

        //Upserting records
        List<Database.UpsertResult> upsResults = Database.upsert(orderItemListToUpsert, OrderItem.ExternalId__c, false);

        IntegrationUtils.upsertChildRecords(upsResults, responseMap, orderItemListToUpsert, OrderItem.ExternalId__c); 
        System.debug('upsResults' + upsResults);
        System.debug('orderItemListToUpsert' + orderItemListToUpsert);
        System.debug(' OrderItem.ExternalId__c' +  OrderItem.ExternalId__c);
        //Returning response
        return responseMap;
    }
}
