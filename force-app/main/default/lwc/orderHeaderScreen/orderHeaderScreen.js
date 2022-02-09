import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';

import LISTA_PRECO_NAME from '@salesforce/schema/Pricebook2.Name';
import LISTA_PRECO_OBJECT from '@salesforce/schema/Pricebook2';

export default class OrderHeaderScreen extends LightningElement {
    readonly = false
    @api accountData;

    tipo_venda;
    filial;
    cliente_entrega;
    safra;
    cultura;
    lista_precos;
    condicao_pagamento;
    data_pagamento;
    data_entrega;

    @track redispatchListaPrecosSearchFields = [LISTA_PRECO_NAME];
    @track redispatchListaPrecoObject = LISTA_PRECO_OBJECT;
    @track redispatchListaPrecoListItemOptions = { title: 'Name', description: 'Name' };

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

    selectTipoVenda(event) {
        this.tipo_venda = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectFilial(event) {
        this.filial = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectClienteEntrega(event) {
        this.cliente_entrega = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectSafra(event) {
        this.safra = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectCultura(event) {
        this.cultura = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectListaPrecos(event) {
        this.lista_precos = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectCondicaoPagamento(event) {
        this.condicao_pagamento = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectDataPagamento(event) {
        this.data_pagamento = event.detail.value;
        this._verifyFieldsToSave();
    }

    selectDataEntrega(event) {
        this.data_entrega = event.detail.value;

    }

    _verifyFieldsToSave() {
        console.log(
            this.tipo_venda,
            /* this.filial &&
            this.cliente_entrega &&
            this.safra &&
            this.cultura &&
            this.lista_precos &&
            this.condicao_pagamento &&*/
            this.lista_precos,
            this.cliente_entrega,
            this.data_pagamento,
            this.data_entrega
        );
        if (this.tipo_venda !== null &&
            /* this.filial &&
            this.cliente_entrega &&
            this.safra &&
            this.cultura &&
            this.lista_precos &&
            this.condicao_pagamento &&*/
            this.lista_precos !== null &&
            this.cliente_entrega !== null &&
            this.data_pagamento !== null &&
            this.data_entrega !== null) {
            this._setData();
            return true;
        }
        return false;
    }    
    
    @api
    verifyMandatoryFields() {
        if (this.tipo_venda !== null &&
            /* this.filial &&
            this.cliente_entrega &&
            this.safra &&
            this.cultura &&
            this.lista_precos &&
            this.condicao_pagamento &&*/
            this.lista_precos !== null &&
            this.cliente_entrega !== null &&
            this.data_pagamento !== null &&
            this.data_entrega !== null) {
            this._verifyFieldsToSave();
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
            'data_entrega': this.sdata_entrega
        };
        this.dispatchEvent(setHeaderData);
    }
}