/**
*  @description Helper class for bank details
**/
public without sharing class BankDetailsHelper {
    
    /**
    *  @description Method to validate and create intime sync items
    **/
    public static void validateAndCreateIntimeSyncItemsForParentRecords(List<Bank_Details__c> bankDetailsList, Map<Id, Bank_Details__c> bankDetailsMap) {
        List<Bank_Details__c> modifiedBankDetailsList = new List<Bank_Details__c>();
        Map<Id, Bank_Details__c> modifiedBankDetailsMap = new Map<Id, Bank_Details__c>();
        Set<Id> contactIds = new Set<Id>();
        for (Bank_Details__c bankDetail : bankDetailsList) {
            contactIds.add(bankDetail.Contact_Associated__c);
        }
        if (!contactIds.isEmpty()) {
            Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, LeaverInformationUpdatedInInTime__c FROM Contact WHERE Id IN: contactIds]);
            for (Bank_Details__c bankDetail : bankDetailsList) {
                if (bankDetail.Contact_Associated__c != null && contactsMap.containsKey(bankDetail.Contact_Associated__c) && !contactsMap.get(bankDetail.Contact_Associated__c).LeaverInformationUpdatedInInTime__c) {
                    modifiedBankDetailsList.add(bankDetail);
                    modifiedBankDetailsMap.put(bankDetail.Id, bankDetailsMap.get(bankDetail.Id));
                }
            }
            if (!modifiedBankDetailsList.isEmpty()) {
                IntimeSyncHelper.validateAndCreateIntimeSyncItemsForParentRecords(
                    Bank_Details__c.sObjectType.getDescribe().getName(),
                    modifiedBankDetailsList,
                    modifiedBankDetailsMap
                );
            }
        }
    }
}