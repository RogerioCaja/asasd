import { LightningElement, api } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import createPhoto from '@salesforce/apex/PhotosToReportController.createPhoto'

export default class AddNewPhotosToReport extends LightningElement {
    @api recordId;
    url = 'data:image/png;base64,'
    urlValue;
    showSpinner = false;
    observation= '';
    preview = false;
    fieldData = [];

    get acceptedFormats() {
        return ['.pdf', '.png', 'jpg'];
    }

    openfileUpload(event){
        const file = event.detail.files[0]
        
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            let fileData = [{
                'filename': file.name,
                'base64': base64,
                'url' : this.url + base64
            }]
            this.fieldData = fileData
        }
        reader.readAsDataURL(file)
    }

    handlePreview(event){
        this.preview = true;
        this.urlValue = event.currentTarget.dataset.id
    }

    handleDeleteImage(event){
        const itemToRemove = this.fieldData.find(element => element.url == event.currentTarget.dataset.id)
        this.fieldData =this.fieldData.filter(function(item) {
            return item !== itemToRemove
        })
    }

    handleTyping(event){
        this.observation = event.target.value
    }
    
    handleClick(){
       
        // setTimeout(() => {
        //     this.onSave();
        //     }, 500);
        this.onSave();
    }

    onSave(){
        this.showSpinner = true;
        
        console.log(this.fieldData.length)
        if(this.observation && !(this.fieldData.length == 0)){
            const{filename, base64} = this.fieldData[0]
            createPhoto({
                base64: base64,
                filename: filename, 
                rtrId: this.recordId,
                observation: this.observation 
            }).then((result) =>{
                if(result == null){
                    this.showSpinner = false;
                    this.showToast('error', 'Erro', 'Algum erro aconteceu')
                }else{
                    this.showSpinner = false;
                    this.showToast('success', 'Sucesso', 'O Arquivo de Foto foi criado')
                    window.location.reload()
                }
            })
        }else{
            this.showToast('error', 'Erro', 'Necessário preencher todos os campos')
            this.showSpinner = false;
        }
    }
    cancel(){
        this.preview = false;
    }

    showToast(type, title, message) {
        let event = new ShowToastEvent({
            variant: type,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }
}