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
    @api totalNumberOfRows = 5000;
    headerData = {
        territory: '',
        ctv: '',
        option: ''
    }
    datas = [{
        
        accountName: 'A',
        accountCode: 'A',
        actualCTV: 'A',
        territoryName: 'A',
        territoryFatherName: 'A',
        
    },
    {
        
        accountName: 'A',
        accountCode: 'A',
        actualCTV: 'A',
        territoryName: 'A',
        territoryFatherName: 'A',
        
    },
    {
        
        accountName: 'B',
        accountCode: 'B',
        actualCTV: 'B',
        territoryName: 'B',
        territoryFatherName: 'B',
        
    },
    {
        
        accountName: 'C',
        accountCode: 'C',
        actualCTV: 'C',
        territoryName: 'C',
        territoryFatherName: 'C',
        
    },
    {
        
        accountName: 'D',
        accountCode: 'D',
        actualCTV: 'D',
        territoryName: 'D',
        territoryFatherName: 'D',
        
    },
    {
        
        accountName: 'E',
        accountCode: 'E',
        actualCTV: 'E',
        territoryName: 'E',
        territoryFatherName: 'E',
        
    },
    {
        
        accountName: 'F',
        accountCode: 'F',
        actualCTV: 'F',
        territoryName: 'F',
        territoryFatherName: 'F',
        
    },
    {
        
        accountName: 'G',
        accountCode: 'G',
        actualCTV: 'G',
        territoryName: 'G',
        territoryFatherName: 'G',
        
    },
    {
        
        accountName: 'H',
        accountCode: 'H',
        actualCTV: 'H',
        territoryName: 'H',
        territoryFatherName: 'H',
        
    },
    ]

    value = 'add';

    loadMoreData(event) {
        //Display a spinner to signal that data is being loaded
        // event.target.isLoading = true;
        // //Display "Loading" when more data is being loaded
        // this.loadMoreStatus = 'Loading';
        // fetchData(50).then((data) => {
        //     if (data.length >= this.totalNumberOfRows) {
        //         event.target.enableInfiniteLoading = false;
        //         this.loadMoreStatus = 'No more data to load';
        //     } else {
        //         const currentData = this.datas;
        //         //Appends new data to the end of the table
        //         const newData = currentData.concat(data);
        //         this.datas = newData;
        //         this.loadMoreStatus = '';
        //     }
        //     event.target.isLoading = false;
        // });
    }
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

    onNextPage(){
        this.datas = [{
        
            accountName: 'Z',
            accountCode: 'Z',
            actualCTV: 'Z',
            territoryName: 'Z',
            territoryFatherName: 'Z',
            
        }]
    }
}