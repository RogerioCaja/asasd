public virtual class AGRO_RemotingResult {
    @AuraEnabled
    public Boolean hasError;
    @AuraEnabled
    public Boolean sessionExpired;
    @AuraEnabled
    public String code;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public String stackTrace;
    @AuraEnabled
    public String orderId;

    /*public AGRO_RemotingResult() {
        this.hasError   = false;
        this.sessionExpired = UserInfo.getSessionId() == null;
    }*/
    
    /*public AGRO_RemotingResult(Boolean hasError) {
        this.hasError   = hasError;
        this.sessionExpired = UserInfo.getSessionId() == null;
    }*/

    /*public AGRO_RemotingResult(Boolean hasError, String message) {
        this.hasError   = hasError;
        this.sessionExpired = UserInfo.getSessionId() == null;
        this.message    = message;
    }*/

    public AGRO_RemotingResult(Boolean hasError, String code, String message) {
        this.hasError   = hasError;
        this.sessionExpired = UserInfo.getSessionId() == null;
        this.code       = code;
        this.message    = message;
    }
    public AGRO_RemotingResult(Boolean hasError, String code, String message, String Id) {
        this.hasError   = hasError;
        this.sessionExpired = UserInfo.getSessionId() == null;
        this.code       = code;
        this.message    = message;
        this.orderId = Id;
    }

    /*public AGRO_RemotingResult(Boolean hasError, String code, String message, String description) {
        this.hasError       = hasError;
        this.sessionExpired = UserInfo.getSessionId() == null;
        this.code           = code;
        this.message        = message;
        this.description    = description;
    }*/
    
    public void setMessage(String message) {
        this.message    = message;
    }

    public AGRO_RemotingResult(Exception e) {
        String pureErrorMsg = e.getMessage().substringAfter('_EXCEPTION,');
        
        this.hasError   = true;
        this.sessionExpired = UserInfo.getSessionId() == null;
        this.message        = pureErrorMsg;
        this.stackTrace = e.getTypeName().containsIgnoreCase('handledexception') ? null : e.getStackTraceString();
    }

    /*public AGRO_RemotingResult(Exception e, String msg) {
        this.hasError   = true;
        this.sessionExpired = UserInfo.getSessionId() == null;
        this.message    = msg;   
        this.stackTrace = e.getTypeName().containsIgnoreCase('handledexception') ? null : e.getStackTraceString();
    }*/
}