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

import COND_PAGAMENTO_OBJECT from '@salesforce/schema/CondicaoPagamento__c';
import COND_PAGAMENTO_NAME from '@salesforce/schema/CondicaoPagamento__c.Name';

import CULTURA_OBJECT from '@salesforce/schema/Cultura__c';
import CULTURA_NAME from '@salesforce/schema/Cultura__c.Name';

import SAFRA_OBJECT from '@salesforce/schema/Safra__c';
import SAFRA_NAME from '@salesforce/schema/Safra__c.Name';

import getAccountDataChild from '@salesforce/apex/OrderScreenController.getAccountDataChild';

//import FILIAL_OBJECT from '@salesforce/schema/';
//import FILIAL_NAME from '@salesforce/schema/';

export default class OrderHeaderScreen extends LightningElement {
    readonly = false;
    booleanTrue = true;

    @api accountData;
    @api accountChildData;

    @api headerDataTitle;
    @api headerDataTitleLocale = {};

    @api headerData;
    @api headerDictLocale ={
        Id: " ",
        AccountId: " ",
        tipo_venda: " ",
        filial: null,
        numero_pedido_cliente: " ",
        safra: " ",
        cultura: " ",
        lista_precos: " ",
        condicao_pagamento: " ",
        data_pagamento: " ",
        data_entrega: " ",
        status_pedido: "Em digitação",
        cliente_faturamento: " ",
        cliente_entrega: " ",
        organizacao_vendas: null,
        canal_distribuicao: null,
        setor_atividade: null,
        forma_pagamento: " ",
        moeda: " ",
        ctv_venda: " ",
        frete: "CIF",
        pedido_mae:" "
    };

    @api productData;

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
            label: 'Bonificação',
            value: 'Bonificação',
            description: 'Bonificação'
        },
    ];

    canalDistribuicao = [{
        label: 'Venda Direta',
        value: 'Venda Direta',
        description: 'Venda Direta'
        },
    ];


    //Lista de Preço
    redispatchListaPrecoObject = LISTA_PRECO_OBJECT;
    lista_precos;
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
    status_pedido = "Em digitação";
    frete = "CIF";

    //Condicao Pagamento
    @track redispatchCondicaoPagamentoObject = COND_PAGAMENTO_OBJECT;
    condicao_pagamento;
    @track redispatchCondicaoPagamentoSearchFields = [COND_PAGAMENTO_NAME];
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

        this.loadDataHeader();
        getAccountDataChild({accountId: this.accountData.Id})
        .then((result) =>{
            const accountsChild = JSON.parse(result);
            this.accountChildData = accountsChild.accountList;
        })
        .catch((err)=>{
        });
    
    }

    loadDataHeader(){
        if(this.headerData.tipo_venda != " "){
            this.headerDictLocale ={...this.headerData};
            this.headerDataTitleLocale = {... this.headerDataTitle};
            this.pass = false;
            if(this.headerDataTitleLocale.tipo_venda != " "){
                this.headerDataTitleLocale.tipo_venda = this.tiposVenda.find(element => element.value == this.headerData.tipo_venda).label;
                this.headerDataTitleLocale.data_pagamento = this.headerData.data_pagamento;
                this.headerDataTitleLocale.data_entrega = this.headerData.data_entrega ? this.headerData.data_entrega : null;
            }
        }
        else{
            this.pass = true;
        }
        
    }
    //Filial
    /*@track redispatchFilialObject = [FILIAL_OBJECT];
    filial;
    @track redispatchFilialSearchFields = [FILIAL_NAME];
    @track redispatchFilialListItemOptions = {title:'Name', description:'Name'};*/
    @track registerDetails = ['cliente_entrega'];

    selectItemRegister(event){
        
        var field = event.target.name;
        if(event.detail.value){
            this.headerDictLocale[field] = event.detail.value;
            this.headerDataTitleLocale[field] = (field == 'tipo_venda' ? this.tiposVenda.find(element => element.value == event.detail.value).label : event.detail.value);
        }
        else{
            const { record } = event.detail;
            console.log(JSON.stringify(record));
            this.headerDictLocale[field] = record.Id;
            try{
            this.headerDataTitleLocale[field] = (this.registerDetails.includes(field) ? this.resolveRegister(record)  : record.Name);
            }
            catch(e){
                console.log(e);
            }
        }
        this._verifyFieldsToSave();
    }

    resolveRegister(record){
   
        return  {
            Name:record.Name,
            CPF:record.CPF,
            CNPJ:record.CNPJ,
            City:record.City,
            UF:record.UF
        }
    }
  
    removeSelectClienteEntrega(event){
        this.headerDataTitleLocale.cliente_entrega = '';
        this._verifyFieldsToSave();
    }

    @api
    _verifyFieldsToSave() {
        // if (this.verifyMandatoryFields()) {
            this._setData();
            return true;
        // }
        return false;
    }

    @api
    verifyMandatoryFields() {
        if ((this.headerDictLocale.tipo_venda !== undefined &&
            this.headerDictLocale.safra !== undefined &&
            this.headerDictLocale.cultura !== undefined &&
            this.headerDictLocale.data_pagamento !== undefined &&
            this.headerDictLocale.lista_precos !== undefined &&
            this.headerDictLocale.moeda !== undefined &&
            this.headerDictLocale.numero_pedido_cliente !== undefined &&
            this.headerDictLocale.ctv_venda !==undefined &&
            this.headerDictLocale.forma_pagamento !== undefined &&
            this.headerDictLocale.hectares !== undefined) || this.pass
            ) {
            return true;
        }
        return false;
    }

    _setData() {
       
        const setHeaderData = new CustomEvent('setheaderdata');
        setHeaderData.data = this.headerDictLocale;
        setHeaderData.dataTitles = this.headerDataTitleLocale;
        this.dispatchEvent(setHeaderData);
       
    }
}