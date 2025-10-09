declare module "@salesforce/apex/SIM_FilterComponent.getFilterOptions" {
  export default function getFilterOptions(param: {targetObject: any, filterGroup: any}): Promise<any>;
}
declare module "@salesforce/apex/SIM_FilterComponent.getSOQLFilter" {
  export default function getSOQLFilter(param: {targetObject: any, crossGroupOperator: any, groupsJSON: any}): Promise<any>;
}
