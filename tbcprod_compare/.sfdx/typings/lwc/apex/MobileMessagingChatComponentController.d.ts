declare module "@salesforce/apex/MobileMessagingChatComponentController.getPastMessages" {
  export default function getPastMessages(param: {contactId: any}): Promise<any>;
}
declare module "@salesforce/apex/MobileMessagingChatComponentController.createNewMessage" {
  export default function createNewMessage(param: {contactId: any, messageBody: any, newMessageType: any}): Promise<any>;
}
