global class BatchCTVSchedulable implements Schedulable{
    global void execute(SchedulableContext sc) {
        try {
            if(!Test.isRunningTest()){
                BatchImplementationCTV.run();
            }
            //String sch = '0 0 12 * * ?';

            //system.schedule('Integration BP', sch, new BatchCTVSchedulable());
        } catch(Exception e){
            system.debug('Error: ' + e);
        }
    }
}
    