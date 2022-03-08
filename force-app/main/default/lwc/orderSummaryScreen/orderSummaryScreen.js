import { LightningElement, api } from 'lwc';

const columns = [
    { label: 'Nome do Produto', fieldName: 'productName' },
    { label: 'Unidade de Medida', fieldName: 'unitMeasure'},
    { label: 'Preço Unitário', fieldName: 'unitPrice', type: 'currency' },
    { label: 'Quantidade', fieldName: 'quantity', type: 'number' },
    { label: 'Preço Total', fieldName: 'totalAMount', type: 'currency' },
    {   label: 'Percentual Desconto Comercial',
        fieldName: 'comercialDiscountPercent',
        type: 'percent', 
        typeAttributes: {
            step: '0.00001',
            minimumFractionDigits: '2',
            maximumFractionDigits: '3',
        }, 
    },
    { label: 'Valor Desconto Comercial', fieldName: 'comercialDiscountValue', type: 'currency' },
    {   label: 'Percentual Acréscimo Financeiro', 
        fieldName: 'FinancialAggregatePercent',
        type: 'percent',
        typeAttributes: {
            step: '0.00001',
            minimumFractionDigits: '2',
            maximumFractionDigits: '3',
        }, 
    },
    { label: 'Valor Acréscimo Financeiro', fieldName: 'FinancialAggregateValue', type: 'currency' },
    { label: 'Remessas', fieldName: 'shipping', type: 'url',
        typeAttributes: { 
            label : 'Remessa'
        }
    },
];

export default class OrderSummaryScreen extends LightningElement {
    columns = columns;
    staticValue = 'hidden';

    @api accountData;
    @api productData;
    @api headerDataTitle;
    @api _data = [{
        productName:'Semente de Soja',
        unitMeasure:'Kilogramas',
        unitPrice: 4.12,
        quantity:3,
        totalAMount:3.00,
        comercialDiscountPercent:0.03,
        comercialDiscountValue:3.00,
        FinancialAggregatePercent:0.03,
        FinancialAggregateValue:102.67,
        
        shipping: 'TESTE.COM' 


    },
    {
        productName:'Semente de Algodão',
        unitMeasure:'Kilogramas',
        unitPrice:10256214.12,
        quantity:1.5,
        totalAMount:4.00,
        comercialDiscountPercent:0.03,
        comercialDiscountValue:3.00,
        FinancialAggregatePercent:0.03,
        FinancialAggregateValue:102.67,
        shipping:'/lightning/r/Remessas/REM01029/view',

    },
    {
        productName:'Fertilizante geral',
        unitMeasure:'Litros',
        unitPrice:10.00,
        quantity:0.5,
        totalAMount:4.00,
        comercialDiscountPercent:0.005,
        comercialDiscountValue:0.5,
        FinancialAggregatePercent:0.005,
        FinancialAggregateValue:36.00,
        shipping:'/lightning/r/Remessas/REM01029/view',

    },];

                
    connectedCallback(){
        console.log(JSON.stringify(this.productData));
        console.log(JSON.stringify(this.headerDataTitle));
    }    
        
    @api showandHiddenTextArea(){
        let values;
        let buttons;
        values = this.template.querySelectorAll('textarea');
        buttons = this.template.querySelectorAll('button');

        if(this.staticValue == 'hidden'){
            this.staticValue = "visible"
            values[0].style.visibility = this.staticValue;
            buttons[0].style.setProperty("-webkit-transform", "rotate(-180deg)", null);
            buttons[0].style.setProperty("transition-duration", "1s", null);
        }
        else{
            this.staticValue = "hidden"
            values[0].style.visibility = this.staticValue;
            buttons[0].style.setProperty("-webkit-transform", "rotate(0deg)", null);
        }
    }
  

    
}