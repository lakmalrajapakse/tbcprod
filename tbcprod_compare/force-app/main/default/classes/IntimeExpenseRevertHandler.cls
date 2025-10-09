/**
*  @description Apex class to manage the expense data to revert in intime
**/
public without sharing class IntimeExpenseRevertHandler extends IntimeSyncHandler implements IIntimeSyncHandler{
    
    private sObject record;
    @testVisible
    private static Boolean throwException = false;

    /**
    *  @description Constructor]
    **/
    public IntimeExpenseRevertHandler() {
        super();
    }

    /**
    *  @description Method to trigger the intime sync
    **/
    public void syncToIntime(List<InTimeSyncItem__c> inTimeSyncItemsList, InTimeObject__mdt inTimeObject) {
        try {
            this.setIntimeSyncItems(inTimeSyncItemsList);
            this.resetIntimeSyncItems();

            if (throwException) throw new IntimeException('Test Exception');

            // fetch record from the system
            this.getRecords(this.getRecordIds(inTimeSyncItemsList), inTimeObject);

            this.record = !this.recordsList.isEmpty() ? this.recordsList[0] : null;

            revertExpense(inTimeSyncItemsList[0], inTimeObject);
            this.updateRecords();
            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_EXPENSE_REVERT);
        }catch(Exception ex){
            for (InTimeSyncItem__c intimeSyncItem : this.intimeSyncItemByRecordIdMap.values()) {
                intimeSyncItem.ErrorMessage__c =  JSON.serialize(ex.getMessage());
                intimeSyncItem.InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+JSON.serialize(ex.getMessage());
                this.errorMap.put(intimeSyncItem.SourceRecordId__c,true);
            }
            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_EXPENSE_REVERT);
        }
    }

    /**
    *  @description Method to get additional fields to query for processing
    **/
    public override Set<String> getAdditionalFields() {
        Set<String> additionalFieldsList = new Set<String>{sirenum__Timesheet__c.SendToIntime__c.getDescribe().getName()};
        return additionalFieldsList;
    }

    /**
    *  @description Method to create or update client in intime
    **/
    private void revertExpense(InTimeSyncItem__c inTimeSyncItem, InTimeObject__mdt inTimeObject) {
        String clientId = '';
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST);
        List<String> recordValuesList = new List<String>{this.intimeToken,String.valueOf(this.record.get('IntimeId__c'))};

        //Placement record
        this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
        HttpResponse httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectPayload,recordValuesList);
        this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();

        if (httpResponse.getStatusCode() == 200) {
            this.record.put('SendToIntime__c', false);
            this.record.put('IntimeId__c','');
        } else {
            this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).ErrorMessage__c =  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
            this.errorMap.put(inTimeSyncItem.SourceRecordId__c, true);
        }
    }
    public class IntimeException extends Exception {}
}