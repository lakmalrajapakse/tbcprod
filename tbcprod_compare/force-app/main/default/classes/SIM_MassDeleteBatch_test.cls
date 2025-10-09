@isTest
public with sharing class SIM_MassDeleteBatch_test {    

    static void createTestData(){
        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        insert invoiceTermsList;

        // Create Picklist Libraries
        List<Picklist_Library__c> picklistLibrariesList = TestDataCreator.createPicklistLibraries(1);
        insert picklistLibrariesList;

        // Create Account 
        List<Account> accountsList = TestDataCreator.createClients(
            2, 
            invoiceTermsList[0].Id,
            picklistLibrariesList[0].Id
        );
        insert accountsList;        
    }

    @IsTest
    static void test_Batch(){
        createTestData();
        
        List<Account> accounts = [SELECT Id FROM Account];
        system.assertEquals(2, accounts.size());

        Test.startTest();
        Database.executeBatch(new SIM_MassDeleteBatch('Account', 'Id = \'' + accounts[0].Id + '\''));
        Test.stopTest();

        List<Account> leftovers = [SELECT Id FROM Account];
        system.assertEquals(1, leftovers.size());        
    }
}