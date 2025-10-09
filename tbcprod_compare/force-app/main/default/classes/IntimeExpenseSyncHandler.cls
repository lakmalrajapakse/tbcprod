/**
*  @description Apex class to manage the expense data sync to intime
**/
public with sharing class IntimeExpenseSyncHandler extends IntimeSyncHandler implements IIntimeSyncHandler{

    private Map<String, List<String>> intimeIdsByExpenseIdMap;
    private Map<String, Map<String, Object>> intimeObjectsByExpenseIdMap;

    /**
    *  @description Constructor
    **/
    public IntimeExpenseSyncHandler() {
        super();
        this.intimeIdsByExpenseIdMap = new Map<String, List<String>>();
        this.intimeObjectsByExpenseIdMap = new Map<String, Map<String, Object>>();
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

            // fetch expense from intime
            fetchExpenseFromInTime(inTimeObject);
            
            // Create or update expense claim
            createOrUpdateExpenseClaim(inTimeSyncItemsList, inTimeObject);
            
            this.updateInTimeSyncItems(inTimeObject.Type__c);
            this.updateRecords();
        }catch(Exception ex){
            for (InTimeSyncItem__c intimeSyncItem : this.intimeSyncItemByRecordIdMap.values()) {
                intimeSyncItem.ErrorMessage__c =  JSON.serialize(ex.getMessage());
                intimeSyncItem.InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+JSON.serialize(ex.getMessage());
                this.errorMap.put(intimeSyncItem.SourceRecordId__c,true);
            }
            this.updateInTimeSyncItems(inTimeObject.Type__c);
        }
    }

    /**
    *  @description Method to get sobject record
    **/
    public override void getRecords(Set<Id> recordIds, InTimeObject__mdt inTimeObject) {
        String contentDocumentQuery = ',(SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.FileExtension FROM ContentDocumentLinks ORDER BY ContentDocument.CreatedDate DESC LIMIT 1)';
        Set<String> fieldsList = getFieldsList(inTimeObject);
        fieldsList.add(sirenum__Expense__c.sirenum__Timesheet__c.getDescribe().getName());
        fieldsList.add(sirenum__Expense__c.SubmittedInIntime__c.getDescribe().getName());
        fieldsList.add(sirenum__Expense__c.sirenum__Expense_Type__c.getDescribe().getName().replace('__c','__r')+'.Name');
        fieldsList.add(sirenum__Expense__c.ChargeExpenseValue__c.getDescribe().getName());
        fieldsList.add(sirenum__Expense__c.Expense_value__c.getDescribe().getName());
        fieldsList.add(sirenum__Expense__c.InTimeId__c.getDescribe().getName());
        String soqlQuery = 'SELECT '+String.join(new List<String>(fieldsList),',')+contentDocumentQuery+' FROM '+sirenum__Expense__c.sObjectType.getDescribe().getName()+' WHERE Id IN: recordIds';
        this.recordsList = (List<sObject>)Database.query(soqlQuery);
    }

    /**
    *  @description Method to fetch timesheet record from intime
    **/
    private void fetchExpenseFromInTime(InTimeObject__mdt inTimeObject) {
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_FETCH);
        for (sObject record : this.recordsList) {
            this.context = record.get(sirenum__Expense__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
            Id recordId = (Id)record.get('Id');
            if (intimeObjectPayload != null && record != null && record.get(intimeObjectPayload.IntimeFieldReference__c) != null) {
                List<String> expenseClaimIdList = String.valueOf(record.get(intimeObjectPayload.IntimeFieldReference__c)).split(';');
                for (String expenseClaimId : expenseClaimIdList) {
                    List<String> recordValuesList = new List<String>{this.intimeToken,expenseClaimId};
                    this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += (!String.isBlank(this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c) ? '\r\n\r\n' : '')+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
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
                            this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\nExpense Record doesn\'t exists in Intime';
                        } else if (timesheetRecord instanceof Map<String, Object>) {
                            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(
                                IntimeWebserviceParser.getFetchResponse(
                                    httpResponse.getBody(),
                                    intimeObjectPayload.ResponseElementName__c
                                )
                            ));
                            Map<String,Object> expenseItemsList = (Map<String,Object>)responseMap.get('expenseItems');
                            if (!expenseItemsList.isEmpty()) {
                                this.intimeObjectsByExpenseIdMap.put(expenseClaimId,expenseItemsList);
                            }
                        }
                    } else {
                        this.intimeSyncItemByRecordIdMap.get(recordId).ErrorMessage__c =  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                        this.errorMap.put(recordId, true);
                    }
                } 
            }
        }
       
    }

    /**
    *  @description Method to create or update expense in intime
    **/
    private void createOrUpdateExpenseClaim(List<InTimeSyncItem__c> inTimeSyncItemsList, InTimeObject__mdt inTimeObject) {
        HttpResponse httpResponse = null;
        List<String> expenseClaimIds = new List<String>();
        for (sObject expenseRecord : this.recordsList){
            IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,(this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE ? IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_UPDATE : IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST));
            List<String> expenseClaimIdList = expenseRecord.get(intimeObjectPayload.IntimeFieldReference__c) != null ? String.valueOf(expenseRecord.get(intimeObjectPayload.IntimeFieldReference__c)).split(';') : new List<String>(); 
            Boolean hasError = false;
            this.context = expenseRecord.get(sirenum__Expense__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
            Id expenseId = (Id)expenseRecord.get('Id');
            Boolean hasPayChargeSame = expenseRecord.get('ChargeExpenseValue__c') == expenseRecord.get('Expense_value__c');
            List<Object> objectsList = new List<Object>();
            if (hasPayChargeSame) {
                objectsList.add(new Map<String, String>{'name' => String.valueOf(expenseRecord.getSObject('sirenum__Expense_Type__r')?.get('Name')), 'value' => (expenseRecord.get('Expense_value__c') != null ? String.valueOf(expenseRecord.get('Expense_value__c')) : '0.00')});
            } else {
                objectsList.add(new Map<String, String>{'name' => String.valueOf(expenseRecord.getSObject('sirenum__Expense_Type__r')?.get('Name'))+' PAY', 'value' => (expenseRecord.get('Expense_value__c') != null ? String.valueOf(expenseRecord.get('Expense_value__c')) : '0.00')});
                objectsList.add(new Map<String, String>{'name' => String.valueOf(expenseRecord.getSObject('sirenum__Expense_Type__r')?.get('Name'))+' CHARGE', 'value' => (expenseRecord.get('ChargeExpenseValue__c') != null ? String.valueOf(expenseRecord.get('ChargeExpenseValue__c')) : '0.00')});
            }
            Integer counter = 0;
            for (Object expenseObject : objectsList) {
                intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,(this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE ? IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_UPDATE : IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST));
                Map<String, Object> expenseRecordObjectsMap = new Map<String, Object>();
                if ((!this.errorMap.containsKey(expenseId) || (this.errorMap.containsKey(expenseId) && !this.errorMap.get(expenseId)))) {
                    if (expenseRecord.getSObjects('ContentDocumentLinks') != null && expenseRecord.getSObjects('ContentDocumentLinks').size() > 0  && !Boolean.valueOf(expenseRecord.get(sirenum__Expense__c.SubmittedInIntime__c.getDescribe().getName()))) {
                        ContentDocumentLink contentDocumentLink = (ContentDocumentLink)expenseRecord.getSObjects('ContentDocumentLinks')[0];
                        expenseRecordObjectsMap.put('claimFileBase64',EncodingUtil.base64Encode(contentDocumentLink.ContentDocument.LatestPublishedVersion.VersionData));
                        expenseRecordObjectsMap.put('claimFileName',contentDocumentLink.ContentDocument.Title+'.'+contentDocumentLink.ContentDocument.LatestPublishedVersion.FileExtension);
                    }
                    if (!expenseClaimIdList.isEmpty() && this.intimeObjectsByExpenseIdMap.containsKey(expenseClaimIdList[counter])) {
                        expenseRecordObjectsMap.putAll(this.intimeObjectsByExpenseIdMap.get(expenseClaimIdList[counter]));
                    }
                    expenseRecordObjectsMap.putAll(IntimeSyncHelper.createIntimeObject(inTimeObject, expenseRecord, this.context));
                    Map<String, String> expenseObjectMap = (Map<String, String>)expenseObject;
                    for (String expenseObjectMapKey : expenseObjectMap.keySet()) {
                        if (expenseObjectMapKey == 'name') {
                            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_INSERT) {
                                if (expenseRecordObjectsMap.containsKey('description')) expenseRecordObjectsMap.put('description',expenseObjectMap.get(expenseObjectMapKey));
                                if (expenseRecordObjectsMap.containsKey('expenseItems')) {
                                    List<Object> expenseItems = (List<Object>)expenseRecordObjectsMap.get('expenseItems');
                                    if (!expenseItems.isEmpty()) {
                                        Map<String, Object> expenseItemMap = (Map<String, Object>)expenseItems[0];
                                        if (expenseItemMap.containsKey('payElementCode')) expenseItemMap.put('payElementCode',expenseObjectMap.get(expenseObjectMapKey));
                                        if (expenseItemMap.containsKey('type')) expenseItemMap.put('type',expenseObjectMap.get(expenseObjectMapKey));
                                        if (expenseItemMap.containsKey('description')) expenseItemMap.put('description',expenseObjectMap.get(expenseObjectMapKey));
                                    }
                                }
                            } else if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE) {
                                if (expenseRecordObjectsMap.containsKey('payElementCode')) expenseRecordObjectsMap.put('payElementCode',expenseObjectMap.get(expenseObjectMapKey));
                                if (expenseRecordObjectsMap.containsKey('type')) expenseRecordObjectsMap.put('type',expenseObjectMap.get(expenseObjectMapKey));
                                if (expenseRecordObjectsMap.containsKey('description')) expenseRecordObjectsMap.put('description',expenseObjectMap.get(expenseObjectMapKey));
                            }
                        } else if (expenseObjectMapKey == 'value') {
                            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_INSERT) {
                                if (expenseRecordObjectsMap.containsKey('expenseItems')) {
                                    List<Object> expenseItems = (List<Object>)expenseRecordObjectsMap.get('expenseItems');
                                    if (!expenseItems.isEmpty()) {
                                        Map<String, Object> expenseItemMap = (Map<String, Object>)expenseItems[0];
                                        if (expenseItemMap.containsKey('grossValue')) expenseItemMap.put('grossValue',expenseObjectMap.get(expenseObjectMapKey));
                                    }
                                }
                            } else if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE) {
                                if (expenseRecordObjectsMap.containsKey('grossValue')) expenseRecordObjectsMap.put('grossValue',expenseObjectMap.get(expenseObjectMapKey));
                            }
                        }
                    }
                    XMLSerializer serializer = new XMLSerializer('ns');
                    String xmlBody = serializer.JSONToXML(JSON.serialize(expenseRecordObjectsMap),true);
                    List<String> recordValuesList = new List<String>{this.intimeToken,xmlBody};

                    //Sync Log
                    if (this.intimeSyncItemByRecordIdMap.containsKey(expenseId)) this.intimeSyncItemByRecordIdMap.get(expenseId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
                    httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectPayload,recordValuesList);
                    if (this.intimeSyncItemByRecordIdMap.containsKey(expenseId)) this.intimeSyncItemByRecordIdMap.get(expenseId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();
                    if (httpResponse.getStatusCode() == 200) {
                        Object expenseClaimId = IntimeWebserviceParser.getCreateOrUpdateResponse(
                            httpResponse.getBody(),
                            intimeObjectPayload.ResponseElementName__c
                        );
                        expenseClaimIds.add(String.valueOf(expenseClaimId));
                        // SUBMIT EXPENSE
                        if (expenseClaimId != null && !Boolean.valueOf(expenseRecord.get(sirenum__Expense__c.SubmittedInIntime__c.getDescribe().getName()))) {
                            intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_SUBMIT);
                            recordValuesList = new List<String>{this.intimeToken,String.valueOf(expenseClaimId)};
                            if (this.intimeSyncItemByRecordIdMap.containsKey(expenseId)) this.intimeSyncItemByRecordIdMap.get(expenseId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
                            httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectPayload,recordValuesList);
                            if (this.intimeSyncItemByRecordIdMap.containsKey(expenseId)) this.intimeSyncItemByRecordIdMap.get(expenseId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();
                        }
                        counter++;
                    } else {
                        hasError = true;
                        this.intimeSyncItemByRecordIdMap.get(expenseId).ErrorMessage__c +=  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                        this.intimeSyncItemByRecordIdMap.get(expenseId).InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                        this.errorMap.put(expenseId,true);
                    }
                }
            }
            if (!hasError && this.context == IntimeConstants.INTIME_SYNC_CONTEXT_INSERT) {
                expenseRecord.put(sirenum__Expense__c.InTimeId__c.getDescribe().getName(),String.join(expenseClaimIds,';'));
                expenseRecord.put(sirenum__Expense__c.LastIntimeSync__c.getDescribe().getName(),System.now());
            }
            if (!hasError) expenseRecord.put(sirenum__Expense__c.SubmittedInIntime__c.getDescribe().getName(),true);
        }
    }
}