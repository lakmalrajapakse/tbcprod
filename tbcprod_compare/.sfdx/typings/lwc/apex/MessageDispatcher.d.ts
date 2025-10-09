declare module "@salesforce/apex/MessageDispatcher.dispatchMessages" {
  export default function dispatchMessages(param: {recepientsJSON: any, messageContent: any}): Promise<any>;
}
