/**
*   @description Wrapper class for record processor
**/
public without sharing class RecordProcessor {
    public List<Id> recordsToProcess;
    public IRecordProcessor recordProcessorHandler;
    public RecordProcessor recordProcessor;

    /**
    *   @description Constructor
    **/
    public RecordProcessor(List<Id> recordsToProcess, IRecordProcessor recordProcessorHandler) {
        this.recordsToProcess = recordsToProcess;
        this.recordProcessorHandler = recordProcessorHandler;
    }

    /**
    *   @description Method to get record Id
    **/
    public List<Id> getRecordIds() {
        return this.recordsToProcess;
    }
}