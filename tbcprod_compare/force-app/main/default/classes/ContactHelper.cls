/**
*  @description Helper class for contact
**/
public without sharing class ContactHelper {
    
    /**
    *  @description Method to validate and create intime sync items
    **/
    public static void validateAndCreateIntimeSyncItems(List<Contact> contactsList, Map<Id, Contact> contactsMap) {
        List<Contact> modifiedContactsList = new List<Contact>();
        Map<Id, Contact> modifiedContactsMap = new Map<Id, Contact>();

        for (Contact contact : contactsList) {
            if (!contact.LeaverInformationUpdatedInInTime__c) {
                modifiedContactsList.add(contact);
                modifiedContactsMap.put(contact.Id, contactsMap.get(contact.Id));
            }
        }

        if (!modifiedContactsList.isEmpty()) {
            IntimeSyncHelper.validateAndCreateIntimeSyncItems(
                Contact.sObjectType.getDescribe().getName(),
                InTimeSyncItem__c.Person__c.getDescribe().getName(),
                modifiedContactsList,
                modifiedContactsMap
            );
        }
    }
}