// Tests for FieldServiceService (lib/features/field_service/services/field_service_service.dart).
//
// The WorkOrderTask tests below are the regression guard for a real, live bug fixed 2026-08-07
// (see docs/testing/TEST_BACKLOG.md T3-FIELDSERVICE): createWorkOrderTask/updateWorkOrderTask/
// deleteWorkOrderTask/streamWorkOrderTasks all queried the root-level `work_orders` collection
// instead of the tenant-scoped path every other method in this file correctly uses — reachable
// via work_order_details_screen.dart. 3 more methods with the exact same bug
// (streamRoutePlansForTechnician, streamCustomerAssets, streamIotDevicesForCustomer) were left
// unfixed after confirming each has zero live callers — see the file's own comments at each site.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/field_service/models/field_service_models.dart';
import 'package:sentinel1/features/field_service/services/field_service_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FieldServiceService service;
  const tenantId = 'tenant-fs-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FieldServiceService(firestore.collection('tenants').doc(tenantId));
  });

  group('WorkOrder', () {
    test('createWorkOrder then getWorkOrder round-trips', () async {
      await service.createWorkOrder(WorkOrder(
        id: 'wo-1',
        workOrderNumber: 'WO-001',
        status: 'New',
        priority: 'Medium',
        customerId: 'CUST-1',
      ));

      final result = await service.getWorkOrder('wo-1');

      expect(result, isNotNull);
      expect(result!.customerId, 'CUST-1');
    });
  });

  group('WorkOrderTask — regression guard for the root-vs-tenant-collection fix', () {
    test('createWorkOrderTask nests under the work order and is findable via streamWorkOrderTasks', () async {
      await service.createWorkOrder(WorkOrder(
        id: 'wo-2',
        workOrderNumber: 'WO-002',
        status: 'New',
        priority: 'Medium',
        customerId: 'CUST-1',
      ));

      await service.createWorkOrderTask('wo-2', WorkOrderTask(
        id: 'task-1',
        taskName: 'Inspect unit',
        isMandatory: true,
        status: 'NotStarted',
        sequenceOrder: 1,
      ));

      final result = await service.streamWorkOrderTasks('wo-2').first;
      expect(result, hasLength(1));
      expect(result.single.taskName, 'Inspect unit');

      // Confirms the write really landed nested under the work order, not at a top-level collection.
      final nestedDoc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('work_orders')
          .doc('wo-2')
          .collection('tasks')
          .get();
      expect(nestedDoc.docs, hasLength(1));
    });

    test('updateWorkOrderTask persists changed fields on the nested doc', () async {
      await service.createWorkOrder(WorkOrder(
        id: 'wo-3',
        workOrderNumber: 'WO-003',
        status: 'New',
        priority: 'Medium',
        customerId: 'CUST-1',
      ));
      await service.createWorkOrderTask('wo-3', WorkOrderTask(
        id: 'task-2',
        taskName: 'Task',
        isMandatory: false,
        status: 'NotStarted',
        sequenceOrder: 1,
      ));

      await service.updateWorkOrderTask('wo-3', WorkOrderTask(
        id: 'task-2',
        taskName: 'Task',
        isMandatory: false,
        status: 'Completed',
        sequenceOrder: 1,
      ));

      final result = await service.streamWorkOrderTasks('wo-3').first;
      expect(result.single.status, 'Completed');
    });

    test('deleteWorkOrderTask removes the nested doc', () async {
      await service.createWorkOrder(WorkOrder(
        id: 'wo-4',
        workOrderNumber: 'WO-004',
        status: 'New',
        priority: 'Medium',
        customerId: 'CUST-1',
      ));
      await service.createWorkOrderTask('wo-4', WorkOrderTask(
        id: 'task-3',
        taskName: 'Task',
        isMandatory: false,
        status: 'NotStarted',
        sequenceOrder: 1,
      ));

      await service.deleteWorkOrderTask('wo-4', 'task-3');

      final result = await service.streamWorkOrderTasks('wo-4').first;
      expect(result, isEmpty);
    });
  });

  group('DispatcherRoute (route_plans)', () {
    test('createRoutePlan then getRoutePlan round-trips', () async {
      await service.createRoutePlan(DispatcherRoute(
        id: 'route-1',
        technicianId: 'TECH-1',
        status: 'Planned',
      ));

      final result = await service.getRoutePlan('route-1');

      expect(result, isNotNull);
      expect(result!.technicianId, 'TECH-1');
    });
  });

  group('CustomerAsset', () {
    test('createCustomerAsset then getCustomerAsset round-trips', () async {
      await service.createCustomerAsset(CustomerAsset(
        id: 'asset-1',
        assetName: 'Pump Unit A',
        customerId: 'CUST-1',
        status: 'Active',
      ));

      final result = await service.getCustomerAsset('asset-1');

      expect(result, isNotNull);
      expect(result!.assetName, 'Pump Unit A');
    });
  });
}
