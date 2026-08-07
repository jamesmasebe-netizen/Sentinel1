// Tests for ActionTrackerService (lib/features/operations/services/action_tracker_service.dart).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/operations/models/action_tracker_models.dart';
import 'package:sentinel1/features/operations/services/action_tracker_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ActionTrackerService service;
  const tenantId = 'tenant-ops-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = ActionTrackerService(firestore.collection('tenants').doc(tenantId));
  });

  ActionItem buildItem({String id = '', String status = 'Open', String dueDate = '2026-12-01'}) {
    return ActionItem(
      id: id,
      collectionName: 'incidents',
      type: 'CAPA',
      title: 'Fix guardrail',
      status: status,
      dueDate: dueDate,
      assignee: 'emp-1',
    );
  }

  test('createActionItem persists and is findable via streamActionItems', () async {
    await service.createActionItem(buildItem());

    final result = await service.streamActionItems().first;

    expect(result, hasLength(1));
    expect(result.single.title, 'Fix guardrail');
  });

  test('streamActionItemsByStatus filters by status', () async {
    await service.createActionItem(buildItem(id: 'item-1', status: 'Open'));
    await service.createActionItem(buildItem(id: 'item-2', status: 'Closed'));

    final result = await service.streamActionItemsByStatus('Open').first;

    expect(result, hasLength(1));
    expect(result.single.id, 'item-1');
  });

  test('updateActionItem persists changed fields without clobbering createdAt', () async {
    await service.createActionItem(buildItem(id: 'item-3', status: 'Open'));

    await service.updateActionItem(buildItem(id: 'item-3', status: 'Closed'));

    final result = await service.getActionItem('item-3');
    expect(result!.status, 'Closed');
  });

  test('deleteActionItem removes the doc', () async {
    await service.createActionItem(buildItem(id: 'item-4'));

    await service.deleteActionItem('item-4');

    expect(await service.getActionItem('item-4'), isNull);
  });
}
