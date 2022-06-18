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

//import FILIAL_OBJECT from '@salesforce/schema/';
//import FILIAL_NAME from '@salesforce/schema/';

export default class OrderHeaderScreen extends LightningElement {
    readonly = false;
    booleanTrue = true;
    disabled = false;
    paymentDisabled = false;
    barterSale = false;
    currentDate;
    dateLimit;
    dateStartBilling;
    dateLimitBilling;

    @api accountData;
    @api accountChildData;

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
        pedido_mae: {},
        pedido_mae_check : true,
        pre_pedido : false,
        frete: "CIF",
        org: {Name: " "},
        aprovation: null,
        IsOrderChild : false,
        isCompleted : false,
        companyId: null,
        firstTime: true
    };

    @api productData;
    @api divisionData;
    @api commodityData;
    @api cloneData;

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
            label: 'Operação Barter',
            value: 'C',
            description: 'Operação Barter'
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

    
    connectedCallback(){
        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let yyyy = today.getFullYear();

        this.currentDate = yyyy + '-' + mm + '-' + dd;

        this.loadDataHeader();
        getAccountDataChild({accountId: this.accountData.Id})
        .then((result) =>{
            console.log(result);
            const accountsChild = JSON.parse(result);
            this.accountChildData = accountsChild.accountList;
        })
        .catch((err)=>{
        });
    }

    loadDataHeader(){

        try{

            if(this.headerData){
                this.headerDictLocale = JSON.parse(JSON.stringify(this.headerData));
                this.barterSale = this.headerDictLocale.tipo_venda == 'Venda Barter' ? true : false;
                if (this.headerData.status_pedido == 'Em aprovação - Gerente Filial' || this.headerData.status_pedido == 'Em aprovação - Gerente Regional' ||
                    this.headerData.status_pedido == 'Em aprovação - Diretor' || this.headerData.status_pedido == 'Em aprovação - Comitê Margem' || this.headerData.status_pedido == 'Em aprovação - Mesa de Grãos') {
                    this.disabled = true;
                    this.paymentDisabled = true;
                }
                
                this.pass = false;
                if(this.headerDictLocale.tipo_venda != " "){
                    // this.headerDataTitleLocale.tipo_venda = this.tiposVenda.find(element => element.value == this.headerData.tipo_venda).label;
                    this.headerDictLocale.data_pagamento = this.headerData.data_pagamento;
                    this.headerDictLocale.data_entrega = this.headerData.data_entrega ? this.headerData.data_entrega : null;
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
                    if ((field == 'data_pagamento' || (field == 'data_entrega')) && ((field == 'data_pagamento' && this.currentDate) > event.detail.value || (field == 'data_pagamento' && this.dateLimit < event.detail.value) || (field == 'data_entrega' && this.dateLimitBilling < event.detail.value) || (field == 'data_entrega' && this.dateStartBilling > event.detail.value))) 
                    {
                        this.headerDictLocale[field] = null;
                        let headerValues = JSON.parse(JSON.stringify(this.headerData));
                        headerValues[field] = null;
                        this.headerData = JSON.parse(JSON.stringify(headerValues));
                        this.showToast('warning', 'Atenção!', 'Data não permitida.');
                    } else {
                        this.headerDictLocale[field] = field != 'pedido_mae_check' ? event.detail.value : event.target.checked;
                    }
                }
                else{
                    const { record } = event.detail;
                    if (field == 'condicao_pagamento') {
                        this.headerDictLocale[field] = {Id: record.Id, Name: record.Name, CashPayment: record.CashPayment__c};
                        if (record.CashPayment__c) {
                            if (this.headerDictLocale.firstTime) {
                                this.headerDictLocale.data_pagamento = this.headerDictLocale['data_pagamento'];
                                this.headerDictLocale.firstTime = false;
                            } else {
                                this.headerDictLocale.data_pagamento = this.currentDate;
                            }

                            this.headerData = JSON.parse(JSON.stringify(this.headerDictLocale));
                            this.paymentDisabled = true;
                        } else {
                            this.paymentDisabled = false;
                        }
                    } else {
                        this.headerDictLocale[field] = (this.registerDetails.includes(field) ? this.resolveRegister(record)  : {Id: record.Id, Name: record.Name});
                    }

                    if(field == 'safra'){
                        this.setDateLimit(record.Id);
                    }
                }
            }  
        }
        catch(err){
            console.log(err);
        }
        this._verifyFieldsToSave();
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

            if (field == 'condicao_pagamento') {
                this.paymentDisabled = false;
            }
            this._setData();
        }catch(err){
            console.log(err);
        }
    }

    setDateLimit(){
        if(this.isFilled(this.headerDictLocale['safra'])){
            getDateLimit({safraId: this.headerDictLocale['safra'].Id})
            .then((result) =>{
                const data = JSON.parse(result);
                this.dateLimit = data.paymentDate;
                this.dateLimitBilling = data.endDateBilling;
                this.dateStartBilling = data.startDateBilling;
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
                this.headerDictLocale.cliente_entrega.Id !== undefined) || this.pass
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
        // this.headerDictLocale.IsOrderChild = false;
        this.dispatchEvent(setHeaderData);
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