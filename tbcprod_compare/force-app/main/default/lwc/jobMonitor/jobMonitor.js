import { LightningElement, api, track, wire } from 'lwc';
import checkBatchStatus from '@salesforce/apex/JobMonitorController.checkBatchStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JobMonitor extends LightningElement {

    // PUBLIC ATTRIBUTES
    @api batchId;

    // PRIVATE ATTRIBUTES
    @track _batchInititated;
    @track _monitorInitiated;
    @track _progress;
    @track _apexJob;
    _hasError;
    _errorMessage;


    /**
    * @description Constructor
    **/
    constructor() {
        super();
        this._batchInititated = true;
        this._monitorInitiated = false;
        this._progress = 0; 
        this._errorMessage = '';
        this._hasError = false;
    }
    
    /**
    * @description connected callback method
    **/
    connectedCallback() {
        if (!this._monitorInitiated) {
            this._monitorInitiated = true;
            this.getStatus();
            var interval = window.setInterval(() => {
                if (this._batchInititated) {
                    this.getStatus();
                } else {
                    window.clearInterval(interval);
                }
                if (this._hasError) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            "message" : this._errorMessage,
                            "variant" : 'error'
                        }),
                    );
                }
            }, 10000);
        }
    }

    /**
    * @description Method to get the job status
    **/
    getStatus() {
        checkBatchStatus({  
            'batchId' : this.batchId
        }).then(result => {
            if (result) {
                this._apexJob = result[0];
                if (result[0].Status == 'Holding') this._progress = 5;
                if (result[0].Status == 'Queued') this._progress = 10;
                if (result[0].Status == 'Preparing') this._progress = 20;
                if (result[0].Status == 'Processing') this._progress = 60;
                if (result[0].Status == 'Completed') {
                    this._progress = 100;
                    this._batchInititated = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            "message" : 'Job has been completed successfully.',
                            "variant" : 'success'
                        }),
                    );
                    this.dispatchEvent(new CustomEvent('jobcompleted'));
                }
            }
        }).catch(error => {
            console.log('Error is '+JSON.stringify(error));
            this.error = error;
        });
    }

    /**
    * @description Method to get the job status
    **/
    get showJobDetail() {
        return this._apexJob;
    }
}