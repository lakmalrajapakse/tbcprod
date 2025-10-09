/**
*   @description Implements the Intime records processor
**/
public with sharing class IntimeRecordProcessorBatch implements Database.Batchable<InTimeSyncItem__c>{

    /**
    *  @description : Batch start method 
    **/ 
    public List<InTimeSyncItem__c> start(Database.BatchableContext BC) { 
        return [SELECT Id, Client__c, Client__r.InTimeSyncStatus__c, Placement__c, Placement__r.InTimeSyncStatus__c, SourceRecordId__c,
                Person__c, Person__r.InTimeSyncStatus__c, Timesheet__c, Timesheet__r.InTimeSyncStatus__c, ObjectType__c,
                Placement__r.sirenum__Contract__r.sirenum__Client__c, Placement__r.sirenum__Contract__r.sirenum__Client__r.InTimeSyncStatus__c,
                Timesheet__r.sirenum__Worker__c, Timesheet__r.sirenum__Worker__r.InTimeSyncStatus__c,
                Timesheet__r.Placement__c, Timesheet__r.Placement__r.InTimeSyncStatus__c,
                Timesheet__r.Placement__r.sirenum__Contract__r.sirenum__Client__c, 
                Timesheet__r.Placement__r.sirenum__Contract__r.sirenum__Client__r.InTimeSyncStatus__c,
                Timesheet__r.sirenum__Worker__r.LeaverInformationUpdatedInInTime__c,
                EmployeeRequest__r.sirenum__Contact__c, EmployeeRequest__r.sirenum__Contact__r.InTimeSyncStatus__c,
                Placement__r.sirenum__Contact__c, Placement__r.sirenum__Contact__r.InTimeSyncStatus__c
                FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED];
    }

    /**
    *  @description : Batch Execute method
    **/ 
    public void execute(Database.BatchableContext BC, List<InTimeSyncItem__c> scope) {
        Map<String, Set<Id>> recordIdByObjectTypeMap = new Map<String, Set<Id>>{
            'Account' => new Set<Id>(),
            'Contact' => new Set<Id>(),
            'sirenum__Placement__c' => new Set<Id>(),
            'sirenum__Timesheet__c' => new Set<Id>()
        }; 
        List<InTimeSyncItem__c> intimeSyncItemsList = [SELECT Id, SourceRecordId__c, ObjectType__c FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED OR Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED];
        List<InTimeSyncItem__c> inTimeSyncItemsToUpsert = new List<InTimeSyncItem__c>();
        try {
            for (InTimeSyncItem__c intimeSyncItem : scope) {
                if (recordIdByObjectTypeMap.containsKey(intimeSyncItem.ObjectType__c)) {
                    recordIdByObjectTypeMap.get(intimeSyncItem.ObjectType__c).add(intimeSyncItem.SourceRecordId__c);
                } else {
                    recordIdByObjectTypeMap.put(intimeSyncItem.ObjectType__c, new Set<Id>{intimeSyncItem.SourceRecordId__c});
                }
            }
            for (InTimeSyncItem__c intimeSyncItem : intimeSyncItemsList) {
                if (recordIdByObjectTypeMap.containsKey(intimeSyncItem.ObjectType__c)) {
                    recordIdByObjectTypeMap.get(intimeSyncItem.ObjectType__c).add(intimeSyncItem.SourceRecordId__c);
                } else {
                    recordIdByObjectTypeMap.put(intimeSyncItem.ObjectType__c, new Set<Id>{intimeSyncItem.SourceRecordId__c});
                }
            }

            for (InTimeSyncItem__c intimeSyncItem : scope) {
                intimeSyncItem.Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED;
                inTimeSyncItemsToUpsert.add(intimeSyncItem);
                if (intimeSyncItem.ObjectType__c == 'sirenum__Timesheet__c') {
                    Id clientId = intimeSyncItem.Timesheet__r?.Placement__r?.sirenum__Contract__r?.sirenum__Client__c;
                    String clientStatus = intimeSyncItem.Timesheet__r?.Placement__r?.sirenum__Contract__r?.sirenum__Client__r.InTimeSyncStatus__c;
                    Id workerId = intimeSyncItem.Timesheet__r?.sirenum__Worker__c;
                    String workerStatus = intimeSyncItem.Timesheet__r?.sirenum__Worker__r?.InTimeSyncStatus__c;
                    Id placementId = intimeSyncItem.Timesheet__r?.Placement__c;
                    String placementStatus = intimeSyncItem.Timesheet__r?.Placement__r?.InTimeSyncStatus__c;
                    if (clientId != null && clientStatus == IntimeConstants.INTIME_SYNC_STATUS_NOT_SYNCED && !recordIdByObjectTypeMap.get('Account').contains(clientId)){
                        inTimeSyncItemsToUpsert.add(new InTimeSyncItem__c(Client__c = clientId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED,Type__c = IntimeConstants.SALESFORCE_TO_INTIME_CLIENT));
                        recordIdByObjectTypeMap.get('Account').add(clientId);
                    } 
                    if (workerId != null && (workerStatus == IntimeConstants.INTIME_SYNC_STATUS_NOT_SYNCED || intimeSyncItem.Timesheet__r?.sirenum__Worker__r?.LeaverInformationUpdatedInInTime__c) && !recordIdByObjectTypeMap.get('Contact').contains(workerId)){
                        inTimeSyncItemsToUpsert.add(new InTimeSyncItem__c(Person__c = workerId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED,Type__c = IntimeConstants.SALESFORCE_TO_INTIME_WORKER));
                        recordIdByObjectTypeMap.get('Contact').add(workerId);
                    } 
                    if (placementId != null && placementStatus == IntimeConstants.INTIME_SYNC_STATUS_NOT_SYNCED && !recordIdByObjectTypeMap.get('sirenum__Placement__c').contains(placementId)){
                        inTimeSyncItemsToUpsert.add(new InTimeSyncItem__c(Placement__c = placementId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED,Type__c = IntimeConstants.SALESFORCE_TO_INTIME_PLACEMENT));
                        recordIdByObjectTypeMap.get('sirenum__Placement__c').add(placementId);
                    } 
                } else if (intimeSyncItem.ObjectType__c == 'sirenum__Placement__c') {
                    Id clientId = intimeSyncItem.Placement__r?.sirenum__Contract__r?.sirenum__Client__c;
                    String clientStatus = intimeSyncItem.Placement__r?.sirenum__Contract__r?.sirenum__Client__r?.InTimeSyncStatus__c;
                    Id workerId = intimeSyncItem.Placement__r?.sirenum__Contact__c;
                    String workerStatus = intimeSyncItem.Placement__r?.sirenum__Contact__r?.InTimeSyncStatus__c;
                    if (clientId != null && clientStatus == IntimeConstants.INTIME_SYNC_STATUS_NOT_SYNCED && !recordIdByObjectTypeMap.get('Account').contains(clientId)){
                        inTimeSyncItemsToUpsert.add(new InTimeSyncItem__c(Client__c = clientId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED,Type__c = IntimeConstants.SALESFORCE_TO_INTIME_CLIENT));
                        recordIdByObjectTypeMap.get('Account').add(clientId);
                    } 
                    if (workerId != null && workerStatus == IntimeConstants.INTIME_SYNC_STATUS_NOT_SYNCED && !recordIdByObjectTypeMap.get('Contact').contains(workerId)){
                        inTimeSyncItemsToUpsert.add(new InTimeSyncItem__c(Person__c = workerId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED,Type__c = IntimeConstants.SALESFORCE_TO_INTIME_WORKER));
                        recordIdByObjectTypeMap.get('Contact').add(workerId);
                    } 
                } else if (intimeSyncItem.ObjectType__c == 'sirenum__Employee_Request__c') {
                    Id workerId = intimeSyncItem.EmployeeRequest__r?.sirenum__Contact__c;
                    String workerStatus = intimeSyncItem.EmployeeRequest__r?.sirenum__Contact__r?.InTimeSyncStatus__c;
                    if (workerId != null && workerStatus == IntimeConstants.INTIME_SYNC_STATUS_NOT_SYNCED && !recordIdByObjectTypeMap.get('Contact').contains(workerId)){
                        inTimeSyncItemsToUpsert.add(new InTimeSyncItem__c(Person__c = workerId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED,Type__c = IntimeConstants.SALESFORCE_TO_INTIME_WORKER));
                        recordIdByObjectTypeMap.get('Contact').add(workerId);
                    } 
                }
            }   
            if (!inTimeSyncItemsToUpsert.isEmpty()) {
                IntimeSyncHelper.processRecordsInChunks(inTimeSyncItemsToUpsert);
            }
        } catch(Exception ex) {
        }
    }
    
    /**
    *  @description : Batch Finish Method
    **/ 
    public void finish(Database.BatchableContext BC) {
        // Trigger the intime sync batch
        if (!Test.isRunningTest()) IntimeSyncProcessor.startIntimeSyncBatch(IntimeConstants.INTIME_OBJECT_SOURCE_SALESFORCE);
    }
}