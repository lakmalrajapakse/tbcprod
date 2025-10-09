/**
*  @description Apex Class used to initiate and manage the intime sync
**/
public without sharing class IntimeSyncProcessor {
    
    public static Map<String, Set<Id>> recordIdsByRecordTypeMap;
    static {
        recordIdsByRecordTypeMap = new Map<String, Set<Id>>();
    }

    /**
    *  @description Method used to trigger the next intime sync batch
    **/
    public static void triggerNextIntimeSyncBatch(String sourceType, Set<Id> intimeObjectIds) {
        Set<String> objectsList = getIntimeSyncItems();
        for (InTimeObject__mdt intimeObject : getIntimeObjects(sourceType)) {
            if (objectsList.contains(intimeObject.Type__c) && !intimeObjectIds.contains(intimeObject.Id)) {
                triggerIntimeSyncBatch(intimeObject, intimeObjectIds);
                break;
            } 
        }
    }

    /**
    *  @description Method used to start the batch
    **/
    public static void startIntimeSyncBatch(String sourceType) {
        triggerNextIntimeSyncBatch(sourceType, new Set<Id>());
    }

    /**
    *  @description Method used to trigger the intime sync batch
    **/
    public static void triggerIntimeSyncBatch(InTimeObject__mdt intimeObject, Set<Id> intimeObjectIds) {
       Database.executeBatch(new IntimeSyncBatch(intimeObject, intimeObjectIds),Integer.valueOf(intimeObject.BatchSize__c));
    }

    /**
    *  @description Method used to trigger the intime sync record processor batch
    **/
    public static void triggerIntimeRecordProcessorBatch() {
        Database.executeBatch(new IntimeRecordProcessorBatch(),500);
    }

    /**
    *  @description Method to get intime objectss
    **/
    public static List<InTimeObject__mdt> getIntimeObjects(String sourceType) {
        return [SELECT Id, Object__c, RelationshipName__c, HandlerName__c, Order__c, BatchSize__c, SendContentDocument__c, Type__c,
            (SELECT Id, IntimeFieldReference__c, MethodName__c, Payload__c, ResponseElementName__c, Type__c FROM IntimeObjectPayload__r),
            (SELECT Id, FieldType__c, StaticValue__c, InTimeField__c, RelatedObject__c, SalesforceField__c, Insert__c, Update__c,
                RelatedObject__r.RelationshipName__c, RelatedObject__r.Object__c FROM InTimeFieldMappings__r WHERE FieldType__c != null) 
                FROM InTimeObject__mdt WHERE Order__c != null AND Source__c =: sourceType ORDER BY Order__c];
    }

    /**
    *  @description Method to get intime objects
    **/
    public static List<InTimeObject__mdt> getIntimeObject(String developerName) {
        return [SELECT Id, Object__c, RelationshipName__c, HandlerName__c, Order__c, BatchSize__c, SendContentDocument__c, Type__c,
            (SELECT Id, IntimeFieldReference__c, MethodName__c, Payload__c, ResponseElementName__c, Type__c FROM IntimeObjectPayload__r),
            (SELECT Id, FieldType__c, StaticValue__c, InTimeField__c, RelatedObject__c, SalesforceField__c, Insert__c, Update__c,
                RelatedObject__r.RelationshipName__c, RelatedObject__r.Object__c FROM InTimeFieldMappings__r WHERE FieldType__c != null) 
                FROM InTimeObject__mdt WHERE DeveloperName =: developerName];
    }

    /**
    *  @description Method to get intime sync objects that needs to be processed
    **/
    public static Set<String> getIntimeSyncItems() {
        Set<String> objectsList = new Set<String>();
        for (InTimeSyncItem__c inTimeSyncItem : [SELECT ObjectType__c, Type__c FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED AND IsReverse__c = false
            AND Type__c !=: IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET_FILE]) {
           if (!String.isBlank(inTimeSyncItem.Type__c)) objectsList.add(inTimeSyncItem.Type__c.trim());
        }
        return objectsList;
    }

}