import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';

import CONDICAO_VENDA_OBJECT from '@salesforce/schema/SalesCondition__c';
import CONDICAO_VENDA_NAME from '@salesforce/schema/SalesCondition__c.Name';

import CTV_OBJECT from '@salesforce/schema/User';
import CTV_NAME from '@salesforce/schema/User.Name';

import ORG_VENDA_OBJECT from '@salesforce/schema/SalesOrg__c';
import ORG_VENDAS_NAME from '@salesforce/schema/SalesOrg__c.Name';

import CLIENTE_ENTREGA_OBJECT from '@salesforce/schema/Account';
import CLIENTE_ENTREGA_NAME from '@salesforce/schema/Account.Name';

import CLIENTE_FATURAMENTO_OBJECT from '@salesforce/schema/Account';
import CLIENTE_FATURAMENTO_NAME from '@salesforce/schema/Account.Name';
import COND_PAGAMENTO_OBJECT from '@salesforce/schema/CondicaoPagamento__c';
import COND_PAGAMENTO_NAME from '@salesforce/schema/CondicaoPagamento__c.Name';
import COND_PAGAMENTO_CASH from '@salesforce/schema/CondicaoPagamento__c.CashPayment__c';

import CULTURA_OBJECT from '@salesforce/schema/Cultura__c';
import CULTURA_NAME from '@salesforce/schema/Cultura__c.Name';

import SAFRA_OBJECT from '@salesforce/schema/Safra__c';
import SAFRA_NAME from '@salesforce/schema/Safra__c.Name';

import getAccountDataChild from '@salesforce/apex/OrderScreenController.getAccountDataChild';

import getDateLimit from '@salesforce/apex/OrderScreenController.getSafraInfos';

import getAccountCompanies from '@salesforce/apex/OrderScreenController.getAccountCompanies';

import isSeedSale from '@salesforce/apex/OrderScreenController.isSeedSale';


import getMTOTypes from '@salesforce/apex/OrderScreenController.getMTOTypes';
//import FILIAL_OBJECT from '@salesforce/schema/';
//import FILIAL_NAME from '@salesforce/schema/';

export default class OrderHeaderScreen extends LightningElement {
    readonly = false;
    booleanTrue = true;
    disabled = false;
    fieldKey = true;
    paymentDisabled = false;
    blockPaymentForm = false;
    barterSale = false;
    seedSale = false;
    safraName = null;
    currencyOption = null;
    hasDelimiter = true;
    currentDate;
    dateLimit;
    dateStartBilling;
    dateLimitBilling;
    showMto = false;

    @api accountData;
    @api accountChildData;

    @api childOrder;
    @api headerData;
    @api headerDictLocale ={
        Id: " ",
        AccountId: " ",
        tipo_venda: " ",
        filial: null,
        numero_pedido_cliente: " ",
        safra: {},
        cultura: {},
        condicao_venda: {},
        condicao_pagamento: null,
        data_pagamento: " ",
        data_entrega: " ",
        status_pedido: "Em digitação",
        cliente_faturamento: " ",
        cliente_entrega: " ",
        organizacao_vendas: {},
        canal_distribuicao: null,
        setor_atividade: null,
        forma_pagamento: " ",
        tipo_pedido: " ",
        moeda: " ",
        ctv_venda: " ",
        pedido_mae: null,
        pedido_mae_check : true,
        pre_pedido : false,
        frete: "CIF",
        org: {Name: " "},
        aprovation: null,
        IsOrderChild : false,
        isCompleted : false,
        companyId: null,
        companySector: null,
        companyFromDeliveredAccount: null,
        supplierCenterDeliveredAccount: null,
        hectares: '',
        freightPerUnit: null,
        motherTotalQuantity: null,
        firstTime: true,
        centerId: null,
        mto: null
    };

    @api salesOrgId;
    @api productData;
    @api divisionData;
    @api commodityData;
    @api cloneData;
    @api excludedItems;
    @api combosSelecteds;
    @api taxData;
    @api formsOfPayment
    @api bpData;

    @track pass = false;

    moedas = [{
        value: 'BRL',
        label: 'BRL (R$)',
        description: 'Real Brasileiro'
    }, {
        value: 'USD',
        label: 'USD (US$)',
        description: 'Dólar Americano'
    }];

    fretes = [{
        value: 'CIF',
        label: 'CIF',
        description: 'Frete'
    }, {
        value: 'FOB',
        label: 'FOB',
        description: 'Frete'
    }];

    tiposVenda = [{
            value: '0',
            label: 'Venda Amostra Grátis',
            description: ''
        },
        {
            value: '1',
            label: 'Venda Bonificação',
            description: ''
        },
        {
            value: '2',
            label: 'Venda Conta e Ordem',
            description: ''
        },
        {
            value: '3',
            label: 'Venda de Serviço',
            description: ''
        },
        {
            value: '4',
            label: 'Venda Barter',
            description: ''
        },
        {
            value: '5',
            label: 'Venda Entrega Futura',
            description: ''
        },
        {
            value: '6',
            label: 'Venda Normal',
            description: ''
        },
        {
            value: '7',
            label: 'Venda Ordem Simples Faturamento',
            description: ''
        },
        
    ];

    statusPedido = [{
            value: 'Em digitação',
            label: 'Em digitação',
            description: 'Em digitação',
        },
        {
            value: 'Em aprovação',
            label: 'Em aprovação',
            description: 'Em aprovação',
        },
        {
            value: 'Recusado',
            label: 'Recusado',
            description: 'Recusado',
        },
        {
            value: 'Em Aprovação - Comitê Margem',
            label: 'Em Aprovação - Comitê Margem',
            description: 'Em Aprovação - Comitê Margem',
        },
        {
            value: 'Em aprovação - Gerente Filial',
            label: 'Em aprovação - Gerente Filial',
            description: 'Em aprovação - Gerente Filial',
        },
        {
            value: 'Em Aprovação - Gerente Regional',
            label: 'Em Aprovação - Gerente Regional',
            description: 'Em Aprovação - Gerente Regional',
        },
        {
            value: 'Em Aprovação - Diretor',
            label: 'Em Aprovação - Diretor',
            description: 'Em Aprovação - Diretor',
        },
        {
            value: 'Em Aprovação - Diretor Torre',
            label: 'Em Aprovação - Diretor Torre',
            description: 'Em Aprovação - Diretor Torre',
        },
        {
            value: 'Em Aprovação - Mesa de Grãos',
            label: 'Em Aprovação - Mesa de Grãos',
            description: 'Em Aprovação - Mesa de Grãos',
        },
        {
            value: 'Aprovado',
            label: 'Aprovado',
            description: 'Aprovado',
        },
        {
            value: 'Integrado',
            label: 'Integrado',
            description: 'Integrado',
        }
    ];

    formasPagamento = [{
            label: 'Cessão Crédito ',
            value: 'A',
            description: 'Cessão Crédito'
        },
        {
            label: 'Boleto',
            value: 'B',
            description: 'Boleto'
        },
        {
            label: 'Dinheiro/Adiantamento',
            value: 'D',
            description: 'Dinheiro/Adiantamento'
        },
        {
            label: 'Encontro de Contas',
            value: 'E',
            description: 'Encontro de Contas'
        },
        {
            label: 'Cheque Recebido',
            value: 'H',
            description: 'Cheque Recebido'
        },
        {
            label: 'DOC',
            value: 'L',
            description: 'DOC'
        },
        {
            label: 'Operação CRA',
            value: 'P',
            description: 'Operação CRA'
        },
        {
            label: 'TED',
            value: 'S',
            description: 'TED'
        },
        {
            label: 'DOC/TED',
            value: 'T',
            description: 'DOC/TED'
        },
        {
            label: 'Transferência',
            value: 'V',
            description: 'Transferência'
        },
        {
            label: 'PIX',
            value: 'X',
            description: 'PIX'
        },
    ];

    canalDistribuicao = [{
        label: 'Venda Direta',
        value: 'Venda Direta',
        description: 'Venda Direta'
        },
    ];
    mtoOpitions = [];


    //Lista de Preço
    redispatchCondicaoVendaObject = CONDICAO_VENDA_OBJECT;
    condicao_venda;
    redispatchCondicaoVendaSearchFields = [CONDICAO_VENDA_NAME];
    redispatchCondicaoVendaListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    //CTV Venda
    @track redispatchCtvVendaObject = CTV_OBJECT;
    ctv_venda;
    @track redispatchCtvSearchFields = [CTV_NAME];
    @track redispatchCtvVendaListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    //Organizacao Vendas
    @track redispatchOrgVendasObject = ORG_VENDA_OBJECT;
    organizacao_vendas;
    @track redispatchOrgVendasSearchFields = [ORG_VENDAS_NAME]
    @track redispatchOrgVendasListItemOptions = {title:'Name', description:'Name'};

    //Cliente Entrega
    @track redispatchClienteEntregaObject = CLIENTE_ENTREGA_OBJECT;
    cliente_entrega;
    @track redispatchClienteEntregaSearchFields = [CLIENTE_ENTREGA_NAME];
    @track redispatchClienteEntregaListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    //Cliente Faturamento
    @track redispatchClienteFaturamentoObject = CLIENTE_FATURAMENTO_OBJECT;
    cliente_faturamento;
    @track redispatchClienteFaturamentoSearchFields = [CLIENTE_FATURAMENTO_NAME];
    @track redispatchClienteFaturamentoListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    //Status Pedido
    status_pedido = "Em digitação";
    frete = "CIF";
    deliveryId='';

    //Condicao Pagamento
    @track redispatchCondicaoPagamentoObject = COND_PAGAMENTO_OBJECT;
    condicao_pagamento;
    @track redispatchCondicaoPagamentoSearchFields = [COND_PAGAMENTO_NAME, COND_PAGAMENTO_CASH];
    @track redispatchCondicaoPagamentoListItemOptions = {title:'Name', description:'Name'};

    //Cultura
    @track redispatchCulturaObject = CULTURA_OBJECT;
    cultura;
    @track redispatchCulturaSearchFields = [CULTURA_NAME];
    @track redispatchCulturaListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    //Safra
    @track redispatchSafraObject = SAFRA_OBJECT;
    safra;
    @track redispatchSafraSearchFields = [SAFRA_NAME];
    @track redispatchSafraListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    allowMotherOrder = false;
    
    connectedCallback(){
        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let yyyy = today.getFullYear();

        this.currentDate = yyyy + '-' + mm + '-' + dd;

        this.loadDataHeader();
        this._setData();
        getAccountDataChild({accountId: this.accountData.Id})
        .then((result) =>{
            console.log(result);
            const accountsChild = JSON.parse(result);
            this.accountChildData = accountsChild.accountList;
        })
        .catch((err)=>{
        });
    }

    @api sequentialDict ={
        "cliente_entrega": '1',
        "ctv_venda" : '2',
        "safra" : '3',
        "moeda" : '4',
        "condicao_venda" : '5'
    }

    fieldKeyList = ["cliente_entrega", "ctv_venda", "safra", "moeda", "condicao_venda"];
    nextEnable(field){
        let index = this.sequentialDict[field];
        this.sequentialDict = this.invertDict();
        index = String(Number(index) + 1)
        let name = this.sequentialDict[index];
        setTimeout(()=>this.template.querySelector(`[data-name="${name}"]`).disabled = false);
        this.nextEnableEvent(Number(index));

    }


    previousDisable(index){
        index = Number(Number(index) + 1)
        if(Number(index) > 5){
            this.sequentialDict = this.invertDict();
            return;
        }else{
            let name = this.sequentialDict[index];
            if(name == "condicao_venda") this.removeItemRegisterByField("condicao_venda");
            setTimeout(()=>this.template.querySelector(`[data-name="${name}"]`).disabled = true);
            return this.previousDisable(index)
        }

    }

    nextEnableEvent(index){
        index = Number(Number(index) + 1)
        if(Number(index) > 5){
            this.sequentialDict = this.invertDict();
            return;
        }else if(this.headerDictLocale[this.sequentialDict[index]] != ' ' && this.headerDictLocale[this.sequentialDict[index]] != null){
            let name = this.sequentialDict[index];
            if(name == 'condicao_venda'  && this.headerDictLocale['moeda'] != ' ' && this.headerDictLocale['safra'].hasOwnProperty("Id")){
                let condition = "condicao_venda";
                setTimeout(()=>this.template.querySelector(`[data-name="${condition}"]`).disabled = false);
            }

            if(name != "condicao_venda"){
                setTimeout(()=>this.template.querySelector(`[data-name="${name}"]`).disabled = false);
            }
            
            return this.nextEnableEvent(Number(index))
        }
        else{
            return this.nextEnableEvent(Number(index))
        }
    }

    invertDict(){
        var invert = {}
        for(var key in this.sequentialDict){
            invert[this.sequentialDict[key]] = key;
        }

        return invert;
    }

    loadDataHeader(){

        try{

            if(this.headerData){
                this.fieldKey = true;
                this.headerDictLocale = JSON.parse(JSON.stringify(this.headerData));
                if(this.childOrder || this.headerData.IsOrderChild){
                    console.log('this.headerData.codigo_sap: ' + this.headerData.codigo_sap);
                    if (this.isFilled(this.headerData.codigo_sap) && this.headerData.codigo_sap.startsWith('003')) {
                        this.showMto = true;
                        console.log('this.showMto: ' + this.showMto);
                        getMTOTypes().then((result) => {
                            let mtoValues = JSON.parse(result);
                            this.mtoOpitions = JSON.parse(JSON.stringify(mtoValues));
                            if(this.headerDictLocale.tipo_venda == 'Venda Barter' || this.headerDictLocale.tipo_venda == 'Venda Entrega Futura'){
                                this.mtoOpitions.splice(this.mtoOpitions.findIndex((e) => e.value == 'ZVNO'), 1)
                            }else{
                                this.mtoOpitions.splice(this.mtoOpitions.findIndex((e) => e.value == 'ZVBA'), 1)
                            }

                            if (this.headerDictLocale.tipo_venda == 'Venda Entrega Futura') {
                                this.mtoOpitions.splice(this.mtoOpitions.findIndex((e) => e.value == 'ZVBA'), 1)
                            }
                            console.log('this.mtoOpitions: ' + this.mtoOpitions);
                        });
                    }
                }
                if (this.headerDictLocale.tipo_venda == 'Venda Conta e Ordem' || this.headerDictLocale.tipo_venda == 'Venda Entrega Futura' || this.headerDictLocale.tipo_venda == 'Venda Normal' ||
                    this.headerDictLocale.tipo_venda == 'Venda Barter' || this.headerDictLocale.tipo_venda == 'Venda Zona Franca') {
                    this.allowMotherOrder = true;
                } else {
                    this.headerDictLocale.pedido_mae_check = false;
                    this.allowMotherOrder = false;
                }

                this.barterSale = this.headerDictLocale.tipo_venda == 'Venda Barter' ? true : false;
                if (this.headerData.status_pedido.toLowerCase() == 'em aprovação - gerente filial' || this.headerData.status_pedido.toLowerCase() == 'em aprovação - gerente regional' || this.headerData.status_pedido.toLowerCase() == 'em aprovação - diretor torre' ||
                this.headerData.status_pedido.toLowerCase() == 'em aprovação - diretor' || this.headerData.status_pedido.toLowerCase() == 'em aprovação - comitê margem' || this.headerData.status_pedido.toLowerCase() == 'em aprovação - mesa de grãos') {
                    this.disabled = true;
                    this.paymentDisabled = true;
                    this.blockPaymentForm = true;
                }else{
                    setTimeout(()=>this.template.querySelector('[data-name="cliente_entrega"]').disabled = false);
                }

                this.pass = false;
                if(this.headerDictLocale.tipo_venda != " "){
                    // this.headerDataTitleLocale.tipo_venda = this.tiposVenda.find(element => element.value == this.headerData.tipo_venda).label;
                    this.headerDictLocale.data_pagamento = this.headerData.data_pagamento;
                    this.headerDictLocale.data_entrega = this.headerData.data_entrega ? this.headerData.data_entrega : null;
                }
                this.currencyOption = this.headerData.moeda;

                if (this.barterSale) {
                    this.formasPagamento.push({label: 'Operação Barter', value: 'C', description: 'Operação Barter'});
                    this.headerDictLocale.forma_pagamento = 'C';
                    this.blockPaymentForm = true;
                }
                
               
            }
            else{
                this.pass = true;
            }
        }
        catch(err){
            console.log(err);
        }
        
    }
    //Filial
    /*@track redispatchFilialObject = [FILIAL_OBJECT];
    filial;
    @track redispatchFilialSearchFields = [FILIAL_NAME];
    @track redispatchFilialListItemOptions = {title:'Name', description:'Name'};*/
    @track registerDetails = ['cliente_entrega'];

    isFilled(field) {
        return ((field !== undefined && field != null && field != '') || field == 0);
    }
    selectItemRegister(event){
        try{ 
            if(this.isFilled(event)){
                var field = event.target.name;
                if(event.target.value || event.target.checked){
                    if ((field == 'data_pagamento' && this.currentDate > event.detail.value) || (field == 'data_pagamento' && this.dateLimit < event.detail.value))
                    {
                        this.headerDictLocale[field] = null;
                        let headerValues = JSON.parse(JSON.stringify(this.headerData));
                        headerValues[field] = null;
                        this.headerData = JSON.parse(JSON.stringify(headerValues));
                        this.showToast('warning', 'Atenção!', 'Data não permitida.');
                    }
                    else if((field == 'data_entrega' && this.dateLimitBilling < event.detail.value) || (field == 'data_entrega' && this.dateStartBilling > event.detail.value)){
                        this.headerDictLocale[field] = null;
                        let headerValues = JSON.parse(JSON.stringify(this.headerData));
                        headerValues[field] = null;
                        this.headerData = JSON.parse(JSON.stringify(headerValues));
                        console.log('this.headerData: ' + JSON.stringify(this.headerData));
                        this.showToast('warning', 'Atenção!', 'Data não permitida.');
                    } else {
                        this.headerDictLocale[field] = field != 'pedido_mae_check' ? event.detail.value : event.target.checked;
                    }

                    if(field == 'pedido_mae_check'){
                        this.getCompaniesInHeader();
                    }
                    if(field == 'moeda'){
                        this.currencyOption = event.target.value;
                    }
                }
                else{
                    const { record } = event.detail;
                    if (field == 'condicao_pagamento') {
                        this.headerDictLocale[field] = {Id: record.Id, Name: record.Name, CashPayment: record.CashPayment__c};
                        if (!this.barterSale) {
                            if (record.CashPayment__c) {
                                if (this.headerDictLocale.firstTime) {
                                    this.headerDictLocale.data_pagamento = this.headerDictLocale['data_pagamento'] != ' ' ? this.headerDictLocale['data_pagamento'] : this.currentDate;
                                    this.headerDictLocale.firstTime = false;
                                } else {
                                    this.headerDictLocale.data_pagamento = this.currentDate;
                                    setTimeout(()=>this.template.querySelector('[data-target-id="data_pagamento"]').value =  this.headerDictLocale.data_pagamento);
                                }

                                this.headerData = JSON.parse(JSON.stringify(this.headerDictLocale));
                                this.paymentDisabled = true;
                            } else {
                                this.paymentDisabled = false;
                            }
                        }
                    } else {
                        this.headerDictLocale[field] = (this.registerDetails.includes(field) ? this.resolveRegister(record)  : {Id: record.Id, Name: record.Name});
                    }

                    if(field == 'safra'){
                        this.safraName = record.Name;
                    }
                    if(field == 'condicao_venda'){
                        this.setDateLimit();
                    }

                    if (field == 'cliente_entrega') 
                    {
                        this.deliveryId = this.headerDictLocale.cliente_entrega.Id;
                        this.getCompaniesInHeader();
                    }

                    if(field == 'ctv_venda'){
                        let getCompanyData = {
                            ctvId: this.headerDictLocale.ctv_venda.Id != null ? this.headerDictLocale.ctv_venda.Id : '',
                            accountId: this.headerData.cliente_entrega.Id != null ? this.headerData.cliente_entrega.Id : (this.accountData.Id != null ? this.accountData.Id : ''),
                            orderType: this.headerData.tipo_venda,
                            approvalNumber: 1
                        }
                        console.log('this.childOrder: ' + this.childOrder);
                        getAccountCompanies({data: JSON.stringify(getCompanyData), isHeader: true, verifyUserType: false, priceScreen: false, childOrder: this.childOrder})
                        .then((result) => {
                            let data = JSON.parse(result).companyInfoHeader;
                           this.salesOrgId = data.salesOrgId;
                           this.headerDictLocale.organizacao_vendas = {Id: data.salesOrgId};
                           this.headerDictLocale.companyFromDeliveredAccount = {Id: data.companyId};
                           this.headerDictLocale.supplierCenterDeliveredAccount = data.supplierCenter;
                           isSeedSale({salesOrgId: data.salesOrgId, productGroupName: null})
                           .then((result1) => {
                                this.seedSale = result1;
                                if(this.seedSale == true){
                                    setTimeout(()=>this.template.querySelector('lightning-input[data-name="hectares"]').style.display = 'none');
                                    this.headerDictLocale.hectares = 1
                                }else{
                                    setTimeout(()=>this.template.querySelector('lightning-input[data-name="hectares"]').style.display = '');
                                }
                                
                           });
                        });
                    }
                }
                if(this.fieldKeyList.includes(field) && !this.headerData.IsOrderChild)
                    this.nextEnable(field);
            }  
        }
        catch(err){
            console.log(err);
        }
        this._verifyFieldsToSave();
    }

    getCompaniesInHeader(){
        if(this.headerDictLocale.ctv_venda.Id != null){
            let getCompanyData = {
                ctvId: this.headerDictLocale.ctv_venda.Id != null ? this.headerDictLocale.ctv_venda.Id : '',
                accountId: this.headerData.cliente_entrega.Id != null ? this.headerData.cliente_entrega.Id : (this.accountData.Id != null ? this.accountData.Id : ''),
                orderType: this.headerData.tipo_venda,
                approvalNumber: 1
            }
            console.log('this.childOrder: ' + this.childOrder);
            getAccountCompanies({data: JSON.stringify(getCompanyData), isHeader: true, verifyUserType: false, priceScreen: false, childOrder: this.childOrder})
            .then((result) => {
                let data = JSON.parse(result).companyInfoHeader;
            this.salesOrgId = data.salesOrgId;
            this.headerDictLocale.organizacao_vendas = {Id: data.salesOrgId};
            this.headerDictLocale.companyFromDeliveredAccount = {Id: data.companyId};
            this.headerDictLocale.supplierCenterDeliveredAccount = data.supplierCenter;
            isSeedSale({salesOrgId: data.salesOrgId, productGroupName: null})
            .then((result1) => {
                    this.seedSale = result1;
                    if(this.seedSale == true){
                        setTimeout(()=>this.template.querySelector('lightning-input[data-name="hectares"]').style.display = 'none');
                        this.headerDictLocale.hectares = 1
                    }else{
                        setTimeout(()=>this.template.querySelector('lightning-input[data-name="hectares"]').style.display = '');
                    }
                    
            });
            });
        }
    }

    resolveRegister(record){
   
        return  {
            Id: record.Id,
            Name:record.Name,
            CPF:record.CPF,
            CNPJ:record.CNPJ,
            City:record.City,
            CodSap: record.ExternalId__c,
            UF:record.UF
        }
    }

    removeItemRegister(event){
        try{
            var field = event.target.name;
            this.headerDictLocale[field] = {};
            this.headerDictLocale.isCompleted = false;

            if (field == 'condicao_pagamento' && !this.barterSale) {
                this.paymentDisabled = false;
            } else if (field == 'safra' && this.barterSale) {
                this.headerData = JSON.parse(JSON.stringify(this.headerDictLocale));
                this.paymentDisabled = false;
                this._verifyFieldsToSave();
            }else if (field == 'safra'){
                this.safraName = null;
            }else if (field == 'condicao_venda'){
                this.clearDates()
            }
            if(this.fieldKeyList.includes(field) && !this.headerData.IsOrderChild){
                let index = this.sequentialDict[field];
                this.sequentialDict = this.invertDict();
                this.previousDisable(index);
            }
            
            this._setData();
        }catch(err){
            console.log(err);
        }
    }

    clearDates(){
        this.headerDictLocale['data_entrega'] = null;
        this.headerDictLocale['data_pagamento'] = null;
        setTimeout(()=>{
            this.template.querySelector('[data-target-id="data_entrega"]').value = " "
        });
        setTimeout(()=>this.template.querySelector('[data-target-id="data_pagamento"]').value =  " ");
        this.headerData = JSON.parse(JSON.stringify(this.headerDictLocale));
    }
    
    removeItemRegisterByField(field){
        this.headerDictLocale[field] = {};
        this.headerDictLocale.isCompleted = false;
        this.template.querySelector(`[data-name="${field}"]`).clearAll();
        this._setData();
    }

    setDateLimit(){
       
        if(this.isFilled(this.headerDictLocale['safra']) && this.isFilled(this.salesOrgId) && this.isFilled(this.headerDictLocale['condicao_venda'])){
            getDateLimit({
                safraId: this.headerDictLocale['safra'].Id,
                salesConditionId: this.headerDictLocale['condicao_venda'].Id,
                salesOrgId: this.salesOrgId
            })
            .then((result) =>{
                if(result != 'Não foi possível encontrar as datas da Safra selecionada, contate o time de Pricing AgroGalaxy.'){
                    const data = JSON.parse(result);
                    this.dateLimit = data.paymentDate;
                    this.dateLimitBilling = data.endDateBilling;
                    this.dateStartBilling = data.startDateBilling;
                    this.hasDelimiter = true;

                    if (this.barterSale) {
                        this.headerDictLocale.data_pagamento = data.paymentBaseDate;
                        this.headerData = JSON.parse(JSON.stringify(this.headerDictLocale));
                        this.paymentDisabled = true;
                    }
                    this._verifyFieldsToSave();
                }else{
                    this.hasDelimiter = false;
                    this.showToast('warning', 'Atenção', result);
                    this._verifyFieldsToSave();
                }
            })
            .catch((err)=>{
                console.log(err);
            });
        }
    }

    @api
    _verifyFieldsToSave() {
        if (this.verifyMandatoryFields()) {
            this.headerDictLocale.isCompleted = true;
            this._setData();
            return true;
        }
        return false;
    }

    @api
    verifyMandatoryFields() {
        try{
            if ((this.headerDictLocale.tipo_venda !== undefined &&
                this.headerDictLocale.safra.Id !== undefined &&
                this.headerDictLocale.cultura.Id !== undefined &&
                this.headerDictLocale.data_pagamento !== null &&
                this.headerDictLocale.data_pagamento !== ' ' &&
                this.headerDictLocale.data_entrega !== null &&
                this.headerDictLocale.data_entrega !== ' ' &&
                this.headerDictLocale.condicao_venda != ' ' &&
                this.headerDictLocale.condicao_venda.Id !== undefined &&
                this.headerDictLocale.condicao_pagamento.Id !== undefined &&
                this.headerDictLocale.moeda !== undefined &&
                this.headerDictLocale.moeda !== ' ' &&
                this.headerDictLocale.numero_pedido_cliente !== undefined &&
                this.headerDictLocale.ctv_venda.Id !==undefined &&
                this.headerDictLocale.forma_pagamento !== undefined &&
                this.headerDictLocale.cliente_entrega.Id !== undefined) &&
                this.headerDictLocale.hectares !== 0 &&
                this.headerDictLocale.hectares !== undefined &&
                this.headerDictLocale.hectares !== '' && 
                ((this.showMto && this.headerDictLocale.mto !== undefined &&
                this.headerDictLocale.mto !== '' && this.headerDictLocale.mto !== null) || !this.showMto) && 
                this.hasDelimiter || this.pass 
            ) {
                return true;
            }
        } catch(err){
            console.log(err);
        }
        this.headerDictLocale.isCompleted = false;
        return false; 
    }

    _setData() {
        const setHeaderData = new CustomEvent('setheaderdata');
        setHeaderData.data = this.headerDictLocale;
        this.dispatchEvent(setHeaderData);

        if (this.headerData.IsOrderChild) {
            this.disabled = true;
            this.paymentDisabled = true;
            this.blockPaymentForm = true;
            setTimeout(()=>this.template.querySelector('[data-name="cliente_entrega"]').disabled = false);////
        }
    }

    showToast(type, title, message) {
        let event = new ShowToastEvent({
            variant: type,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }
}