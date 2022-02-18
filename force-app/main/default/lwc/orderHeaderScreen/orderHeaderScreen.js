import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';

import LISTA_PRECO_OBJECT from '@salesforce/schema/Pricebook2';
import LISTA_PRECO_NAME from '@salesforce/schema/Pricebook2.Name';

import CTV_OBJECT from '@salesforce/schema/User';
import CTV_NAME from '@salesforce/schema/User.Name';

import ORG_VENDA_OBJECT from '@salesforce/schema/SalesOrg__c';
import ORG_VENDAS_NAME from '@salesforce/schema/SalesOrg__c.Name';

import CLIENTE_ENTREGA_OBJECT from '@salesforce/schema/Account';
import CLIENTE_ENTREGA_NAME from '@salesforce/schema/Account.Name';

import CLIENTE_FATURAMENTO_OBJECT from '@salesforce/schema/Account';
import CLIENTE_FATURAMENTO_NAME from '@salesforce/schema/Account.Name';

//import COND_PAGAMENTO_OBJECT from '@salesforce/schema/';
//import COND_PAGAMENTO_NAME from '@salesforce/schema/';

import CULTURA_OBJECT from '@salesforce/schema/Cultura__c';
import CULTURA_NAME from '@salesforce/schema/Cultura__c.Name';

import SAFRA_OBJECT from '@salesforce/schema/Safra__c';
import SAFRA_NAME from '@salesforce/schema/Safra__c.Name';

//import FILIAL_OBJECT from '@salesforce/schema/';
//import FILIAL_NAME from '@salesforce/schema/';

export default class OrderHeaderScreen extends LightningElement {
    readonly = false
    @api accountData;

    @api headerData;

    moedas = [{
        value: 'BRL',
        label: 'BRL (R$)',
        description: 'Real Brasileiro'
    }, {
        value: 'USD',
        label: 'USD (US$)',
        description: 'Dólar Americano'
    }];

    tiposVenda = [{
            value: '0',
            label: 'Venda Normal',
            description: ''
        },
        {
            value: '1',
            label: 'Venda Conta e Ordem',
            description: ''
        },
        {
            value: '1',
            label: 'Venda Entrega Futura',
            description: ''
        },
        {
            value: '2',
            label: 'Venda Exportação',
            description: ''
        },
        {
            value: '3',
            label: 'Venda Sucata',
            description: ''
        },
        {
            value: '4',
            label: 'Venda de Ativo',
            description: ''
        },
        {
            value: '5',
            label: 'Venda de Serviço',
            description: ''
        },
        {
            value: '6',
            label: 'Remessas Promocionais',
            description: ''
        },
    ];

    statusPedido = [{
            value: '0',
            label: 'Em digitação',
            description: 'Em digitação',
        },
        {
            value: '1',
            label: 'Confirmado',
            description: 'Confirmado',
        },
        {
            value: '2',
            label: 'Integrado',
            description: 'Integrado',
        }
    ];

    formasPagamento = [{
            label: 'Credito',
            value: '0',
            description: 'Crédito'
        },{
            label: 'A vista',
            value: '1',
            description: 'A vista'
        },{
            label: 'Cheque',
            value: '2',
            description: 'Cheque'
        },
    ]

    tipo_venda;

    moeda;

    data_pagamento;

    data_entrega;

    forma_pagamento;

    numero_pedido_cliente;

    //Lista de Preço
    redispatchListaPrecoObject = LISTA_PRECO_OBJECT;
    lista_precos;// = '01s3F000006RwA7QAK';
    redispatchListaPrecosSearchFields = [LISTA_PRECO_NAME];
    redispatchListaPrecoListItemOptions = {
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
    status_pedido;

    //Condicao Pagamento
    /*@track redispatchCondicaoPagamentoObject = COND_PAGAMENTO_OBJECT;
    condicao_pagamento;
    @track redispatchCondicaoPagamentoSearchFields = [COND_PAGAMENTO_NAME];
    @track redispatchCondicaoPagamentoListItemOptions = {title:'Name', description:'Name'};*/

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

    //Filial
    /*@track redispatchFilialObject = [FILIAL_OBJECT];
    filial;
    @track redispatchFilialSearchFields = [FILIAL_NAME];
    @track redispatchFilialListItemOptions = {title:'Name', description:'Name'};*/

    selectCtvVenda(event) {
        const { record } = event.detail;
        this.ctv_venda = record.Id;
        this._verifyFieldsToSave();
    }

    selectOrgVendas(event) {
        const { record } = event.detail;
        this.organizacao_vendas = record.Id;
        this._verifyFieldsToSave();
    }

    selectNumeroPedido(event) {
        this.numero_pedido_cliente = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectClienteEntrega(event) {
        const { record } = event.detail;
        this.cliente_entrega = record.Id;
        this._verifyFieldsToSave();
    }

    selectClienteFaturamento(event) {
        const { record } = event.detail;
        this.cliente_faturamento = record.Id;
        this._verifyFieldsToSave();
    }

    selectCondicaoPagamento(event) {
        this.condicao_pagamento = event.detail;
        this._verifyFieldsToSave();
    }

    selectListaPrecos(event) {
        const { record } = event.detail;
        this.lista_precos = record.Id;
        this._verifyFieldsToSave();
    }

    selectCultura(event) {
        const { record } = event.detail;
        this.cultura = record.Id;
        this._verifyFieldsToSave();
    }

    selectSafra(event) {
        const { record } = event.detail;
        this.safra = record.Id;
        this._verifyFieldsToSave();
    }

    selectFilial(event) {
        const { record } = event.detail;
        this.filial = record.Id;
        this._verifyFieldsToSave();
    }

    selectTipoVenda(event) {
        this.tipo_venda = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectMoeda(event) {
        this.moeda = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectFormaPagamento(event) {
        this.forma_pagamento = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectDataPagamento(event) {
        this.data_pagamento = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectDataEntrega(event) {
        this.data_entrega = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectStatusPedido(event){
        this.status_pedido = event.detail.value;
        this._verifyFieldsToSave();
    }

    @api
    _verifyFieldsToSave() {
        if (this.verifyMandatoryFields()) {
            this._setData();
            return true;
        }
        return false;
    }

    @api
    verifyMandatoryFields() {
        if (this.tipo_venda !== undefined &&
            /* this.filial &&
            this.safra !== null &&
            this.cultura !== null &&
            this.condicao_pagamento !== null &&*/
            this.cliente_entrega !== undefined &&
            this.lista_precos !== undefined &&
            this.cliente_faturamento !== undefined &&
            this.data_pagamento !== undefined &&
            this.data_entrega !== undefined) {
            return true;
        }
        return false;
    }

    _setData() {
        const setHeaderData = new CustomEvent('setheaderdata');
        setHeaderData.data = {
            'tipo_venda': this.tipo_venda,
            'filial': this.filial,
            'cliente_entrega': this.cliente_entrega,
            'safra': this.safra,
            'cultura': this.cultura,
            'lista_precos': this.lista_precos,
            'condicao_pagamento': this.condicao_pagamento,
            'data_pagamento': this.data_pagamento,
            'data_entrega': this.data_entrega,
            'status_pedido': this.status_pedido,
            'cliente_faturamento': this.cliente_faturamento,
            'moeda': this.moeda,
            'organizacao_vendas': this.organizacao_vendas,
            'forma_pagamento': this.forma_pagamento,
            'ctv_venda': this.ctv_venda,
        };
        this.dispatchEvent(setHeaderData);
    }
}