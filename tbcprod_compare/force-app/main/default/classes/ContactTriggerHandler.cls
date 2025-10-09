/**
* @description Trigger handler for Contact
**/
public without sharing class ContactTriggerHandler extends TriggerHandler{

	/**
	* @description Function to handle the after update trigger event
	**/
	public override void afterInsert() {
        SharingHelper.manageSharing(
            Contact.sObjectType.getDescribe().getName(),
            Trigger.new,
            null,
            SharingHelper.TriggerContext.RECORDCREATE
        );
	}
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        ContactHelper.validateAndCreateIntimeSyncItems((List<Contact>)Trigger.new,(Map<Id, Contact>)Trigger.oldMap);
		SharingHelper.manageSharing(
            Contact.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}
}