// Tests for PmoService's TimeEntry CRUD (lib/features/projects/services/pmo_service.dart).
//
// FIXED (see docs/testing/TEST_BACKLOG.md's "still open" close-out pass,
// timeEntries/time_entries unification): createTimeEntry/
// updateTimeEntry/deleteTimeEntry had zero callers anywhere in lib/ despite
// project_detail_screen.dart's Time Entries tab already streaming
// streamTimeEntriesForProject live — meaning that tab always rendered empty.
// timesheet_entry_screen.dart (previously writing a separate, never-read
// 'timeEntries' collection via ProjectService.addTimeEntry, now deleted) was
// repointed to createTimeEntry, making this the module's real writer. WBS/
// Expense/Actual CRUD are untouched by that fix and out of scope here.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/projects/models/pmo_models.dart';
import 'package:sentinel1/features/projects/services/pmo_service.dart';

const _tenantId = 'tenant-pmo-1';

void main() {
  late FakeFirebaseFirestore firestore;
  late PmoService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = PmoService(firestore, _tenantId);
  });

  TimeEntry buildEntry({String entryId = 'entry-1', String projectId = 'proj-1'}) {
    return TimeEntry(
      entryId: entryId,
      resourceId: 'user-1',
      projectId: projectId,
      taskId: '',
      date: DateTime(2026, 1, 1),
      hours: 4.5,
      description: 'Site inspection',
      isBillable: true,
      billingStatus: 'Unbilled',
      approvalStatus: 'Draft',
    );
  }

  group('TimeEntry CRUD', () {
    test('createTimeEntry writes to the tenant-scoped time_entries collection', () async {
      await service.createTimeEntry(buildEntry());

      final doc = await firestore
          .collection('tenants')
          .doc(_tenantId)
          .collection('time_entries')
          .doc('entry-1')
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['projectId'], 'proj-1');
      expect(doc.data()!['hours'], 4.5);
      expect(doc.data()!['approvalStatus'], 'Draft');
    });

    test('getTimeEntry reads back a created entry', () async {
      await service.createTimeEntry(buildEntry());

      final result = await service.getTimeEntry('entry-1');

      expect(result, isNotNull);
      expect(result!.description, 'Site inspection');
      expect(result.resourceId, 'user-1');
    });

    test('getTimeEntry returns null for a nonexistent id', () async {
      final result = await service.getTimeEntry('does-not-exist');

      expect(result, isNull);
    });

    test('updateTimeEntry overwrites the existing doc', () async {
      await service.createTimeEntry(buildEntry());

      final updated = TimeEntry(
        entryId: 'entry-1',
        resourceId: 'user-1',
        projectId: 'proj-1',
        taskId: '',
        date: DateTime(2026, 1, 1),
        hours: 8,
        description: 'Site inspection',
        isBillable: true,
        billingStatus: 'Unbilled',
        approvalStatus: 'Approved',
      );
      await service.updateTimeEntry(updated);

      final result = await service.getTimeEntry('entry-1');
      expect(result!.hours, 8);
      expect(result.approvalStatus, 'Approved');
    });

    test('deleteTimeEntry removes the doc', () async {
      await service.createTimeEntry(buildEntry());

      await service.deleteTimeEntry('entry-1');

      final result = await service.getTimeEntry('entry-1');
      expect(result, isNull);
    });

    test('streamTimeEntriesForProject filters by projectId', () async {
      await service.createTimeEntry(buildEntry(entryId: 'e1', projectId: 'proj-1'));
      await service.createTimeEntry(buildEntry(entryId: 'e2', projectId: 'proj-2'));

      final result = await service.streamTimeEntriesForProject('proj-1').first;

      expect(result, hasLength(1));
      expect(result.single.entryId, 'e1');
    });
  });
}
