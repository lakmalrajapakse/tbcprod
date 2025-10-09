/**
* @description Scheduler used to trigger the intime sync
**/
global without sharing class IntimeSyncScheduler implements Schedulable{
    
    /**
    * @description Execute method
    **/
    global void execute(SchedulableContext schedulableContext) {
        if (IntimeSyncHelper.IsInTimeBatchRunning()) {
            IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
        }
    }
}