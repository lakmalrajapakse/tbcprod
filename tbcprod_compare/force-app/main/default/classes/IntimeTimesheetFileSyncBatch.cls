/**
*   @description Implements the Intime timesheet file sync process
**/
public with sharing class IntimeTimesheetFileSyncBatch implements Database.Batchable<InTimeSyncItem__c>, Database.AllowsCallouts, Database.Stateful, Database.RaisesPlatformEvents{
    
    private InTimeObject__mdt intimeObject;
    @testVisible
    private static Boolean throwException = false;

    /**
    *  @description Batch constructor
    **/ 
    public IntimeTimesheetFileSyncBatch(InTimeObject__mdt intimeObject) {
        this.intimeObject = intimeObject;
        IntimeSyncHelper.updateRetryCount(this.intimeObject.Type__c);     
    }
    
    /**
    *  @description : Batch start method 
    **/ 
    public List<InTimeSyncItem__c> start(Database.BatchableContext BC) { 
        return [SELECT Id, Name, SourceRecordId__c, InTimeSyncLog__c, ObjectType__c, RetryCount__c FROM InTimeSyncItem__c 
            WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED AND Type__c =: IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET_FILE];
    }

    /**
    *  @description : Batch Execute method
    **/
    public void execute(Database.BatchableContext BC, List<InTimeSyncItem__c> scope) {
        try {
            IIntimeSyncHandler syncHandler = (IIntimeSyncHandler)Type.forName(this.intimeObject.HandlerName__c).newInstance();
            if (syncHandler != null)  syncHandler.syncToIntime(scope,this.intimeObject);
            if (throwException) throw new IntimeException('Test Exception');
        } catch(Exception ex) {
            sirenum__LogEntry__c logEntry = new sirenum__LogEntry__c(
                sirenum__Category__c = IntimeTimesheetFileSyncBatch.class.getName(),
                sirenum__Details__c = 'Failed Ids are '+JSON.serialize(new Map<Id, InTimeSyncItem__c>(scope).keySet())+'\r\n\r\n'+'Error is \r\n\r\n'+ex.getMessage(),
                sirenum__Severity__c = 'Medium'
            );
            insert logEntry;
        }
    }
    
    /**
    *  @description : Batch Finish Method
    **/ 
    public void finish(Database.BatchableContext BC) {
    }

    public class IntimeException extends Exception {}
}