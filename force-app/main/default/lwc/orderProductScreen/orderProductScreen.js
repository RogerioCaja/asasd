import {
    LightningElement,
    api
} from 'lwc';

const actions = [{
        label: 'Adicionar remessa',
        name: 'adicionar_remessa'
    },
    {
        label: 'Remover',
        name: 'delete'
    }
];
export default class OrderProductScreen extends LightningElement {
    products = [{
        'Id': '1',
        'Name': 'Produto 1',
        'unidade': 'LITROS',
        'preco_unitario': 0,
        'quantidade': 3000,
        'preco_total': 0,
        'percentual_desconto_comercial': 0,
        'valor_desconto_comercial': 0,
        'percentual_acrescimo_financeiro': 0,
        'remessas': []
    }, {
        'Id': '2',
        'Name': 'Produto 2',
        'unidade': 'KG',
        'preco_unitario': 0,
        'quantidade': 200,
        'preco_total': 0,
        'percentual_desconto_comercial': 0,
        'valor_desconto_comercial': 0,
        'percentual_acrescimo_financeiro': 0,
        'remessas': [{
                'index':0,
                'data': '02-05-2022',
                'quantidade': 150
            },
            {
                'index':1,
                'data': '28-05-2022',
                'quantidade': 50
            }
        ]
    }];

    message = false;

    showList = true;

    selectedProducts;

    columns = [{
            label: 'Name',
            fieldName: 'Name',
            type: 'text'
        },
        {
            label: 'Unidade',
            fieldName: 'unidade',
            type: 'text',
            hideDefaultActions: true,
        },
        {
            label: 'Preço Un.',
            fieldName: 'preco_unitario',
            type: 'number',
            typeAttributes: {
                currencyCode: 'BRL',
                step: '0.001'
            },
            editable: true,
            hideDefaultActions: true,
        },
        {
            label: 'Quantidade',
            fieldName: 'quantidade',
            type: 'number',
            cellAttributes: {
                iconName: {
                    fieldName: 'trendIcon'
                },
                iconPosition: 'right',
            },
            editable: true,
            hideDefaultActions: true,
        },
        {
            label: 'Preço Total',
            fieldName: 'preco_total',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'BRL',
                step: '0.001'
            },
            editable: true,
            hideDefaultActions: true,
        },
        {
            label: 'Percentual Desc. Comercial',
            fieldName: 'percentual_desconto_comercial',
            type: 'percent',
            editable: true,
            hideDefaultActions: true,
        },
        {
            label: 'Valor Desc. Comercial',
            fieldName: 'valor_desconto_comercial',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'BRL',
                step: '0.001'
            },
            editable: true,
            hideDefaultActions: true,
        },
        {
            label: 'Percentual Acrésc. Financeiro',
            fieldName: 'percentual_acrescimo_financeiro',
            type: 'text',
            hideDefaultActions: true,
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: actions,
                menuAlignment: 'right',
                hideDefaultActions: true,
            }
        }
    ];

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'adicionar_remessa':
                this.template.querySelector('c-modal-remessa').openModal(row);
                break;
            case 'delete':
                const rows = this.products;
                const rowIndex = rows.indexOf(row);
                rows.splice(rowIndex, 1);
                this.products = rows;
                break;
        }
    }

    getFieldsValueProduct() {

    }

    getSelectedName(event){
        this.selectedProducts =  event.detail.selectedRows;
        console.log(JSON.parse(JSON.stringify(this.selectedProducts)));
    }

    @api
    _verifyFieldsToSave() {
        if (this.verifyMandatoryFields()) {
            this._setData();
            return true;
        }
        return false;
    }

    @api
    verifyMandatoryFields() {
        if (this.products !== undefined) {
            return true;
        }
        return false;
    }

    _setData() {
        const setHeaderData = new CustomEvent('setproductdata');
        setHeaderData.data = this.products;
        this.dispatchEvent(setHeaderData);
    }

    showResults(event){
        console.log('showResults');
        this.showList = event.showResults;
        this.products = event.results;
        this.message = event.message;
    }

}