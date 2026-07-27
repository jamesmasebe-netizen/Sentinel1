import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../models/equipment_models.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// Streams all equipment from the tenant's 'equipment' collection.
final equipmentListProvider = StreamProvider<List<EquipmentModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final tenantId = ref.watch(currentTenantIdProvider) ?? '';
  if (tenantId.isEmpty) return Stream.value([]);

  return firestore
      .tenantCollection(tenantId, 'equipment')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => EquipmentModel.fromFirestore(doc)).toList());
});
