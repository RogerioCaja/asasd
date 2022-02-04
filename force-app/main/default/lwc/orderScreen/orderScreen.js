import { LightningElement, api  } from 'lwc';
import NoHeader from '@salesforce/resourceUrl/NoHeader';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class OrderScreen extends LightningElement {
    account = true;
    header = false;
    product = false;
    summary = false;

    connectedCallback() {
        //Importando estilo para esconder header padrão de página
        loadStyle(this, NoHeader)
    }

    setTabs(event){
        [this.account, this.header, this.product, this.summary] = event.tabs;
    }

}