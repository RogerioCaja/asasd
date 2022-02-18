import {
    LightningElement,
    api, track
} from 'lwc';
import NoHeader from '@salesforce/resourceUrl/NoHeader';
import {
    loadStyle,
    loadScript
} from 'lightning/platformResourceLoader';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import saveOrder from '@salesforce/apex/OrderScreenController.saveOrder';
import getOrder from '@salesforce/apex/OrderScreenController.getOrder';
import getAccount from '@salesforce/apex/OrderScreenController.getAccount';

export default class OrderScreen extends LightningElement {
    @api recordId;
    @api originScreen;

    account = true;
    header = false;
    product = false;
    @track summary = false;

    @track accountData;
    @track headerData;
    @track productData;
    @track summaryData;

    qtdItens = 0;
    valorTotal = 0;
    frete = '';

    currentTab = 0;

    isLoading = false;

    tabs = [{
            name: 'account',
            current: true,
            enable: false,
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
            enable: true,
            completed:false,
            message: 'Necessário selecionar pelo menos 1 produto',
            component: 'c-order-product-screen'
        },
        {
            name: 'summary',
            current: false,
            enable: true,
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
        console.log(this.recordId, this.originScreen);

    }

    getAccount(){
        console.log('getAccount');
        if(this.accountData)
            return;
            
        this.isLoading = true;
        getAccount({recordId: this.recordId})
        .then((result) =>{
            const account = JSON.parse(JSON.stringify(result));
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
        if(this.headerData)
            return;

        this.isLoading = true;
        getOrder({recordId: this.recordId})
        .then((result) =>{
            const data = JSON.parse(result);
            this.accountData = data.accountData;
            this.headerData = data.headerData;
            this.enableScreens([0, 1]);
            this.completeScreens([0, 1]);
            this.isLoading = false;
        })
        .catch((err)=>{
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
/*
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
    async saveOrder(){
        await this.recordId;
        const data = {accountData: this.accountData, headerData: this.headerData};
        this.isLoading = true;

        saveOrder({orderId: (this.recordId && this.originScreen.includes('Order')) ? this.recordId : null, 
                    data: JSON.stringify(data)})
        .then((result) => {

            result = JSON.parse(result);

            if(result.hasError)
                this.showNotification(result.message, 'Sucesso', 'success');
            else
                this.showNotification(result.message, 'Algo de errado aconteceu','erro');

            this.isLoading = false;
        }).catch((err)=>{
            this.showNotification(err.message, 'Aconteceram alguns erros', 'error');
            this.isLoading = false;
        });
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
        console.log('acproductcount data setted:', this.productData, event.detail, event.data, event);
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
        if ((this.currentTab + 1) < 3) {
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