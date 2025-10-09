/**
*  @description Apex class to manage the timesheet data sync to intime
**/
public with sharing class IntimeTimesheetSyncHandler extends IntimeSyncHandler implements IIntimeSyncHandler{

    /**
    *  @description Constructor
    **/
    public IntimeTimesheetSyncHandler() {
        super();
    }

    /**
    *  @description Method to trigger the intime sync
    **/
    public void syncToIntime(List<InTimeSyncItem__c> inTimeSyncItemsList, InTimeObject__mdt inTimeObject) {
        try {
            this.setIntimeSyncItems(inTimeSyncItemsList);
            this.resetIntimeSyncItems();

            Set<Id> recordIds = this.getRecordIds(inTimeSyncItemsList);

            // fetch record from the system
            this.getRecords(recordIds, inTimeObject);

            // Reinstate worker - LRTEM
            //LR-TEMP this.reinstateWorkerForCurrentPeriod();

            // set file information
            if(inTimeObject.SendContentDocument__c) this.setFileInformation();

            // fetch timesheet from intime
            this.fetchTimeFromInTime(inTimeObject);

            //create or update timesheet in intime 
            createOrUpdateTimesheets(inTimeSyncItemsList, inTimeObject);
            
            this.updateInTimeSyncItems(inTimeObject.SendContentDocument__c ? IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET_FILE : IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET);
            TriggerHandler.bypass(TimesheetTriggerHandler.class.getName());
            this.updateRecords();
            TriggerHandler.clearBypass(TimesheetTriggerHandler.class.getName());
            // set file information
            if(!inTimeObject.SendContentDocument__c) createIntimeSyncItems((List<sirenum__Timesheet__c>)this.recordsList);
        }catch(Exception ex){
            for (InTimeSyncItem__c intimeSyncItem : this.intimeSyncItemByRecordIdMap.values()) {
                intimeSyncItem.ErrorMessage__c =  JSON.serialize(ex.getMessage());
                intimeSyncItem.InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+JSON.serialize(ex.getMessage());
                this.errorMap.put(intimeSyncItem.SourceRecordId__c,true);
            }
            this.updateInTimeSyncItems(inTimeObject.SendContentDocument__c ? IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET_FILE : IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET);
        }
    }

    /**
    *  @description Method to get additional fields to query for processing
    **/
    public override Set<String> getAdditionalFields() {
        Set<String> additionalFieldsList = new Set<String>{};
        additionalFieldsList.add(sirenum__Timesheet__c.ProofUploaded__c.getDescribe().getName());
        additionalFieldsList.add(sirenum__Timesheet__c.ProofUploadedInIntime__c.getDescribe().getName());
        additionalFieldsList.add(sirenum__Timesheet__c.sirenum__Worker__c.getDescribe().getName());
        additionalFieldsList.add(sirenum__Timesheet__c.sirenum__Worker__c.getDescribe().getName().replace('__c','__r')+'.'+Contact.InPayReference__c.getDescribe().getName());
        additionalFieldsList.add(sirenum__Timesheet__c.sirenum__Worker__c.getDescribe().getName().replace('__c','__r')+'.'+Contact.LeaverInformationUpdatedInInTime__c.getDescribe().getName());
        return additionalFieldsList;
    }

    /**
    *  @description Method to create intime sync items
    **/
    public void createIntimeSyncItems(List<sirenum__Timesheet__c> timesheetsList) {
        List<InTimeSyncItem__c> inTimeSyncItemsToInsert = new List<InTimeSyncItem__c>();
        Set<Id> recordIdsAlreadyInProcess = new Set<Id>();
        Set<Id> recordIds = new Map<Id, sirenum__Timesheet__c>(timesheetsList).keySet();
        List<InTimeSyncItem__c> intimeSyncItemsList = [SELECT Id, SourceRecordId__c, ObjectType__c 
            FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED AND Type__c =: IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET_FILE
            AND Timesheet__c IN: recordIds];
        for (InTimeSyncItem__c intimeSyncItem : intimeSyncItemsList) {
            recordIdsAlreadyInProcess.add((Id)intimeSyncItem.SourceRecordId__c);
        }
        for (sirenum__Timesheet__c timesheet : timesheetsList) {
            if (!recordIdsAlreadyInProcess.contains(timesheet.Id) && (!this.errorMap.containsKey(timesheet.Id) || (this.errorMap.containsKey(timesheet.Id) && !this.errorMap.get(timesheet.Id)))
                && timesheet.ProofUploaded__c && !timesheet.ProofUploadedInIntime__c) {
                inTimeSyncItemsToInsert.add(new InTimeSyncItem__c(
                    Timesheet__c = timesheet.Id, 
                    Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED,
                    Type__c = IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET_FILE
                ));
            }
        }
        if (!inTimeSyncItemsToInsert.isEmpty()) insert inTimeSyncItemsToInsert;
    }

    /**
    *  @description Method to get sobject record
    **/
    public override void getRecords(Set<Id> recordIds, InTimeObject__mdt inTimeObject) {
        String contentDocumentQuery = ',(SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.FileExtension FROM ContentDocumentLinks ORDER BY ContentDocument.CreatedDate DESC LIMIT 1)';
        Set<String> fieldsList = getFieldsList(inTimeObject);
        fieldsList.addAll(getAdditionalFields());
        String soqlQuery = 'SELECT '+String.join(new List<String>(fieldsList),',')+(inTimeObject.SendContentDocument__c ? contentDocumentQuery : '')+' FROM '+new List<Id>(recordIds)[0].getSObjectType().getDescribe().getName()+' WHERE Id IN: recordIds';
        this.recordsList = (List<sObject>)Database.query(soqlQuery);
    }

    /**
    *  @description Method to set file information on payload
    **/
    public void setFileInformation() {
        for (sObject record : this.recordsList) {
            Id recordId = (Id)record.get('Id');
            Map<String, Object> fileObjectMap = new Map<String, Object>();
            if (record.getSObjects('ContentDocumentLinks') != null && !record.getSObjects('ContentDocumentLinks').isEmpty()) {
                ContentDocumentLink contentDocumentLink = (ContentDocumentLink)record.getSObjects('ContentDocumentLinks')[0];
                fileObjectMap.put('timesheetFileBase64',EncodingUtil.base64Encode(contentDocumentLink.ContentDocument.LatestPublishedVersion.VersionData));
                fileObjectMap.put('timesheetFileName',contentDocumentLink.ContentDocument.Title+'.'+contentDocumentLink.ContentDocument.LatestPublishedVersion.FileExtension);
            }
            this.objectsMap.get(recordId).putAll(fileObjectMap);
        }
    }

    /**
    *  @description Method to reinstate worker in inpay
    **/
    /*LR-TEMP public void reinstateWorkerForCurrentPeriod() {
        Set<Id> workerIds = new Set<Id>();
        for (sObject record : this.recordsList) {
            Id recordId = (Id)record.get('Id');
            Id workerId = (Id)record.get(sirenum__Timesheet__c.sirenum__Worker__c.getDescribe().getName());
            String inpayReference = record.getSObject(sirenum__Timesheet__c.sirenum__Worker__c.getDescribe().getName().replace('__c','__r')).get(Contact.InPayReference__c.getDescribe().getName()) != null ? String.valueOf(record.getSObject(sirenum__Timesheet__c.sirenum__Worker__c.getDescribe().getName().replace('__c','__r')).get(Contact.InPayReference__c.getDescribe().getName())) : '';
            Boolean leaverInformationUpdatedInTime = record.getSObject(sirenum__Timesheet__c.sirenum__Worker__c.getDescribe().getName().replace('__c','__r')).get(Contact.LeaverInformationUpdatedInInTime__c.getDescribe().getName()) != null ? Boolean.valueOf(record.getSObject(sirenum__Timesheet__c.sirenum__Worker__c.getDescribe().getName().replace('__c','__r')).get(Contact.LeaverInformationUpdatedInInTime__c.getDescribe().getName())) : false;
            if (leaverInformationUpdatedInTime && !String.isBlank(inpayReference) && !workerIds.contains(workerId)) {
                if (Test.isRunningTest()) IntimeCalloutMock.systemName = 'Inpay';
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c = 'ReinstateWorkerInInpay is '+JSON.serialize(new Map<String, String>{'ReinstateReason' => '2'});
                String reinstateWorkerInInpayResponse = InpaySyncHelper.reinstateWorkerForCurrentPeriod(inpayReference);
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\nReinstateWorkerInInpay Response is '+reinstateWorkerInInpayResponse;
                if (!String.isBlank(reinstateWorkerInInpayResponse)) {
                    Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(reinstateWorkerInInpayResponse);
                    if (jsonMap.containsKey('result') && String.valueOf(jsonMap.get('result')).toLowerCase() == 'ok') {
                    } else if (jsonMap.containsKey('result') && String.valueOf(jsonMap.get('result')).toLowerCase() == 'error' && jsonMap.containsKey('message')) {
                        this.intimeSyncItemByRecordIdMap.get(recordId).ErrorMessage__c = String.valueOf(jsonMap.get('message'));
                        this.errorMap.put(recordId, true);
                    }
                }
                workerIds.add(workerId);
            } 
            if (Test.isRunningTest()) IntimeCalloutMock.systemName = 'Intime';
        }
    }*/
    
    /**
    *  @description Method to fetch timesheet record from intime
    **/
    private void fetchTimeFromInTime(InTimeObject__mdt inTimeObject) {
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_FETCH);
        for (sObject record : this.recordsList) {
            Id recordId = (Id)record.get('Id');
            if (record != null && record.get(intimeObjectPayload.IntimeFieldReference__c) != null) {
                List<String> recordValuesList = new List<String>{this.intimeToken,String.valueOf(record.get(intimeObjectPayload.IntimeFieldReference__c))};
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c = (!String.isBlank(this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c) ? '\r\n\r\n' : '')+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
                // calling webserice 
                HttpResponse httpResponse = IntimeWebservice.getRecord(intimeObjectPayload,recordValuesList);
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();
                
                if (httpResponse.getStatusCode() == 200) {
                    // get the response
                    Object timesheetRecord = IntimeWebserviceParser.getFetchResponse(
                        httpResponse.getBody(),
                        intimeObjectPayload.ResponseElementName__c
                    );
                    if (timesheetRecord == null || timesheetRecord instanceof String) {
                        this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\nTimesheet Record doesn\'t exists in Intime';
                    } else if (timesheetRecord instanceof Map<String, Object>) {
                        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(
                            IntimeWebserviceParser.getFetchResponse(
                                httpResponse.getBody(),
                                intimeObjectPayload.ResponseElementName__c
                            )
                        ));
                        this.objectsMap.put(recordId,responseMap);
                    }
                } else {
                    this.intimeSyncItemByRecordIdMap.get(recordId).ErrorMessage__c =  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                    this.errorMap.put(recordId, true);
                }
            }
        }
       
    }

    /**
    *  @description Method to create or update timesheet in intime
    **/
    private void createOrUpdateTimesheets(List<InTimeSyncItem__c> inTimeSyncItemsList, InTimeObject__mdt inTimeObject) {
        IntimeObjectPayload__mdt intimeObjectPayload = null;
        IntimeObjectPayload__mdt intimeObjectCreatePayload = null;
        IntimeObjectPayload__mdt intimeObjectUpdatePayload = null;
        Map<Id, Object> timesheetResultsByIdMap = new Map<Id, Object>();
        List<Object> objectsList = new List<Object>();
        for (sObject record : this.recordsList) {
            Id recordId = (Id)record.get('Id');
            this.context = record.get(sirenum__Timesheet__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
            intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,(this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE ? IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_SUBMIT : IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST));
            //create intime object
            this.objectsMap.get(recordId).putAll(IntimeSyncHelper.createIntimeObject(inTimeObject, record, this.context));
            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_INSERT) intimeObjectCreatePayload = intimeObjectPayload;
            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE) intimeObjectUpdatePayload = intimeObjectPayload;
        }

        String xmlBody = '';
        // DO THIS FOR UPDATE CONTEXT
        // UPDATE DOES NOT SUPPORT BULK SUBMISSION
        for (sObject record : this.recordsList) {
            XMLSerializer serializer = new XMLSerializer('ns');
            Id recordId = (Id)record.get('Id');
            this.context = record.get(sirenum__Timesheet__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE) {
                String recordXmlBody = serializer.JSONToXML(JSON.serialize(new Map<String, Object>{'timesheet' => this.objectsMap.get(recordId)}),true);
                List<String> recordValuesList = new List<String>{this.intimeToken,recordXmlBody};
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectUpdatePayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectUpdatePayload.Payload__c,recordValuesList);
                HttpResponse httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectUpdatePayload,recordValuesList);
                timesheetResultsByIdMap.putAll(processResponse(new List<Id>{recordId},httpResponse,intimeObjectUpdatePayload));
            }
        }

        // DO THIS FOR CREATE CONTEXT
        // CREATE DOES SUPPORT BULK SUBMISSION
        xmlBody = '';
        List<Id> timesheetIds = new List<Id>();
        for (sObject record : this.recordsList) {
            XMLSerializer serializer = new XMLSerializer('ns');
            Id recordId = (Id)record.get('Id');
            this.context = record.get(sirenum__Timesheet__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_INSERT) {
                timesheetIds.add(recordId);
                String recordXmlBody = serializer.JSONToXML(JSON.serialize(new Map<String, Object>{'timesheets' => this.objectsMap.get(recordId)}),true);
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectCreatePayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectCreatePayload.Payload__c,new List<String>{this.intimeToken,recordXmlBody});
                xmlBody += recordXmlBody;
            }
        }
        if (!timesheetIds.isEmpty()) {
            List<String> recordValuesList = new List<String>{this.intimeToken,xmlBody};
            //Timesheet record
            HttpResponse httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectCreatePayload,recordValuesList);
            timesheetResultsByIdMap.putAll(processResponse(timesheetIds,httpResponse,intimeObjectCreatePayload));
        }
        
        Map<Id, sObject> recordsMap = new Map<Id, sObject>(this.recordsList);
        for (Id timesheetId : timesheetResultsByIdMap.keySet()) {
            Map<String, Object> timeSheetResultMap = (timesheetResultsByIdMap.get(timesheetId) instanceof Map<String, Object>) ? (Map<String, Object>)timesheetResultsByIdMap.get(timesheetId) : (Map<String, Object>)JSON.deserializeUntyped(String.valueOf(timesheetResultsByIdMap.get(timesheetId)));
            if (timeSheetResultMap.containsKey('TIMESHEET_ID')) {
                recordsMap.get(timesheetId).put(sirenum__Timesheet__c.InTimeId__c.getDescribe().getName(),String.valueOf(timeSheetResultMap.get('TIMESHEET_ID')));
                if (inTimeObject.SendContentDocument__c) {
                    recordsMap.get(timesheetId).put(sirenum__Timesheet__c.ProofUploadedInIntime__c.getDescribe().getName(),true);
                }
            }
            if (timeSheetResultMap.containsKey('RESULT') && String.valueOf(timeSheetResultMap.get('RESULT')).toLowerCase() != 'ok') {
                if (timeSheetResultMap.containsKey('MESSAGE')) {
                    this.intimeSyncItemByRecordIdMap.get(timesheetId).ErrorMessage__c = String.valueOf(timeSheetResultMap.get('MESSAGE'));
                    this.errorMap.put(timesheetId, true);
                }
            }
        }
    }

    /**
    *  @description Method to process the response
    **/
    public Map<Id, Object> processResponse(List<Id> timesheetIds, HttpResponse httpResponse, IntimeObjectPayload__mdt intimeObjectPayload) {
        Map<Id, Object> timesheetResultsByIdMap = new Map<Id, Object>();
        List<Object> timesheetResultsList = new List<Object>();
        if (httpResponse.getStatusCode() == 200) {
            if (timesheetIds.size() == 1) {
                Object timesheeetRecord = IntimeWebserviceParser.getFetchResponse(
                    httpResponse.getBody(),
                    intimeObjectPayload.ResponseElementName__c
                );
                this.intimeSyncItemByRecordIdMap.get(timesheetIds[0]).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+String.valueOf(timesheeetRecord);
                if (timesheeetRecord != null && String.valueOf(timesheeetRecord).startsWith('{')) {
                    timesheetResultsByIdMap.put(timesheetIds[0],timesheeetRecord);
                } else {
                    timesheetResultsByIdMap.put(timesheetIds[0],new Map<String, Object>{'TIMESHEET_ID' => timesheeetRecord});
                }
            } else {
                timesheetResultsList = (List<Object>)IntimeWebserviceParser.getCreateOrUpdateResponse(
                    httpResponse.getBody(),
                    intimeObjectPayload.ResponseElementName__c
                );
                for (Integer i=0;i<timesheetIds.size();i++) {
                    this.intimeSyncItemByRecordIdMap.get(timesheetIds[i]).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+timesheetResultsList[i];
                    timesheetResultsByIdMap.put(timesheetIds[i],timesheetResultsList[i]);
                }
            }
        } else {
            for (Id timesheetId : timesheetIds) { 
                this.intimeSyncItemByRecordIdMap.get(timesheetId).ErrorMessage__c +=  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                this.intimeSyncItemByRecordIdMap.get(timesheetId).InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                this.errorMap.put(timesheetId,true);
            }
        }
        return timesheetResultsByIdMap;
    }

    /**
    *  @description Method to update record
    **/
    public override void updateRecords() {
        for (Integer i=0;i<this.recordsList.size();i++) {
            if (this.errorMap.containsKey((Id)this.recordsList[i].get('Id')) && !this.errorMap.get((Id)this.recordsList[i].get('Id'))) {
                this.recordsList[i].put(sirenum__Timesheet__c.Status__c.getDescribe().getName(),IntimeConstants.TIMESHEET_STATUS_EXPORTED);
            }
            this.recordsList[i].put('LastIntimeSync__c',System.now());
        }
        update this.recordsList;
    }
}