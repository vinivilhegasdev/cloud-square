global class WebhookResponse {
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String recordType { get; set; }
    @AuraEnabled public Id recordId { get; set; }
    @AuraEnabled public String message { get; set; }
}