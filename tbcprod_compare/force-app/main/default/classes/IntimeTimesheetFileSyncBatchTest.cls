/**
*   @description Test class for IntimeTimesheetFileSyncBatch
**/
@isTest(seeAllData=false)
private with sharing class IntimeTimesheetFileSyncBatchTest {
    
    /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){

        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        insert invoiceTermsList;

        // Create Picklist Libraries
        List<Picklist_Library__c> picklistLibrariesList = TestDataCreator.createPicklistLibraries(1);
        insert picklistLibrariesList;

        // Create Account 
        List<Account> accountsList = TestDataCreator.createClients(
            1, 
            invoiceTermsList[0].Id,
            picklistLibrariesList[0].Id
        );
        insert accountsList;

        // create credit checks
        List<Credit_Check__c> creditChecksList = TestDataCreator.createCreditChecks(
            1, 
            accountsList[0].Id
        );
        insert creditChecksList;
        accountsList[0].Credit_Check__c = creditChecksList[0].Id;
        update accountsList;

        // create contacts 
        List<Contact> contactsList =  TestDataCreator.createContacts(
            1,
            accountsList
        );
        contactsList[0].InTimeExternalId__c = 'Person-2';
        contactsList[0].LeaverInformationUpdatedInInTime__c = true;
        insert contactsList;

        // Create sites
        List<sirenum__Site__c> sitesList = TestDataCreator.createSites(1);
        insert sitesList;

        // Create contracts
        List<sirenum__ProActiveContract__c> contractsList = TestDataCreator.createContracts(
            1,
            accountsList[0].Id
        );
        insert contractsList;

        // Create job roles
        List<sirenum__Team__c> jobRolesList = TestDataCreator.createJobRoles(
            1,
            contractsList[0].Id
        );
        insert jobRolesList;

        // Create placements
        List<sirenum__Placement__c> placementsList = TestDataCreator.createPlacements(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id
        );
        insert placementsList;

        // Create payroll cycles
        List<sirenum__Payroll_Cycle__c> payrollCyclesList = TestDataCreator.createPayrollCycles(1);
        insert payrollCyclesList;

        // Create weeks
        List<sirenum__Week__c> weeksList = TestDataCreator.createWeeks(
            1,
            payrollCyclesList[0].Id
        );
        insert weeksList;

        // Create timesheets
        List<sirenum__Timesheet__c> timesheetsList = TestDataCreator.createTimesheets(
            1,
            accountsList[0].Id,
            contractsList[0].Id,
            weeksList[0].Id,
            contactsList[0].Id
        );
        insert timesheetsList;

        // Create shifts
        List<sirenum__Shift__c> shiftsList = TestDataCreator.createShifts(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id,
            placementsList[0].Id
        );
        insert shiftsList;

        // Create Timesheet lines
        List<sirenum__Timesheet_Line__c> timesheetLinesList = TestDataCreator.createTimesheetLines(
            1,
            timesheetsList[0].Id,
            new Map<Id, sirenum__Shift__c>(shiftsList).keySet()
        );
        insert timesheetLinesList;

        // Create Expenses
        List<sirenum__Expense__c> expensesList = TestDataCreator.createExpenses(
            1,
            timesheetsList[0].Id
        );
        insert expensesList;

        // create content versions 
        List<ContentVersion> contentVersionsList = TestDataCreator.createContentVersion(1);
        contentVersionsList[0].Is_Timesheet_Proof_Document__c = true;
        insert contentVersionsList;

        // create content document link
        List<ContentDocumentLink> contentDocumentLinksList = TestDataCreator.createContentDocumentLinks(
            new Map<Id, ContentVersion>(contentVersionsList).keySet(),
            new Map<Id, sirenum__Timesheet__c>(timesheetsList).keySet()
        );
        insert contentDocumentLinksList;

        // create employee request
        List<sirenum__Employee_Request__c> employeeRequestsList = TestDataCreator.createEmployeeRequests(
            1,
            contactsList[0].Id
        );
        insert employeeRequestsList;
    }

    /**
    *   @description : Test IntimeSyncBatchForTimesheet
    **/
    @isTest
    static void test_IntimeSyncBatchForTimesheet(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual(null, timesheetsList[0].InTimeId__c);
        Assert.areEqual('Not Synced', timesheetsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, timesheetsList[0].LastIntimeSync__c);
        timesheetsList[0].InTimeId__c = '1210910';
        update timesheetsList;

        // create intime sync item
        List<InTimeSyncItem__c> intimeSyncItemsList = TestDataCreator.createIntimeSyncItems(
            null,
            null,
            null,
            timesheetsList[0].Id,
            null,
            null
        );
        intimeSyncItemsList[0].Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED;
        intimeSyncItemsList[0].Type__c = IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET_FILE;
        insert intimeSyncItemsList;
        List<InTimeObject__mdt> intimeObjectsList = IntimeSyncProcessor.getIntimeObject(IntimeConstants.INTIME_OBJECT_TIMESHEET_FILE_DEVELOPER_NAME);
        Database.executeBatch(new IntimeTimesheetFileSyncBatch(intimeObjectsList[0]),1);
        Test.stopTest();
        timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual('1210910', timesheetsList[0].InTimeId__c);
        Assert.areEqual('Synced', timesheetsList[0].InTimeSyncStatus__c);
        List<sirenum__Expense__c> expensesList = [SELECT Id, InTimeId__c FROM sirenum__Expense__c LIMIT 1];
    }

    /**
    *   @description : Test IntimeSyncBatchForTimesheet
    **/
    @isTest
    static void test_IntimeSyncBatchForTimesheet_ThrowException(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual(null, timesheetsList[0].InTimeId__c);
        Assert.areEqual('Not Synced', timesheetsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, timesheetsList[0].LastIntimeSync__c);
        timesheetsList[0].InTimeId__c = '1210910';
        update timesheetsList;

        // create intime sync item
        List<InTimeSyncItem__c> intimeSyncItemsList = TestDataCreator.createIntimeSyncItems(
            null,
            null,
            null,
            timesheetsList[0].Id,
            null,
            null
        );
        intimeSyncItemsList[0].Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED;
        intimeSyncItemsList[0].Type__c = IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET_FILE;
        insert intimeSyncItemsList;
        List<InTimeObject__mdt> intimeObjectsList = IntimeSyncProcessor.getIntimeObject(IntimeConstants.INTIME_OBJECT_TIMESHEET_FILE_DEVELOPER_NAME);
        IntimeTimesheetFileSyncBatch.throwException = true;
        Database.executeBatch(new IntimeTimesheetFileSyncBatch(intimeObjectsList[0]),1);
        Test.stopTest();
        timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual('1210910', timesheetsList[0].InTimeId__c);
        Assert.areEqual('Synced', timesheetsList[0].InTimeSyncStatus__c);
        List<sirenum__Expense__c> expensesList = [SELECT Id, InTimeId__c FROM sirenum__Expense__c LIMIT 1];
    }
}