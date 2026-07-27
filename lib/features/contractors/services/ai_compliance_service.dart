import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/compliance_prescreen_models.dart';

final aiComplianceServiceProvider = Provider<AiComplianceService>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider) ?? '';
  return AiComplianceService(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
    tenantId,
  );
});

final compliancePreScreenProvider = StreamProvider.family<CompliancePreScreenResult?, String>((ref, String documentId) {
  final service = ref.watch(aiComplianceServiceProvider);
  return service.streamPreScreenResult(documentId);
});

class AiComplianceService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final String _tenantId;

  AiComplianceService(this._firestore, this._functions, this._tenantId);

  Future<void> triggerPreScreen(String documentId, String documentUrl) async {
    if (_tenantId.isEmpty) return;
    
    try {
      final callable = _functions.httpsCallable('preScreenComplianceDocument');
      await callable.call({
        'documentId': documentId,
        'documentUrl': documentUrl,
        'tenantId': _tenantId,
      });
    } catch (e, stackTrace) {
      debugPrint('AI Pre-Screen failed for document $documentId: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<CompliancePreScreenResult?> streamPreScreenResult(String documentId) {
    if (_tenantId.isEmpty) return Stream.value(null);

    return _firestore
        .tenantCollection(_tenantId, 'compliance_prescreens')
        .where('documentId', isEqualTo: documentId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CompliancePreScreenResult.fromFirestore(snapshot.docs.first);
    });
  }
}
