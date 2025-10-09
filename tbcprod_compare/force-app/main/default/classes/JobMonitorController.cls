/**
*  @description Apex class to manage apex jobs
**/
public without sharing class JobMonitorController {
    
    /**
    *  @description Method to get the status of the batch jobs
    *  @param batchId Id of the batch job
    **/
    @AuraEnabled
    public static Object checkBatchStatus(String batchId){
        return [SELECT Id, Status, NumberOfErrors, TotalJobItems, JobItemsProcessed FROM AsyncApexJob WHERE Id = :batchId];
    }     
}