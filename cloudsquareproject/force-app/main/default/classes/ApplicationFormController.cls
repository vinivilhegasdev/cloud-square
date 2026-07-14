public without sharing class ApplicationFormController {

    @AuraEnabled
    public static ApplicationResult submitApplication(ApplicationDTO input) {
        System.debug('=== INPUT RECEBIDO NO CONTROLLER ===');
        System.debug('input é null? ' + (input == null));
        if (input != null) {
            System.debug('JSON do input: ' + JSON.serialize(input));
        }
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