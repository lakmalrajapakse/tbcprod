declare module "@salesforce/apex/SIM_TimeApproval.getSetup" {
  export default function getSetup(param: {usrID: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.getData" {
  export default function getData(param: {soqlFilter: any, weekStart: any, weekEnd: any, filterContacts: any, filterSites: any, resumeFromId: any, filterPlanCodes: any, filterRoles: any, periodId: any, approvedShiftFilter: any, timesheetGenerationFilter: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.updateShifts" {
  export default function updateShifts(param: {jsonData: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.getManualRates" {
  export default function getManualRates(param: {jobRoles: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.getExpenseTypes" {
  export default function getExpenseTypes(): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.getShiftSignature" {
  export default function getShiftSignature(param: {documentLink: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.processPay" {
  export default function processPay(param: {startDate: any, endDate: any, contactNames: any, siteNames: any, roleNames: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.generateTimesheetProof" {
  export default function generateTimesheetProof(param: {timesheetIds: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.updateTimesheetProof" {
  export default function updateTimesheetProof(param: {timesheetIds: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.getJobDetails" {
  export default function getJobDetails(param: {jobId: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_TimeApproval.getBreaks" {
  export default function getBreaks(param: {shiftId: any}): Promise<any>;
}
