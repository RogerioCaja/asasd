import { LightningElement, api} from 'lwc';

export default class OrderAccountResults extends LightningElement {
    @api records = [];
    @api message = false;

    renderedCallback(){}

    selectAccount = (event) => {
        this.changeStyle(event);
        console.log('selectAccount', event.target.dataset.key.toString());
        try{
        const accEv = new CustomEvent('accountSelected');
        accEv.account = event.target.dataset.key.toString();
        console.log('accEv.account',accEv.account);
        this.dispatchEvent(accEv);
        }catch(e){
            console.log(e);
        }
    }

    changeStyle(event){
        let elems = this.template.querySelectorAll('div[data-key]');
        var index = 0, length = elems.length;
        for ( ; index < length; index++) {
            elems[index].classList.remove('accountSelected');
            elems[index].querySelector('.botaoConta button').classList.remove('selected');
        }
        this.template.querySelector(`div[data-key="${event.target.dataset.key.toString()}"]`).classList.add('accountSelected');
        this.template.querySelector(`button[data-key="${event.target.dataset.key.toString()}"]`).classList.add('selected');
    }

}