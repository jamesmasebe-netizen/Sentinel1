import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../models/crm_models.dart';

final crmServiceProvider = Provider<CrmService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final tenantId = ref.watch(currentTenantIdProvider);
  return CrmService(firestoreService, tenantId);
});

final dealsStreamProvider = StreamProvider<List<Deal>>((ref) {
  final crmService = ref.watch(crmServiceProvider);
  return crmService.streamDeals();
});

class CrmService {
  final FirestoreService _firestoreService;
  final String? _tenantId;
  static const String _collection = 'crm_deals';

  CrmService(this._firestoreService, this._tenantId);

  Stream<List<Deal>> streamDeals() {
    if (_tenantId == null) {
      return Stream.value([]);
    }

    return _firestoreService.streamCollection<Deal>(
      collection: _collection,
      tenantId: _tenantId,
      fromFirestore: (doc) => Deal.fromFirestore(doc),
      orderByField: 'createdAt',
      descending: true,
    );
  }

  Future<void> createDeal(Deal deal) async {
    if (_tenantId == null) return;

    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: _collection,
      data: deal.toMap(),
    );
  }

  Future<void> updateDeal(Deal deal) async {
    if (_tenantId == null) return;

    await _firestoreService.updateDocument(
      tenantId: _tenantId,
      collection: _collection,
      documentId: deal.id,
      data: deal.toMap(),
    );
  }

  Future<void> deleteDeal(String dealId) async {
    if (_tenantId == null) return;

    await _firestoreService.deleteDocument(
      tenantId: _tenantId,
      collection: _collection,
      documentId: dealId,
    );
  }
}
