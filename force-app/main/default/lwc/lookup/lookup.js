import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import getRecords from '@salesforce/apex/Lookup.getRecords';
import fetchAccountRecords from '@salesforce/apex/CustomAccountLookupController.fetchAccountRecords';

export default class Lookup extends LightningElement {
	// APIs
	@api recordId;
	@api targetObject;
	@api searchFields = [];
	@api moreFields = [];
	@api labelNewRecord = 'Criar novo registro';
	@api newRecordButton = false;
	@api noRepeats = 'Id';
	@api required;
	@api disabled;
	@api barterSale;
	@api priceScreen;
	@api safraName = null;
	@api salesType = null;
	@api salesOrg = null;
	@api currencyOption = null;

	@api parentRecordList; // Valor do WHERE =
	@api parentRelationFieldList; // Campo do WHERE =
	@api parentDifferentRecordList; // Valor do WHERE <>
	@api parentDifferentRelationFieldList; // Campo do WHERE <>

	@api objectIconName = 'standard:custom_notification';
	@api inputLabel = 'Selecione um registro';
	@api placeholder = 'Digite para buscar...';

	@api listItemOptions = {
		title: 'Id',
		description: null
	};

	@api standardFormLayout = false;
	@api recordTypeId;
	@api levelFieldTitle = 0;
	@api fieldTitle = [];

	// TRACKs
	@track searchFieldsApiNames = null;
	@track moreFieldsApiNames = null;
	@track searchValue = null;
	@api accountId;
	@track isLoading = true;

	@track records = null;
	@track noRecords = false;
	@track selectedRecord = null;

	@track showCreateRecordForm = false;

	@track allFields;

	// GETs
	get recordsList() {
		if (!this.records) {
			return null;
		}

		let itemsList = this.records.map(record => {
			var title;
			if (this.levelFieldTitle > 0) {
				var fieldValue = record[this.listItemOptions.title];

				for (let level = 0; level < this.levelFieldTitle; level++) {
					fieldValue = fieldValue[this.fieldTitle[level]];
				}

				title = fieldValue;
			} else {
				title = record[this.listItemOptions.title] || record['Id'];
			}

			let description = null;

			if (this.listItemOptions.description) {
				if (typeof this.listItemOptions.description === 'string') {
					description = record[this.listItemOptions.description] || null;
				} else if (this.listItemOptions.description.length > 0) {
					let descriptionValues = [];

					this.listItemOptions.description.forEach(field => {
						if (typeof record[field] != 'undefined' && record[field] != null && record[field] != '') {
							descriptionValues.push(record[field]);
						}
					});

					description = descriptionValues.join(' | ');
				}
			}

			return {
				Id: record.Id,
				title,
				description
			}
		});

		return itemsList;
	}

	// WIREs
	@wire(getRecord, { recordId: '$recordId', fields: '$allFields' })
	wiredGetRecord({ error, data }) {
		this.isLoading = false;

		if (!this.recordId) {
			this.selectedRecord = null;
			return;
		}

		if (error) {
			console.log(error);
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
					title: fields[this.listItemOptions.title].value
				};
			}

			let record = { Id: this.recordId };
			this.allFields.forEach(field => {
				record = {
				...record,
				[field.fieldApiName]: fields[field.fieldApiName]?.value
				}
			})

			this.dispatchEvent(
				new CustomEvent('selectrecord', {
					detail: {
						record
					}
				})
			);
		}
	}

	// METHODs
	connectedCallback() {
		if (this.searchFields) {
			const searchFieldsApiNames = this.searchFields
				.filter(fieldRef => fieldRef.objectApiName === this.targetObject.objectApiName)
				.map(fieldRef => fieldRef.fieldApiName);

			this.searchFieldsApiNames = searchFieldsApiNames;

			const moreFieldsApiNames = this.moreFields
				.filter(fieldRef => fieldRef.objectApiName === this.targetObject.objectApiName)
				.map(fieldRef => fieldRef.fieldApiName);

			this.moreFieldsApiNames = moreFieldsApiNames;
		}

		this.allFields = [...this.searchFields, ...this.moreFields];
	}

	handleTyping(event) {
		const { value } = event.target;

		if (value.length < 0) {
			this.records = null;
			return;
		}

		this.searchValue = value;
		this.isLoading = true;

		this.handleGetRecords();
	}

	async handleGetRecords() {
		let requestData = {
			targetObject: this.targetObject.objectApiName,
			searchFields: this.searchFieldsApiNames,
			searchValue: this.searchValue,
			moreFields: this.moreFieldsApiNames || null,
			accountId: this.accountId
		};

		if (this.parentRelationFieldList && this.parentRecordList) {
			var relationList = [];
			var cont = 0;

			this.parentRelationFieldList.forEach(field => {
				var value = this.parentRecordList[cont];
				relationList = [
					...relationList,
					{
						parentRelationField: field.fieldApiName,
						parentRecord: value,
					}
				];

				cont++;
			});

			requestData = {
				...requestData,
				relations: relationList
			}
		}

		//console.log('this.parentDifferentRelationFieldList =>', this.parentDifferentRelationFieldList ? JSON.parse(JSON.stringify(this.parentDifferentRelationFieldList)) : this.parentDifferentRelationFieldList);
		//console.log('this.parentDifferentRecordList =>', this.parentDifferentRecordList ? JSON.parse(JSON.stringify(this.parentDifferentRecordList)) : this.parentDifferentRecordList);
		if (this.parentDifferentRelationFieldList && this.parentDifferentRecordList) {
			var relationList = [];
			var cont = 0;

			this.parentDifferentRelationFieldList.forEach(field => {
				var value = this.parentDifferentRecordList[cont];
				relationList = [
					...relationList,
					{
						parentRelationField: field.fieldApiName,
						parentRecord: value,
					}
				];

				cont++;
			});

			requestData = {
				...requestData,
				differentRelations: relationList
			}
		}

		try {
			let data;
			if (requestData.targetObject == 'Account') {
				data = await fetchAccountRecords({searchString: requestData.searchValue});
			} else {
				let salesConditionData = {
					salesOrgId: this.salesOrg  != null ? this.salesOrg  : '',
					safraName:  this.safraName != null ?  this.safraName : '',
					currencyGet: this.currencyOption != null ? this.currencyOption : '',
					typeOrder: this.salesType != null ? this.salesType : ''
				}
				data = await getRecords({ data: JSON.stringify(requestData), barterSale: this.barterSale, salesConditionData: JSON.stringify(salesConditionData), priceScreen: this.priceScreen });
			}

			var dataResult = [];
			if (data) {
				data.forEach(element => {
					if (dataResult.length > 0) {
						if (!(dataResult.find(item => item[this.noRepeats] == element[this.noRepeats]))) {
							dataResult = [
								...dataResult,
								element
							];
						}
					} else {
						dataResult = [
							...dataResult,
							element
						];
					}
				});
			}

			if (dataResult) {
				this.records = dataResult.map(item => ({ ...item }));
				this.noRecords = (dataResult.length == 0);
			} else {
				this.records = null;
			}
		} catch (error) {
			//console.log(error);
		} finally {
			this.isLoading = false;
		}
	}

	handleOnFocus() {
		this.handleGetRecords();
		this.focusAnchor();
	}

	handleCloseList() {
		this.records = null;
	}
	focusAnchor() {
		setTimeout(()=>this.template.querySelector('[data-id="list"]').focus());
	  }
	handleSelectRecord(event) {
		const { value } = event.currentTarget.dataset;
		const record = this.records.find(item => item.Id === value);

		var recordTitle;
		if (this.levelFieldTitle > 0) {
			recordTitle = record[this.listItemOptions.title];
			this.fieldTitle.forEach(field => {
				recordTitle = recordTitle[field];
			});
		} else {
			recordTitle = record[this.listItemOptions.title];
		}

		this.selectedRecord = {
			Id: record.Id,
			title: recordTitle
		};

		this.dispatchEvent(
			new CustomEvent('selectrecord', {
				detail: {
					record
				}
			})
		);
	}

	handleClearSelected() {
		this.selectedRecord = null;
		this.recordId = null;

		this.dispatchEvent(
			new CustomEvent('clearselectedrecord')
		);
	}

	@api clearAll() {
		this.selectedRecord = null;
		this.recordId = null;
		this.searchValue = null;
		this.records = null;
	}

	handleToggleCreateRecord() {
		this.showCreateRecordForm = !this.showCreateRecordForm;
		this.scrollToTop();
	}

	scrollToTop() {
		if (!this.desktop) {
			const scrollOptions = {
				left: 0,
				top: 0
			}

			parent.scrollTo(scrollOptions);
		}
	}

	async handleSuccessCreate(event) {
		const { id: recordId } = event.detail;

		this.isLoading = true;
		this.recordId = recordId;

		this.handleToggleCreateRecord();
	}
}
