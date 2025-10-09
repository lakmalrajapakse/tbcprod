trigger JobOrderTrigger on sirenum__JobOrder__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new JobOrderTriggerHandler().run();
}