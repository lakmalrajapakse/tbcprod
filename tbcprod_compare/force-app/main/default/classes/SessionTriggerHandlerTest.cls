/**
* @description Test class for session trigger handler
**/
@isTest(seeAllData=false)

public with sharing class SessionTriggerHandlerTest {
    
     /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){

        // Create sessions
        List<b3o__Session__c> sessionsList = TestDataCreator.createSessions(1);
        insert sessionsList;
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        List<b3o__Session__c> sessionsList = [SELECT Id FROM b3o__Session__c LIMIT 1];
        update sessionsList;
        Test.stopTest();
        Assert.areEqual(2,[SELECT COUNT() FROM b3o__Session__Share WHERE ParentId =: sessionsList[0].Id AND RowCause = 'PlanCode__c']);
    }
}