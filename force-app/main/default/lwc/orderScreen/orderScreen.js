import {
    LightningElement,
    api, track, wire
} from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import NoHeader from '@salesforce/resourceUrl/NoHeader';
import {
    loadStyle,
    loadScript
} from 'lightning/platformResourceLoader';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import Order from '@salesforce/schema/Order';
import saveOrder from '@salesforce/apex/OrderScreenController.saveOrder';
// import calloutOrder from '@salesforce/apex/OrderScreenController.callout';
import getOrder from '@salesforce/apex/OrderScreenController.getOrder';
import getAccount from '@salesforce/apex/OrderScreenController.getAccount';
import { NavigationMixin } from 'lightning/navigation';

export default class OrderScreen extends NavigationMixin(LightningElement) {
    @api recordId;
    @api originScreen;
    @api recordTypeId;
    @api clone;
    @track cloneData = {
        cloneOrder: false
    };

    @wire(getObjectInfo, {objectApiName: Order})
    getObjectData({data, error}){
        if(data){
            if(this.recordTypeId != undefined && this.recordTypeId != ''){
                var arrayType = data.recordTypeInfos[this.recordTypeId]
                this.headerData.tipo_venda = arrayType.name;
            }
        }
    }
    account = true;
    header = false;
    product = false;
    @track summary = false;

    @api accountData;
    @api headerDataTitle = {};
    @api headerData = {
        Id: " ",
        AccountId: " ",
        tipo_venda: " ",
        filial: " ",
        numero_pedido_cliente: " ",
        safra: " ",
        cultura: " ",
        condicao_venda: " ",
        condicao_pagamento: " ",
        data_pagamento: " ",
        data_entrega: " ",
        status_pedido: "Em digitação",
        cliente_faturamento: " ",
        cliente_entrega: " ",
        organizacao_vendas: {},
        canal_distribuicao: " ",
        setor_atividade: " ",
        forma_pagamento: " ",
        moeda: " ",
        ctv_venda: " ",
        pedido_mae: {},
        pedido_mae_check : false,
        frete: "CIF",
        org: {Name: " "},
        aprovation: " "
    };
    @track productData;
    @track divisionData;
    @track commodityData;
    @track summaryData = {
        'observation' : "",
        'billing_sale_observation': ""
    };

    qtdItens = 0;
    valorTotal = 0;
    frete = '';

    currentTab = 0;

    isLoading = false;

    tabs = [{
            name: 'account',
            current: true,
            enable: true,
            completed:false,
            message: 'Necessário selecionar pelo menos uma conta',
            component: 'c-order-account-screen'
        },
        {
            name: 'header',
            current: false,
            enable: false,
            completed:false,
            message: 'Necessário preencher todos os dados obrigatórios antes de seguir',
            component: 'c-order-header-screen'
        },
        {
            name: 'product',
            current: false,
            enable: false,
            completed:false,
            message: 'Necessário selecionar pelo menos 1 produto',
            component: 'c-order-product-screen'
        },
        {
            name: 'summary',
            current: false,
            enable: false,
            completed:false,
            message: '',
            component: 'c-order-summary-screen'
        }
    ];

    //Variaveis para mensagem
    _title = 'Operação inválida';
    message = 'Esta operação não pode ser finalizada';
    variant = 'warning';
    variantOptions = [{
            label: 'error',
            value: 'error'
        },
        {
            label: 'warning',
            value: 'warning'
        },
        {
            label: 'success',
            value: 'success'
        },
        {
            label: 'info',
            value: 'info'
        },
    ];

    renderedCallback() {
        this.checkPreviousNextBtn();
        this.changeStyle();
        if(this.originScreen.includes('Order')){
            if(this.recordId)
                this.getOrder();
        }else if(this.originScreen.includes('Account')){
            this.getAccount();
        }
        //console.log(this.recordId, this.originScreen);

    }

    getAccount(){
        console.log('getAccount');
        if(this.accountData)
            return;
            
        this.isLoading = true;
        getAccount({recordId: this.recordId})
        .then((result) =>{
            const account = JSON.parse(result);
            this.accountData = account.accountData;
            this.enableNextScreen();
            this.completeCurrentScreen();
            this.isLoading = false;
        })
        .catch((err)=>{
            this.showNotification(err.message, 'Ocorreu algum erro');
            this.isLoading = false;
        });
    }

    getOrder(){
        console.log('getOrder');
        if(this.headerData.Id != " ")
            return;

        this.isLoading = true;
        getOrder({recordId: this.recordId, cloneOrder: this.clone.cloneOrder})
        .then((result) =>{
            const data = JSON.parse(result);
            this.accountData = data.accountData;
            this.headerData = data.headerData;
            this.productData = data.productData;
            this.divisionData = data.divisionData;
            this.summaryData['observation'] = this.headerData.observation;
            this.summaryData['billing_sale_observation'] = this.headerData.billing_sale_observation;
            this.enableScreens([0, 1, 2, 3]);
            this.completeScreens([0, 1, 2, 3]);
            this.isLoading = false;
            this.cloneData.cloneOrder = this.clone.cloneOrder;
            this.headerData.condicao_venda = this.headerData.condicao_venda != null ? this.headerData.condicao_venda : ' ';
            // this.cloneData.pricebookListId = this.headerData.condicao_venda != ' ' ?  this.headerData.condicao_venda.Id : '';
        })
        .catch((err)=>{
            console.log(err);
            this.showNotification(err.message, 'Ocorreu algum erro');
            this.isLoading = false;
        })
    }

    getOrderMother(id, name){
        console.log('getOrder');
        if(this.headerData.Id != " ")
            return;

        this.isLoading = true;
        getOrder({recordId: id, cloneOrder: this.clone.cloneOrder})
        .then((result) =>{
            const data = JSON.parse(result);
            this.accountData = data.accountData;
            this.headerData = data.headerData;
            this.headerData.pedido_mae_check = false;
            this.headerData.pedido_mae = {Id: id, Name: name};
            this.productData = data.productData;
            this.divisionData = data.divisionData;
            this.summaryData['observation'] = this.headerData.observation;
            this.summaryData['billing_sale_observation'] = this.headerData.billing_sale_observation;
            this.enableScreens([0, 1, 2, 3]);
            this.completeScreens([0, 1, 2, 3]);
            this.isLoading = false;
            this.cloneData.cloneOrder = this.clone.cloneOrder;
            this.headerData.condicao_venda = this.headerData.condicao_venda != null ? this.headerData.condicao_venda : ' ';
            // this.cloneData.pricebookListId = this.headerData.condicao_venda != ' ' ?  this.headerData.condicao_venda.Id : '';
        })
        .catch((err)=>{
            console.log(err);
            this.showNotification(err.message, 'Ocorreu algum erro');
            this.isLoading = false;
        })
    }


    connectedCallback() {
        //Importando estilo para esconder header padrão de página
        loadStyle(this, NoHeader);
        this.loadVariable();
    }

    async loadVariable(){
        await this.recordId;
    }

    async saveOrder(event){
        const mode = event.detail;
        await this.recordId;
        const data = {accountData: this.accountData, headerData: this.headerData, productData: this.productData, divisionData: this.divisionData, commodityData: this.commodityData, summaryData: this.summaryData};
        console.log(JSON.stringify(data));
        this.isLoading = true;
        //console.log(data);
        saveOrder({
            orderId: (this.recordId && this.originScreen.includes('Order')) ? this.recordId : null,
            cloneOrder: this.cloneData.cloneOrder,
            data: JSON.stringify(data),
            typeOrder: mode
        })
        .then((result) => {
            console.log(JSON.stringify(result));
            result = JSON.parse(result);

            if(!result.hasError){
                this.showNotification(result.message, 'Sucesso', 'success');
              
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.orderId,
                        objectApiName: 'Order',
                        actionName: 'view'
                    }
                });
               
            }
            else
                this.showNotification(result.message, 'Algo de errado aconteceu','erro');

            this.isLoading = false;
        }).catch((err)=>{
            console.log(JSON.stringify(err));
            this.showNotification(err.message, 'Aconteceram alguns erros', 'error');
            this.isLoading = false;
        });
    }

    _setAccountData(event) {
        try {
            if(event.data.Id != this.accountData.id){
                this.headerData.cliente_entrega = " "
                this.headerData.ctv_venda = " "
                this.headerData.status_pedido = "Em digitação"
            }
            this.accountData = event.data;

            console.log('account data setted:', this.accountData);
        } catch (e) {
            console.log(e);
        }
        this.enableNextScreen();
        this.completeCurrentScreen();
    }

    _setHeaderData(event) {
        this.headerData = event.data;
        if(this.headerData.IsOrderChild) this.getOrderMother(this.headerData.pedido_mae.Id, this.headerData.pedido_mae.Name);
        console.log('header data setted:', this.headerData);
        this.enableNextScreen();
        this.completeCurrentScreen();
    }

    _setProductData(event) {
        this.productData = event.data;
        console.log('this.productData: ' + this.productData);
        console.log('acproductcount data setted:', this.productData, event.detail, event.data, event);
        //this.qtdItens = this.productData.length;
        this.enableNextScreen();
        this.completeCurrentScreen();
    }

    _setDivisionData(event) {
        this.divisionData = event.data;
    }

    _setCommodityData(event) {
        this.commodityData = event.data;
    }

    _setSummaryData(event) {
        this.summaryData = event.data;
        console.log('summary data setted:', this.summaryData);
        this.enableNextScreen();
    }

    //c/orderScreenNavbar
    changeStyle() {
        for (var index = 0; index < this.tabs.length; index++) {
            const element = this.tabs[index];
            let tab = this.template.querySelector(`[data-tab-name="${element.name}"]`);
            if(tab){
                if (element.enable === true && element.current === false)
                    tab.className = 'succeed';
                else if (element.enable === true && element.current === true)
                    tab.className = 'current';
                else if (element.enable === false && element.current === false)
                    tab.className = '';

                if (element.completed === true){
                    let inputCheck = this.template.querySelector(`[data-tab-name="${element.name}"] input[type="checkbox"]`);
                    if(inputCheck)
                        this.template.querySelector(`[data-tab-name="${element.name}"] input[type="checkbox"]`).checked = true;
                }
            }
        }
    }

    checkPreviousNextBtn() {
        let previousTab = this.template.querySelector('[data-tab="previous"]');
        let nextTab = this.template.querySelector('[data-tab="next"]');
        if(previousTab && nextTab){
            if (this.currentTab == 0) {
                nextTab.className = 'next';
                previousTab.className = 'previous disabled';
            } else if (this.currentTab == 3) {
                nextTab.className = 'next disabled';
                previousTab.className = 'previous';
            } else {
                nextTab.className = 'next';
                previousTab.className = 'previous';
            }
        }
    }

    handlePrevious() {
        if (this.currentTab !== 0) {
            if (this.tabs[this.currentTab - 1].enable == true) {
                this.tabs[this.currentTab].current = false;
                this.currentTab = this.currentTab - 1;
                this.tabs[this.currentTab].current = true;
                this.changeTab();
                this.changeStyle();
            } else {
                this.showNotification(this.tabs[this.currentTab].message, 'Não é possível voltar uma etapa');
            }
        }
    }

    handleNext() {
        if (this.currentTab !== 3) {
            if (this.tabs[this.currentTab + 1].enable == true) {
                this.tabs[this.currentTab].current = false;
                this.currentTab = this.currentTab + 1;
                this.tabs[this.currentTab].current = true;
                this.changeTab();
                this.changeStyle();
            } else {
                this.showNotification(this.tabs[this.currentTab].message, 'Não é possível avançar uma etapa');
            }
        }
    }

    handleTab(event) {
        console.log('orderScreenData:', this.accountData, this.headerData);
        try {
            if(this.currentTab > event.target.dataset.tab){
                this.handlePrevious();
                return;
            }
            if(this.template.querySelector(this.tabs[this.currentTab].component).verifyMandatoryFields()){
                if (this.tabs[event.target.dataset.tab].enable == true) {
                    this.tabs[this.currentTab].current = false;

                    this.tabs[event.target.dataset.tab].current = true;
                    this.currentTab = parseInt(event.target.dataset.tab);
                    this.changeTab();
                    this.changeStyle();
                } else {
                    this.showNotification(this.tabs[this.currentTab].message, 'Próxima etapa não habilitada');
                }
            }else{
                this.showNotification(this.tabs[this.currentTab].message, 'Próxima etapa não habilitada');
            }
        } catch (e) {
            console.log(e);
        }
    }

    showNotification(message, title, variant = 'warning') {
        const evt = new ShowToastEvent({
            title: title,
            message: `${message}`,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    changeTab() {
        this.checkPreviousNextBtn();
        this.account = false;
        this.header = false;
        this.product = false;
        this.summary = false;

        switch (this.currentTab) {
            case 0:
                this.account = true;
                break;
            case 1:
                this.header = true;
                break;
            case 2:
                this.product = true;
                break;
            case 3:
                this.summary = true;
                break;
        }

    }

    //Funcoes para message
    titleChange(event) {
        this._title = event.target.value;
    }

    messageChange(event) {
        this.message = event.target.value;
    }

    variantChange(event) {
        this.variant = event.target.value;
    }

    enableNextScreen() {
        console.log('enableNextScreen');
        if ((this.currentTab + 1) <= 3) {
            if (this.tabs[this.currentTab + 1].enable == false) {
                this.tabs[this.currentTab + 1].enable = true;
            }
        }
    }

    enableScreens(screens){
        if(screens.length <= 0)
            return;
        for(let index = 0; index < screens.length; index++){
            if (this.tabs[screens[index]].enable == false) {
                this.tabs[screens[index]].enable = true;
            }
        }
    }

    completeScreens(screens) {
        if(screens.length <= 0)
        return;
        for(let index = 0; index < screens.length; index++){
            if (this.tabs[screens[index]].completed == false) {
                this.tabs[screens[index]].completed = true;
            }
        }
    }

    completeCurrentScreen() {
        this.tabs[this.currentTab].completed = true;
    }

    enableAndJumpToNext() {
        this.enableNextScreen();
        this.handleNext();
    }

}