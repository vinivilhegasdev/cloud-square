@RestResource(urlMapping='/external/applications')
global without sharing class ApplicationWebhook {

    @HttpPost
    global static WebhookResponse handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        WebhookResponse response = new WebhookResponse();

        try {
            String jsonBody = req.requestBody.toString();
            WebhookRequest payload = (WebhookRequest) JSON.deserialize(jsonBody, WebhookRequest.class);

            ApplicationDTO dto = new ApplicationDTO();
            dto.companyName = payload.companyName;
            dto.federalTaxId = payload.federalTaxId;
            dto.annualRevenue = payload.annualRevenue;

            if (payload.contact != null) {
                dto.firstName = payload.contact.firstName;
                dto.lastName = payload.contact.lastName;
                dto.email = payload.contact.email;
                dto.phone = payload.contact.phone;
            }

            dto.applicationSource = ApplicationConstants.SOURCE_WEBHOOK;

            ApplicationResult result = ApplicationProcessingService.processApplication(dto);

            response.success = result.success;
            response.recordType = result.recordType;
            response.recordId = result.recordId;
            response.message = result.message;

            res.statusCode = result.success ? 200 : 400;
        } catch (Exception e) {
            response.success = false;
            response.message = 'Error: ' + e.getMessage();
            res.statusCode = 400;
        }

        res.responseBody = Blob.valueOf(JSON.serialize(response));
        return response;
    }
}