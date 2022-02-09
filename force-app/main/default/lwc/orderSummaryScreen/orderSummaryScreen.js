import { LightningElement, api } from 'lwc';

const columns = [
    { label: 'Nome do Produto', fieldName: 'productName' },
    { label: 'Unidade de Medida', fieldName: 'unitMeasure'},
    { label: 'Preço Unitário', fieldName: 'unitPrice', type: 'currency' },
    { label: 'Quantidade', fieldName: 'quantity', type: 'number' },
    { label: 'Preço Total', fieldName: 'totalAMount', type: 'currency' },
    { label: 'Percentual Desconto Comercial', fieldName: 'comercialDiscountPercent', type: 'percent' },
    { label: 'Valor Desconto Comercial', fieldName: 'comercialDiscountValue', type: 'number' },
    { label: 'Percentual Acréscimo Financeiro', fieldName: 'FinancialAggregatePercent', type: 'percent' },
    { label: 'Valor Acréscimo Financeiro', fieldName: 'FinancialAggregateValue', type: 'number' },
    { label: 'Remessas', fieldName: 'shipping', type: 'url' },
];

export default class OrderSummaryScreen extends LightningElement {
    columns = columns;
    @api _data = [{
        productName:'Picanha',
        unitMeasure:'Kg',
        unitPrice:2.00,
        quantity:2,
        totalAMount:4.00,
        comercialDiscountPercent:0.03,
        comercialDiscountValue:3.00,
        FinancialAggregatePercent:0.03,
        FinancialAggregateValue:3.00,
        shipping:'https://jaera.com',

    }];

  

    
}