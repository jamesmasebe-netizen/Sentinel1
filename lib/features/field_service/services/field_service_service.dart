import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/field_service_models.dart';
import '../../../core/providers/app_providers.dart';

final fieldServiceServiceProvider = Provider<FieldServiceService>((ref) {
  return FieldServiceService(ref.watch(tenantDocProvider));
});

class FieldServiceService {
  final DocumentReference _tenantDoc;

  FieldServiceService(this._tenantDoc);

  // =====================
  // WORK ORDERS
  // =====================

  Future<void> createWorkOrder(WorkOrder workOrder) async {
    final docRef = _tenantDoc.collection('work_orders').doc(workOrder.id);
    await docRef.set(workOrder.toJson());
  }

  Future<WorkOrder?> getWorkOrder(String id) async {
    final doc = await _tenantDoc.collection('work_orders').doc(id).get();
    if (doc.exists) {
      return WorkOrder.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateWorkOrder(WorkOrder workOrder) async {
    final docRef = _tenantDoc.collection('work_orders').doc(workOrder.id);
    await docRef.update(workOrder.toJson());
  }

  Future<void> deleteWorkOrder(String id) async {
    await _tenantDoc.collection('work_orders').doc(id).delete();
  }

  Stream<List<WorkOrder>> streamWorkOrders() {
    return _tenantDoc.collection('work_orders').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkOrder.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<WorkOrder?> streamWorkOrder(String id) {
    return _tenantDoc.collection('work_orders').doc(id).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return WorkOrder.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // =====================
  // WORK ORDER TASKS
  // =====================

  Future<void> createWorkOrderTask(
    String workOrderId,
    WorkOrderTask task,
  ) async {
    final docRef = _tenantDoc.firestore
        .collection('work_orders')
        .doc(workOrderId)
        .collection('tasks')
        .doc(task.id);
    await docRef.set(task.toJson());
  }

  Future<void> updateWorkOrderTask(
    String workOrderId,
    WorkOrderTask task,
  ) async {
    final docRef = _tenantDoc.firestore
        .collection('work_orders')
        .doc(workOrderId)
        .collection('tasks')
        .doc(task.id);
    await docRef.update(task.toJson());
  }

  Future<void> deleteWorkOrderTask(String workOrderId, String taskId) async {
    await _tenantDoc.firestore
        .collection('work_orders')
        .doc(workOrderId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Stream<List<WorkOrderTask>> streamWorkOrderTasks(String workOrderId) {
    return _tenantDoc.firestore
        .collection('work_orders')
        .doc(workOrderId)
        .collection('tasks')
        .orderBy('sequence_order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkOrderTask.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  // =====================
  // ROUTE PLANS (DispatcherRoute)
  // =====================

  Future<void> createRoutePlan(DispatcherRoute route) async {
    final docRef = _tenantDoc.collection('route_plans').doc(route.id);
    await docRef.set(route.toJson());
  }

  Future<DispatcherRoute?> getRoutePlan(String id) async {
    final doc = await _tenantDoc.collection('route_plans').doc(id).get();
    if (doc.exists) {
      return DispatcherRoute.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateRoutePlan(DispatcherRoute route) async {
    final docRef = _tenantDoc.collection('route_plans').doc(route.id);
    await docRef.update(route.toJson());
  }

  Future<void> deleteRoutePlan(String id) async {
    await _tenantDoc.collection('route_plans').doc(id).delete();
  }

  Stream<List<DispatcherRoute>> streamRoutePlansForTechnician(
    String technicianId,
  ) {
    return _tenantDoc.firestore
        .collection('route_plans')
        .where('technician_id', isEqualTo: technicianId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DispatcherRoute.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<DispatcherRoute?> streamRoutePlan(String id) {
    return _tenantDoc.collection('route_plans').doc(id).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return DispatcherRoute.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // =====================
  // CUSTOMER ASSETS
  // =====================

  Future<void> createCustomerAsset(CustomerAsset asset) async {
    final docRef = _tenantDoc.collection('customer_assets').doc(asset.id);
    await docRef.set(asset.toJson());
  }

  Future<CustomerAsset?> getCustomerAsset(String id) async {
    final doc = await _tenantDoc.collection('customer_assets').doc(id).get();
    if (doc.exists) {
      return CustomerAsset.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateCustomerAsset(CustomerAsset asset) async {
    final docRef = _tenantDoc.collection('customer_assets').doc(asset.id);
    await docRef.update(asset.toJson());
  }

  Future<void> deleteCustomerAsset(String id) async {
    await _tenantDoc.collection('customer_assets').doc(id).delete();
  }

  Stream<List<CustomerAsset>> streamCustomerAssets(String customerId) {
    return _tenantDoc.firestore
        .collection('customer_assets')
        .where('customer_id', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CustomerAsset.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<CustomerAsset?> streamCustomerAsset(String id) {
    return _tenantDoc.collection('customer_assets').doc(id).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return CustomerAsset.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // =====================
  // IOT DEVICES
  // =====================

  Future<void> createIotDevice(IotDevice device) async {
    final docRef = _tenantDoc.collection('iot_devices').doc(device.id);
    await docRef.set(device.toJson());
  }

  Future<IotDevice?> getIotDevice(String id) async {
    final doc = await _tenantDoc.collection('iot_devices').doc(id).get();
    if (doc.exists) {
      return IotDevice.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateIotDevice(IotDevice device) async {
    final docRef = _tenantDoc.collection('iot_devices').doc(device.id);
    await docRef.update(device.toJson());
  }

  Future<void> deleteIotDevice(String id) async {
    await _tenantDoc.collection('iot_devices').doc(id).delete();
  }

  Stream<List<IotDevice>> streamIotDevicesForCustomer(String customerId) {
    return _tenantDoc.firestore
        .collection('iot_devices')
        .where('customer_id', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => IotDevice.fromJson(doc.data(), doc.id))
              .toList();
        });
  }
}
