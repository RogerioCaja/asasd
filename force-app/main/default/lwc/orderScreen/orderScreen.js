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
import getOrderByOrderItem from '@salesforce/apex/OrderScreenController.getOrderByOrderItem';
import checkMotherQuantities from '@salesforce/apex/OrderScreenController.checkMotherQuantities';
import { NavigationMixin } from 'lightning/navigation';

export default class OrderScreen extends NavigationMixin(LightningElement) {
    @api recordId;
    @api originScreen;
    @api recordTypeId;
    @api clone;
    @api childOrder;
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

    customErrorMessage = '';

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
        tipo_pedido: " ",
        moeda: " ",
        ctv_venda: " ",
        pedido_mae: {},
        IsOrderChild : false,
        pedido_mae_check : true,
        pre_pedido : false,
        frete: "CIF",
        org: {Name: " "},
        aprovation: " ",
        companyId: null,
        firstTime: true
    };
    @track productData;
    @track divisionData;
    @track commodityData;
    @track summaryData = {
        'observation' : "",
        'billing_sale_observation': ""
    };

    qtdItens = 0;
    @api valorTotal = 0.0;
    frete = '-----';

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
        if(this.originScreen.includes('OrderItem')){
            this.getOrderItem();
        }else if(this.originScreen.includes('Order')){
            if(this.recordId) {
                this.headerData.pedido_mae = this.childOrder ? {Id: this.recordId, Name: ''} : {};
                this.getOrder();
            }
        }
        else if(this.originScreen.includes('Account')){
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

    getOrderItem(){
        console.log('getOrderItem');
        if(this.headerData.Id != " ")
            return;

        this.isLoading = true;
        getOrderByOrderItem({recordId: this.recordId})
        .then((result) =>{
            const data = JSON.parse(result);
            this.accountData = data.accountData;
            this.headerData = data.headerData;

            if (this.childOrder) {
                this.headerData.status_pedido = 'Em digitação'
            }

            this.productData = data.productData;
            this.qtdItens = data.productData.length;
            this.valorTotal = 0;
            try
            {
                this.productData.forEach(product =>{
                    this.valorTotal  += parseFloat(product.totalPrice);
                })
                this.valorTotal = parseFloat(this.valorTotal).toLocaleString("pt-BR", {style:"currency", currency:"BRL"});

            }
            catch(e)
            {
                console.log(e);
            }
           
            this.divisionData = data.divisionData;
            this.summaryData['observation'] = this.headerData.observation;
            this.summaryData['billing_sale_observation'] = this.headerData.billing_sale_observation;
            
            this.isLoading = false;
            this.cloneData.cloneOrder = this.clone.cloneOrder;
            if(this.cloneData.cloneOrder){
                this.headerData.ctv_venda.Id = null;
                this.headerData.status_pedido = 'Em digitação';
                this.headerData.cliente_entrega.Id = null;
                this.enableScreens([0, 1]);
                this.completeScreens([0]);
            }else{
                this.enableScreens([0, 1, 2, 3]);
                this.completeScreens([0, 1, 2, 3]);
            }
            this.headerData.condicao_venda = this.headerData.condicao_venda != null ? this.headerData.condicao_venda : ' ';
            
            if (this.childOrder) {
                if (!this.headerData.pedido_mae_check) {
                    this.showNotification('Só é possível gerar pedidos filhos a partir de um pedido mãe', 'Atenção!', 'warning');
                    this.redirectToOrder();
                } else if (this.headerData.codigo_sap == undefined || this.headerData.codigo_sap == null || this.headerData.codigo_sap == '') {
                    this.showNotification('Só é possível gerar pedidos filhos após o pedido ser integrado com o SAP', 'Atenção!', 'warning');
                    this.redirectToOrder();
                } else {
                    checkMotherQuantities({orderId: this.recordId})
                    .then((motherResult) =>{
                        if (!motherResult) {
                            this.showNotification('Todos os produtos já foram distribuídos', 'Atenção!', 'warning');
                            this.redirectToOrder();
                        } else {
                            let availableProducts = [];
                            for (let index = 0; index < this.productData.length; index++) {
                                if (this.productData[index].quantity > 0) {
                                    availableProducts.push(this.productData[index]);
                                }
                            }
                            this.productData = JSON.parse(JSON.stringify(availableProducts));
                            console.log('this.productData: ' + JSON.stringify(this.productData));
                        }
                    })
                }
            }
            // this.cloneData.pricebookListId = this.headerData.condicao_venda != ' ' ?  this.headerData.condicao_venda.Id : '';
        })
        .catch((err)=>{
            console.log(err);
            this.showNotification(err.message, 'Ocorreu algum erro');
            this.isLoading = false;
        })
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

            if (this.childOrder) {
                this.headerData.status_pedido = 'Em digitação'
            }

            this.productData = data.productData;
            this.qtdItens = data.productData.length;
            this.valorTotal = 0;
            try
            {
                this.productData.forEach(product =>{
                    this.valorTotal  += parseFloat(product.totalPrice);
                })
                this.valorTotal = parseFloat(this.valorTotal).toLocaleString("pt-BR", {style:"currency", currency:"BRL"});

            }
            catch(e)
            {
                console.log(e);
            }
           
            this.divisionData = data.divisionData;
            this.summaryData['observation'] = this.headerData.observation;
            this.summaryData['billing_sale_observation'] = this.headerData.billing_sale_observation;
            this.isLoading = false;
            this.cloneData.cloneOrder = this.clone.cloneOrder;
            if(this.cloneData.cloneOrder){
                this.headerData.ctv_venda.Id = null;
                this.headerData.status_pedido = 'Em digitação';
                this.headerData.cliente_entrega.Id = null;
                this.enableScreens([0, 1]);
                this.completeScreens([0]);
            }else{
                this.enableScreens([0, 1, 2, 3]);
                this.completeScreens([0, 1, 2, 3]);
            }
            this.headerData.condicao_venda = this.headerData.condicao_venda != null ? this.headerData.condicao_venda : ' ';
            
            if (this.childOrder) {
                if (!this.headerData.pedido_mae_check) {
                    this.showNotification('Só é possível gerar pedidos filhos a partir de um pedido mãe', 'Atenção!', 'warning');
                    this.redirectToOrder();
                } else if (this.headerData.codigo_sap == undefined || this.headerData.codigo_sap == null || this.headerData.codigo_sap == '') {
                    this.showNotification('Só é possível gerar pedidos filhos após o pedido ser integrado com o SAP', 'Atenção!', 'warning');
                    this.redirectToOrder();
                } else {
                    checkMotherQuantities({orderId: this.recordId})
                    .then((motherResult) =>{
                        if (!motherResult) {
                            this.showNotification('Todos os produtos já foram distribuídos', 'Atenção!', 'warning');
                            this.redirectToOrder();
                        } else {
                            let availableProducts = [];
                            for (let index = 0; index < this.productData.length; index++) {
                                if (this.productData[index].quantity > 0) {
                                    availableProducts.push(this.productData[index]);
                                }
                            }
                            this.productData = JSON.parse(JSON.stringify(availableProducts));
                            console.log('this.productData: ' + JSON.stringify(this.productData));
                        }
                    })
                }
            }
            // this.cloneData.pricebookListId = this.headerData.condicao_venda != ' ' ?  this.headerData.condicao_venda.Id : '';
        })
        .catch((err)=>{
            console.log(err);
            this.showNotification(err.message, 'Ocorreu algum erro');
            this.isLoading = false;
        })
    }

    redirectToOrder() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Order',
                actionName: 'view'
            }
        });
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
        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let yyyy = today.getFullYear();
        let currentDate = yyyy + '-' + mm + '-' + dd;

        if (this.headerData.status_pedido == 'Em aprovação - Gerente Filial' || this.headerData.status_pedido == 'Em aprovação - Gerente Regional' ||
            this.headerData.status_pedido == 'Em aprovação - Diretor' || this.headerData.status_pedido == 'Em aprovação - Comitê Margem' || this.headerData.status_pedido == 'Em aprovação - Mesa de Grãos') {
            this.showNotification('O pedido está Em Aprovação, portanto não pode ser alterado', 'Atenção', 'warning');
            return;
        } else if (this.headerData.pre_pedido && event.detail == 'gerarpedido' && this.headerData.condicao_pagamento.CashPayment && this.headerData.data_pagamento != currentDate) {
            this.headerData.condicao_pagamento = {Id: null, Name: null, CashPayment: null};
            this.headerData.data_pagamento = " ";
            this.showNotification('Informe a condição de pagamento novamente', 'Atenção', 'warning');
            return;
        }

        const mode = event.detail;
        await this.recordId;
        const data = {accountData: this.accountData, headerData: this.headerData, productData: this.productData, divisionData: this.divisionData, commodityData: this.commodityData, summaryData: this.summaryData};
        console.log(JSON.stringify(data));
        this.isLoading = true;
        //console.log(data);
        saveOrder({
            orderId: (this.recordId && this.originScreen.includes('Order') && !this.childOrder) ? this.recordId : null,
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
            if(event.data !== undefined && this.accountData != undefined && event.data.Id != this.accountData.id){
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
        this.headerData.IsOrderChild = this.childOrder || this.headerData.tipo_pedido == 'Pedido Filho';
        console.log('header data setted:', this.headerData);
        if(this.headerData.isCompleted){
            this.enableNextScreen();
            this.completeCurrentScreen();
        }
        else{
            this.disableNextScreen();
        }
    }

    _setHeaderValues(event) {
        this.headerData = event.data;
    }

    _setProductData(event) {
        this.productData = event.data;
        this.qtdItens = this.productData.length;
        this.valorTotal = 0;
        try
        {
            this.productData.forEach(product =>{
                this.valorTotal  = parseFloat(this.valorTotal) + parseFloat(product.totalPrice);
            })
            this.valorTotal = parseFloat(this.valorTotal).toLocaleString("pt-BR", {style:"currency", currency:"BRL"});
        }
        catch(e)
        {
            console.log(e);
        }
        
        console.log('this.productData: ' + this.productData);
        console.log('acproductcount data setted:', this.productData, event.detail, event.data, event);
        if (!this.checkProductDivisionAndCommodities()) {
            this.disableNextScreen();
        } else {
            this.enableNextScreen();
            this.completeCurrentScreen();
        }
    }

    checkProductDivisionAndCommodities() {
        let enableScreen = true;
        if (this.headerData.IsOrderChild) {
            for (let index = 0; index < this.productData.length; index++) {
                let productDivisionQuantity = 0;
                for (let i = 0; i < this.divisionData.length; i++) {
                    if (this.divisionData[i].productId == this.productData[index].productId) {
                        productDivisionQuantity += Number(this.divisionData[i].quantity);
                    }
                }

                if (productDivisionQuantity != this.productData[index].quantity) {
                    enableScreen = false;
                    this.customErrorMessage = 'É preciso criar remessa para todos os produtos selecionados';
                    break;
                }
            }
        }
        
        if (this.headerData.tipo_venda == 'Venda Barter' && (this.commodityData == undefined || this.commodityData == null || this.commodityData.length == 0)) {
            enableScreen = false;
            this.customErrorMessage = 'É necessário selecionar uma commodity';
        }

        return enableScreen;
    }

    _setDivisionData(event) {
        this.divisionData = event.data;
        let enableScreen = this.checkProductDivisionAndCommodities();

        if (enableScreen) {
            this.enableNextScreen();
            this.completeCurrentScreen();
        } else {
            this.disableNextScreen();
        }
    }

    _setCommodityData(event) {
        this.commodityData = event.data;
        let enableScreen = this.checkProductDivisionAndCommodities();

        if (enableScreen) {
            this.enableNextScreen();
            this.completeCurrentScreen();
        } else {
            this.disableNextScreen();
        }
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
                if(this.currentTab == 2)
                    this.tabs[this.currentTab].enable = false;
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
            let errorMessage = this.customErrorMessage != '' ? this.customErrorMessage : this.tabs[this.currentTab].message;
            if(this.template.querySelector(this.tabs[this.currentTab].component).verifyMandatoryFields()){
                if (this.tabs[this.currentTab + 1].enable == true) {
                    this.tabs[this.currentTab].current = false;
                    this.currentTab = this.currentTab + 1;
                    this.tabs[this.currentTab].current = true;
                    this.changeTab();
                    this.changeStyle();
                }
                else {
                    this.showNotification(errorMessage, 'Não é possível avançar uma etapa');
                }
            }
            else{
                this.disableNextScreen();
                this.changeStyle();
                this.showNotification(errorMessage, 'Não é possível avançar uma etapa');
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

    disableNextScreen() {
        console.log('disableNextScreen');
        if ((this.currentTab + 1) <= 3) {
            if (this.tabs[this.currentTab + 1].enable == true) {
                this.tabs[this.currentTab + 1].enable = false;
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