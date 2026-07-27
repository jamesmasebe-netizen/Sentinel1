import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_providers.dart';
import '../../features/field_service/models/work_order.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

final lotoAutomationProvider = Provider<LotoAutomation>((ref) {
  final tenantId = ref.read(currentTenantIdProvider) ?? '';
  return LotoAutomation(FirebaseFirestore.instance, tenantId);
});

class LotoAutomation {
  final FirebaseFirestore _db;
  final String _tenantId;

  LotoAutomation(this._db, this._tenantId);

  /// Locks out a failed equipment item and auto-generates a Field Service Work Order
  Future<String> lockoutFailedEquipment({
    required String equipmentId,
    required String equipmentName,
    required String reason,
    required String reportedById,
    String? projectId,
  }) async {
    // 1. Update equipment status to 'Locked Out'
    await _db.tenantCollection(_tenantId, 'equipment').doc(equipmentId).update({
      'status': 'Locked Out',
      'lockoutReason': reason,
      'lockoutDate': DateTime.now().toIso8601String(),
      'lockoutBy': reportedById,
    });

    // 2. Auto-generate a Work Order for repair/inspection
    final workOrderId = 'WO-LOTO-${DateTime.now().millisecondsSinceEpoch}';
    final workOrder = WorkOrder(
      id: workOrderId,
      title: 'LOTO: $equipmentName - Mandatory Inspection',
      description: 'Auto-generated LOTO work order.\nReason: $reason\nEquipment: $equipmentName ($equipmentId)',
      status: 'Open',
      scheduledDate: DateTime.now().add(const Duration(hours: 24)),
    );

    await _db.tenantCollection(_tenantId, 'work_orders').doc(workOrderId).set(workOrder.toJson());

    // 3. Log the LOTO event
    await _db.tenantCollection(_tenantId, 'loto_events').add({
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'workOrderId': workOrderId,
      'reason': reason,
      'reportedById': reportedById,
      'projectId': projectId,
      'action': 'lockout',
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('LOTO: Equipment $equipmentId locked out, work order $workOrderId created');
    return workOrderId;
  }

  /// Releases a lockout after inspection/repair is completed
  Future<void> releaseLockout({
    required String equipmentId,
    required String releasedById,
    required String workOrderId,
  }) async {
    await _db.tenantCollection(_tenantId, 'equipment').doc(equipmentId).update({
      'status': 'Operational',
      'lockoutReason': null,
      'lockoutDate': null,
      'lockoutBy': null,
    });

    // Log the release
    await _db.tenantCollection(_tenantId, 'loto_events').add({
      'equipmentId': equipmentId,
      'workOrderId': workOrderId,
      'releasedById': releasedById,
      'action': 'release',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Stream equipment that is currently locked out
  Stream<List<Map<String, dynamic>>> streamLockedOutEquipment() {
    return _db
        .tenantCollection(_tenantId, 'equipment')
        .where('status', isEqualTo: 'Locked Out')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
