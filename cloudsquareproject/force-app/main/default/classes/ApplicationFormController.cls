public without sharing class ApplicationFormController {

    @AuraEnabled
    public static ApplicationResult submitApplication(ApplicationDTO input) {
        if (input == null) {
            ApplicationResult errorResult = new ApplicationResult();
            errorResult.success = false;
            errorResult.message = 'No application data received.';
            return errorResult;
        }

        input.applicationSource = ApplicationConstants.SOURCE_COMMUNITY;
        return ApplicationProcessingService.processApplication(input);
    }
}