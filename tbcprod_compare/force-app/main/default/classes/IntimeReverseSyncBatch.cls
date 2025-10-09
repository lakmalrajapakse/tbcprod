/**
*   @description Implements the sync process from intime to salesforce
**/
public without sharing class IntimeReverseSyncBatch implements Database.Batchable<Object>, Database.AllowsCallouts{

    private Integer index;
    private DateTime jobStartTime;
    private List<Object> objectsList;

    /**
    *  @description : Constructor
    **/ 
    public IntimeReverseSyncBatch(Integer index) {
        this.index = index;
        this.jobStartTime = System.now();
        this.objectsList = new List<Object>();
    }

    /**
    *  @description : Constructor
    **/ 
    public IntimeReverseSyncBatch(List<Object> objectsList) {
        this.index = 0;
        this.objectsList = objectsList;
    }

    /**
    *  @description : Batch start method 
    **/ 
    public List<Object> start(Database.BatchableContext BC) { 
        if (this.objectsList.isEmpty()) this.objectsList = IntimeSyncHelper.getModifiedItemsFromIntime();
        return Test.isRunningTest() ? new List<Object>{this.objectsList[this.index]} : this.objectsList;
    }

    /**
    *  @description : Batch Execute method
    **/ 
    public void execute(Database.BatchableContext BC, List<Object> scope) {
        try {
            IntimeReverseSyncHandler intimeReverseSyncHandler = new IntimeReverseSyncHandler();
            intimeReverseSyncHandler.syncToSalesforce(scope[0]);
        } catch(Exception ex) {
        }
    }
    
    /**
    *  @description : Batch Finish Method
    **/ 
    public void finish(Database.BatchableContext BC) {
        IntimeReverseSyncSetting__c inTimeReverseSyncSetting = IntimeReverseSyncSetting__c.getInstance();
        inTimeReverseSyncSetting.DateTimeWhenSyncLastRanSuccess__c = this.jobStartTime;
        inTimeReverseSyncSetting.Until__c = null;
        upsert inTimeReverseSyncSetting;
    }
}