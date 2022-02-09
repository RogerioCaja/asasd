import {
    LightningElement,
    api
} from 'lwc';
import NoHeader from '@salesforce/resourceUrl/NoHeader';
import {
    loadStyle,
    loadScript
} from 'lightning/platformResourceLoader';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
//import getOrder from '@salesforce/apex/CustomOrderScreen.getOrder';

export default class OrderScreen extends LightningElement {
    @api recordId;

    account = true;
    header = false;
    product = false;
    summary = false;

    @api accountData;
    @api headerData = {
        'tipo_venda': null,
        'filial': null,
        'cliente_entrega': null,
        'safra': null,
        'cultura': null,
        'lista_precos': null,
        'condicao_pagamento': null,
        'data_pagamento': null,
        'data_entrega': null
    };
    @api productData;
    @api summaryData;

    qtdItens = 0;
    valorTotal = 0;
    frete = '';

    currentTab = 0;

    tabs = [{
            name: 'account',
            current: true,
            enable: true,
            message: 'Necessário selecionar pelo menos uma conta',
            component: 'c-order-account-screen'
        },
        {
            name: 'header',
            current: false,
            enable: true,
            message: 'Necessário preencher todos os dados obrigatórios antes de seguir',
            component: 'c-order-header-screen'
        },
        {
            name: 'product',
            current: false,
            enable: true,
            message: 'Necessário selecionar pelo menos 1 produto',
            component: 'c-order-product-screen'
        },
        {
            name: 'summary',
            current: false,
            enable: true,
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
    }
    /*connectedCallback() {
        this.loadVariable();
    }

    async loadVariable(){
        await this.recordId;
        this.getOrder();
    }

    getOrder(){
        getOrder({orderId: this.recordId})
        .then((result) => {
            result = JSON.parse(result);
            
            this.showSpinner = false;
            this.showLoadingDataMessage = false;

            //Nenhum registro
            if(result.length == 0){
                this.showNoItemsMessage = true;
            }
            //Pelo menos um registro
            else{
                this.data = result;
                this.showItems = true;
            }
        })
    }*/

    connectedCallback() {
        //Importando estilo para esconder header padrão de página
        loadStyle(this, NoHeader);
    }

    _setAccountData(event) {
        try {
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
        console.log('header data setted:', this.headerData);
        this.enableNextScreen();
        this.completeCurrentScreen();
    }

    _setProductData(event) {
        this.productData = event.data;
        console.log('acproductcount data setted:', this.productData);
        this.enableNextScreen();
        this.completeCurrentScreen();
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

            if (element.enable === true && element.current === false)
                this.template.querySelector(`[data-tab-name="${element.name}"]`).className = 'succeed';
            else if (element.enable === true && element.current === true)
                this.template.querySelector(`[data-tab-name="${element.name}"]`).className = 'current';
            else if (element.enable === false && element.current === false)
                this.template.querySelector(`[data-tab-name="${element.name}"]`).className = '';

            if (element.completed === true)
                this.template.querySelector(`[data-tab-name="${element.name}"] input[type="checkbox"]`).checked = true;

        }
    }

    checkPreviousNextBtn() {
        if (this.currentTab == 0) {
            this.template.querySelector('[data-tab="previous"]').className = 'previous disabled';
            this.template.querySelector('[data-tab="next"]').className = 'next';
        } else if (this.currentTab == 3) {
            this.template.querySelector('[data-tab="next"]').className = 'next disabled';
            this.template.querySelector('[data-tab="previous"]').className = 'previous';
        } else {
            this.template.querySelector('[data-tab="next"]').className = 'next';
            this.template.querySelector('[data-tab="previous"]').className = 'previous';
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
                this.showNotification(this.tabs[this.currentTab].message);
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
                this.showNotification(this.tabs[this.currentTab].message);
            }
        }
    }

    handleTab(event) {
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
                    this.showNotification(this.tabs[this.currentTab].message);
                }
            }else{
                this.showNotification(this.tabs[this.currentTab].message);
            }
        } catch (e) {
            console.log(e);
        }
    }

    showNotification(message) {
        const evt = new ShowToastEvent({
            title: this._title,
            message: `${message}`,
            variant: this.variant,
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
        console.log(this.currentTab + 1);
        console.log((this.currentTab + 1) < 3);
        if ((this.currentTab + 1) < 3) {
            console.log('enableNextScreen if 1');
            if (this.tabs[this.currentTab + 1].enable == false) {
                console.log('enableNextScreen if 2');
                this.tabs[this.currentTab + 1].enable = true;
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