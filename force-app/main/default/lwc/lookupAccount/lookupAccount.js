import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import CLIENTE_ENTREGA_NAME from '@salesforce/schema/Account.Name';
// import CLIENTE_ID from '@salesforce/schema/Account.Id';
// import CLIENTE_CNPJ from '@salesforce/schema/Account.CNPJ__c';
// import CLIENTE_CPF from '@salesforce/schema/Account.CPF__c';
// import CLIENTE_UF from '@salesforce/schema/Account.BillingState';
// import CLIENTE_CITY from '@salesforce/schema/Account.BillingCity';
export default class LookupAccount extends LightningElement {
    @api recordId;
    @api selectedRecord = null;
    @api accountList;
    @track showData = false;
    
    // WIREs
	@wire(getRecord, { recordId: '$recordId', fields: [CLIENTE_ENTREGA_NAME] })
	wiredGetRecord({ error, data }) {
		this.isLoading = false;

		if (!this.recordId) {
			this.selectedRecord = null;
			return;
		}

		if (error) {
			//console.log(error);
			return;
		}

		if (data) {
			const { id, fields } = data;

			if (this.levelFieldTitle > 0) {
				var fieldValue = fields[this.listItemOptions.title].value;

				for (let level = 0; level < this.levelFieldTitle; level++) {
					fieldValue = fieldValue.fields[this.fieldTitle[level]].value;
				}

				this.selectedRecord = {
					Id: id,
					title: fieldValue
				};
			} else {
				this.selectedRecord = {
					Id: id,
					Name: fields['Name'].value
				};
			}

			let record = { Id: this.recordId };

			this.dispatchEvent(
				new CustomEvent('selectrecord', {
					detail: {
						record
					}
				})
			);
		}
	}

    selectAccountChild(event) {
		const { value } = event.currentTarget.dataset;
		const record = this.accountList.find(item => item.Id == value);
        

        this.selectedRecord = record;
       
		this.dispatchEvent(
			new CustomEvent('selectrecord', {
				detail: {
					record
				}
			})
		);
        this.showDataMethod();
	}

    showDataMethod(){
        this.showData = !this.showData;
    }

    handleClearSelected(){
        this.selectedRecord = null;
		this.recordId = null;

		this.dispatchEvent(
			new CustomEvent('clearselectedrecord')
		);
    }
}
