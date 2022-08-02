global with sharing class IntegrationINOrderItem {
    public IntegrationINOrderItem() {
    }
    // Integração do OrderItem Upsert
    //@HttpPost 
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertOrderItem(List<TemplateDataIntegrationFields.OrderItemINData> request, List<TemplateDataIntegrationFields.ConditionInsert> conditionList) {
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
        for(TemplateDataIntegrationFields.OrderItemINData OrderItemINData : request) {
            // Pega a relação do OrderItem com Order
            //Getting order parameters to search


            orderLookups.add(OrderItemINData.orderExternalId);
            // Pega a relação do Product com o OrderItem
            //Getting product parameters to search
            productLookups.add(OrderItemINData.material);

            idsOrderItem.add(OrderItemINData.orderExternalId + '|' + OrderItemINData.orderItemCode);
            for(TemplateDataIntegrationFields.ConditionInsert  conditions : conditionList){
                conditions.KPOSN = conditions.KPOSN.replaceFirst('^0+','');
                if(conditions.KPOSN == OrderItemINData.orderItemCode){

                    if(conditions.KSCHL == 'ZPR0'){
                        OrderItemINData.precoUnitario = (Decimal.valueOf(conditions.KBETR) / Decimal.valueOf(conditions.KPEIN));
                       //OrderItemINData.multiplicador == conditions.KPEIN;
                    }
                    
                    if(conditions.KSCHL == 'ZDAC'){ //Antigo ZDAN
                        System.debug('conditions.KSCHL' + conditions.KSCHL);
                       OrderItemINData.porcentagemDescontoFin = Decimal.valueOf(conditions.KBETR);
                        System.debug('porcentagemDescontoFin' + OrderItemINData.porcentagemDescontoFin);
                    }
                    if(conditions.KSCHL == 'ZJUC'){ //Antigo ZJUR
                        OrderItemINData.porcentagemAcrescFin = Decimal.valueOf(conditions.KBETR);

                    }
                    if(conditions.KSCHL == 'ZMAR'){
                        OrderItemINData.margemComercial = Decimal.valueOf(conditions.KBETR);
                    }

                    if(conditions.KSCHL == 'ZCP0'){
                        OrderItemINData.custoPreco = Decimal.valueOf(conditions.KBETR);
                    }

                    if(conditions.KSCHL == 'ZDEC'){
                        
                        OrderItemINData.porcentagemAcrescComercial = 0;
                        OrderItemINData.porcentagemDesconto = 0;
                        
                        
                        System.debug('KBETR ' + Decimal.valueOf(conditions.KBETR));
                        if(Decimal.valueOf(conditions.KBETR) > 0){
                            OrderItemINData.porcentagemAcrescComercial = Decimal.valueOf(conditions.KBETR);
                            System.debug('porcentagemAcrescComercial ' + OrderItemINData.porcentagemAcrescComercial);

                        }
                        else {
                            OrderItemINData.porcentagemDesconto = Decimal.valueOf(conditions.KBETR);
                            OrderItemINData.porcentagemDesconto *= (-1);
                            System.debug('porcentagemDesconto ' + OrderItemINData.porcentagemDesconto);
                        }
                    }   
            }
        }
                    
                    //Decimal porcentagemDescontoFinanceiro = 0;
                    Decimal valorDescontoFinanceiro = 0;
            
                    //Decimal porcentagemAcrescimoFinanceiro = 0; 
                    Decimal valorAcrescimoFinanceiro = 0;
            
                    //Decimal porcentagemDescontoComercial = 0;
                    Decimal valorDescontoComercial = 0; 
                    
                    //Decimal porcentagemAcrescimoComercial = 0;
                    Decimal valorAcrescimoComercial = 0;
                    
                    Decimal valorFinal = OrderItemINData.precoUnitario * OrderItemINData.quantidade;
                    
                    if(OrderItemINData.porcentagemDescontoFin > 0){
                        //porcentagemDescontoFinanceiro = OrderItemINData.precoUnitario * (OrderItemINData.porcentagemDescontoFin / 100);
                        valorDescontoFinanceiro = valorFinal * (OrderItemINData.porcentagemDescontoFin / 100);
                        OrderItemINData.valorDescontoFin = valorDescontoFinanceiro;
                        valorFinal = valorFinal - valorDescontoFinanceiro; //Bateu
                        OrderItemINData.precoPraticado = (valorFinal) / OrderItemINData.quantidade;
                        OrderItemINData.valorTotal = valorFinal;
                        System.debug('valorFinal ' + valorFinal);
                        System.debug('valorDescontoFinanceiro ' + valorDescontoFinanceiro);
                    }
                    if (OrderItemINData.porcentagemAcrescFin > 0){
                        //porcentagemAcrescimoFinanceiro = OrderItemINData.precoUnitario * (OrderItemINData.porcentagemAcrescFin / 100);
                        
                        valorAcrescimoFinanceiro = valorFinal * (OrderItemINData.porcentagemAcrescFin / 100);     
                        OrderItemINData.valorAcrescFin = valorAcrescimoFinanceiro;
                        valorFinal = valorFinal + valorAcrescimoFinanceiro;
                        OrderItemINData.precoPraticado = (valorFinal) / OrderItemINData.quantidade;
                        OrderItemINData.valorTotal = valorFinal;
                        System.debug('valorFinal ' + valorFinal);
                        System.debug('valorAcrescimoFinanceiro ' + valorAcrescimoFinanceiro);
                    }
                    if (OrderItemINData.porcentagemDesconto != 0 && OrderItemINData.porcentagemDesconto != null){ 
                        //porcentagemDescontoComercial = OrderItemINData.precoUnitario * (OrderItemINData.porcentagemDesconto / 100);
                        valorDescontoComercial = valorFinal  * (OrderItemINData.porcentagemDesconto / 100);
                        System.debug('porcentagemDesconto ' + (OrderItemINData.porcentagemDesconto / 100));
                        System.debug('valorDescontoComercial ' + valorDescontoComercial);
                        OrderItemINData.precoPraticado = (valorFinal - valorDescontoComercial) / OrderItemINData.quantidade;
                        OrderItemINData.valorTotal = (valorFinal - valorDescontoComercial);
                        System.debug('valorFinalFinal  ' + OrderItemINData.valorTotal);
                        OrderItemINData.descontoValor = valorDescontoComercial;
                    }
                    if(OrderItemINData.porcentagemAcrescComercial != 0 && OrderItemINData.porcentagemAcrescComercial != null){
                        //porcentagemAcrescimoComercial = OrderItemINData.precoUnitario * (OrderItemINData.porcentagemAcrescComercial / 100);
                        valorAcrescimoComercial = valorFinal * (OrderItemINData.porcentagemAcrescComercial / 100);
                        System.debug('valorAcrescimoComercial ' + valorAcrescimoComercial);
                        
                        OrderItemINData.precoPraticado = (valorFinal + valorAcrescimoComercial) / OrderItemINData.quantidade;
                        OrderItemINData.valorTotal = (valorFinal + valorAcrescimoComercial);
                        OrderItemINData.valorAcrescComercial = valorAcrescimoComercial;
                        //System.debug('porcentagemDesconto ' + OrderItemINData.porcentagemDesconto);
                    }
                                        
                    System.debug('Valor Final   ' + valorFinal);
                    System.debug('valorAcrescComercial  ' + OrderItemINData.valorAcrescComercial);
                    
                    System.debug('Desconto Valor ' + OrderItemINData.descontoValor);
                    System.debug('Preço Praticado ' + OrderItemINData.precoPraticado);
                    
        }

        

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
        System.debug('orderItemsIdsMap ' + orderItemsIdsMap);
        for (TemplateDataIntegrationFields.OrderItemINData orderItem : request){
            OrderItem ordItem = orderItemsIdsMap.get(orderItem.orderExternalId + '|' + orderItem.orderItemCode);
            if(ordItem != null){
                System.debug('OrderItem ' + ordItem);
                System.debug('orderExternalId ' + orderItem.orderExternalId);
    
                System.debug('orderItem.orderExternalId '+ orderItem.orderExternalId);
                
                if(orderItem.orderExternalId == null){
                    System.debug('ordItem.OrderId '+ ordItem.OrderId);
                    if(ordItem.OrderId != null){
                        orderItem.orderExternalId = ordItem.OrderId; 
                        lookups.put('Order' + ordItem.Order.CodigoSap__c, ordItem.OrderId);
                        System.debug('lookups ' + lookups);
                    }
                }
                
                if(orderItem.material == null){
                    if(ordItem.Product2Id != null){
                        orderItem.material = ordItem.Product2.ProductCode__c;
                        lookups.put('PricebookEntry' + ordItem.Product2.ProductCode__c, ordItem.Product2Id);
                    } 
                }
                
    
                if(orderItem.material == null){
                    if(ordItem.Product2Id != null){
                        orderItem.material = ordItem.Product2.ProductCode__c;
                        lookups.put('Product2' + ordItem.Product2.ProductCode__c, ordItem.Product2Id);
                    } 
                }
                                  
                
                if(orderItem.quantidade == null){
                    orderItem.quantidade = ordItem.Quantity;
                }
    
                if(orderItem.unidadeMedida == null){
                    orderItem.unidadeMedida = ordItem.UnitMeasure__c;
                }
    
                if(orderItem.porcentagemComissao == null){
                    orderItem.porcentagemComissao = ordItem.PercentComission__c;
                }
    
                if(orderItem.porcentagemDesconto == null){
                    orderItem.porcentagemDesconto = ordItem.DiscountPercent__c;
                }
    
                if(orderItem.comissaoValor == null){
                    orderItem.comissaoValor = ordItem.ComissionValue__c;
                }
    
                if(orderItem.margemComercial == null){
                    orderItem.margemComercial = ordItem.CommercialMargin__c;
                }
    
                if(orderItem.descontoValor == null){
                    orderItem.descontoValor = ordItem.DiscountValue__c;
                }
    
                if(orderItem.valorTotal == null){
                    orderItem.valorTotal = ordItem.FinalTotalValue__c;
                }
    
                if(orderItem.porcentagemDescontoFin == null){
                    orderItem.porcentagemDescontoFin = ordItem.FinancialDiscountPercent__c;
                }
    
                if(orderItem.valorDescontoFin == null){
                    orderItem.valorDescontoFin = ordItem.FinancialDiscountValue__c;
                }
    
                if(orderItem.porcentagemAcrescFin == null){
                    orderItem.porcentagemAcrescFin = ordItem.FinancialAdditionPercent__c;
                }
    
                if(orderItem.valorAcrescFin == null){
                    orderItem.valorAcrescFin = ordItem.FinancialAdditionValue__c;
                }
    
                if(orderItem.porcentagemAcrescComercial == null){
                    orderItem.porcentagemAcrescComercial = ordItem.CommercialAdditionPercent__c;
                }
    
                if(orderItem.valorAcrescComercial == null){
                   orderItem.valorAcrescComercial = ordItem.CommercialAdditionValue__c;
                }
    
                if(orderItem.dosagem == null){
                   orderItem.dosagem = ordItem.Dosage__c;
                }
    
                if(orderItem.custoLista == null){
                    orderItem.custoLista = ordItem.ListCost__c;
                }
    
                if(orderItem.orderItemCode == null){
                   orderItem.orderItemCode = ordItem.NumeroSap__c;
                }
    
                if(orderItem.custoPreco == null){
                    orderItem.custoPreco = ordItem.PracticedCost__c;
                }
    
                if(orderItem.precoPraticado == null){
                    orderItem.precoPraticado = ordItem.PracticedPrice__c;
                }
    
                if(orderItem.precoUnitario == null){
                    orderItem.precoUnitario = ordItem.UnitPrice;
                }  
            }
        }
        // Pega o produto com base no ExternalID recebido
        //Product2 search based on ExternalId__c field sent
        for (Product2 product : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: productLookups ]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Product2' + product.ProductCode, product.Id);
        }
        // Pega o pedido com base no ExternalId recebido
        //Order search based on ExternalId__c field sent
        for (Order order : [SELECT Id, NumeroPedidoApp__c FROM Order WHERE NumeroPedidoApp__c IN : orderLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Order' + order.NumeroPedidoApp__c, order.Id);
        }
        
        for (PricebookEntry pricebookEntry : [SELECT Id, Product2Id, productCode, Pricebook2.isStandard FROM PricebookEntry ]){
            lookups.put('PricebookEntry' + pricebookEntry.productCode, pricebookEntry.Id);
        }
        
        // Associa as respostas do OrderItem com Order
        //OrderItem ExternalId Map to Order ExternalId for association of responses
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.OrderItemINData orderItem : request) {
            // como estava = parentMapKeys.put(ORDEREXTERNALID + '|' + ORDERITEMEXTERNALID, lookups.containsKey('Order'+ORDEREXTERNALID) ? lookups.get('Order'+ORDEREXTERNALID) : ORDEREXTERNALID);
            parentMapKeys.put(orderItem.orderExternalId + '|' + orderItem.orderItemCode, lookups.containsKey('Order'+orderItem.orderExternalId) ? String.valueOf(lookups.get('Order'+orderItem.orderExternalId)) : orderItem.orderExternalId);
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
        System.debug('orderItemListToUpsert ' + orderItemListToUpsert);

        //Upserting records
        List<Database.UpsertResult> upsResults = Database.upsert(orderItemListToUpsert, OrderItem.ExternalId__c, false);
        IntegrationUtils.upsertChildRecords(upsResults, responseMap, orderItemListToUpsert, OrderItem.ExternalId__c); 
        
        //Returning response
        return responseMap;
    }
}