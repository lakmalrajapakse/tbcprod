import { api, wire } from "lwc";
import LightningModal from "lightning/modal";
import { createRecord, updateRecord, getRecord} from "lightning/uiRecordApi";
import { handleTransactionError } from "c/utils";
import PROOF_FIELD from "@salesforce/schema/ContentVersion.Is_Timesheet_Proof_Document__c";
import ID_FIELD from "@salesforce/schema/ContentVersion.Id";
import CONTENTSIZE_FIELD from "@salesforce/schema/ContentVersion.ContentSize";
import CONTENTDOCUMENTID_FIELD from "@salesforce/schema/ContentVersion.ContentDocumentId";

export default class ShiftManagementTimesheetsUpload extends LightningModal {
    MAX_FILE_SIZE = 1048576; //Max file size 1.0 MB 
    @api recordIds;    
    
    contentVersionId;
    contentVersion;
    fileLoaded = true;
    completed = false;

    @wire(getRecord, { recordId: "$contentVersionId", fields: [ID_FIELD,CONTENTSIZE_FIELD,CONTENTDOCUMENTID_FIELD] }) handleGetRecord({data, error}) {
        if (data) {             
            console.log("Content Version : " + JSON.stringify(data));
            this.contentVersion = data;
            if (this.fileLoaded) {
                this._attachingToRecords = true;
                return;
            }
            this.handleFileUpload();
        }

        if (error) {
            handleTransactionError("Upload Load", error);
        }
    }

    _attachingToRecords = false;

    get isLoading() {
        return this._attachingToRecords;
    }

    async handleFileUpload() {
        this.fileLoaded = true;
        try {
            const file = this.contentVersion.fields;

            if (file.ContentSize.value > this.MAX_FILE_SIZE) {
                throw new Error("File size cannot exceed 1.0 MB");
            }
                
            const fields = {};
            fields[ID_FIELD.fieldApiName] = file.Id.value
            fields[PROOF_FIELD.fieldApiName] = true;
            const recordInput = { fields };
            console.log("Record Input : " + JSON.stringify(recordInput));

            await updateRecord(recordInput);
                
            for (let recordId of this.recordIds) {
                let data = {
                    apiName: "ContentDocumentLink",
                    fields: {
                        ContentDocumentId: file.ContentDocumentId.value,
                        LinkedEntityId: recordId,
                        ShareType: "V", // Viewer access
                        Visibility: "AllUsers"
                    }
                };

                await createRecord(data);
            }
            
            this.close({ success: true });
        } catch (ex) {
            handleTransactionError("Upload error", ex);            
        } finally {            
            this._attachingToRecords = false;
        }
    }

    handleAttachmentUpload(event) {
        const uploadedFiles = event.detail.files;
        this.fileLoaded = false;

        if (uploadedFiles.length !== 1)  {
            this._attachingToRecords = true;
            return;
        }
    
        this.contentVersionId = uploadedFiles[0].contentVersionId;                
    }

    handleCancelClick() {
        this.close({ success: false });
    }
}