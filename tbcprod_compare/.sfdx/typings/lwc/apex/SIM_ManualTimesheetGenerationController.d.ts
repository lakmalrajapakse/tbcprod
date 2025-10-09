declare module "@salesforce/apex/SIM_ManualTimesheetGenerationController.getBatchProgress" {
  export default function getBatchProgress(param: {batchId: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_ManualTimesheetGenerationController.getUploadTemplates" {
  export default function getUploadTemplates(): Promise<any>;
}
declare module "@salesforce/apex/SIM_ManualTimesheetGenerationController.loadData" {
  export default function loadData(param: {template: any, filename: any, hrow: any, drow: any, payrollPeriod: any, jsonString: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_ManualTimesheetGenerationController.searchPeriods" {
  export default function searchPeriods(param: {searchTerm: any, selectedIds: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_ManualTimesheetGenerationController.searchPayCycles" {
  export default function searchPayCycles(param: {searchTerm: any, selectedIds: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_ManualTimesheetGenerationController.getRecentlyViewedPayCycles" {
  export default function getRecentlyViewedPayCycles(): Promise<any>;
}
