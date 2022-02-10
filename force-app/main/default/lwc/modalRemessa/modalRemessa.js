import { LightningElement, track, api } from 'lwc';

export default class ModalRemessa extends LightningElement {
        @track isModalOpen = false;
        produtoAtual;
        @api
        openModal(produto) {
            console.log('modal remessa', produto);
            this.produtoAtual = produto;
            this.isModalOpen = true;
        }
        closeModal() {
            this.isModalOpen = false;
        }
        submitDetails() {
            this.isModalOpen = false;
        }
}