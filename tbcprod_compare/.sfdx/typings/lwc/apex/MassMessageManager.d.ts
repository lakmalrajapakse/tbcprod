declare module "@salesforce/apex/MassMessageManager.getRecepients" {
  export default function getRecepients(param: {recordIds: any}): Promise<any>;
}
declare module "@salesforce/apex/MassMessageManager.dispatchMessages" {
  export default function dispatchMessages(param: {recepientsJSON: any, messageContent: any}): Promise<any>;
}
declare module "@salesforce/apex/MassMessageManager.getTemplateOptions" {
  export default function getTemplateOptions(): Promise<any>;
}
declare module "@salesforce/apex/MassMessageManager.getTemplateBody" {
  export default function getTemplateBody(param: {templateId: any}): Promise<any>;
}
