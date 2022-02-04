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
            enable: true
        },
        {
            name: 'header',
            current: false,
            enable: false
        },
        {
            name: 'product',
            current: false,
            enable: false
        },
        {
            name: 'summary',
            current: false,
            enable: false
        }
    ];

    //Variaveis para mensagem
    _title = 'Sample Title';
    message = 'Sample Message';
    variant = 'error';
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
            if (element.enable === true && element.current === false) {
                this.template.querySelector(`[data-tab-name="${element.name}"]`).className = 'succeed';
                this.template.querySelector(`[data-tab-name="${element.name}"] input[type="checkbox"]`).checked = true;
            }else if (element.enable === true && element.current === true) {
                this.template.querySelector(`[data-tab-name="${element.name}"]`).className = 'current';
            }else if(element.enable === false && element.current === false){
                this.template.querySelector(`[data-tab-name="${element.name}"]`).className = '';
            }
            
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
            this.showNotification();
        }
    }

    showNotification(){
        const evt = new ShowToastEvent({
            title: this._title,
            message: this.message,
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

    showNotification() {
        const evt = new ShowToastEvent({
            title: this._title,
            message: this.message,
            variant: this.variant,
        });
        this.dispatchEvent(evt);
    }
}