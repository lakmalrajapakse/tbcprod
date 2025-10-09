declare module "@salesforce/apex/JobOffersController.getJobOffers" {
  export default function getJobOffers(param: {contactId: any}): Promise<any>;
}
declare module "@salesforce/apex/JobOffersController.decline" {
  export default function decline(param: {offerId: any}): Promise<any>;
}
declare module "@salesforce/apex/JobOffersController.accept" {
  export default function accept(param: {offerId: any}): Promise<any>;
}
