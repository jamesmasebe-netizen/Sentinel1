// Tests for LotoAutomation (lib/core/automation/loto_automation.dart) — the Lockout/Tagout
// safety automation: locking out failed equipment auto-generates a Work Order and logs an
// event; releasing a lockout requires and persists the 3-point verification checklist (F-215 in
// docs/fixes/FIX_LIST.md).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/automation/loto_automation.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late LotoAutomation automation;
  const tenantId = 'tenant-loto-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    automation = LotoAutomation(firestore, tenantId);
  });

  group('lockoutFailedEquipment', () {
    test('marks the equipment Locked Out, creates a HIGH-priority work order, and logs a lockout event',
        () async {
      await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('equipment')
          .doc('eq-1')
          .set({'status': 'Operational'});

      final workOrderId = await automation.lockoutFailedEquipment(
        equipmentId: 'eq-1',
        equipmentName: 'Excavator #3',
        reason: 'Hydraulic leak',
        reportedById: 'emp-1',
      );

      final equipmentDoc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('equipment')
          .doc('eq-1')
          .get();
      expect(equipmentDoc.data()!['status'], 'Locked Out');
      expect(equipmentDoc.data()!['lockoutReason'], 'Hydraulic leak');
      expect(equipmentDoc.data()!['lockoutWorkOrderId'], workOrderId);

      final workOrderDoc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('work_orders')
          .doc(workOrderId)
          .get();
      expect(workOrderDoc.exists, isTrue);
      expect(workOrderDoc.data()!['priority'], 'HIGH');
      expect(workOrderDoc.data()!['asset_id'], 'eq-1');

      final events = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('loto_events')
          .get();
      expect(events.docs, hasLength(1));
      expect(events.docs.single.data()['action'], 'lockout');
      expect(events.docs.single.data()['workOrderId'], workOrderId);
    });
  });

  group('releaseLockout', () {
    test('restores equipment to Operational, clears lockout fields, and persists the verification checklist',
        () async {
      await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('equipment')
          .doc('eq-2')
          .set({
        'status': 'Locked Out',
        'lockoutReason': 'Test',
        'lockoutDate': 'x',
        'lockoutBy': 'emp-1',
        'lockoutWorkOrderId': 'WO-LOTO-1',
      });

      await automation.releaseLockout(
        equipmentId: 'eq-2',
        releasedById: 'emp-2',
        workOrderId: 'WO-LOTO-1',
        guardsRestored: true,
        areaClear: true,
        isolationDeviceRemoved: false,
      );

      final equipmentDoc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('equipment')
          .doc('eq-2')
          .get();
      expect(equipmentDoc.data()!['status'], 'Operational');
      expect(equipmentDoc.data()!['lockoutReason'], isNull);
      expect(equipmentDoc.data()!['lockoutWorkOrderId'], isNull);

      final events = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('loto_events')
          .get();
      final releaseEvent = events.docs.firstWhere((d) => d.data()['action'] == 'release');
      final checklist = releaseEvent.data()['verificationChecklist'] as Map;
      expect(checklist['guardsRestored'], isTrue);
      expect(checklist['areaClear'], isTrue);
      // Deliberately false — proves the checklist isn't silently coerced to all-true.
      expect(checklist['isolationDeviceRemoved'], isFalse);
    });
  });

  group('streamLockedOutEquipment', () {
    test('returns only equipment currently in Locked Out status', () async {
      await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('equipment')
          .doc('eq-locked')
          .set({'status': 'Locked Out'});
      await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('equipment')
          .doc('eq-ok')
          .set({'status': 'Operational'});

      final result = await automation.streamLockedOutEquipment().first;

      expect(result, hasLength(1));
      expect(result.single['id'], 'eq-locked');
    });
  });
}
