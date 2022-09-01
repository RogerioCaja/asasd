import { LightningElement, track, api}from 'lwc';

import CTV_OBJECT from '@salesforce/schema/User';
import CTV_NAME from '@salesforce/schema/User.Name';

import TERRITORY_OBJECT from '@salesforce/schema/Territory2';
import TERRITORY_NAME from '@salesforce/schema/Territory2.Name';

import NoHeader from '@salesforce/resourceUrl/NoHeader';
import {
    loadStyle,
    loadScript
} from 'lightning/platformResourceLoader';

const columns = [
    { label: 'Nome da Conta', fieldName: 'accountName' },
    { label: 'Código SAP da Conta', fieldName: 'accountCode' },
    { label: 'CTV Atual', fieldName: 'actualCTV' },
    { label: 'Nome do Território', fieldName: 'territoryName' },
    { label: 'Nome do Território Pai', fieldName: 'territoryFatherName' },
];
export default class ClientTerritories extends LightningElement {
    columns = columns;
    flag= true;
    @api territoryParams = {
        territory: '',
        ctv: '',
        offSet: 0,
        option: 'add'
    }
    oldOffset = 0
    datas = []
    datasReceived = 0;
   
    get options() {
        return [
            { label: 'Adicionar', value: 'add' },
            { label: 'Remover', value: 'remove' },
            { label: 'Adicionar e Remover', value: 'addRemove' },
        ];
    }

    //CTV Venda
     @track redispatchCtvVendaObject = CTV_OBJECT;
     ctv_venda;
     @track redispatchCtvSearchFields = [CTV_NAME];
     @track redispatchCtvVendaListItemOptions = {
         title: 'Name',
         description: 'Name'
     };

    //Territorios
    @track redispatchtTerritoryObject = TERRITORY_OBJECT;
    territory;
    @track redispatchTerritorySearchFields = [TERRITORY_NAME];
    @track redispatchTerritoryListItemOptions = {
        title: 'Name',
        description: 'Name'
    };

    connectedCallback(){
        loadStyle(this, NoHeader)
    }

    selectItemRegister(event){
        const { record } = event.detail;
        this.territoryParams[event.target.dataset.targetId] = record.Id;
    }

    removeItemRegister(event){
        this.territoryParams[event.target.dataset.targetId] = ''
    }

    async showMore(){
        var field = 'object-territory-search';
        var field2 = 'show-more'

        if(this.datas.length != this.datasReceived) this.template.querySelector(`[data-target-id="${field}"]`).fetchData();
        
        if(this.datas.length == this.datasReceived){
            setTimeout(() => {
                this.template.querySelector(`[data-target-id="${field2}"]`).disabled = true
                this.template.querySelector(`[data-target-id="${field2}"]`).innerText = 'Não há mais dados para serem carregados'
            })
            this.territoryParams.offSet = 0;
        }
    }

    showResults(event){
        var field2 = 'show-more'
        
        if(this.territoryParams.offSet == 0)  {
                setTimeout(() => {
                this.template.querySelector(`[data-target-id="${field2}"]`).innerText = 'Mais registros'
                this.template.querySelector(`[data-target-id="${field2}"]`).disabled = false
            })
            this.datas = []
        }
        this.datas = this.datas.concat(event.results.dataList);
        this.datasReceived = event.results.counter;
        this.territoryParams.offSet += 30;
    }

    resetData(event){
        this.datas = [];
        this.territoryParams.offSet = 0;
    }
}