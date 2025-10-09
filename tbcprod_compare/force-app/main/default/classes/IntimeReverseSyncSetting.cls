/**
* @description : Apex class to manage intime reverse sync settting
**/
public without sharing class IntimeReverseSyncSetting {
    
    private static IntimeReverseSyncSetting__c inTimeReverseSyncSetting;

    static {
        if (inTimeReverseSyncSetting == null) {
            inTimeReverseSyncSetting = IntimeReverseSyncSetting__c.getInstance();
        }
    }

    /**
    * @description Method to get date time when last ran sucessfully
    **/
    public static DateTime getDateTimeWhenSyncLastRanSuccessfully(){
        return inTimeReverseSyncSetting?.DateTimeWhenSyncLastRanSuccess__c != null ? inTimeReverseSyncSetting.DateTimeWhenSyncLastRanSuccess__c : null;
    }

    /**
    * @description Method to get until
    **/
    public static DateTime getUntil(){
        return inTimeReverseSyncSetting?.Until__c != null ? inTimeReverseSyncSetting.Until__c : null;
    }
}