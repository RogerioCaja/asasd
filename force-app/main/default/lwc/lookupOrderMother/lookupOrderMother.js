import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ORDER_NUMBER_CLIENT from '@salesforce/schema/Order.CustomerOrderNumber__c';

export default class LookupOrderMother extends LightningElement {

    @api recordId;
    @api selectedRecord = null;
    @api orderList;
	@api disabled = false;
    @track showData = false;
    
    // WIREs
	@wire(getRecord, { recordId: '$recordId', fields: [ORDER_NUMBER_CLIENT] })
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
					Name: fields['CustomerOrderNumber__c'].value,
				};
			}

			let record = this.selectedRecord


			this.dispatchEvent(
				new CustomEvent('selectrecord', {
					detail: {
						record
					}
				})
			);
		}
	}

	handleCloseList(){
		this.showDataMethod();
	}
    selectOrderMother(event) {
		const { value } = event.currentTarget.dataset;
		const record = this.orderList.find(item => item.Id == value);
        

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