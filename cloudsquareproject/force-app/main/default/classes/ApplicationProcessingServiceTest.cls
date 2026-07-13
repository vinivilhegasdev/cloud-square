@isTest
private class ApplicationProcessingServiceTest {

    @isTest
    static void testLeadCreation_NoAccountMatch() {
        ApplicationDTO dto = new ApplicationDTO();
        dto.companyName = 'NonExistent Co';
        dto.federalTaxId = '999999999';
        dto.firstName = 'John';
        dto.lastName = 'Doe';
        dto.email = 'john@doe.com';
        dto.phone = '123456789';
        dto.applicationSource = ApplicationConstants.SOURCE_COMMUNITY;

        Test.startTest();
        ApplicationResult result = ApplicationProcessingService.processApplication(dto);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals('Lead', result.recordType);

        Lead createdLead = [SELECT Id, Company, Application_Source__c FROM Lead WHERE Id = :result.recordId];
        System.assertEquals('NonExistent Co', createdLead.Company);
        System.assertEquals('Community', createdLead.Application_Source__c);
    }

    @isTest
    static void testOpportunityCreation_TaxIdMatch() {
        Account acc = new Account(Name = 'Acme Corp', Federal_Tax_Id__c = 'TAX123');
        insert acc;

        ApplicationDTO dto = new ApplicationDTO();
        dto.companyName = 'Acme Corp';
        dto.federalTaxId = 'TAX123';
        dto.firstName = 'Ivan';
        dto.lastName = 'Ivanov';
        dto.email = 'ivan@example.com';
        dto.phone = '+359888123456';
        dto.applicationSource = ApplicationConstants.SOURCE_WEBHOOK;

        Test.startTest();
        ApplicationResult result = ApplicationProcessingService.processApplication(dto);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals('Opportunity', result.recordType);

        Opportunity opp = [SELECT Id, AccountId, Application_Source__c FROM Opportunity WHERE Id = :result.recordId];
        System.assertEquals(acc.Id, opp.AccountId);
        System.assertEquals('Webhook', opp.Application_Source__c);
    }

    @isTest
    static void testOpportunityCreation_NameMatch() {
        Account acc = new Account(Name = 'Globex Inc');
        insert acc;

        ApplicationDTO dto = new ApplicationDTO();
        dto.companyName = 'Globex Inc';
        dto.federalTaxId = '';
        dto.firstName = 'Jane';
        dto.lastName = 'Smith';
        dto.email = 'jane@globex.com';
        dto.phone = '5551234';
        dto.applicationSource = ApplicationConstants.SOURCE_COMMUNITY;

        Test.startTest();
        ApplicationResult result = ApplicationProcessingService.processApplication(dto);
        Test.stopTest();

        System.assertEquals('Opportunity', result.recordType);

        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :result.recordId];
        System.assertEquals(acc.Id, opp.AccountId);
    }

    @isTest
    static void testApplicationSource_WebhookVsCommunity() {
        ApplicationDTO dtoCommunity = new ApplicationDTO();
        dtoCommunity.companyName = 'Community Co';
        dtoCommunity.firstName = 'A';
        dtoCommunity.lastName = 'B';
        dtoCommunity.email = 'a@b.com';
        dtoCommunity.applicationSource = ApplicationConstants.SOURCE_COMMUNITY;

        ApplicationDTO dtoWebhook = new ApplicationDTO();
        dtoWebhook.companyName = 'Webhook Co';
        dtoWebhook.firstName = 'C';
        dtoWebhook.lastName = 'D';
        dtoWebhook.email = 'c@d.com';
        dtoWebhook.applicationSource = ApplicationConstants.SOURCE_WEBHOOK;

        Test.startTest();
        ApplicationResult r1 = ApplicationProcessingService.processApplication(dtoCommunity);
        ApplicationResult r2 = ApplicationProcessingService.processApplication(dtoWebhook);
        Test.stopTest();

        Lead l1 = [SELECT Application_Source__c FROM Lead WHERE Id = :r1.recordId];
        Lead l2 = [SELECT Application_Source__c FROM Lead WHERE Id = :r2.recordId];
        System.assertEquals('Community', l1.Application_Source__c);
        System.assertEquals('Webhook', l2.Application_Source__c);
    }

    @isTest
    static void testFormControllerSetsCommunitySource() {
        ApplicationDTO dto = new ApplicationDTO();
        dto.companyName = 'Test Controller Co';
        dto.firstName = 'X';
        dto.lastName = 'Y';
        dto.email = 'x@y.com';

        Test.startTest();
        ApplicationResult result = ApplicationFormController.submitApplication(dto);
        Test.stopTest();

        System.assertEquals(true, result.success);
        Lead createdLead = [SELECT Application_Source__c FROM Lead WHERE Id = :result.recordId];
        System.assertEquals('Community', createdLead.Application_Source__c);
    }

    @isTest
    static void testWebhookEndpointCreatesLead() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/external/applications';
        req.httpMethod = 'POST';
        String body = '{"companyName":"Acme Webhook","federalTaxId":"",'
            + '"contact":{"firstName":"Ivan","lastName":"Ivanov","email":"ivan@example.com","phone":"+359888123456"},'
            + '"annualRevenue":500000}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        WebhookResponse response = ApplicationWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(true, response.success);
        System.assertEquals('Lead', response.recordType);
    }

    @isTest
    static void testWebhookEndpointCreatesOpportunity() {
        Account acc = new Account(Name = 'Webhook Match Co', Federal_Tax_Id__c = 'TAX999');
        insert acc;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/external/applications';
        req.httpMethod = 'POST';
        String body = '{"companyName":"Webhook Match Co","federalTaxId":"TAX999",'
            + '"contact":{"firstName":"Maria","lastName":"Silva","email":"maria@example.com","phone":"+5511999999999"},'
            + '"annualRevenue":100000}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        WebhookResponse response = ApplicationWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(true, response.success);
        System.assertEquals('Opportunity', response.recordType);
    }
}