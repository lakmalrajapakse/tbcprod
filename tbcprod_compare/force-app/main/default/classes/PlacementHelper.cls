/**
* @description Helper class for Placement
**/
public without sharing class PlacementHelper {
    
    /**
    *  @description Method to validate and create intime sync items
    **/
    public static void validateAndCreateIntimeSyncItems(List<sirenum__Placement__c> placementsList, Map<Id, sirenum__Placement__c> placementsMap) {
        List<sirenum__Placement__c> modifiedPlacemensList = new List<sirenum__Placement__c>();
        Map<Id, sirenum__Placement__c> modifiedPlacementsMap = new Map<Id, sirenum__Placement__c>();
        Set<Id> contactIds = new Set<Id>();
        for (sirenum__Placement__c placement : placementsList) {
            contactIds.add(placement.sirenum__Contact__c);
        }
        if (!contactIds.isEmpty()) {
            Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, LeaverInformationUpdatedInInTime__c FROM Contact WHERE Id IN: contactIds]);
            for (sirenum__Placement__c placement : placementsList) {
                if (placement.sirenum__Contact__c != null && contactsMap.containsKey(placement.sirenum__Contact__c) && !contactsMap.get(placement.sirenum__Contact__c).LeaverInformationUpdatedInInTime__c) {
                    modifiedPlacemensList.add(placement);
                    modifiedPlacementsMap.put(placement.Id, placementsMap.get(placement.Id));
                }
            }
            if (!modifiedPlacemensList.isEmpty()) {
                IntimeSyncHelper.validateAndCreateIntimeSyncItems(
                    sirenum__Placement__c.sObjectType.getDescribe().getName(),
                    InTimeSyncItem__c.Placement__c.getDescribe().getName(),
                    modifiedPlacemensList,
                    modifiedPlacementsMap
                );
            }
        }
    }
}