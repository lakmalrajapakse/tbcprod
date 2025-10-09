/**
*   @description : Apex class to fetch the datatable 
**/
public without sharing class DatatableController {
    
    /**
    *   @description : Method to used to fetch the datatable attributes
    *   @param dataTableParams params for the datatable to fetch the data from open
    *   @return Map<String, Object> Map contains open data and field information for lightning datatable
    **/
    @AuraEnabled
    public static Map<String,Object> getDatatable(Map<String, Object> dataTableParams) {
        try{
            if(dataTableParams != null 
            && !dataTableParams.isEmpty()) {
                Type classType = Type.forName((String)dataTableParams.get('className'));
                if(classType == null || !iDataTable.class.isAssignableFrom(classType)) {
                    throw new DataTableException('Invalid Datatable');
                }
                iDataTable datatable = (iDataTable)Type.forName(
                    (String)dataTableParams.get('className')).newInstance();
                return datatable.getDatatableAttributes(dataTableParams);
            }
        }catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }   
        return new Map<String,Object>();
    }

    /**
    *   @description : Method to save the records
    *   @return Object created record.
    **/
    @AuraEnabled
    public static Object saveRecords(Map<String, Object> dataTableParams) {
        try{
            if(dataTableParams != null 
                && !dataTableParams.isEmpty()) {
                Type classType = Type.forName((String)dataTableParams.get('className'));
                if(classType == null || !iDataTable.class.isAssignableFrom(classType)) {
                    throw new DataTableException('Invalid Datatable');
                }
                iDataTable datatable = (iDataTable)Type.forName(
                    (String)dataTableParams.get('className')).newInstance();
                return datatable.saveRecords(dataTableParams);
            }
        }catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }   
        return null;
    }

    /**
    *   @description : Apex class for used for timesheet approval
    **/
    public class TimesheetApprovalController implements IDatatable {
        
        /**
        *   @description : Method to get the datatable attributes
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return Map<String, Object> Map contains open data and field information for lightning datatable
        **/
        public Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams) {
            Map<String, Object> objectsMap = new Map<String, Object>();
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            objectsMap.put('columns',getColumns());
            objectsMap.put('data',getData(dataTableParams));
            objectsMap.put('planCodes',DatatableHelper.getPlanCodes());
            objectsMap.put('ayncJobId',intimeDataManagerAsyncJobSetting.TimesheetApprovalJobId__c);
            objectsMap.put('ayncJobStatus',!String.isBlank(intimeDataManagerAsyncJobSetting.TimesheetApprovalJobId__c) ? IntimeSyncHelper.IsRecordProcessorBatchRunning(intimeDataManagerAsyncJobSetting.TimesheetApprovalJobId__c) : false);
            return objectsMap;
        }

        /**
        *   @description : Method to get the datatable columns
        *   @return List<Map<String,Object>> List of columns to be displayed in the datatable
        **/
        public List<Map<String,Object>> getColumns() {
            List<Map<String,Object>> columnsList = new List<Map<String,Object>>();
            columnsList.add(new Map<String,Object> {
                'label' => 'Name',
                'fieldName' => 'timesheetUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'Name'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Worker',
                'fieldName' => 'workerUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'workerName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Placement',
                'fieldName' => 'placementUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'placementName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Week',
                'fieldName' => 'weekUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'weekName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Total Charge',
                'fieldName' => 'sirenum__Total_Charge__c', 
                'type' => 'currency'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Total Pay',
                'fieldName' => 'sirenum__Total_Pay__c', 
                'type' => 'currency'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Gross Margin',
                'fieldName' => 'sirenum__Profit__c', 
                'type' => 'currency'
            });
            return columnsList;
        }

         /**
        *   @description : Method to get the data from OPEN
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return List<Object> List of data from open
        **/
        public List<Object> getData(Map<String, Object> dataTableParams) {
            List<Object> objectsList = new List<Object>();
            List<String> filterStringList = new List<String>();
            if (dataTableParams.containsKey('filters')) {
                Set<String> planCodesList = new Set<String>();
                Map<String, Object> filtersMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataTableParams.get('filters')));
                if (filtersMap.containsKey('plancodes') && !String.isBlank(String.valueOf(filtersMap.get('plancodes')))) planCodesList.addAll(new List<String>(String.valueOf(filtersMap.get('plancodes')).replace('(','').replace(')','').deleteWhitespace().split(',')));
                if (filtersMap.containsKey('branches') && !String.isBlank(String.valueOf(filtersMap.get('branches'))))  planCodesList.addAll(DatatableHelper.getPlanCodesForBranches(new Set<String>(new List<String>(String.valueOf(filtersMap.get('branches')).replace('(','').replace(')','').deleteWhitespace().split(',')))));
                if (!planCodesList.isEmpty()) filterStringList.add('Plan_Code__c IN (\'' + String.join(new List<String>(planCodesList),'\',\'') + '\')');
                if (filtersMap.containsKey('accounts') && !String.isBlank(String.valueOf(filtersMap.get('accounts'))) && String.valueOf(filtersMap.get('accounts')) != '()') filterStringList.add('sirenum__Client__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('accounts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
                if (filtersMap.containsKey('contacts') && !String.isBlank(String.valueOf(filtersMap.get('contacts'))) && String.valueOf(filtersMap.get('contacts')) != '()') filterStringList.add('sirenum__Worker__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('contacts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
                if (filtersMap.containsKey('weeks') && !String.isBlank(String.valueOf(filtersMap.get('weeks'))) && String.valueOf(filtersMap.get('weeks')) != '()') filterStringList.add('sirenum__Week__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('weeks')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
            }
            String soqlQuery = 'SELECT Id, Name, sirenum__Worker__c, sirenum__Worker__r.Name, Placement__c, Placement__r.Name, '+
                'sirenum__Week__c, sirenum__Week__r.Name, sirenum__Total_Charge__c, sirenum__Total_Pay__c, sirenum__Profit__c FROM sirenum__Timesheet__c '+
                   'WHERE Status__c = \''+IntimeConstants.TIMESHEET_STATUS_SUBMITTED+'\' '+(!filterStringList.isEmpty() ? 'AND '+String.join(filterStringList,' AND ') : '')+' ORDER BY Name LIMIT 50000';
            System.debug('Query is '+soqlQuery);
            List<sirenum__Timesheet__c> timesheetsList = (List<sirenum__Timesheet__c>)Database.query(soqlQuery);
            for (sirenum__Timesheet__c timesheet : timesheetsList) {
                Map<String, Object> objectsMap = new Map<String, Object>();
                objectsMap.putAll(timesheet.getPopulatedFieldsAsMap());
                objectsMap.put('workerUrl',timesheet.sirenum__Worker__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.sirenum__Worker__c : '');
                objectsMap.put('workerName',timesheet.sirenum__Worker__r.Name);
                objectsMap.put('placementUrl',timesheet.Placement__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.Placement__c : '');
                objectsMap.put('placementName',timesheet.Placement__r.Name);
                objectsMap.put('weekUrl',timesheet.sirenum__Week__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.sirenum__Week__c : '');
                objectsMap.put('weekName',timesheet.sirenum__Week__r.Name);
                objectsMap.put('timesheetUrl',URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.Id);
                objectsList.add(objectsMap);
            }
            return objectsList;
        }

        /** 
        * @description : Method to create a new note in open
        * @param openDataParams open data params
        **/ 
        public Object saveRecords(Map<String, Object> dataTableParams) {
            List<sirenum__Timesheet__c> timeSheetsToUpdate = new List<sirenum__Timesheet__c>();
            List<Id> timesheetIdsList = (List<Id>)JSON.deserialize(String.valueOf(dataTableParams.get('timesheetIds')),List<Id>.class);
            List<IntimeDataManagerSetting__mdt> intimeDataManagerSetting = [SELECT Id, BatchSize__c, HandlerName__c FROM IntimeDataManagerSetting__mdt WHERE Type__c = 'Timesheet Approval' LIMIT 1];
            if (timesheetIdsList.size() <= 1 && !Test.isRunningTest()) {
                IRecordProcessor recordProcessor = (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance();
                if (recordProcessor != null) recordProcessor.processRecords(timesheetIdsList);
            } else {
                Id apexJobId = Database.executeBatch(new RecordProcessorBatch(
                    new RecordProcessor(
                        timesheetIdsList,
                        (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance()
                    )
                ),(intimeDataManagerSetting[0].BatchSize__c != null ? Integer.valueOf(intimeDataManagerSetting[0].BatchSize__c) : 200));
                IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
                intimeDataManagerAsyncJobSetting.TimesheetApprovalJobId__c = apexJobId;
                upsert intimeDataManagerAsyncJobSetting;
                return new Map<String, Object>{
                    'apexJobId' => apexJobId,
                    'success' => true
                };
            }
            return new Map<String, Object>{
                'apexJobId' => '',
                'success' => true
            };
        }
    }

     /**
    *   @description : Apex class for used for timesheet approval
    **/
    public class HolidayApprovalController implements IDatatable {
        
        /**
        *   @description : Method to get the datatable attributes
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return Map<String, Object> Map contains open data and field information for lightning datatable
        **/
        public Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams) {
            Map<String, Object> objectsMap = new Map<String, Object>();
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            objectsMap.put('columns',getColumns());
            objectsMap.put('data',getData(dataTableParams));
            objectsMap.put('planCodes',DatatableHelper.getPlanCodes());
            objectsMap.put('ayncJobId',intimeDataManagerAsyncJobSetting.HolidayApprovalJobId__c);
            objectsMap.put('ayncJobStatus',!String.isBlank(intimeDataManagerAsyncJobSetting.HolidayApprovalJobId__c) ? IntimeSyncHelper.IsRecordProcessorBatchRunning(intimeDataManagerAsyncJobSetting.HolidayApprovalJobId__c) : false);
            return objectsMap;
        }

        /**
        *   @description : Method to get the datatable columns
        *   @return List<Map<String,Object>> List of columns to be displayed in the datatable
        **/
        public List<Map<String,Object>> getColumns() {
            List<Map<String,Object>> columnsList = new List<Map<String,Object>>();
            columnsList.add(new Map<String,Object> {
                'label' => 'Name',
                'fieldName' => 'employeeRequestUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'Name'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Worker',
                'fieldName' => 'workerUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'workerName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Start Time',
                'fieldName' => 'sirenum__Start_Time__c', 
                'type' => 'date',
                'typeAttributes' => new Map<String, Object>{
                    'year' => 'numeric',
                    'month' =>  '2-digit',
                    'day' => '2-digit',
                    'hour' => '2-digit',
                    'minute' => '2-digit'
                }
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'End Time',
                'fieldName' => 'sirenum__End_Time__c', 
                'type' => 'date',
                'typeAttributes' => new Map<String, Object>{
                    'year' => 'numeric',
                    'month' =>  '2-digit',
                    'day' => '2-digit',
                    'hour' => '2-digit',
                    'minute' => '2-digit'
                }
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Description',
                'fieldName' => 'sirenum__Description__c', 
                'type' => 'text'
            });
            return columnsList;
        }

         /**
        *   @description : Method to get the data from OPEN
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return List<Object> List of data from open
        **/
        public List<Object> getData(Map<String, Object> dataTableParams) {
            List<Object> objectsList = new List<Object>();
            List<String> filterStringList = new List<String>();
            if (dataTableParams.containsKey('filters')) {
                Set<String> planCodesList = new Set<String>();
                Map<String, Object> filtersMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataTableParams.get('filters')));
                if (filtersMap.containsKey('plancodes') && !String.isBlank(String.valueOf(filtersMap.get('plancodes')))) planCodesList.addAll(new List<String>(String.valueOf(filtersMap.get('plancodes')).replace('(','').replace(')','').deleteWhitespace().split(',')));
                if (filtersMap.containsKey('branches') && !String.isBlank(String.valueOf(filtersMap.get('branches'))))  planCodesList.addAll(DatatableHelper.getPlanCodesForBranches(new Set<String>(new List<String>(String.valueOf(filtersMap.get('branches')).replace('(','').replace(')','').deleteWhitespace().split(',')))));
                if (!planCodesList.isEmpty()) filterStringList.add('sirenum__Contact__r.Plan_Code__r.Name IN (\'' + String.join(new List<String>(planCodesList),'\',\'') + '\')');
                if (filtersMap.containsKey('startDate') && !String.isBlank(String.valueOf(filtersMap.get('startDate'))) && String.valueOf(filtersMap.get('startDate')) != '()') filterStringList.add('sirenum__Date__c >= '+String.valueOf(filtersMap.get('startDate')));
                if (filtersMap.containsKey('endDate') && !String.isBlank(String.valueOf(filtersMap.get('endDate'))) && String.valueOf(filtersMap.get('endDate')) != '()') filterStringList.add('sirenum__Date__c <= '+String.valueOf(filtersMap.get('endDate'))); 
                if (filtersMap.containsKey('contacts') && !String.isBlank(String.valueOf(filtersMap.get('contacts'))) && String.valueOf(filtersMap.get('contacts')) != '()') filterStringList.add('sirenum__Contact__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('contacts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
            }
            String soqlQuery = 'SELECT Id, Name, sirenum__Description__c, sirenum__Start_Time__c, sirenum__End_Time__c, sirenum__Contact__c, sirenum__Contact__r.Name'+
                ' FROM sirenum__Employee_Request__c WHERE sirenum__Type__c = \'Holiday\' AND SendToIntime__c = false AND sirenum__Approved__c = true '+(!filterStringList.isEmpty() ? 'AND '+String.join(filterStringList,' AND ') : '')+' ORDER BY sirenum__Start_Time__c';
            List<sirenum__Employee_Request__c> employeeRequestsList = (List<sirenum__Employee_Request__c>)Database.query(soqlQuery);
            for (sirenum__Employee_Request__c employeeRequest : employeeRequestsList) {
                Map<String, Object> objectsMap = new Map<String, Object>();
                objectsMap.putAll(employeeRequest.getPopulatedFieldsAsMap());
                objectsMap.put('workerUrl',employeeRequest.sirenum__Contact__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+employeeRequest.sirenum__Contact__c : '');
                objectsMap.put('workerName',employeeRequest.sirenum__Contact__r.Name);
                objectsMap.put('employeeRequestUrl',URL.getOrgDomainURL().toExternalForm()+'/'+employeeRequest.Id);
                objectsList.add(objectsMap);
            }
            return objectsList;
        }

        /** 
        * @description : Method to create a new note in open
        * @param openDataParams open data params
        **/ 
        public Object saveRecords(Map<String, Object> dataTableParams) {
            List<sirenum__Employee_Request__c> employeeRequestsToUpdate = new List<sirenum__Employee_Request__c>();
            List<Id> employeeRequestIdsList = (List<Id>)JSON.deserialize(String.valueOf(dataTableParams.get('employeeRequestIds')),List<Id>.class);
            List<IntimeDataManagerSetting__mdt> intimeDataManagerSetting = [SELECT Id, BatchSize__c, HandlerName__c FROM IntimeDataManagerSetting__mdt WHERE Type__c = 'Holiday Approval' LIMIT 1];
            if (employeeRequestIdsList.size() <= 1 && !Test.isRunningTest()) {
                IRecordProcessor recordProcessor = (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance();
                if (recordProcessor != null) recordProcessor.processRecords(employeeRequestIdsList);
            } else {
                Id apexJobId = Database.executeBatch(new RecordProcessorBatch(
                    new RecordProcessor(
                        employeeRequestIdsList,
                        (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance()
                    )
                ),(intimeDataManagerSetting[0].BatchSize__c != null ? Integer.valueOf(intimeDataManagerSetting[0].BatchSize__c) : 200));
                IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
                intimeDataManagerAsyncJobSetting.HolidayApprovalJobId__c = apexJobId;
                upsert intimeDataManagerAsyncJobSetting;
                return new Map<String, Object>{
                    'apexJobId' => apexJobId,
                    'success' => true
                };
            }
            return new Map<String, Object>{
                'apexJobId' => '',
                'success' => true
            };
        }
    }

    /**
    *   @description : Apex class for used to send contacts
    **/
    public class ClientIntimeSendController implements IDatatable {
        
        /**
        *   @description : Method to get the datatable attributes
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return Map<String, Object> Map contains open data and field information for lightning datatable
        **/
        public Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams) {
            Map<String, Object> objectsMap = new Map<String, Object>();
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            objectsMap.put('columns',getColumns());
            objectsMap.put('data',getData(dataTableParams));
            objectsMap.put('planCodes',DatatableHelper.getPlanCodes());
            objectsMap.put('ayncJobId',intimeDataManagerAsyncJobSetting.AccountSendJobId__c);
            objectsMap.put('ayncJobStatus',!String.isBlank(intimeDataManagerAsyncJobSetting.AccountSendJobId__c) ? IntimeSyncHelper.IsRecordProcessorBatchRunning(intimeDataManagerAsyncJobSetting.AccountSendJobId__c) : false);
            return objectsMap;
        }

        /**
        *   @description : Method to get the datatable columns
        *   @return List<Map<String,Object>> List of columns to be displayed in the datatable
        **/
        public List<Map<String,Object>> getColumns() {
            List<Map<String,Object>> columnsList = new List<Map<String,Object>>();
            columnsList.add(new Map<String,Object> {
                'label' => 'Name',
                'fieldName' => 'clientUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'Name'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Client Code',
                'fieldName' => 'Client_Code__c', 
                'type' => 'text'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Plan Code',
                'fieldName' => 'PlanCode__c', 
                'type' => 'text'
            });
            return columnsList;
        }

         /**
        *   @description : Method to get the data from OPEN
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return List<Object> List of data from open
        **/
        public List<Object> getData(Map<String, Object> dataTableParams) {
            List<Object> objectsList = new List<Object>();
            List<String> filterStringList = new List<String>();
            if (dataTableParams.containsKey('filters')) {
                Set<String> planCodesList = new Set<String>();
                Map<String, Object> filtersMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataTableParams.get('filters')));
                if (filtersMap.containsKey('plancodes') && !String.isBlank(String.valueOf(filtersMap.get('plancodes')))) planCodesList.addAll(new List<String>(String.valueOf(filtersMap.get('plancodes')).replace('(','').replace(')','').deleteWhitespace().split(',')));
                if (filtersMap.containsKey('branches') && !String.isBlank(String.valueOf(filtersMap.get('branches'))))  planCodesList.addAll(DatatableHelper.getPlanCodesForBranches(new Set<String>(new List<String>(String.valueOf(filtersMap.get('branches')).replace('(','').replace(')','').deleteWhitespace().split(',')))));
                if (!planCodesList.isEmpty()) filterStringList.add('Plan_Code__r.Name IN (\'' + String.join(new List<String>(planCodesList),'\',\'') + '\')');
                if (filtersMap.containsKey('accounts') && !String.isBlank(String.valueOf(filtersMap.get('accounts'))) && String.valueOf(filtersMap.get('accounts')) != '()') filterStringList.add('Id IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('accounts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
            }
            String soqlQuery = 'SELECT Id, Name, Client_Code__c, PlanCode__c, TR1__Status__c FROM Account '+
                   'WHERE '+(!Test.isRunningTest() ? 'TR1__Status__c = \'Onboarded\' AND ' : '')+' IntimeId__c = null AND SendToIntime__c = false AND RecordType.DeveloperName = \'Client\' '+(!filterStringList.isEmpty() ? 'AND '+String.join(filterStringList,' AND ') : '')+' ORDER BY Name LIMIT 50000';
            List<Account> accountsList = (List<Account>)Database.query(soqlQuery);
            for (Account account : accountsList) {
                Map<String, Object> objectsMap = new Map<String, Object>();
                objectsMap.putAll(account.getPopulatedFieldsAsMap());
                objectsMap.put('clientUrl',URL.getOrgDomainURL().toExternalForm()+'/'+account.Id);
                objectsList.add(objectsMap);
            }
            return objectsList;
        }

        /** 
        * @description : Method to create a new note in open
        * @param openDataParams open data params
        **/ 
        public Object saveRecords(Map<String, Object> dataTableParams) {
            List<Id> recordIds = (List<Id>)JSON.deserialize(String.valueOf(dataTableParams.get('accountIds')),List<Id>.class);
            List<IntimeDataManagerSetting__mdt> intimeDataManagerSetting = [SELECT Id, BatchSize__c, HandlerName__c FROM IntimeDataManagerSetting__mdt WHERE Type__c = 'Account Send' LIMIT 1];
            if (recordIds.size() <= 1 && !Test.isRunningTest()) {
                IRecordProcessor recordProcessor = (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance();
                if (recordProcessor != null) recordProcessor.processRecords(recordIds);
            } else {
                Id apexJobId = Database.executeBatch(new RecordProcessorBatch(
                    new RecordProcessor(
                        recordIds,
                        (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance()
                    )
                ),(intimeDataManagerSetting[0].BatchSize__c != null ? Integer.valueOf(intimeDataManagerSetting[0].BatchSize__c) : 200));
                IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
                intimeDataManagerAsyncJobSetting.AccountSendJobId__c = apexJobId;
                upsert intimeDataManagerAsyncJobSetting;
                return new Map<String, Object>{
                    'apexJobId' => apexJobId,
                    'success' => true
                };
            }
            return new Map<String, Object>{
                'apexJobId' => '',
                'success' => true
            };
        }
    }

    /**
    *   @description : Apex class for used to send contacts
    **/
    public class PersonIntimeSendController implements IDatatable {
        
        /**
        *   @description : Method to get the datatable attributes
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return Map<String, Object> Map contains open data and field information for lightning datatable
        **/
        public Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams) {
            Map<String, Object> objectsMap = new Map<String, Object>();
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            objectsMap.put('columns',getColumns());
            objectsMap.put('data',getData(dataTableParams));
            objectsMap.put('planCodes',DatatableHelper.getPlanCodes());
            objectsMap.put('ayncJobId',intimeDataManagerAsyncJobSetting.ContactSendJobId__c);
            objectsMap.put('ayncJobStatus',!String.isBlank(intimeDataManagerAsyncJobSetting.ContactSendJobId__c) ? IntimeSyncHelper.IsRecordProcessorBatchRunning(intimeDataManagerAsyncJobSetting.ContactSendJobId__c) : false);
            return objectsMap;
        }

        /**
        *   @description : Method to get the datatable columns
        *   @return List<Map<String,Object>> List of columns to be displayed in the datatable
        **/
        public List<Map<String,Object>> getColumns() {
            List<Map<String,Object>> columnsList = new List<Map<String,Object>>();
            columnsList.add(new Map<String,Object> {
                'label' => 'Name',
                'fieldName' => 'personUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'Name'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Email',
                'fieldName' => 'Email', 
                'type' => 'text'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Payroll Number',
                'fieldName' => 'InTimeExternalId__c', 
                'type' => 'text'
            });
            return columnsList;
        }

         /**
        *   @description : Method to get the data from OPEN
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return List<Object> List of data from open
        **/
        public List<Object> getData(Map<String, Object> dataTableParams) {
            List<Object> objectsList = new List<Object>();
            List<String> filterStringList = new List<String>();
            if (dataTableParams.containsKey('filters')) {
                Set<String> planCodesList = new Set<String>();
                Map<String, Object> filtersMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataTableParams.get('filters')));
                if (filtersMap.containsKey('plancodes') && !String.isBlank(String.valueOf(filtersMap.get('plancodes')))) planCodesList.addAll(new List<String>(String.valueOf(filtersMap.get('plancodes')).replace('(','').replace(')','').deleteWhitespace().split(',')));
                if (filtersMap.containsKey('branches') && !String.isBlank(String.valueOf(filtersMap.get('branches'))))  planCodesList.addAll(DatatableHelper.getPlanCodesForBranches(new Set<String>(new List<String>(String.valueOf(filtersMap.get('branches')).replace('(','').replace(')','').deleteWhitespace().split(',')))));
                if (!planCodesList.isEmpty()) filterStringList.add('Plan_Code__r.Name IN (\'' + String.join(new List<String>(planCodesList),'\',\'') + '\')');
                if (filtersMap.containsKey('contacts') && !String.isBlank(String.valueOf(filtersMap.get('contacts'))) && String.valueOf(filtersMap.get('contacts')) != '()') filterStringList.add('Id IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('contacts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
            }
            String soqlQuery = 'SELECT Id, Name, Email, Birthdate, InTimeExternalId__c FROM Contact '+
                   'WHERE '+(!Test.isRunningTest() ? 'TR1__Candidate_Status__c = \'Registered\' AND ' : '')+' IntimeId__c = null AND SendToIntime__c = false '+(!filterStringList.isEmpty() ? 'AND '+String.join(filterStringList,' AND ') : '')+' ORDER BY Name LIMIT 50000';
            List<Contact> contactsList = (List<Contact>)Database.query(soqlQuery);
            for (Contact contact : contactsList) {
                Map<String, Object> objectsMap = new Map<String, Object>();
                objectsMap.putAll(contact.getPopulatedFieldsAsMap());
                objectsMap.put('personUrl',URL.getOrgDomainURL().toExternalForm()+'/'+contact.Id);
                objectsList.add(objectsMap);
            }
            return objectsList;
        }

        /** 
        * @description : Method to create a new note in open
        * @param openDataParams open data params
        **/ 
        public Object saveRecords(Map<String, Object> dataTableParams) {
            List<Id> recordIds = (List<Id>)JSON.deserialize(String.valueOf(dataTableParams.get('contactIds')),List<Id>.class);
            List<IntimeDataManagerSetting__mdt> intimeDataManagerSetting = [SELECT Id, BatchSize__c, HandlerName__c FROM IntimeDataManagerSetting__mdt WHERE Type__c = 'Contact Send' LIMIT 1];
            if (recordIds.size() <= 1 && !Test.isRunningTest()) {
                IRecordProcessor recordProcessor = (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance();
                if (recordProcessor != null) recordProcessor.processRecords(recordIds);
            } else {
                Id apexJobId = Database.executeBatch(new RecordProcessorBatch(
                    new RecordProcessor(
                        recordIds,
                        (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance()
                    )
                ),(intimeDataManagerSetting[0].BatchSize__c != null ? Integer.valueOf(intimeDataManagerSetting[0].BatchSize__c) : 200));
                IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
                intimeDataManagerAsyncJobSetting.ContactSendJobId__c = apexJobId;
                upsert intimeDataManagerAsyncJobSetting;
                return new Map<String, Object>{
                    'apexJobId' => apexJobId,
                    'success' => true
                };
            }
            return new Map<String, Object>{
                'apexJobId' => '',
                'success' => true
            };
        }
    }

    /**
    *   @description : Apex class for used to send contacts
    **/
    public class PlacementIntimeSendController implements IDatatable {
        
        /**
        *   @description : Method to get the datatable attributes
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return Map<String, Object> Map contains open data and field information for lightning datatable
        **/
        public Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams) {
            Map<String, Object> objectsMap = new Map<String, Object>();
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            objectsMap.put('columns',getColumns());
            objectsMap.put('data',getData(dataTableParams));
            objectsMap.put('planCodes',DatatableHelper.getPlanCodes());
            objectsMap.put('ayncJobId',intimeDataManagerAsyncJobSetting.PlacementSendJobId__c);
            objectsMap.put('ayncJobStatus',!String.isBlank(intimeDataManagerAsyncJobSetting.PlacementSendJobId__c) ? IntimeSyncHelper.IsRecordProcessorBatchRunning(intimeDataManagerAsyncJobSetting.PlacementSendJobId__c) : false);
            return objectsMap;
        }

        /**
        *   @description : Method to get the datatable columns
        *   @return List<Map<String,Object>> List of columns to be displayed in the datatable
        **/
        public List<Map<String,Object>> getColumns() {
            List<Map<String,Object>> columnsList = new List<Map<String,Object>>();
            columnsList.add(new Map<String,Object> {
                'label' => 'Name',
                'fieldName' => 'placementUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'Name'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Worker',
                'fieldName' => 'workerUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'workerName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Job Role',
                'fieldName' => 'jobRoleUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'jobRoleName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Contract',
                'fieldName' => 'contractUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'contractName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Status ',
                'fieldName' => 'sirenum__Status__c', 
                'type' => 'text'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Start Date',
                'fieldName' => 'sirenum__Start_Date__c', 
                'type' => 'date',
                'typeAttributes' => new Map<String, Object>{
                    'year' => 'numeric',
                    'month' =>  '2-digit',
                    'day' => '2-digit',
                    'hour' => '2-digit',
                    'minute' => '2-digit'
                }
            });
            return columnsList;
        }

         /**
        *   @description : Method to get the data from OPEN
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return List<Object> List of data from open
        **/
        public List<Object> getData(Map<String, Object> dataTableParams) {
            List<Object> objectsList = new List<Object>();
            List<String> filterStringList = new List<String>();
            if (dataTableParams.containsKey('filters')) {
                Set<String> planCodesList = new Set<String>();
                Map<String, Object> filtersMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataTableParams.get('filters')));
                if (filtersMap.containsKey('plancodes') && !String.isBlank(String.valueOf(filtersMap.get('plancodes')))) planCodesList.addAll(new List<String>(String.valueOf(filtersMap.get('plancodes')).replace('(','').replace(')','').deleteWhitespace().split(',')));
                if (filtersMap.containsKey('branches') && !String.isBlank(String.valueOf(filtersMap.get('branches'))))  planCodesList.addAll(DatatableHelper.getPlanCodesForBranches(new Set<String>(new List<String>(String.valueOf(filtersMap.get('branches')).replace('(','').replace(')','').deleteWhitespace().split(',')))));
                if (!planCodesList.isEmpty()) filterStringList.add('PlanCode__r.Name IN (\'' + String.join(new List<String>(planCodesList),'\',\'') + '\')');
                if (filtersMap.containsKey('accounts') && !String.isBlank(String.valueOf(filtersMap.get('accounts'))) && String.valueOf(filtersMap.get('accounts')) != '()') filterStringList.add('sirenum__Contract__r.sirenum__Client__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('accounts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
                if (filtersMap.containsKey('contacts') && !String.isBlank(String.valueOf(filtersMap.get('contacts'))) && String.valueOf(filtersMap.get('contacts')) != '()') filterStringList.add('sirenum__Contact__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('contacts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
            }
            String soqlQuery = 'SELECT Id, Name, sirenum__Contract__c, sirenum__Contract__r.Name, sirenum__Job_Role__c, sirenum__Job_Role__r.Name,'+
                'sirenum__Contact__c, sirenum__Contact__r.Name, sirenum__Status__c, sirenum__Start_Date__c'+
                ' FROM sirenum__Placement__c '+
                   'WHERE IntimeId__c = null AND SendToIntime__c = false '+(!filterStringList.isEmpty() ? 'AND '+String.join(filterStringList,' AND ') : '')+' ORDER BY Name LIMIT 50000';
            List<sirenum__Placement__c> placementsList = (List<sirenum__Placement__c>)Database.query(soqlQuery);
            for (sirenum__Placement__c placement : placementsList) {
                Map<String, Object> objectsMap = new Map<String, Object>();
                objectsMap.putAll(placement.getPopulatedFieldsAsMap());
                objectsMap.put('placementUrl',URL.getOrgDomainURL().toExternalForm()+'/'+placement.Id);
                objectsMap.put('workerUrl',placement.sirenum__Contact__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+placement.sirenum__Contact__c : '');
                objectsMap.put('workerName',placement.sirenum__Contact__r.Name);
                objectsMap.put('jobRoleUrl',placement.sirenum__Job_Role__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+placement.sirenum__Job_Role__c : '');
                objectsMap.put('jobRoleName',placement.sirenum__Job_Role__r.Name);
                objectsMap.put('contractUrl',placement.sirenum__Contract__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+placement.sirenum__Contract__c : '');
                objectsMap.put('contractName',placement.sirenum__Contract__r.Name);
                objectsList.add(objectsMap);
            }
            return objectsList;
        }

        /** 
        * @description : Method to create a new note in open
        * @param openDataParams open data params
        **/ 
        public Object saveRecords(Map<String, Object> dataTableParams) {
            List<Id> recordIds = (List<Id>)JSON.deserialize(String.valueOf(dataTableParams.get('placementIds')),List<Id>.class);
            List<IntimeDataManagerSetting__mdt> intimeDataManagerSetting = [SELECT Id, BatchSize__c, HandlerName__c FROM IntimeDataManagerSetting__mdt WHERE Type__c = 'Placement Send' LIMIT 1];
            if (recordIds.size() <= 1 && !Test.isRunningTest()) {
                IRecordProcessor recordProcessor = (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance();
                if (recordProcessor != null) recordProcessor.processRecords(recordIds);
            } else {
                Id apexJobId = Database.executeBatch(new RecordProcessorBatch(
                    new RecordProcessor(
                        recordIds,
                        (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance()
                    )
                ),(intimeDataManagerSetting[0].BatchSize__c != null ? Integer.valueOf(intimeDataManagerSetting[0].BatchSize__c) : 200));
                IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
                intimeDataManagerAsyncJobSetting.PlacementSendJobId__c = apexJobId;
                upsert intimeDataManagerAsyncJobSetting;
                return new Map<String, Object>{
                    'apexJobId' => apexJobId,
                    'success' => true
                };
            }
            return new Map<String, Object>{
                'apexJobId' => '',
                'success' => true
            };
        }
    }

    /**
    *   @description : Apex class for used for timesheet revert
    **/
    public class TimesheetRevertController implements IDatatable {
        
        /**
        *   @description : Method to get the datatable attributes
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return Map<String, Object> Map contains open data and field information for lightning datatable
        **/
        public Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams) {
            Map<String, Object> objectsMap = new Map<String, Object>();
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            objectsMap.put('columns',getColumns());
            objectsMap.put('data',getData(dataTableParams));
            objectsMap.put('planCodes',DatatableHelper.getPlanCodes());
            objectsMap.put('ayncJobId',intimeDataManagerAsyncJobSetting.TimesheetRevertJobId__c);
            objectsMap.put('ayncJobStatus',!String.isBlank(intimeDataManagerAsyncJobSetting.TimesheetRevertJobId__c) ? IntimeSyncHelper.IsRecordProcessorBatchRunning(intimeDataManagerAsyncJobSetting.TimesheetRevertJobId__c) : false);
            return objectsMap;
        }

        /**
        *   @description : Method to get the datatable columns
        *   @return List<Map<String,Object>> List of columns to be displayed in the datatable
        **/
        public List<Map<String,Object>> getColumns() {
            List<Map<String,Object>> columnsList = new List<Map<String,Object>>();
            columnsList.add(new Map<String,Object> {
                'label' => 'Name',
                'fieldName' => 'timesheetUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'Name'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Worker',
                'fieldName' => 'workerUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'workerName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Placement',
                'fieldName' => 'placementUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'placementName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Week',
                'fieldName' => 'weekUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'weekName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Total Charge',
                'fieldName' => 'sirenum__Total_Charge__c', 
                'type' => 'currency'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Total Pay',
                'fieldName' => 'sirenum__Total_Pay__c', 
                'type' => 'currency'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Gross Margin',
                'fieldName' => 'sirenum__Profit__c', 
                'type' => 'currency'
            });
            return columnsList;
        }

         /**
        *   @description : Method to get the data from OPEN
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return List<Object> List of data from open
        **/
        public List<Object> getData(Map<String, Object> dataTableParams) {
            List<Object> objectsList = new List<Object>();
            List<String> filterStringList = new List<String>();
            if (dataTableParams.containsKey('filters')) {
                Set<String> planCodesList = new Set<String>();
                Map<String, Object> filtersMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataTableParams.get('filters')));
                if (filtersMap.containsKey('plancodes') && !String.isBlank(String.valueOf(filtersMap.get('plancodes')))) planCodesList.addAll(new List<String>(String.valueOf(filtersMap.get('plancodes')).replace('(','').replace(')','').deleteWhitespace().split(',')));
                if (filtersMap.containsKey('branches') && !String.isBlank(String.valueOf(filtersMap.get('branches'))))  planCodesList.addAll(DatatableHelper.getPlanCodesForBranches(new Set<String>(new List<String>(String.valueOf(filtersMap.get('branches')).replace('(','').replace(')','').deleteWhitespace().split(',')))));
                if (!planCodesList.isEmpty()) filterStringList.add('Plan_Code__c IN (\'' + String.join(new List<String>(planCodesList),'\',\'') + '\')');
                if (filtersMap.containsKey('accounts') && !String.isBlank(String.valueOf(filtersMap.get('accounts'))) && String.valueOf(filtersMap.get('accounts')) != '()') filterStringList.add('sirenum__Client__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('accounts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
                if (filtersMap.containsKey('contacts') && !String.isBlank(String.valueOf(filtersMap.get('contacts'))) && String.valueOf(filtersMap.get('contacts')) != '()') filterStringList.add('sirenum__Worker__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('contacts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
                if (filtersMap.containsKey('weeks') && !String.isBlank(String.valueOf(filtersMap.get('weeks'))) && String.valueOf(filtersMap.get('weeks')) != '()') filterStringList.add('sirenum__Week__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('weeks')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
            }
            String soqlQuery = 'SELECT Id, Name, sirenum__Worker__c, sirenum__Worker__r.Name, Placement__c, Placement__r.Name, '+
                'sirenum__Week__c, sirenum__Week__r.Name, sirenum__Total_Charge__c, sirenum__Total_Pay__c, sirenum__Profit__c FROM sirenum__Timesheet__c '+
                   'WHERE InTimeId__c != null AND SendToIntime__c = false AND InTime_Invoice_No__c = null AND Erni__c = null '+(!filterStringList.isEmpty() ? 'AND '+String.join(filterStringList,' AND ') : '')+' ORDER BY Name LIMIT 50000';
            List<sirenum__Timesheet__c> timesheetsList = (List<sirenum__Timesheet__c>)Database.query(soqlQuery);
            for (sirenum__Timesheet__c timesheet : timesheetsList) {
                Map<String, Object> objectsMap = new Map<String, Object>();
                objectsMap.putAll(timesheet.getPopulatedFieldsAsMap());
                objectsMap.put('workerUrl',timesheet.sirenum__Worker__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.sirenum__Worker__c : '');
                objectsMap.put('workerName',timesheet.sirenum__Worker__r.Name);
                objectsMap.put('placementUrl',timesheet.Placement__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.Placement__c : '');
                objectsMap.put('placementName',timesheet.Placement__r.Name);
                objectsMap.put('weekUrl',timesheet.sirenum__Week__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.sirenum__Week__c : '');
                objectsMap.put('weekName',timesheet.sirenum__Week__r.Name);
                objectsMap.put('timesheetUrl',URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.Id);
                objectsList.add(objectsMap);
            }
            return objectsList;
        }

        /** 
        * @description : Method to create a new note in open
        * @param openDataParams open data params
        **/ 
        public Object saveRecords(Map<String, Object> dataTableParams) {
            List<sirenum__Timesheet__c> timeSheetsToUpdate = new List<sirenum__Timesheet__c>();
            List<Id> timesheetIdsList = (List<Id>)JSON.deserialize(String.valueOf(dataTableParams.get('timesheetIds')),List<Id>.class);
            List<IntimeDataManagerSetting__mdt> intimeDataManagerSetting = [SELECT Id, BatchSize__c, HandlerName__c FROM IntimeDataManagerSetting__mdt WHERE Type__c = 'Timesheet Revert' LIMIT 1];
            if (timesheetIdsList.size() <= 1 && !Test.isRunningTest()) {
                IRecordProcessor recordProcessor = (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance();
                if (recordProcessor != null) recordProcessor.processRecords(timesheetIdsList);
            } else {
                Id apexJobId = Database.executeBatch(new RecordProcessorBatch(
                    new RecordProcessor(
                        timesheetIdsList,
                        (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance()
                    )
                ),(intimeDataManagerSetting[0].BatchSize__c != null ? Integer.valueOf(intimeDataManagerSetting[0].BatchSize__c) : 200));
                IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
                intimeDataManagerAsyncJobSetting.TimesheetRevertJobId__c = apexJobId;
                upsert intimeDataManagerAsyncJobSetting;
                return new Map<String, Object>{
                    'apexJobId' => apexJobId,
                    'success' => true
                };
            }
            return new Map<String, Object>{
                'apexJobId' => '',
                'success' => true
            };
        }
    }

    /**
    *   @description : Apex class for used for expense revert
    **/
    public class ExpenseRevertController implements IDatatable {
        
        /**
        *   @description : Method to get the datatable attributes
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return Map<String, Object> Map contains open data and field information for lightning datatable
        **/
        public Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams) {
            Map<String, Object> objectsMap = new Map<String, Object>();
            IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
            objectsMap.put('columns',getColumns());
            objectsMap.put('data',getData(dataTableParams));
            objectsMap.put('planCodes',DatatableHelper.getPlanCodes());
            objectsMap.put('ayncJobId',intimeDataManagerAsyncJobSetting.ExpenseRevertJobId__c);
            objectsMap.put('ayncJobStatus',!String.isBlank(intimeDataManagerAsyncJobSetting.ExpenseRevertJobId__c) ? IntimeSyncHelper.IsRecordProcessorBatchRunning(intimeDataManagerAsyncJobSetting.ExpenseRevertJobId__c) : false);
            return objectsMap;
        }

        /**
        *   @description : Method to get the datatable columns
        *   @return List<Map<String,Object>> List of columns to be displayed in the datatable
        **/
        public List<Map<String,Object>> getColumns() {
            List<Map<String,Object>> columnsList = new List<Map<String,Object>>();
            columnsList.add(new Map<String,Object> {
                'label' => 'Name',
                'fieldName' => 'expenseUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'Name'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Worker',
                'fieldName' => 'workerUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'workerName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Expense Type',
                'fieldName' => 'expenseTypeUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'expenseTypeName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Expense Date',
                'fieldName' => 'sirenum__Date_of_expense__c', 
                'type' => 'date',
                'typeAttributes' => new Map<String, Object>{
                    'year' => 'numeric',
                    'month' =>  '2-digit',
                    'day' => '2-digit',
                    'hour' => '2-digit',
                    'minute' => '2-digit'
                }
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Expense Pay',
                'fieldName' => 'Expense_value__c', 
                'type' => 'currency'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Expense Charge',
                'fieldName' => 'ChargeExpenseValue__c', 
                'type' => 'currency'
            });
            return columnsList;
        }

         /**
        *   @description : Method to get the data from OPEN
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return List<Object> List of data from open
        **/
        public List<Object> getData(Map<String, Object> dataTableParams) {
            List<Object> objectsList = new List<Object>();
            List<String> filterStringList = new List<String>();
            if (dataTableParams.containsKey('filters')) {
                Set<String> planCodesList = new Set<String>();
                Map<String, Object> filtersMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataTableParams.get('filters')));
                if (filtersMap.containsKey('plancodes') && !String.isBlank(String.valueOf(filtersMap.get('plancodes')))) planCodesList.addAll(new List<String>(String.valueOf(filtersMap.get('plancodes')).replace('(','').replace(')','').deleteWhitespace().split(',')));
                if (filtersMap.containsKey('branches') && !String.isBlank(String.valueOf(filtersMap.get('branches'))))  planCodesList.addAll(DatatableHelper.getPlanCodesForBranches(new Set<String>(new List<String>(String.valueOf(filtersMap.get('branches')).replace('(','').replace(')','').deleteWhitespace().split(',')))));
                if (!planCodesList.isEmpty()) filterStringList.add('sirenum__Contact__r.Plan_Code__r.Name IN (\'' + String.join(new List<String>(planCodesList),'\',\'') + '\')');
                if (filtersMap.containsKey('accounts') && !String.isBlank(String.valueOf(filtersMap.get('accounts'))) && String.valueOf(filtersMap.get('accounts')) != '()') filterStringList.add('sirenum__Account__r.sirenum__Client__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('accounts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
                if (filtersMap.containsKey('contacts') && !String.isBlank(String.valueOf(filtersMap.get('contacts'))) && String.valueOf(filtersMap.get('contacts')) != '()') filterStringList.add('sirenum__Worker__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('contacts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
                if (filtersMap.containsKey('startDate') && !String.isBlank(String.valueOf(filtersMap.get('startDate'))) && String.valueOf(filtersMap.get('startDate')) != '()') filterStringList.add('sirenum__Date_of_expense__c >= '+String.valueOf(filtersMap.get('startDate')));
                if (filtersMap.containsKey('endDate') && !String.isBlank(String.valueOf(filtersMap.get('endDate'))) && String.valueOf(filtersMap.get('endDate')) != '()') filterStringList.add('sirenum__Date_of_expense__c <= '+String.valueOf(filtersMap.get('endDate'))); 
            }
            String soqlQuery = 'SELECT Id, Name, sirenum__Contact__c, sirenum__Contact__r.Name, sirenum__Expense_Type__c, '+
                ' sirenum__Expense_Type__r.Name, sirenum__Date_of_expense__c, Expense_value__c, ChargeExpenseValue__c FROM sirenum__Expense__c '+
                   'WHERE InTimeId__c != null AND SendToIntime__c = false '+(!filterStringList.isEmpty() ? 'AND '+String.join(filterStringList,' AND ') : '')+' ORDER BY Name LIMIT 50000';
            List<sirenum__Expense__c> expensesList = (List<sirenum__Expense__c>)Database.query(soqlQuery);
            for (sirenum__Expense__c expense : expensesList) {
                Map<String, Object> objectsMap = new Map<String, Object>();
                objectsMap.putAll(expense.getPopulatedFieldsAsMap());
                objectsMap.put('workerUrl',expense.sirenum__Contact__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+expense.sirenum__Contact__c : '');
                objectsMap.put('workerName',expense.sirenum__Contact__r.Name);
                objectsMap.put('expenseTypeUrl',expense.sirenum__Expense_Type__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+expense.sirenum__Expense_Type__c : '');
                objectsMap.put('expenseTypeName',expense.sirenum__Expense_Type__r.Name);
                objectsMap.put('expenseUrl',URL.getOrgDomainURL().toExternalForm()+'/'+expense.Id);
                objectsList.add(objectsMap);
            }
            return objectsList;
        }

        /** 
        * @description : Method to create a new note in open
        * @param openDataParams open data params
        **/ 
        public Object saveRecords(Map<String, Object> dataTableParams) {
            List<sirenum__Timesheet__c> timeSheetsToUpdate = new List<sirenum__Timesheet__c>();
            List<Id> timesheetIdsList = (List<Id>)JSON.deserialize(String.valueOf(dataTableParams.get('expenseIds')),List<Id>.class);
            List<IntimeDataManagerSetting__mdt> intimeDataManagerSetting = [SELECT Id, BatchSize__c, HandlerName__c FROM IntimeDataManagerSetting__mdt WHERE Type__c = 'Expense Revert' LIMIT 1];
            if (timesheetIdsList.size() <= 1 && !Test.isRunningTest()) {
                IRecordProcessor recordProcessor = (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance();
                if (recordProcessor != null) recordProcessor.processRecords(timesheetIdsList);
            } else {
                Id apexJobId = Database.executeBatch(new RecordProcessorBatch(
                    new RecordProcessor(
                        timesheetIdsList,
                        (IRecordProcessor)Type.forName(intimeDataManagerSetting[0].HandlerName__c).newInstance()
                    )
                ),(intimeDataManagerSetting[0].BatchSize__c != null ? Integer.valueOf(intimeDataManagerSetting[0].BatchSize__c) : 200));
                IntimeDataManagerAsyncJobSetting__c intimeDataManagerAsyncJobSetting = IntimeDataManagerAsyncJobSetting__c.getInstance();
                intimeDataManagerAsyncJobSetting.ExpenseRevertJobId__c = apexJobId;
                upsert intimeDataManagerAsyncJobSetting;
                return new Map<String, Object>{
                    'apexJobId' => apexJobId,
                    'success' => true
                };
            }
            return new Map<String, Object>{
                'apexJobId' => '',
                'success' => true
            };
        }
    }

    // Exception 
    public class DataTableException extends Exception {}
}