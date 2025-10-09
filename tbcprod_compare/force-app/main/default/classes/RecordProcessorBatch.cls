/**
*   @description Implements the record processor batch
**/
public without sharing class RecordProcessorBatch implements Database.Batchable<Id>{

    private RecordProcessor recordProcessor;
    
    /**
    *  @description Batch constructor
    **/ 
    public RecordProcessorBatch(RecordProcessor recordProcessor) {
        this.recordProcessor = recordProcessor;
    }
    
    /**
    *  @description : Batch start method 
    **/ 
    public List<Id> start(Database.BatchableContext BC) { 
        return this.recordProcessor.getRecordIds();
    }

    /**
    *  @description : Batch Execute method
    **/ 
    public void execute(Database.BatchableContext BC, List<Id> scope) {
        try {
            if (this.recordProcessor.recordProcessorHandler != null)  this.recordProcessor.recordProcessorHandler.processRecords(scope);
        } catch(Exception ex) {
        }
    }
    
    /**
    *  @description : Batch Finish Method
    **/ 
    public void finish(Database.BatchableContext BC) {
        if (this.recordProcessor.recordProcessorHandler != null)  this.recordProcessor.recordProcessorHandler.finish(this.recordProcessor.getRecordIds());
        if (this.recordProcessor.recordProcessor != null) Database.executeBatch(new RecordProcessorBatch(this.recordProcessor.recordProcessor),200);
    }
}