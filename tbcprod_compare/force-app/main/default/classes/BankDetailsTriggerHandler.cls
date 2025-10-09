/**
* @description Trigger handler for Bank Account
**/
public without sharing class BankDetailsTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        BankDetailsHelper.validateAndCreateIntimeSyncItemsForParentRecords((List<Bank_Details__c>)Trigger.new,(Map<Id, Bank_Details__c>)Trigger.oldMap);
	}
}