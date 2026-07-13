public without sharing class ApplicationProcessingService {

    public static ApplicationResult processApplication(ApplicationDTO app) {
        ApplicationResult result = new ApplicationResult();

        if (app == null) {
            result.success = false;
            result.message = 'Application data is required.';
            return result;
        }

        try {
            Account matchedAccount = findMatchingAccount(app);

            if (matchedAccount != null) {
                Opportunity opp = new Opportunity();
                opp.Name = app.companyName + ' - New Application';
                opp.StageName = 'Prospecting';
                opp.CloseDate = Date.today().addDays(30);
                opp.AccountId = matchedAccount.Id;
                opp.Application_Source__c = app.applicationSource;
                insert opp;

                result.success = true;
                result.recordType = ApplicationConstants.RECORDTYPE_OPPORTUNITY;
                result.recordId = opp.Id;
                result.message = 'Application processed successfully';
            } else {
                Lead lead = new Lead();
                lead.FirstName = app.firstName;
                lead.LastName = String.isNotBlank(app.lastName) ? app.lastName : 'Unknown';
                lead.Company = app.companyName;
                lead.Email = app.email;
                lead.Phone = app.phone;
                lead.Federal_Tax_Id__c = app.federalTaxId;
                lead.Application_Source__c = app.applicationSource;
                insert lead;

                result.success = true;
                result.recordType = ApplicationConstants.RECORDTYPE_LEAD;
                result.recordId = lead.Id;
                result.message = 'Application processed successfully';
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error processing application: ' + e.getMessage();
        }

        return result;
    }

    private static Account findMatchingAccount(ApplicationDTO app) {
        Account acc;

        if (String.isNotBlank(app.federalTaxId)) {
            List<Account> byTaxId = [
                SELECT Id, Name
                FROM Account
                WHERE Federal_Tax_Id__c = :app.federalTaxId
                LIMIT 1
            ];
            if (!byTaxId.isEmpty()) {
                acc = byTaxId[0];
            }
        }

        if (acc == null && String.isNotBlank(app.companyName)) {
            List<Account> byName = [
                SELECT Id, Name
                FROM Account
                WHERE Name = :app.companyName
                LIMIT 1
            ];
            if (!byName.isEmpty()) {
                acc = byName[0];
            }
        }

        return acc;
    }
}