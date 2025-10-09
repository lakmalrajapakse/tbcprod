/**
* @description Trigger handler for Placement
**/
public without sharing class PlacementTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        PlacementHelper.validateAndCreateIntimeSyncItems((List<sirenum__Placement__c>)Trigger.new,(Map<Id, sirenum__Placement__c>)Trigger.oldMap);
	}
}