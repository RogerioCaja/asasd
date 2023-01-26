global without sharing class IntegrationINOrderItem {
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

        List<String> product2Ids = new List<String>();

        Decimal porcentagemZCBI = 0;
        Decimal porcentagemZCBA = 0;

        //Application of business rules
        for(TemplateDataIntegrationFields.OrderItemINData OrderItemINData : request) {
            // Pega a relação do OrderItem com Order
            //Getting order parameters to search


            orderLookups.add(OrderItemINData.orderExternalId);
            // Pega a relação do Product com o OrderItem
            //Getting product parameters to search
            productLookups.add(OrderItemINData.material);

            if(OrderItemINData.material != null){
                product2Ids.add(OrderItemINData.material);
            }

            idsOrderItem.add(OrderItemINData.orderExternalId + '|' + OrderItemINData.orderItemCode);


            for(TemplateDataIntegrationFields.ConditionInsert  conditions : conditionList){
                conditions.KPOSN = conditions.KPOSN.replaceFirst('^0+','');
                if(conditions.KPOSN == OrderItemINData.orderItemCode){

                    if(conditions.KSCHL == 'ZPR0'){
                        OrderItemINData.precoUnitario = (Decimal.valueOf(conditions.KBETR) / Decimal.valueOf(conditions.KPEIN));
                        OrderItemINData.precoPraticado = OrderItemINData.precoUnitario;
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

                    if(conditions.KSCHL == 'ZFRE'){
                        OrderItemInData.freteItem = Decimal.valueOf(conditions.KBETR);
                    }

                    if(conditions.KSCHL == 'ZROY'){
                        OrderItemInData.valorZroy = Decimal.valueOf(conditions.KBETR);
                        OrderItemInData.valorTotalZroy = Decimal.valueOf(conditions.KBETR) * OrderItemInData.quantidade;
                    }

                    if(conditions.KSCHL == 'ZTRA'){
                        OrderItemInData.valorZtra = Decimal.valueOf(conditions.KBETR);
                        OrderItemINData.valorTotalZtra = Decimal.valueOf(conditions.KBETR) * OrderItemINData.quantidade;
                    }

                    if(conditions.KSCHL == 'ZCP0'){
                        Decimal custoPraticado = Decimal.valueOf(conditions.KBETR) / OrderItemINData.quantidade;
                        OrderItemINData.custoPreco = custoPraticado;
                    }

                    if(conditions.KSCHL == 'ZCBI'){
                        if(Decimal.valueOf(conditions.KBETR) > 0){
                            porcentagemZCBI = Decimal.valueOf(conditions.KBETR);
                        }
                        else {
                            porcentagemZCBI = Decimal.valueOf(conditions.KBETR) * (-1);
                        }
                        //OrderItemINData.valorZCBI = Decimal.valueOf(conditions.KBETR);
                        
                    }

                    if(conditions.KSCHL == 'ZCBA'){
                        if(Decimal.valueOf(conditions.KBETR) > 0){
                            porcentagemZCBA = Decimal.valueOf(conditions.KBETR); 
                        }
                        else {
                            porcentagemZCBA = Decimal.valueOf(conditions.KBETR) * (-1);
                        }
                        
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

                    Decimal valorDescontoComboZCBI = 0;

                    Decimal valorDescontoComboZCBA = 0;
                    
                    Decimal valorFinal = OrderItemINData.precoUnitario * OrderItemINData.quantidade;
                    OrderItemINData.valorTotal = valorFinal;
                    
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
                    if(porcentagemZCBI > 0){

                        valorDescontoComboZCBI = valorFinal * (porcentagemZCBI / 100);
                        OrderItemINData.valorZCBI = valorDescontoComboZCBI;
                        valorFinal = valorFinal - valorDescontoComboZCBI;
                        OrderItemINData.precoPraticado = (valorFinal) / OrderItemINData.quantidade;
                        OrderItemINData.valorTotal = valorFinal;
                    }

                    if(porcentagemZCBA > 0){
                        valorDescontoComboZCBA = valorFinal * (porcentagemZCBA / 100);
                        OrderItemINData.valorZCBA = valorDescontoComboZCBA;
                        valorFinal = valorFinal - valorDescontoComboZCBA;
                        OrderItemINData.precoPraticado = (valorFinal) / OrderItemINData.quantidade;
                        OrderItemINData.valorTotal = valorFinal;
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

                    porcentagemZCBA = 0;
                    porcentagemZCBI = 0;
                    
        }

        Map<String, PricebookEntry> pricebookEntryList = new Map<String, PricebookEntry>();

        for(PricebookEntry priceEntry : [SELECT 
        Product2Id, 
        Pricebook2Id,
        UnitPrice, 
        CurrencyIsoCode,
        Product2.ProductCode 
        FROM PricebookEntry 
        WHERE Pricebook2.IsStandard = true 
        AND Product2.ProductCode IN: product2Ids]){
            pricebookEntryList.put(priceEntry.Product2.ProductCode + String.valueOf(priceEntry.CurrencyIsoCode), priceEntry);
        }


        Map<String, OrderItem> orderItemsIdsMap = new Map<String, OrderItem>();
        List<OrderItem> orderItemSelectList = new List<OrderItem>([SELECT Id, Order.CodigoSap__c, Product2.ProductCode__c, Product2Id, OrderId,
        Quantity, UnitMeasure__c, PercentComission__c, DiscountPercent__c, ComissionValue__c,
        CommercialMargin__c, DiscountValue__c, ExternalId__c, FinalTotalValue__c, FinancialDiscountPercent__c,
        FinancialDiscountValue__c, FinancialAdditionPercent__c, FinancialAdditionValue__c,
        CommercialAdditionPercent__c, CommercialAdditionValue__c, Dosage__c, ListCost__c, NumeroSap__c,
        PracticedCost__c, PracticedPrice__c, UnitPrice, Sieve__c, Class__c, FreightValue__c, RoyaltyAmount__c, TSIValue__c, TotalRoyaltyAmount__c, TotalTSIAmount__c, PricebookEntryId, AmountUsed__c,AgrogalaxyComboDiscount__c,IndustryComboDiscount__c FROM OrderItem WHERE ExternalId__c IN: idsOrderItem]);
    
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
                
                //ordItem.Description += 'In73gr ins37t x';

                if(orderItem.orderExternalId == null || orderItem.orderExternalId == ''){
                    System.debug('ordItem.OrderId '+ ordItem.OrderId);
                    if(ordItem.OrderId != null){
                        orderItem.orderExternalId = ordItem.OrderId; 
                        lookups.put('Order' + ordItem.Order.CodigoSap__c, ordItem.OrderId);
                        System.debug('lookups ' + lookups);
                    }
                }
            
                
    
                if(orderItem.material == null || orderItem.material == ''){
                    if(ordItem.Product2Id != null){
                        orderItem.material = ordItem.Product2.ProductCode__c;
                        lookups.put('Product2' + ordItem.Product2.ProductCode__c, ordItem.Product2Id);
                    } 
                }
                                  
                
                if(orderItem.quantidade == null){
                    orderItem.quantidade = ordItem.Quantity;
                }
                
                if(orderItem.quantidadeUtilizada == null){
                    orderItem.quantidadeUtilizada = ordItem.AmountUsed__c;
                }

                if(orderItem.unidadeMedida == null || orderItem.unidadeMedida == ''){
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
    
                if(orderItem.orderItemCode == null || orderItem.orderItemCode == ''){
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

                if(orderItem.peneira == null || orderItem.peneira == ''){
                    orderItem.peneira = ordItem.Sieve__c;
                }

                if(orderItem.classeCategoria == null || orderItem.classeCategoria == ''){
                    orderItem.classeCategoria = ordItem.class__c;
                }

                if(orderItem.freteItem == null){
                    orderItem.freteItem = ordItem.FreightValue__c;
                }

                if(OrderItem.valorZroy == null){
                    orderItem.valorZroy = ordItem.RoyaltyAmount__c;
                }

                if(OrderItem.valorTotalZroy == null){
                    orderItem.valorTotalZroy = ordItem.TotalRoyaltyAmount__c;
                }

                if(OrderItem.valorZtra == null){
                    OrderItem.valorZtra = ordItem.TSIValue__c;
                }

                if(OrderItem.valorTotalZtra == null){
                    OrderItem.valorTotalZtra = ordItem.TotalTSIAmount__c;
                }

                if(OrderItem.pricebookEntryId == null || OrderItem.pricebookEntryId == ''){
                    OrderItem.pricebookEntryId = ordItem.PricebookEntryId;
                }

                if(OrderItem.valorZCBI == null){
                    OrderItem.valorZCBI = ordItem.IndustryComboDiscount__c;
                }

                if(OrderItem.valorZCBA == null){
                    OrderItem.valorZCBA = ordItem.AgrogalaxyComboDiscount__c;
                }

                if(OrderItem.saldoItem == null){
                    OrderItem.saldoItem = ordItem.ItemBalance__c;
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

            orderItem.pricebookEntryId = pricebookEntryList.get(orderItem.material + String.valueOf(orderItem.currencyOrder)).Id;
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
        for(OrderItem ordItemDesc : orderItemListToUpsert){
            ordItemDesc.Description += 'In73gr ins37t x';
        }
        System.debug('orderItemListToUpsert ' + orderItemListToUpsert);

        //Upserting records
        List<Database.UpsertResult> upsResults = Database.upsert(orderItemListToUpsert, OrderItem.ExternalId__c, false);
        IntegrationUtils.upsertChildRecords(upsResults, responseMap, orderItemListToUpsert, OrderItem.ExternalId__c); 
        
        //Returning response
        return responseMap;
    }
}