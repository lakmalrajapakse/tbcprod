/**
*   @description Wrapper class for record processor
**/
public without sharing class RecordProcessorHandler {
    
    /**
    *   @description : Apex class for used for timesheet approval
    **/
    public class TimesheetApprovalProcessor implements IRecordProcessor {
        
        /**
        *   @description : Method to approve timesheets
        **/
        public void processRecords(List<Id> recordIds) {
            List<sirenum__Timesheet__c> timeSheetsToUpdate = new List<sirenum__Timesheet__c>();
            for (Id timesheetId : recordIds) {
                timeSheetsToUpdate.add(new sirenum__Timesheet__c(
                    Id = timesheetId,
                    Status__c = IntimeConstants.TIMESHEET_STATUS_APPROVED
                ));
            }
            TimesheetHelper.TIMESHEET_APPROVED_IN_BATCH = true;
            if (!timeSheetsToUpdate.isEmpty()) update timeSheetsToUpdate;
        }

        /**
        *   @description : Method to approve timesheets
        **/
        public void finish(List<Id> recordIds) {
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            intimeDataManagerAsyncJobSetting.TimesheetApprovalJobId__c = '';
            upsert intimeDataManagerAsyncJobSetting;
            if (IntimeSyncHelper.IsInTimeBatchRunning()) {
                IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
            }
        }
    }

    /**
    *   @description : Apex class for used for holiday approval
    **/
    public class HolidayApprovalProcessor implements IRecordProcessor {
        
        /**
        *   @description : Method to approve timesheets
        **/
        public void processRecords(List<Id> recordIds) {
            List<sirenum__Employee_Request__c> employeeRequestsToUpdate = new List<sirenum__Employee_Request__c>();
            for (Id employeeRequestId : recordIds) {
                employeeRequestsToUpdate.add(new sirenum__Employee_Request__c(
                    Id = employeeRequestId,
                    SendToIntime__c = true
                ));
            }
            if (!employeeRequestsToUpdate.isEmpty()) update employeeRequestsToUpdate;
        }

        /**
        *   @description : Method to approve timesheets
        **/
        public void finish(List<Id> recordIds) {
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            intimeDataManagerAsyncJobSetting.HolidayApprovalJobId__c = '';
            upsert intimeDataManagerAsyncJobSetting;
            if (IntimeSyncHelper.IsInTimeBatchRunning()) {
                IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
            }
        }
    }

    /**
    *   @description : Apex class to send accounts to intime
    **/
    public class AccountSendProcessor implements IRecordProcessor {
        
        /**
        *   @description : Method to send clients to intime
        **/
        public void processRecords(List<Id> recordIds) {
            List<Account> accountsToUpdate = new List<Account>();
            for (Id contactId : recordIds) {
                accountsToUpdate.add(new Account(
                    Id = contactId,
                    SendToIntime__c = true
                ));
            }
            if (!accountsToUpdate.isEmpty()) update accountsToUpdate;
        }

        /**
        *   @description : Method to trigger batch 
        **/
        public void finish(List<Id> recordIds) {
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            intimeDataManagerAsyncJobSetting.AccountSendJobId__c = '';
            upsert intimeDataManagerAsyncJobSetting;
            if (IntimeSyncHelper.IsInTimeBatchRunning()) {
                IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
            }
        }
    }

    /**
    *   @description : Apex class to send contacts to intime
    **/
    public class ContactSendProcessor implements IRecordProcessor {
        
        /**
        *   @description : Method to send workers to intime
        **/
        public void processRecords(List<Id> recordIds) {
            List<Contact> contactsToUpdate = new List<Contact>();
            for (Id contactId : recordIds) {
                contactsToUpdate.add(new Contact(
                    Id = contactId,
                    SendToIntime__c = true
                ));
            }
            if (!contactsToUpdate.isEmpty()) update contactsToUpdate;
        }

        /**
        *   @description : Method to trigger batch
        **/
        public void finish(List<Id> recordIds) {
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            intimeDataManagerAsyncJobSetting.ContactSendJobId__c = '';
            upsert intimeDataManagerAsyncJobSetting;
            if (IntimeSyncHelper.IsInTimeBatchRunning()) {
                IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
            }
        }
    }

    /**
    *   @description : Apex class to send contacts to intime
    **/
    public class PlacementSendProcessor implements IRecordProcessor {
        
        /**
        *   @description : Method to send placements to intime
        **/
        public void processRecords(List<Id> recordIds) {
            List<sirenum__Placement__c> placementsToUpdate = new List<sirenum__Placement__c>();
            for (Id placementId : recordIds) {
                placementsToUpdate.add(new sirenum__Placement__c(
                    Id = placementId,
                    SendToIntime__c = true
                ));
            }
            if (!placementsToUpdate.isEmpty()) update placementsToUpdate;
        }

        /**
        *   @description : Method to approve timesheets
        **/
        public void finish(List<Id> recordIds) {
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            intimeDataManagerAsyncJobSetting.PlacementSendJobId__c = '';
            upsert intimeDataManagerAsyncJobSetting;
            if (IntimeSyncHelper.IsInTimeBatchRunning()) {
                IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
            }
        }
    }

    /**
    *   @description : Apex class to revert timesheets in intime
    **/
    public class TimesheetRevertProcessor implements IRecordProcessor {
        
        /**
        *   @description : Method to revert timesheets in intime
        **/
        public void processRecords(List<Id> recordIds) {
            List<sirenum__Timesheet__c> timesheetsToUpdate = new List<sirenum__Timesheet__c>();
            for (Id timesheetId : recordIds) {
                timesheetsToUpdate.add(new sirenum__Timesheet__c(
                    Id = timesheetId,
                    SendToIntime__c = true
                ));
            }
            if (!timesheetsToUpdate.isEmpty()) update timesheetsToUpdate;
        }

        /**
        *   @description : Method to approve timesheets
        **/
        public void finish(List<Id> recordIds) {
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            intimeDataManagerAsyncJobSetting.TimesheetRevertJobId__c = '';
            upsert intimeDataManagerAsyncJobSetting;
            if (IntimeSyncHelper.IsInTimeBatchRunning()) {
                IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
            }
        }
    }

    /**
    *   @description : Apex class to revert expenses in intime
    **/
    public class ExpenseRevertProcessor implements IRecordProcessor {
        
        /**
        *   @description : Method to revert timesheets to intime
        **/
        public void processRecords(List<Id> recordIds) {
            List<sirenum__Expense__c> expensesToUpdate = new List<sirenum__Expense__c>();
            for (Id expenseId : recordIds) {
                expensesToUpdate.add(new sirenum__Expense__c(
                    Id = expenseId,
                    SendToIntime__c = true
                ));
            }
            if (!expensesToUpdate.isEmpty()) update expensesToUpdate;
        }

        /**
        *   @description : Method to approve timesheets
        **/
        public void finish(List<Id> recordIds) {
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            intimeDataManagerAsyncJobSetting.ExpenseRevertJobId__c = '';
            upsert intimeDataManagerAsyncJobSetting;
            if (IntimeSyncHelper.IsInTimeBatchRunning()) {
                IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
            }
        }
    }
}