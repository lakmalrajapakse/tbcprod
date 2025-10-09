/**
* @description Test class for leads
**/
@isTest(seeAllData=false)
private with sharing class LeadTriggerHandlerTest {
    
     /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){
        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        insert invoiceTermsList;

        // Create regions
        List<Region__c> regionsList = TestDataCreator.createRegions(1);
        insert regionsList;

        // Create areas
        List<Area__c> areasList = TestDataCreator.createAreas(
            1,
            regionsList[0].Id
        );
        insert areasList;

        // Create branches
        List<Branch__c> branchesList = TestDataCreator.createBranches(
            1,
            areasList[0].Id
        );
        insert branchesList;

        // Create Picklist Libraries
        List<Picklist_Library__c> picklistLibrariesList = TestDataCreator.createPicklistLibraries(
            1,
            branchesList[0].Id
        );
        insert picklistLibrariesList;

        // Create Account 
        List<Lead__c> leadsList = TestDataCreator.createLeads(
            1, 
            picklistLibrariesList[0].Id
        );
        insert leadsList;
    }

     /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        List<Lead__c> leadsList = [SELECT Id FROM Lead__c LIMIT 1];
        update leadsList;
        Test.stopTest();
        Assert.areEqual(2,[SELECT COUNT() FROM Lead__Share WHERE ParentId =: leadsList[0].Id AND RowCause = 'PlanCode__c']);
    }
}