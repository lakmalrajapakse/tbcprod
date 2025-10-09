/** 
*  @description : Apex controller used to trigger the intime reverse sync
*
**/
public with sharing class IntimeReverseSyncController {
    
    private Apexpages.standardSetController standardSetController;

    /** 
    *  @description : Constructor
    **/ 
    public IntimeReverseSyncController(Apexpages.standardSetController standardSetController){
        this.standardSetController = standardSetController;
    }

    /** 
    *  @description : Redirect to list view page
    **/ 
    public PageReference returnToListViewPage() {
        try{
            List<Object> objectsList = new List<Object>();
            List<sObject> selectedRecordsList = (List<sObject>)this.standardSetController.getSelected();
            String sObjectName = selectedRecordsList[0].getSObjectType().getDescribe().getName();
            List<sObject> recordsList = (List<sObject>)Database.query('SELECT Id, IntimeId__c FROM '+sObjectName+' WHERE Id IN: selectedRecordsList AND IntimeId__c != null');
            for (sObject record : recordsList){
                objectsList.add(new Map<String,Object>{
                    'type' => sObjectName == 'Contact' ? 'Worker' : 'Timesheet',
                    'id' => record.get('IntimeId__c')
                });
            }
            if (!objectsList.isEmpty()) Database.executeBatch(new IntimeReverseSyncBatch(objectsList),1);
            return new PageReference('/'+Schema.getGlobalDescribe().get(sObjectName).getDescribe().getKeyPrefix()).setRedirect(true);
        }catch(Exception ex){
            System.debug('Message is '+ex.getMessage());
        }
        return null;
    }
}