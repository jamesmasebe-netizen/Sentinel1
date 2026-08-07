// Tests for notificationsStreamProvider (lib/features/notifications/providers/notifications_provider.dart).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/models/user_profile.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import 'package:sentinel1/features/notifications/providers/notifications_provider.dart';

void main() {
  const tenantId = 'tenant-notif-1';
  const uid = 'user-1';
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      currentTenantIdProvider.overrideWithValue(tenantId),
      userProfileProvider.overrideWith((ref) => Stream.value(const UserProfile(
            uid: uid,
            email: 'user@test.com',
            displayName: 'Test User',
          ))),
    ]);
    addTearDown(container.dispose);
  });

  test('returns only notifications addressed to the signed-in user, newest first', () async {
    // Pre-warm userProfileProvider (also a StreamProvider) so notificationsStreamProvider's
    // ref.watch(userProfileProvider).valueOrNull sees an already-delivered value on its first
    // build, rather than racing it — same fix as safety_service_test.dart established earlier
    // this session. Without this, .future binds to the provider's first (pre-profile) build,
    // which returns Stream.empty() and never emits, hanging the test forever.
    await container.read(userProfileProvider.future);

    final col = firestore.tenantCollection(tenantId, 'notifications');
    await col.add({
      'title': 'Older',
      'body': 'b',
      'recipientUid': uid,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    });
    await col.add({
      'title': 'Newer',
      'body': 'b',
      'recipientUid': uid,
      'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
    });
    await col.add({
      'title': 'Someone else\'s',
      'body': 'b',
      'recipientUid': 'other-user',
      'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
    });

    final result = await container.read(notificationsStreamProvider.future);

    expect(result, hasLength(2));
    expect(result.first.title, 'Newer');
    expect(result.last.title, 'Older');
  });

  test('never emits (Stream.empty()) when there is no signed-in profile', () async {
    final noProfileContainer = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      currentTenantIdProvider.overrideWithValue(tenantId),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
    ]);
    addTearDown(noProfileContainer.dispose);

    // Pre-warm the dependency first (see the note in the test above), then confirm
    // notificationsStreamProvider is still AsyncLoading shortly after — Stream.empty() never
    // emits a value, error, or done event, so it can never resolve to AsyncData/AsyncError.
    await noProfileContainer.read(userProfileProvider.future);
    final sub = noProfileContainer.listen(notificationsStreamProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(sub.read().hasValue, isFalse);
    expect(sub.read().hasError, isFalse);
  });
}
