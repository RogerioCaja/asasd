global class BatchDeliveryNotificationSchedulable implements Schedulable{
    global void execute(SchedulableContext sc) {
        try {
            CalloutBP.processIntegration();
            //String sch = '0 0 * * * ?';
            //system.schedule('Delivery Notification Schedule Job', sch, new BatchDeliveryNotificationSchedulable());
        } catch(Exception e){
            system.debug('Error: ' + e);
        }
    }
}
