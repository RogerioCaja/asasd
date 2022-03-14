import { LightningElement, api, track } from 'lwc';

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
    hasData = true;

    @api accountData;
    @api productData;
    @api summaryData ={
        observation : ""
    };
    
    @api summaryDataLocale = {
        observation : ""
    };
    @api productDataLocale = [];
    @api headerData;
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
        console.log('Header Data');
        console.log(JSON.stringify(this.headerDataTitle));
        console.log('Account Data');
        console.log(JSON.stringify(this.accountData));
        this.summaryDataLocale = {... this.summaryData};
        this.loadData();
    }

    loadData(){
        if(this.productData){
            this.productDataLocale = JSON.parse(JSON.stringify(this.productData));
            console.log(JSON.stringify(this.productDataLocale));
            for(var i= 0; i< this.productDataLocale.length; i++){
                this.productDataLocale[i]['unitPrice'] = this.formatCurrency(this.productDataLocale[i].unitPrice);
                this.productDataLocale[i]['totalPrice']  = this.formatCurrency(this.productDataLocale[i].totalPrice);
                this.productDataLocale[i]['commercialDiscountValue']  =  this.formatCurrency(this.productDataLocale[i].commercialDiscountValue);
                this.productDataLocale[i]['commercialDiscountPercentage']  =  this.formatPercent(this.productDataLocale[i].commercialDiscountPercentage);
                this.productDataLocale[i]['commercialMarginPercentage']  = this.formatPercent( this.productDataLocale[i].commercialMarginPercentage);
            }
        }
    }

    formatCurrency(num){
        try{
            return parseFloat(num).toLocaleString("pt-BR", {style:"currency", currency:"BRL"});
        }
        catch(err){
            console.log(err);
        }
    }

    formatPercent(num){
        try{
            if(num.toString().indexOf('%') != -1)
                num = num.toString().split('%')[0];
            return Number(num/100).toLocaleString(undefined,{style: 'percent', minimumFractionDigits:2});
        }
        catch(err){
            console.log(err);
        }
        //num = parseFloat(num).toFixed()+'%';

    }

    changeObservation(event){
        this.summaryDataLocale.observation = event.target.value;
        const setSummaryData = new CustomEvent('setsummarydata');
        setSummaryData.data = this.summaryDataLocale;
      
        this.dispatchEvent(setSummaryData);
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