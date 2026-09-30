public class ULabOrderStatusKPIHandler {

    public static void handleAfterInsert(List<uLab_Order__c> newOrders){

        List<ULab_Order_Status_KPI__c> kpiRecordsToInsert = new List<ULab_Order_Status_KPI__c>();

        for (uLab_Order__c newOrder : newOrders) {

            Boolean isUAssistStatusChanged = false;
            Boolean isOrderStatusChanged = false;
            Boolean isAssignedCRBChanged = false;

            // After Insert → create KPI if status exists
            if (newOrder.uAssist_Status__c != null) { isUAssistStatusChanged = true; }
            if (newOrder.Order_Status__c != null) { isOrderStatusChanged = true; }
            if (newOrder.Assigned_CRB__c != null) { isAssignedCRBChanged = true; }

            if (isUAssistStatusChanged) {
                ULab_Order_Status_KPI__c kpi = new ULab_Order_Status_KPI__c();
                kpi.Assigned_User__c = newOrder.Assigned_uAssistant__c;
                kpi.Field_Name__c = 'uAssist_Status__c';
                kpi.New_Status_Entry_Date__c = newOrder.Date_Entered_In_Current_Status__c;
                kpi.New_Status__c = newOrder.uAssist_Status__c;
                kpi.Previous_Status_Entry_Time__c = newOrder.Date_Entered_In_Last_Status__c;
                kpi.Previous_Status__c = null;
                kpi.uLab_Order__c = newOrder.Id;
                kpiRecordsToInsert.add(kpi);
            }

            if (isOrderStatusChanged) {
                ULab_Order_Status_KPI__c kpi = new ULab_Order_Status_KPI__c();
                kpi.Assigned_User__c = newOrder.Assigned_CRB__c;
                kpi.Field_Name__c = 'Order_Status__c';
                kpi.New_Status_Entry_Date__c = newOrder.Order_Status_Entered_Current__c;
                kpi.New_Status__c = newOrder.Order_Status__c;
                kpi.Previous_Status_Entry_Time__c = newOrder.Order_Status_Entered_Last__c != null
                    ? newOrder.Order_Status_Entered_Last__c : newOrder.CreatedDate;
                kpi.Previous_Status__c = null;
                kpi.uLab_Order__c = newOrder.Id;
                kpiRecordsToInsert.add(kpi);
            }

            if (isAssignedCRBChanged) {
                ULab_Order_Status_KPI__c kpi = new ULab_Order_Status_KPI__c();
                kpi.Assigned_User__c = newOrder.Assigned_CRB__c;
                kpi.Field_Name__c = 'Assigned_CRB__c';
                kpi.New_Status_Entry_Date__c = newOrder.CRB_Assigned_Date__c;
                kpi.New_Status__c = newOrder.Assigned_CRB__c;
                kpi.Previous_Status_Entry_Time__c = newOrder.CreatedDate;
                kpi.Previous_Status__c = null;
                kpi.uLab_Order__c = newOrder.Id;
                kpiRecordsToInsert.add(kpi);
            }
        }

        if (!kpiRecordsToInsert.isEmpty()) {
            try {
                insert kpiRecordsToInsert;
            } catch (DmlException e) {
                System.debug('ULab Order KPI insert failed: ' + e.getMessage());
            }
        }
    }

    public static void handleAfterUpdate(List<uLab_Order__c> newOrders, Map<Id,uLab_Order__c> oldMap){

        List<ULab_Order_Status_KPI__c> kpiRecordsToInsert = new List<ULab_Order_Status_KPI__c>();

        for (uLab_Order__c newOrder : newOrders) {

            uLab_Order__c oldOrder = oldMap.get(newOrder.Id);

            Boolean isUAssistStatusChanged = false;
            Boolean isOrderStatusChanged = false;
            Boolean isAssignedCRBChanged = false;

            // After Update → create KPI only if status changed
            if (newOrder.uAssist_Status__c != oldOrder.uAssist_Status__c) { isUAssistStatusChanged = true; }
            if (newOrder.Order_Status__c != oldOrder.Order_Status__c) { isOrderStatusChanged = true; }
            if (newOrder.Assigned_CRB__c != oldOrder.Assigned_CRB__c && oldOrder.Assigned_CRB__c == null) { isAssignedCRBChanged = true;}

            if (isUAssistStatusChanged) {
                ULab_Order_Status_KPI__c kpi = new ULab_Order_Status_KPI__c();
                kpi.Assigned_User__c = newOrder.Assigned_uAssistant__c;
                kpi.Field_Name__c = 'uAssist_Status__c';
                kpi.New_Status_Entry_Date__c = newOrder.Date_Entered_In_Current_Status__c;
                kpi.New_Status__c = newOrder.uAssist_Status__c;
                kpi.Previous_Status_Entry_Time__c = newOrder.Date_Entered_In_Last_Status__c;
                kpi.Previous_Status__c = oldOrder.uAssist_Status__c;
                kpi.uLab_Order__c = newOrder.Id;
                kpiRecordsToInsert.add(kpi);
            }

            if (isOrderStatusChanged) {
                ULab_Order_Status_KPI__c kpi = new ULab_Order_Status_KPI__c();
                kpi.Assigned_User__c = newOrder.Assigned_CRB__c;
                kpi.Field_Name__c = 'Order_Status__c';
                kpi.New_Status_Entry_Date__c = newOrder.Order_Status_Entered_Current__c;
                kpi.New_Status__c = newOrder.Order_Status__c;
                kpi.Previous_Status_Entry_Time__c = newOrder.Order_Status_Entered_Last__c != null
                    ? newOrder.Order_Status_Entered_Last__c : newOrder.CreatedDate;
                kpi.Previous_Status__c = oldOrder.Order_Status__c;
                kpi.uLab_Order__c = newOrder.Id;
                kpiRecordsToInsert.add(kpi);
            }

            if (isAssignedCRBChanged) {
                ULab_Order_Status_KPI__c kpi = new ULab_Order_Status_KPI__c();
                kpi.Assigned_User__c = newOrder.Assigned_CRB__c;
                kpi.Field_Name__c = 'Assigned_CRB__c';
                kpi.New_Status_Entry_Date__c = newOrder.CRB_Assigned_Date__c;
                kpi.New_Status__c = newOrder.Assigned_CRB__c;
                kpi.Previous_Status_Entry_Time__c = newOrder.CreatedDate;
                kpi.Previous_Status__c = oldOrder.Assigned_CRB__c;
                kpi.uLab_Order__c = newOrder.Id;
                kpiRecordsToInsert.add(kpi);
            }
        }

        if (!kpiRecordsToInsert.isEmpty()) {
            try {
                insert kpiRecordsToInsert;
            } catch (DmlException e) {
                System.debug('ULab Order KPI insert failed: ' + e.getMessage());
            }
        }
    }
}