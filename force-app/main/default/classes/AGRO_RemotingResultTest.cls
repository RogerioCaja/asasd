@isTest
public with sharing class AGRO_RemotingResultTest {
 
    @isTest
    static void testMessage(){
        new AGRO_RemotingResult(true, '400', 'one Error');
        new AGRO_RemotingResult(true, '400', 'one Error', '234545gh5324');
        new AGRO_RemotingResult(true, '400', 'one Error');
        CalloutException e = (CalloutException)CalloutException.class.newInstance();
        e.setMessage('Error');
        new AGRO_RemotingResult(e);
    }
}