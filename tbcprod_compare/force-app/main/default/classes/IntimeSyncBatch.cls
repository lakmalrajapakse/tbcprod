/**
*   @description Implements the Intime sync process
**/
public without sharing class IntimeSyncBatch implements Database.Batchable<InTimeSyncItem__c>, Database.AllowsCallouts, Database.Stateful, Database.RaisesPlatformEvents{
    
    private InTimeObject__mdt intimeObject;
    private Set<Id> intimeObjectIds;
    @testVisible
    private static Boolean throwException = false;

    /**
    *  @description Batch constructor
    **/ 
    public IntimeSyncBatch(InTimeObject__mdt intimeObject, Set<Id> intimeObjectIds) {
        this.intimeObject = intimeObject;
        this.intimeObjectIds = intimeObjectIds;
        IntimeSyncHelper.updateRetryCount(this.intimeObject.Type__c);     
    }
    
    /**
    *  @description : Batch start method 
    **/ 
    public List<InTimeSyncItem__c> start(Database.BatchableContext BC) { 
        return [SELECT Id, Name, SourceRecordId__c, InTimeSyncLog__c, ObjectType__c, RetryCount__c FROM InTimeSyncItem__c 
            WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED AND Type__c =: this.intimeObject.Type__c];
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
                sirenum__Category__c = IntimeSyncBatch.class.getName(),
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
        // Trigger the next intime sync object
        if (!Test.isRunningTest()) {
            this.intimeObjectIds.add(this.intimeObject.Id);
            IntimeSyncProcessor.triggerNextIntimeSyncBatch(IntimeConstants.INTIME_OBJECT_SOURCE_SALESFORCE, this.intimeObjectIds);
        }
    }

    public class IntimeException extends Exception {}
}