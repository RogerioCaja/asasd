@isTest
public with sharing class ExceptionCallouts implements HttpCalloutMock{
    public ExceptionCallouts() {}

    public HttpResponse respond(HttpRequest request) {
        CalloutException e = (CalloutException)CalloutException.class.newInstance();
        e.setMessage('Error');
        throw e;
    }
}
