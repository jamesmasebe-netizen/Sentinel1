// Tests for pendingApprovalsFutureProvider (lib/features/dashboard/providers/approvals_provider.dart).
//
// FIXED 2026 (this pass): the leave-requests query previously hardcoded FirebaseFirestore.instance
// while the job-requisitions query right below it (in the same function) correctly used the
// overridable firestoreProvider — a real, inconsistent DI gap. A test overriding firestoreProvider
// with a FakeFirebaseFirestore (the standard convention throughout this suite) would previously see
// leave requests silently vanish, since the hardcoded FirebaseFirestore.instance never touches the
// fake. Both queries now share one `firestore = ref.watch(firestoreProvider)` local.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/models/user_profile.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import 'package:sentinel1/features/dashboard/providers/approvals_provider.dart';

const _tenantId = 'tenant-approvals-1';
const _manager = UserProfile(uid: 'mgr-1', email: 'mgr@test.com', displayName: 'Manager One');

void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      currentTenantIdProvider.overrideWithValue(_tenantId),
      userProfileProvider.overrideWith((ref) => Stream.value(_manager)),
    ]);
    addTearDown(container.dispose);
  });

  test('picks up a pending leave request through the injected firestoreProvider, not a real singleton', () async {
    await firestore.tenantCollection(_tenantId, 'leave_requests').add({
      'siteId': _tenantId,
      'managerId': 'mgr-1',
      'status': 'Pending',
      'employeeName': 'Alice',
      'leaveType': 'Annual',
      'reason': 'Vacation',
      'startDate': DateTime(2026, 3, 1),
    });

    // pendingApprovalsFutureProvider is autoDispose: container.read(...future) alone doesn't keep
    // it alive for the duration of the async gap, so it can get disposed mid-flight. An explicit
    // listener holds it open until this scope's teardown.
    final sub = container.listen(pendingApprovalsFutureProvider, (_, __) {});
    addTearDown(sub.close);
    final items = await container.read(pendingApprovalsFutureProvider.future);

    expect(items, hasLength(1));
    expect(items.single.type, 'Leave');
    expect(items.single.title, 'Alice - Annual');
  });

  test('picks up a pending job requisition for the hiring manager', () async {
    await firestore.tenantCollection(_tenantId, 'job_requisitions').add({
      'siteId': _tenantId,
      'hiringManagerId': 'mgr-1',
      'status': 'Draft',
      'jobTitle': 'Site Engineer',
      'department': 'Operations',
      'createdAt': DateTime(2026, 2, 1),
    });

    // pendingApprovalsFutureProvider is autoDispose: container.read(...future) alone doesn't keep
    // it alive for the duration of the async gap, so it can get disposed mid-flight. An explicit
    // listener holds it open until this scope's teardown.
    final sub = container.listen(pendingApprovalsFutureProvider, (_, __) {});
    addTearDown(sub.close);
    final items = await container.read(pendingApprovalsFutureProvider.future);

    expect(items, hasLength(1));
    expect(items.single.type, 'Job Requisition');
    expect(items.single.title, 'Site Engineer');
  });

  test('ignores a leave request belonging to a different manager', () async {
    await firestore.tenantCollection(_tenantId, 'leave_requests').add({
      'siteId': _tenantId,
      'managerId': 'someone-else',
      'status': 'Pending',
      'employeeName': 'Bob',
      'leaveType': 'Sick',
      'reason': 'Flu',
      'startDate': DateTime(2026, 3, 1),
    });

    // pendingApprovalsFutureProvider is autoDispose: container.read(...future) alone doesn't keep
    // it alive for the duration of the async gap, so it can get disposed mid-flight. An explicit
    // listener holds it open until this scope's teardown.
    final sub = container.listen(pendingApprovalsFutureProvider, (_, __) {});
    addTearDown(sub.close);
    final items = await container.read(pendingApprovalsFutureProvider.future);

    expect(items, isEmpty);
  });
}
