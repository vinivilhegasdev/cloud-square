public class ApplicationResult {

    @AuraEnabled
    public Boolean success;

    @AuraEnabled
    public String recordType;

    @AuraEnabled
    public Id recordId;

    @AuraEnabled
    public String message;

}