@isTest
public class ULabOrderTestDataFactory {

    private static Integer counter = 0;

    public static Account createAccount(Boolean doInsert) {
        Account acc = new Account(Name = 'Test Account ' + nextKey());
        if (doInsert) {
            insert acc;
        }
        return acc;
    }

    public static uLab_Case__c createCase(Id accountId, Boolean doInsert) {
        uLab_Case__c caseRec = new uLab_Case__c(Account__c = accountId);
        if (doInsert) {
            insert caseRec;
        }
        return caseRec;
    }

    public static List<uLab_Order__c> createOrders(
        Integer count,
        Id caseId,
        String uAssistStatus,
        String orderStatus,
        Boolean doInsert
    ) {
        return createOrders(count, caseId, uAssistStatus, orderStatus, System.now(), System.now(), doInsert);
    }

    public static List<uLab_Order__c> createOrders(
        Integer count,
        Id caseId,
        String uAssistStatus,
        String orderStatus,
        Datetime enteredCurrentStatus,
        Datetime enteredLastStatus,
        Boolean doInsert
    ) {
        return createOrders(count, caseId, uAssistStatus, orderStatus, enteredCurrentStatus, enteredLastStatus, null, doInsert);
    }

    public static List<uLab_Order__c> createOrders(
        Integer count,
        Id caseId,
        String uAssistStatus,
        String orderStatus,
        Datetime enteredCurrentStatus,
        Datetime enteredLastStatus,
        Id assignedCrb,
        Boolean doInsert
    ) {
        List<uLab_Order__c> orders = new List<uLab_Order__c>();
        for (Integer i = 0; i < count; i++) {
            String key = nextKey();
            orders.add(new uLab_Order__c(
                Name = 'Test Order ' + key,
                orderId__c = 'ORD-' + key,
                uLab_Case__c = caseId,
                uAssist_Status__c = uAssistStatus,
                Order_Status__c = orderStatus,
                Assigned_uAssistant__c = UserInfo.getUserId(),
                Assigned_CRB__c = assignedCrb,
                Date_Entered_In_Current_Status__c = enteredCurrentStatus,
                Date_Entered_In_Last_Status__c = enteredLastStatus,
                Send_to_WebApp__c = true
            ));
        }
        if (doInsert) {
            insert orders;
        }
        return orders;
    }

    // Creates orders without the legacy Date_Entered_In_*_Status__c timestamps so that the
    // uLab_Order_Record_Triggered_Fast_Update_Flow is the only source of the stage/rotation dates.
    public static List<uLab_Order__c> createOrdersForFlow(
        Integer count,
        Id caseId,
        String uAssistStatus,
        String orderStatus,
        Id assignedCrb,
        Boolean doInsert
    ) {
        return createOrders(count, caseId, uAssistStatus, orderStatus, null, null, assignedCrb, doInsert);
    }

    private static String nextKey() {
        counter++;
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd) + '-' + counter;
    }
}
