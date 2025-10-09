trigger X3BReferenceTrigger on b3o__Reference__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new X3BReferenceTriggerHandler().run();
}