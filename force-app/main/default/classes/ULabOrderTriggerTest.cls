@isTest
public class ULabOrderTriggerTest {

    private static final String UASSIST = 'uAssist_Status__c';
    private static final String ORDER = 'Order_Status__c';
    private static final Datetime CURRENT_ENTRY = Datetime.newInstance(2026, 1, 15, 10, 0, 0);
    private static final Datetime LAST_ENTRY = Datetime.newInstance(2026, 1, 10, 8, 30, 0);
    private static final Integer BULK_SIZE = 251;

    @TestSetup
    static void setupTestData() {
        Account acc = ULabOrderTestDataFactory.createAccount(true);
        ULabOrderTestDataFactory.createCase(acc.Id, true);
    }

    // Assigned_CRB__c only accepts Users with CRB_Member__c = true (lookup filter). DML on User is not
    // possible in tests (the CompSuite package trigger fails on it), so reuse an existing CRB member.
    private static Id crbUserId() {
        List<User> members = [SELECT Id FROM User WHERE CRB_Member__c = true AND IsActive = true LIMIT 1];
        Assert.isFalse(members.isEmpty(), 'An active User with CRB_Member__c = true is required to run this test');
        return members[0].Id;
    }

    private static Id caseId() {
        return [SELECT Id FROM uLab_Case__c LIMIT 1].Id;
    }

    private static List<ULab_Order_Status_KPI__c> kpis(Set<Id> orderIds, String fieldName) {
        return [
            SELECT Id, Field_Name__c, New_Status__c, Previous_Status__c, Assigned_User__c,
                   New_Status_Entry_Date__c, Previous_Status_Entry_Time__c, uLab_Order__c
            FROM ULab_Order_Status_KPI__c
            WHERE uLab_Order__c IN :orderIds AND Field_Name__c = :fieldName
        ];
    }

    private static Set<Id> ids(List<uLab_Order__c> orders) {
        return new Map<Id, uLab_Order__c>(orders).keySet();
    }

    @isTest
    static void shouldCreateUAssistKpi_WhenOrderInsertedWithUAssistStatus() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), 'In Progress', null, CURRENT_ENTRY, LAST_ENTRY, false);

        // When
        Test.startTest();
        insert orders;
        Test.stopTest();

        // Then
        List<ULab_Order_Status_KPI__c> uAssistKpis = kpis(ids(orders), UASSIST);
        Assert.areEqual(1, uAssistKpis.size(), 'One uAssist KPI should be created');
        ULab_Order_Status_KPI__c kpi = uAssistKpis[0];
        Assert.areEqual('In Progress', kpi.New_Status__c, 'New status should match the order');
        Assert.isNull(kpi.Previous_Status__c, 'Previous status should be null on insert');
        Assert.areEqual(UserInfo.getUserId(), kpi.Assigned_User__c, 'Assigned user should be copied');
        Assert.isNotNull(kpi.New_Status_Entry_Date__c, 'New entry date should be populated');
        Assert.isNotNull(kpi.Previous_Status_Entry_Time__c, 'Previous entry time should be populated');
        Assert.areEqual(0, kpis(ids(orders), ORDER).size(), 'No Order Status KPI without an order status');
    }

    @isTest
    static void shouldCreateOrderStatusKpi_WhenOrderInsertedWithOrderStatus() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), null, 'Pending', CURRENT_ENTRY, LAST_ENTRY, false);

        // When
        Test.startTest();
        insert orders;
        Test.stopTest();

        // Then
        List<ULab_Order_Status_KPI__c> orderKpis = kpis(ids(orders), ORDER);
        Assert.areEqual(1, orderKpis.size(), 'One Order Status KPI should be created');
        ULab_Order_Status_KPI__c kpi = orderKpis[0];
        Assert.areEqual('Pending', kpi.New_Status__c, 'New status should match the order');
        Assert.isNull(kpi.Previous_Status__c, 'Previous status should be null on insert');
        Assert.areEqual(UserInfo.getUserId(), kpi.Assigned_User__c, 'Assigned user should be copied');
        Assert.isNotNull(kpi.New_Status_Entry_Date__c, 'New entry date should be populated');
        Assert.isNotNull(kpi.Previous_Status_Entry_Time__c, 'Previous entry time should be populated');
        Assert.areEqual(0, kpis(ids(orders), UASSIST).size(), 'No uAssist KPI without a uAssist status');
    }

    @isTest
    static void shouldCreateBothKpis_WhenOrderInsertedWithBothStatuses() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), 'In Progress', 'Pending', CURRENT_ENTRY, LAST_ENTRY, false);

        // When
        Test.startTest();
        insert orders;
        Test.stopTest();

        // Then
        Assert.areEqual(1, kpis(ids(orders), UASSIST).size(), 'uAssist KPI should be created');
        Assert.areEqual(1, kpis(ids(orders), ORDER).size(), 'Order Status KPI should be created');
    }

    @isTest
    static void shouldNotCreateKpi_WhenOrderInsertedWithoutStatuses() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), null, null, CURRENT_ENTRY, LAST_ENTRY, false);

        // When
        Test.startTest();
        insert orders;
        Test.stopTest();

        // Then
        Integer total = [SELECT COUNT() FROM ULab_Order_Status_KPI__c WHERE uLab_Order__c IN :ids(orders)];
        Assert.areEqual(0, total, 'No KPI should be created when both statuses are null');
    }

    @isTest
    static void shouldCreateUAssistKpiWithPreviousStatus_WhenUAssistStatusChanges() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), 'In Progress', null, CURRENT_ENTRY, LAST_ENTRY, true);

        // When
        Test.startTest();
        orders[0].uAssist_Status__c = 'Model Prep Complete';
        update orders;
        Test.stopTest();

        // Then
        List<ULab_Order_Status_KPI__c> changeKpis = [
            SELECT New_Status__c, Previous_Status__c, Assigned_User__c,
                   New_Status_Entry_Date__c, Previous_Status_Entry_Time__c
            FROM ULab_Order_Status_KPI__c
            WHERE uLab_Order__c = :orders[0].Id AND Field_Name__c = :UASSIST
              AND New_Status__c = 'Model Prep Complete'
        ];
        Assert.areEqual(1, changeKpis.size(), 'One KPI should be created for the status change');
        Assert.areEqual('In Progress', changeKpis[0].Previous_Status__c, 'Previous status should be the old value');
        Assert.areEqual(UserInfo.getUserId(), changeKpis[0].Assigned_User__c, 'Assigned user should be copied');
        Assert.isNotNull(changeKpis[0].New_Status_Entry_Date__c, 'New entry date should be populated');
        Assert.isNotNull(changeKpis[0].Previous_Status_Entry_Time__c, 'Previous entry time should be populated');
        Assert.areEqual(0, kpis(ids(orders), ORDER).size(), 'Order Status KPI should not be created');
    }

    @isTest
    static void shouldCreateOrderStatusKpiWithPreviousStatus_WhenOrderStatusChanges() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), null, 'Pending', CURRENT_ENTRY, LAST_ENTRY, true);

        // When
        Test.startTest();
        orders[0].Order_Status__c = 'Processed';
        update orders;
        Test.stopTest();

        // Then
        List<ULab_Order_Status_KPI__c> changeKpis = [
            SELECT New_Status__c, Previous_Status__c, Assigned_User__c,
                   New_Status_Entry_Date__c, Previous_Status_Entry_Time__c
            FROM ULab_Order_Status_KPI__c
            WHERE uLab_Order__c = :orders[0].Id AND Field_Name__c = :ORDER
              AND New_Status__c = 'Processed'
        ];
        Assert.areEqual(1, changeKpis.size(), 'One KPI should be created for the status change');
        Assert.areEqual('Pending', changeKpis[0].Previous_Status__c, 'Previous status should be the old value');
        Assert.areEqual(UserInfo.getUserId(), changeKpis[0].Assigned_User__c, 'Assigned user should be copied');
        Assert.isNotNull(changeKpis[0].New_Status_Entry_Date__c, 'New entry date should be populated');
        Assert.isNotNull(changeKpis[0].Previous_Status_Entry_Time__c, 'Previous entry time should be populated');
        Assert.areEqual(0, kpis(ids(orders), UASSIST).size(), 'uAssist KPI should not be created');
    }

    @isTest
    static void shouldNotCreateKpi_WhenUpdateDoesNotChangeStatuses() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), 'In Progress', 'Pending', CURRENT_ENTRY, LAST_ENTRY, true);
        Integer kpisAfterInsert = [SELECT COUNT() FROM ULab_Order_Status_KPI__c WHERE uLab_Order__c = :orders[0].Id];

        // When
        Test.startTest();
        update orders;
        Test.stopTest();

        // Then
        Integer kpisAfterUpdate = [SELECT COUNT() FROM ULab_Order_Status_KPI__c WHERE uLab_Order__c = :orders[0].Id];
        Assert.areEqual(2, kpisAfterInsert, 'Insert should create one KPI per status');
        Assert.areEqual(kpisAfterInsert, kpisAfterUpdate, 'Update without status change should not create KPIs');
    }

    @isTest
    static void shouldCreateKpisForAllRecords_WhenBulkInsert() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            BULK_SIZE, caseId(), 'In Progress', 'Pending', CURRENT_ENTRY, LAST_ENTRY, false);

        // When
        Test.startTest();
        insert orders;
        Test.stopTest();

        // Then
        Assert.areEqual(BULK_SIZE, kpis(ids(orders), UASSIST).size(), 'One uAssist KPI per order');
        Assert.areEqual(BULK_SIZE, kpis(ids(orders), ORDER).size(), 'One Order Status KPI per order');
    }

    @isTest
    static void shouldCreateKpisForAllRecords_WhenBulkUpdate() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            BULK_SIZE, caseId(), 'In Progress', 'Pending', CURRENT_ENTRY, LAST_ENTRY, true);

        // When
        Test.startTest();
        for (uLab_Order__c ord : orders) {
            ord.uAssist_Status__c = 'Model Prep Complete';
            ord.Order_Status__c = 'Processed';
        }
        update orders;
        Test.stopTest();

        // Then
        Integer uAssistChanges = [
            SELECT COUNT() FROM ULab_Order_Status_KPI__c
            WHERE uLab_Order__c IN :ids(orders) AND Field_Name__c = :UASSIST
              AND Previous_Status__c = 'In Progress' AND New_Status__c = 'Model Prep Complete'
        ];
        Integer orderChanges = [
            SELECT COUNT() FROM ULab_Order_Status_KPI__c
            WHERE uLab_Order__c IN :ids(orders) AND Field_Name__c = :ORDER
              AND Previous_Status__c = 'Pending' AND New_Status__c = 'Processed'
        ];
        Assert.areEqual(BULK_SIZE, uAssistChanges, 'One uAssist change KPI per order');
        Assert.areEqual(BULK_SIZE, orderChanges, 'One Order Status change KPI per order');
    }

    @isTest
    static void shouldSwallowDmlException_WhenInsertKpiMissingRequiredDates() {
        // Given: KPI requires both entry dates, so the handler insert fails and is caught
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), 'In Progress', 'Pending', null, null, false);

        // When
        Test.startTest();
        insert orders;
        Test.stopTest();

        // Then
        Assert.isNotNull(orders[0].Id, 'Order insert should succeed despite the KPI failure');
        Integer total = [SELECT COUNT() FROM ULab_Order_Status_KPI__c WHERE uLab_Order__c = :orders[0].Id];
        Assert.areEqual(0, total, 'No KPI should be saved when required dates are missing');
    }

    @isTest
    static void shouldSwallowDmlException_WhenUpdateKpiMissingRequiredDates() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), null, null, null, null, true);

        // When
        Test.startTest();
        orders[0].uAssist_Status__c = 'In Progress';
        orders[0].Order_Status__c = 'Pending';
        update orders;
        Test.stopTest();

        // Then
        uLab_Order__c reloaded = [SELECT uAssist_Status__c, Order_Status__c FROM uLab_Order__c WHERE Id = :orders[0].Id];
        Assert.areEqual('In Progress', reloaded.uAssist_Status__c, 'Order update should succeed despite the KPI failure');
        Assert.areEqual('Pending', reloaded.Order_Status__c, 'Order update should succeed despite the KPI failure');
        Integer total = [SELECT COUNT() FROM ULab_Order_Status_KPI__c WHERE uLab_Order__c = :orders[0].Id];
        Assert.areEqual(0, total, 'No KPI should be saved when required dates are missing');
    }

    @isTest
    static void shouldCreateCrbKpi_WhenOrderInsertedWithAssignedCrb() {
        // Given
        Id crbId = crbUserId();
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), null, null, CURRENT_ENTRY, LAST_ENTRY, crbId, false);

        // When
        Test.startTest();
        insert orders;
        Test.stopTest();

        // Then
        List<ULab_Order_Status_KPI__c> crbKpis = kpis(ids(orders), CRB);
        Assert.areEqual(1, crbKpis.size(), 'One CRB KPI should be created');
        Assert.areEqual(String.valueOf(crbId), crbKpis[0].New_Status__c, 'New status should hold the CRB user Id');
        Assert.isNull(crbKpis[0].Previous_Status__c, 'Previous status should be null on insert');
        Assert.areEqual(crbId, crbKpis[0].Assigned_User__c, 'Assigned user should be the CRB user');
        Assert.isNotNull(crbKpis[0].New_Status_Entry_Date__c, 'New entry date should be populated');
    }

    @isTest
    static void shouldNotCreateCrbKpi_WhenOrderInsertedWithoutAssignedCrb() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), 'In Progress', 'Pending', CURRENT_ENTRY, LAST_ENTRY, false);

        // When
        Test.startTest();
        insert orders;
        Test.stopTest();

        // Then
        Assert.areEqual(0, kpis(ids(orders), CRB).size(), 'No CRB KPI without an assigned CRB');
    }

    @isTest
    static void shouldCreateCrbKpiWithNullPrevious_WhenAssignedCrbSetFromNull() {
        // Given
        Id crbId = crbUserId();
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), null, null, CURRENT_ENTRY, LAST_ENTRY, true);

        // When
        Test.startTest();
        orders[0].Assigned_CRB__c = crbId;
        update orders;
        Test.stopTest();

        // Then
        List<ULab_Order_Status_KPI__c> crbKpis = kpis(ids(orders), CRB);
        Assert.areEqual(1, crbKpis.size(), 'One CRB KPI should be created on first assignment');
        Assert.areEqual(String.valueOf(crbId), crbKpis[0].New_Status__c, 'New status should hold the CRB user Id');
        Assert.isNull(crbKpis[0].Previous_Status__c, 'Previous status should be null on first assignment');
        Assert.isNotNull(crbKpis[0].New_Status_Entry_Date__c, 'New entry date should be populated');
    }

    @isTest
    static void shouldNotCreateCrbKpi_WhenAssignedCrbCleared() {
        // Given: only the first assignment (old value null) creates a KPI
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), null, null, CURRENT_ENTRY, LAST_ENTRY, crbUserId(), true);
        Assert.areEqual(1, kpis(ids(orders), CRB).size(), 'Insert should create the first CRB KPI');

        // When
        Test.startTest();
        orders[0].Assigned_CRB__c = null;
        update orders;
        Test.stopTest();

        // Then
        Assert.areEqual(1, kpis(ids(orders), CRB).size(), 'Clearing the CRB should not create another CRB KPI');
    }

    @isTest
    static void shouldNotCreateCrbKpi_WhenUpdateDoesNotChangeAssignedCrb() {
        // Given
        List<uLab_Order__c> orders = ULabOrderTestDataFactory.createOrders(
            1, caseId(), 'In Progress', null, CURRENT_ENTRY, LAST_ENTRY, crbUserId(), true);

        // When
        Test.startTest();
        orders[0].uAssist_Status__c = 'Model Prep Complete';
        update orders;
        Test.stopTest();

        // Then
        Assert.areEqual(1, kpis(ids(orders), CRB).size(), 'Only the insert CRB KPI should exist');
    }

    @isTest
    static void shouldCreateCrbKpisForAllRecords_WhenBulkInsertAndUpdate() {
        // Given
        Id crbId = crbUserId();
        List<uLab_Order__c> inserted = ULabOrderTestDataFactory.createOrders(
            BULK_SIZE, caseId(), null, null, CURRENT_ENTRY, LAST_ENTRY, crbId, false);
        List<uLab_Order__c> toUpdate = ULabOrderTestDataFactory.createOrders(
            BULK_SIZE, caseId(), null, null, CURRENT_ENTRY, LAST_ENTRY, true);

        // When
        Test.startTest();
        insert inserted;
        for (uLab_Order__c ord : toUpdate) {
            ord.Assigned_CRB__c = crbId;
        }
        update toUpdate;
        Test.stopTest();

        // Then
        Assert.areEqual(BULK_SIZE, kpis(ids(inserted), CRB).size(), 'One CRB KPI per inserted order');
        Assert.areEqual(BULK_SIZE, kpis(ids(toUpdate), CRB).size(), 'One CRB KPI per updated order');
    }
}
