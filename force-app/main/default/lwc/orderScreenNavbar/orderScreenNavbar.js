import {
    LightningElement,
    api
} from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderScreenNavbar extends LightningElement {
    currentTab = 0;
    @api tabs;
    @api clickedTab;

    tabs = [{
            name: 'account',
            current: true,
            enable: true,
            message: 'Necessário selecionar pelo menos uma conta'
        },
        {
            name: 'header',
            current: false,
            enable: false,
            message: 'Necessário preencher todos os dados obrigatórios antes de seguir'
        },
        {
            name: 'product',
            current: false,
            enable: false,
            message: 'Necessário selecionar pelo menos 1 produto'
        },
        {
            name: 'summary',
            current: false,
            enable: false,
            message: ''
        }
    ];

    //Variaveis para mensagem
    _title = 'Operação inválida';
    message = 'Sample Message';
    variant = 'warning';
    variantOptions = [
        { label: 'error', value: 'error' },
        { label: 'warning', value: 'warning' },
        { label: 'success', value: 'success' },
        { label: 'info', value: 'info' },
    ];

    renderedCallback() {
        this.checkPreviousNextBtn();
        this.changeStyle();
    }

    changeStyle() {
        for(var index = 0; index < this.tabs.length; index++) {
            const element = this.tabs[index];

            if (element.enable === true && element.current === false)
               this.template.querySelector(`[data-tab-name="${element.name}"]`).className = 'succeed';
            else if (element.enable === true && element.current === true) 
                this.template.querySelector(`[data-tab-name="${element.name}"]`).className = 'current';
            else if(element.enable === false && element.current === false)
                this.template.querySelector(`[data-tab-name="${element.name}"]`).className = '';

            if(element.completed === true)
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
                this.tabs[this.currentTab ].current = true;
                this.changeTab();
                this.changeStyle();
            }else{
                this.showNotification(this.tabs[this.currentTab].message);
            }
        }
    }

    handleNext() {
        if (this.currentTab !== 3) {
            if (this.tabs[this.currentTab + 1].enable == true) {
                this.tabs[this.currentTab].current = false;
                this.currentTab = this.currentTab + 1;
                this.tabs[this.currentTab ].current = true;
                this.changeTab();
                this.changeStyle();
            }else{
                this.showNotification(this.tabs[this.currentTab].message);
            }
        }
    }

    handleTab(event) {
        if (this.tabs[event.target.dataset.tab].enable == true) {
            this.tabs[this.currentTab].current = false;

            this.tabs[event.target.dataset.tab].current = true;
            this.currentTab = parseInt(event.target.dataset.tab);
            this.changeTab();
            this.changeStyle();
        }else{
            this.showNotification(this.tabs[this.currentTab].message);
        }
    }

    showNotification(message){
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

        const tabEvent = new CustomEvent("changetab");
        tabEvent.tabs = [this.account, this.header, this.product, this.summary];
        this.dispatchEvent(tabEvent);

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

    @api
    enableNextScreen(){
        console.log('enableNextScreen');
        console.log(this.currentTab + 1);
        console.log((this.currentTab + 1) < 3);
        if((this.currentTab + 1) < 3){
            console.log('enableNextScreen if 1');
            if(this.tabs[this.currentTab + 1].enable == false){
                console.log('enableNextScreen if 2');
                this.tabs[this.currentTab + 1].enable = true;
            }
        }
    }

    @api
    completeCurrentScreen(){
        this.tabs[this.currentTab].completed = true;
    }

    enableAndJumpToNext(){
        this.enableNextScreen();
        this.handleNext();
    }

    
}