import { LightningElement, track, api } from 'lwc';

export default class ModalRemessa extends LightningElement {
        @track isModalOpen = false;
        produto;
        quantidadeRestante = 0;
        remessas;

        @api
        openModal(produto) {
            try{
                console.log('modal remessa', produto);
                this.produto = produto;
                if(this.produto.remessas.length > 0){
                    this.remessas = this.produto.remessas;
                }else{
                    this.remessas = [{
                        index:0,
                        quantidade: 0,
                        data: '02-05-2022'
                    }];
                }
                this.isModalOpen = true;
            }catch(e){
                console.log(e);
                this.isModalOpen = false;
            }
        }

        closeModal() {
            this.isModalOpen = false;
        }
        
        submitDetails() {
            this.isModalOpen = false;
        }

        adicionar(event){

        }

        deletar(event){

        }

        changeQuantity(event){

        }
}