import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDatatable from '@salesforce/apex/DatatableController.getDatatable';
import saveRecords from '@salesforce/apex/DatatableController.saveRecords';

export default class SendClientsToIntime extends LightningElement {
    // PRIVATE ATTRIBUTES 
    _recordsList;
    _recordsToDisplay;
    _dataList;
    _columnsList;
    _currentPage;
    _selectedEntry;
    _totalNumberOfRecords;
    _showSave;
    _selectedRecordIds;
    _selectedContactIds;
    _selectedContacts;
    @track _planCodesList;
    _selectedPlanCodes;
    _selectedBranches;
    _startDate;
    _endDate;
    _ayncJobStatus;
    _apexJobId;

    /**
    * @description Constructor
    **/
    constructor() {
        super();
        this._recordsList = new Array();
        this._recordsToDisplay = new Array();
        this._selectedRecordIds = new Array();
        this._selectedContactIds = new Array();
        this._dataList = new Array();
        this._columnsList = new Array();
        this._currentPage = 1;
        this._selectedEntry = 25;
        this._selectedContacts = '';
        this._selectedPlanCodes = '';
        this._selectedBranches = '';
        this._apexJobId = '';
        this._ayncJobStatus = '';
    }

    /**
    * @description Connected Callback Method
    **/
    connectedCallback() {
       this.getClients();
    }

    /**
    * @description RenderedCallbackMethod
    **/
    renderedCallback() {
        this.rerenderPaginator();
    }

    /**
    * @description Method to fetch the contacts
    **/
    getClients() {
        this._currentPage = 1;
        this._selectedEntry = 25;
        if (this.template.querySelector('lightning-spinner')) {
            this.template.querySelector('lightning-spinner').classList.remove('slds-hide');
        }
        this._planCodesList = new Array();
        getDatatable({
            'dataTableParams' : {
                'className' : 'DatatableController.ClientIntimeSendController',
                'filters' : {
                    'plancodes' : this._selectedPlanCodes,
                    'branches' : this._selectedBranches,
                    'accounts' : this._selectedAccounts
                }
            }
        }).then(result => {
            if (result) {
                if (result.hasOwnProperty('columns')) {
                    this._columnsList = result.columns;
                }
                if (result.hasOwnProperty('data')) {
                    this._dataList = result.data;
                    this._recordsList = result.data;
                }
                if (result.hasOwnProperty('planCodes')) {
                    result.planCodes.forEach(item => {
                        this._planCodesList.push({
                            'label' : item,
                            'value' : item
                        });
                    });
                }
                if (result.hasOwnProperty('ayncJobId')) {
                    this._apexJobId = result.ayncJobId;
                }
                if (result.hasOwnProperty('ayncJobStatus')) {
                    this._ayncJobStatus = result.ayncJobStatus;
                }
                this.setRecordsToDisplay();
            }
            if (this.template.querySelector('lightning-spinner')) {
                this.template.querySelector('lightning-spinner').classList.add('slds-hide');
            }
        }).catch(error => {
            console.log(error);
            this.error = error;
            if (this.template.querySelector('lightning-spinner')) {
                this.template.querySelector('lightning-spinner').classList.add('slds-hide');
            }
        });
    }

    /**
    * @description Method to handle entry change event
    **/
    setRecordsToDisplay() {
        let recordsList = this._recordsList;
        let startIndex = ((this._currentPage - 1) * this._selectedEntry);
        let endIndex = (this._currentPage * this._selectedEntry) >= recordsList.length ? recordsList.length : this._currentPage * this._selectedEntry;
        this._totalNumberOfRecords = recordsList.length;

        if (startIndex !== undefined && endIndex !== undefined) {
            this._recordsToDisplay = new Array();
            for(let i=startIndex;i<endIndex;i++){
                this._recordsToDisplay.push(recordsList[i]);
            } 
        }

        if (this._recordsToDisplay.length == 0 && this.recordsList.length > 0) {
            this._currentPage = (this._currentPage - 1);
            let startIndex = ((this._currentPage - 1) * this._selectedEntry);
            let endIndex = (this._currentPage * this._selectedEntry) >= recordsList.length ? recordsList.length : this._currentPage * this._selectedEntry;
            if (startIndex !== undefined && endIndex !== undefined) {
                this._recordsToDisplay = new Array();
                for(let i=startIndex;i<endIndex;i++){
                    this._recordsToDisplay.push(recordsList[i]);
                }
            }
        }
        this.rerenderPaginator();
    }

     /**
    * @description Method to rerender pagniator
    **/
    rerenderPaginator() {
        // call paginator 
        const paginator = this.template.querySelector('c-timesheet-paginator');
        if (paginator) {
            paginator.rerender(this._currentPage,this._selectedEntry,this._totalNumberOfRecords);
        }
    }

    /**
    * @description Method to check if a record exists to display in a table
    **/
    get hasRecordsToDisplay() {
        return this._recordsToDisplay.length > 0;
    }

    /**
    * @description Method to check if a record selected
    **/
    get hasRecordsSelected() {
        return this._selectedRecordIds.length == 0 || this._ayncJobStatus == true;
    }

     /**
    * @description Method to check if there are more than one page 
    **/
     get hasMoreThanOnePage() {
        return this._recordsToDisplay.length > this._selectedEntry;
    }

    /**
    * @description Method to handle page change event
    **/
    handlePageChange(event) {
        this.template.querySelector('lightning-spinner').classList.remove('slds-hide');
        if (event && event.detail) {
            this._currentPage = event.detail;
            this.setRecordsToDisplay();
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        }
    }

    /**
    * @description Method to handle on row seletion
    **/
    handleOnRowSelection (event) {
        this._selectedRecordIds = new Array();
        let selectedRows = event.detail.selectedRows;
        selectedRows.forEach(item => {
            this._selectedRecordIds.push(item.Id);
        });
    }

    /**
    * @description Method to handle save 
    **/
    handleSave (event) {
        this.template.querySelector('lightning-spinner').classList.remove('slds-hide');
        saveRecords({
            'dataTableParams' : {
                'className' : 'DatatableController.ClientIntimeSendController',
                'accountIds' : JSON.stringify(this._selectedRecordIds)
            }
        }).then(result => {
            if (result && result.hasOwnProperty('apexJobId')) {
                this._apexJobId = result.apexJobId;
            } else {
                // show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        "message" : "Selected client(s) has/have been sent it to intime successfully",
                        "variant" : 'success'
                    }),
                );
                this.getClients();
            }
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        }).catch(error => {
            if (error && error.body && error.body.message) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        "message" : error.body.message,
                        "variant" : 'error'
                    }),
                );
            }
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
            this.error = error;
        });
    }

    /**
    * @description Method to handle on job completed
    **/
    handleOnJobCompleted(event) {
        this._apexJobId = '';
        // show success message
        this.dispatchEvent(
            new ShowToastEvent({
                "message" : "Selected client(s) has/have been sent it to intime successfully",
                "variant" : 'success'
            }),
        );
        this.getClients();
    }

    /**
    * @description Method to handle select all
    **/
    handleSelectAll (event) {
        this._selectedRecordIds = new Array();
        this._holidaysList.forEach(item => {
            this._selectedRecordIds.push(item.Id);
        });
        this._selectedContactIds = [...this._selectedRecordIds];
    }

    /**
    * @description Method to handle on contact selection change
    **/
    handleOnContactSelectionChange(event) {
        this._selectedContacts = event.detail;
    }

    /**
    * @description Method to handle refresh
    **/
    handleRefresh() {
        this.getClients();
    }

    /**
    * @description Method to handle on plan code change
    **/
    handleOnPlanCodeChange(event) {
        this._selectedPlanCodes = event.detail.value;
    }

    /**
    * @description Method to handle on branch selection change
    **/
    handleOnBranchSelectionChange(event) {
        this._selectedBranches = event.detail;
    }

    /**
    * @description Method to handle on account selection change
    **/
    handleOnAccountSelectionChange(event) {
        this._selectedAccounts = event.detail;
    }

    /**
    * @description Method to show job monitor
    **/
    get showJobMonitor() {
        return this._apexJobId;
    }
}