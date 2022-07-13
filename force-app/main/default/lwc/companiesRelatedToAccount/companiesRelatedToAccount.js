import { LightningElement, api } from 'lwc';
import getCompanies from '@salesforce/apex/CompaniesRelatedToAccountController.getCompanies';

export default class CompaniesRelatedToAccount extends LightningElement {
    @api recordId;
    companies = [];
    showCompanyTable = false;
    columns = [
        {label: 'Empresa', fieldName: 'name'},
        {label: 'Organização de vendas', fieldName: 'salesOrg'},
        {label: 'Escritório de vendas', fieldName: 'salesOffice'},
        {label: 'Equipe de vendas', fieldName: 'salesTeam'},
        {label: 'Setor de atividade', fieldName: 'activitySector'},
        {label: 'Canal distribuição', fieldName: 'distributionChannel'},
        {label: 'Grupo cliente', fieldName: 'clientGroup'},
        {label: 'Centro forncecedor', fieldName: 'supplierCenter'}
    ];

    connectedCallback(event) {
        getCompanies({accountId: this.recordId})
        .then((result) => {
            this.companies = JSON.parse(result);
            this.showCompanyTable = this.companies.length > 0;
            console.log('this.companies: ' + JSON.stringify(this.companies));
        });
    }
}