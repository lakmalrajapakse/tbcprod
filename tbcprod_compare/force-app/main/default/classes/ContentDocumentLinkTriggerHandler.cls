/**
* @description : Trigger Handler for Content Document Link  
**/
public without sharing class ContentDocumentLinkTriggerHandler extends TriggerHandler{
    /**
	* @description Method to handle after insert trigger event
	**/
    public override void afterInsert() {
        ContentDocumentLinkTriggerHelper.manageContentDocumentsForTimesheets((List<ContentDocumentLink>)Trigger.new);
	}

    /**
	* @description Method to handle before insert trigger event
	**/
    public override void beforeInsert() {
        ContentDocumentLinkTriggerHelper.validateContentDocumentsForTimesheets((List<ContentDocumentLink>)Trigger.new);
	}
}