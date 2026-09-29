@isTest
public class ULabOrderTriggerTest {

    // Generate unique value
    private static String uniqueSuffix() {        
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

    @isTest
    static void testULabOrderTriggerHandlers() {

        String suf = uniqueSuffix();

        // Create Account
        Account acc = new Account(
            Name = 'Test Account ' + suf
        );
        insert acc;

        // Create uLab Case
        uLab_Case__c caseRec = new uLab_Case__c(
            Account__c = acc.Id
        );
        insert caseRec;

        // Create Order
        uLab_Order__c ord = new uLab_Order__c(
            Name = 'Test Order ' + suf,
            orderId__c = 'ORD-' + suf,
            uLab_Case__c = caseRec.Id,
            uAssist_Status__c = 'In Progress',
            Assigned_uAssistant__c = UserInfo.getUserId(),
            Date_Entered_In_Current_Status__c = System.now(),
            Date_Entered_In_Last_Status__c = System.now(),
            Send_to_WebApp__c = true
        );

        Test.startTest();

        // INSERT → KPI Insert Handler
        insert ord;

        // UPDATE 1 → KPI Update Handler
        ord.uAssist_Status__c = 'Model Prep Complete';
        update ord;

        // UPDATE 2 → OrderChangeHandler (Event publish path)
        ord.uAssist_Status__c = 'Completed';
        update ord;

        Test.stopTest();

        // Verify KPI records
        List<ULab_Order_Status_KPI__c> kpiList = [
            SELECT Id, New_Status__c
            FROM ULab_Order_Status_KPI__c
            WHERE uLab_Order__c = :ord.Id
        ];

        System.assert(kpiList.size() > 0, 'KPI records should be created');
    }
}