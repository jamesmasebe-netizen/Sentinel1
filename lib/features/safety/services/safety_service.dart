import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/providers/app_providers.dart';

final safetyServiceProvider = Provider<SafetyService>((ref) {
  return SafetyService(
    ref.read(firestoreServiceProvider),
    ref.read(currentTenantIdProvider) ?? '',
    ref.read(userProfileProvider).valueOrNull?.uid ?? '',
  );
});

class SafetyService {
  final FirestoreService _firestore;
  final String _tenantId;
  final String _userId;

  SafetyService(this._firestore, this._tenantId, this._userId);

  /// Creates a new CAPA document in Firestore.
  Future<String> createCapa(Map<String, dynamic> data) async {
    final capaData = {
      ...data,
      'status': data['status'] ?? 'Open',
      'createdBy': data['createdBy'] ?? _userId,
      'createdById': data['createdById'] ?? _userId,
      'siteId': data['siteId'] ?? _tenantId,
      'tenantId': data['tenantId'] ?? _tenantId,
      'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
    };

    final docRef = await _firestore.createDocument(
      tenantId: _tenantId,
      collection: 'capas',
      data: capaData,
    );
    
    return docRef;
  }
}
