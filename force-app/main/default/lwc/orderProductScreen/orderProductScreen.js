import { LightningElement, api } from 'lwc';

export default class OrderProductScreen extends LightningElement {
    products = [{
        'Name':'Produto 1',
        'quantidade': 3000,
        'unidade':'LITROS'
    },{
        'Name':'Produto 1',
        'quantidade': 200,
        'unidade':'KG',
        'remessas':[{
            'data_entrega':'02-05-2022',
            'quantidade':150
        },
        {
            'data_entrega':'28-05-2022',
            'quantidade':50
        }]
    }];
     
    getFieldsValueProduct(){

    }

    _verifyFieldsToSave() {
        if (this.products !== null) {
            this._setData();
            return true;
        }
        return false;
    }    
    
    @api
    verifyMandatoryFields() {
        if ( this.products !== null) {
            this._verifyFieldsToSave();
            return true;
        }
        return false;
    }

    _setData() {
        const setHeaderData = new CustomEvent('setproductdata');
        setHeaderData.data = this.products;
        this.dispatchEvent(setHeaderData);
    }

}