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
import getOrderMothers from '@salesforce/apex/OrderScreenController.getOrderMothers';

//import FILIAL_OBJECT from '@salesforce/schema/';
//import FILIAL_NAME from '@salesforce/schema/';

export default class OrderHeaderScreen extends LightningElement {
    readonly = false;
    booleanTrue = true;

    @api accountData;
    @api accountChildData;
    @api orderMother;

    @api headerData;
    @api headerDictLocale ={
        Id: " ",
        AccountId: " ",
        tipo_venda: " ",
        filial: null,
        numero_pedido_cliente: " ",
        safra: {},
        cultura: {},
        lista_precos: {},
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
        moeda: " ",
        ctv_venda: " ",
        pedido_mae: {},
        pedido_mae_check : false,
        frete: "CIF",
        org: {Name: " "},
        aprovation: null
    };

    @api productData;
    @api divisionData;
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
            label: 'Venda Normal',
            description: ''
        },
        {
            value: '1',
            label: 'Venda Conta e Ordem',
            description: ''
        },
        {
            value: '2',
            label: 'Venda Entrega Futura',
            description: ''
        },
        {
            value: '3',
            label: 'Venda Consignação',
            description: ''
        },
        {
            value: '4',
            label: 'Venda Exportação',
            description: ''
        },
        {
            value: '5',
            label: 'Venda Sucata',
            description: ''
        },
        {
            value: '6',
            label: 'Venda de Ativo',
            description: ''
        },
        {
            value: '7',
            label: 'Venda de Serviço',
            description: ''
        },
        {
            value: '8',
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
            console.log(result);
            const accountsChild = JSON.parse(result);
            this.accountChildData = accountsChild.accountList;
        })
        .catch((err)=>{
        });
        console.log('orelhao');
        getOrderMothers().then((result) =>{
            console.log(result);
            const orderData = JSON.parse(result);
            this.orderMother = orderData;
            console.log(this.orderMother);
        })
        .catch((err)=>{
            console.log(err);
        });
    
    }

    loadDataHeader(){

        try{

            if(this.headerData){
                this.headerDictLocale =JSON.parse(JSON.stringify(this.headerData));
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
                    this.headerDictLocale[field] = field != 'pedido_mae_check' ? event.detail.value : event.target.checked;
                }
                else{
                        const { record } = event.detail;
                        this.headerDictLocale[field] = (this.registerDetails.includes(field) ? this.resolveRegister(record)  : {Id: record.Id, Name: record.Name});
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
        var field = event.target.name;
        this.headerDictLocale[field] = null;
        this._setData();
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
        try{
            if ((this.headerDictLocale.tipo_venda !== undefined &&
                this.headerDictLocale.safra.Id !== undefined &&
                this.headerDictLocale.cultura.Id !== undefined &&
                this.headerDictLocale.data_pagamento !== undefined &&
                this.headerDictLocale.lista_precos != ' ' &&
                this.headerDictLocale.lista_precos.Id !== undefined &&
                this.headerDictLocale.condicao_pagamento.Id !== undefined &&
                this.headerDictLocale.moeda !== undefined &&
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

        return false; 
    }

    _setData() {
        const setHeaderData = new CustomEvent('setheaderdata');
        setHeaderData.data = this.headerDictLocale;
        this.dispatchEvent(setHeaderData);
    }
}