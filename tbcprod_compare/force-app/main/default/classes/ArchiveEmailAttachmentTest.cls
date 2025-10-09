@isTest
public class ArchiveEmailAttachmentTest {

    @testSetup
    static void setupData() {       
        // Create dummy ContentVersion with fields expected by batch
        ContentVersion cv = new ContentVersion(
            Title = 'Dummy File',
            PathOnClient = 'dummy.txt',
            VersionData = Blob.valueOf('Sample content'),
            Delete_Email_Attachment_Link__c = true
        );
        insert cv;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contacts
        List<Contact> contacts = TestDataCreator.createContacts(1, new List<Account> {acc});
        insert contacts;

        // Create Job Leads (2 for each contact)
        List<TR1__Job_Leads__c> jobLeads = new List<TR1__Job_Leads__c>();
        for (Contact c : contacts) {
            jobLeads.add(new TR1__Job_Leads__c(
                TR1__Contact__c = c.Id,
                TR1__Account__c = acc.Id,
                TR1__Job__c = 'JL-' + c.LastName + '-1',
                TR1__Type__c = 'Permanent',
                Bill_Rate__c = 55
            ));        
        }
        insert jobLeads;

        Quote__c quote = new Quote__c(
            Name = 'Quote - ' + DateTime.now().format(),
            Client__c = acc.Id
        );
        insert quote;

        Quote_Contact__c qc = new Quote_Contact__c(
            Person__c = contacts[0].Id,
            QuoteId__c = quote.Id
        );
        insert qc;

        insert new TBC_General_Settings__c(
            Name = 'Default',
            Delete_Email_Attachment_Links_days__c = -1
        );

        EmailTemplate template=[SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Quote_email_template' LIMIT 1];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(contacts[0].Id); // sets To address and allows merge fields
        email.setWhatId(qc.id);          // sets relatedTo (Quote__c)
        email.setTemplateId(template.Id);
        email.setEntityAttachments(new list<Id> {cv.Id});
        email.setSaveAsActivity(true);         
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {email});
    }

    @isTest
    static void runArchiveBatch_test() {
        List<ContentDocumentLink> cdl = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM EmailMessage) LIMIT 1];
        System.assertNotEquals(0, cdl.size(), 'ContentDocumentLink should exist before batch runs');

        Test.startTest();

        Database.executeBatch(new ArchiveEmailAttachmentBatch());

        Test.stopTest();

        cdl = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM EmailMessage) LIMIT 1];
        System.assertEquals(0, cdl.size(), 'ContentDocumentLink should not exist after batch runs');
    }    


    @isTest
    static void runArchiveSched_test() {        
        Test.startTest();

        // Schedule the job to run 1 minute from now
        String cronExpr = '0 0 12 * * ?';
        String jobId = System.schedule('Test Scheduler', cronExpr, new ArchiveEmailAttachmentSchedule());        

        Test.stopTest();
        
    }    
}