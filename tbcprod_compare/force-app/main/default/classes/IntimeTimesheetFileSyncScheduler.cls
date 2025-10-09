/**
* @description Scheduler used to trigger the intime timesheet file sync
**/
global without sharing class IntimeTimesheetFileSyncScheduler implements Schedulable{
    
    /**
    * @description Execute method
    **/
    global void execute(SchedulableContext schedulableContext) {
        if (IntimeSyncHelper.IsInTimeTimesheetFileBatchRunning()) {
            List<InTimeObject__mdt> intimeObjectsList = IntimeSyncProcessor.getIntimeObject(IntimeConstants.INTIME_OBJECT_TIMESHEET_FILE_DEVELOPER_NAME);
            if (!intimeObjectsList.isEmpty()) {
                Database.executeBatch(new IntimeTimesheetFileSyncBatch(intimeObjectsList[0]),1);
            }
        }
    }
}