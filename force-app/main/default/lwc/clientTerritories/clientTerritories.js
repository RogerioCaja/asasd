import { LightningElement, track, api}from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import CTV_OBJECT from '@salesforce/schema/User';
import CTV_NAME from '@salesforce/schema/User.Name';

import TERRITORY_OBJECT from '@salesforce/schema/Territory2';
import TERRITORY_NAME from '@salesforce/schema/Territory2.Name';


import realizeTransaction from '@salesforce/apex/ClientTerritoryController.realizeTransaction';

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

    isLoading = false;
    columns = columns;
    flag= true;
    openModal = false;
    openModalAddOrRemove = false;
    isRemoved = false;
    valval = 'utility:close';
    enableLoad = 'Não há mais Registros para serem carregados';
    territorySelected;
    territories = [];
    accountsCodes = [];
    @api territoryParams = {
        territory: '',
        ctv: '',
        offSet: 0,
        option: 'add'
    }
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
        this.modifyStyle()
    }

    modifyStyle(){
        var field2 = 'object-territory-search'
        setTimeout(() => {
            this.template.querySelector(`[data-target-id="${field2}"]`).percentage = 15;
            
        })
    }
    selectItemRegister(event){
        const { record } = event.detail;
        if(event.target.dataset.targetId == 'territory_selected'){
            this.territorySelected = {Id: record.Id, Name: record.Name};
        }else{
            this.territoryParams[event.target.dataset.targetId] = record.Id;
        }
        
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
                this.valval = 'utility:close'
                this.enableLoad = 'Não há mais Registros para serem carregados'
            })
            this.territoryParams.offSet = 0;
        }
    }

    showResults(event){
        var field2 = 'show-more'
        
        if(this.territoryParams.offSet == 0)  {
                setTimeout(() => {
                this.template.querySelector(`[data-target-id="${field2}"]`).disabled = false
                this.valval = 'utility:jump_to_bottom'
                this.enableLoad = 'Mais registros'
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

    openModalScreen(){
        this.territories = [];
        this.accountsCodes = [];
        var selectedRows = this.template.querySelector("lightning-datatable").getSelectedRows();

        if(selectedRows.length == 0){
            this.showToast('warning', 'Atenção', 'Selecione pelo menos uma conta')
            return;
        }
        selectedRows.forEach((key) => {
            if(!this.territories.includes(key.territoryName))
                this.territories.push(key.territoryName)
            if(!this.accountsCodes.includes(key.accountCode))
                this.accountsCodes.push(key.accountCode)
        })
        if(this.territoryParams.option == 'remove') this.isRemoved = true; else this.isRemoved = false;
        if(this.territoryParams.option == 'add' || this.territoryParams.option == 'remove') this.openModalAddOrRemove = true;
        else this.openModal = true;
    }

    cancel(){
        this.openModal = false;
        this.openModalAddOrRemove = false;
    }

    onChangeOption(event){
        this.territoryParams.option = event.target.value;
    }

    onSave(){
        try{
            let shouldContinue = true;
            this.isLoading = true;
            if(!this.territorySelected && this.territoryParams.option != 'remove'){
                this.showToast('warning', 'Atenção', 'Selecione o território de destino')
                this.isLoading = false;
                return;
            }

            if(this.territoryParams.option != 'remove'){
                this.territories.forEach((terr) => {
                    if(this.territorySelected.Name == terr){
                        this.showToast('warning', 'Atenção', 'Não é possível adicionar/remover no território atual da conta')
                        shouldContinue = false;
                        this.isLoading = false;
                    }
                })
            }
            
            if(!shouldContinue) return;
            realizeTransaction({
                data: JSON.stringify({accountCodes: this.accountsCodes, territoryName: this.territories, territoryToGo: this.territorySelected.Id, action: this.territoryParams.option})
            }).then((result) => {
                console.log(JSON.stringify(result))
                if(result.status == true){
                    this.showToast('success', 'Sucesso', 'Ação realizada com Sucesso');
                    this.datas = []
                    this.territoryParams.offSet = 0
                    this.showMore();
                }else{
                    this.showToast('error', 'Erro', result.message);
                }
                this.cancel()
                this.isLoading = false;
            })
            this.isLoading = false;
        }catch(err){
            console.log(err)
            this.isLoading = false;
        }

    }

    isFilled(field) {
        return ((field !== undefined && field != null && field != '') || field == 0 || field == []);
    }

    showToast(type, title, message) {
        let event = new ShowToastEvent({
            variant: type,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }
}