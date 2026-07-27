import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

class RagService {
  final DocumentReference _tenantDoc;

  RagService(this._tenantDoc);

  Future<String> fetchContextForDomain(String domain) async {
    String collectionName;
    switch (domain) {
      case 'CRM':
        collectionName = 'deals';
        break;
      case 'Finance':
        collectionName = 'invoices';
        break;
      case 'HR':
        collectionName = 'employees';
        break;
      case 'SCM':
        collectionName = 'purchase_orders';
        break;
      default:
        return 'No specific context available for $domain.';
    }

    try {
      final snapshot =
          await _tenantDoc
              .collection(collectionName)
              // Defaulting to top 5 without order if createdAt is not universally guaranteed,
              // or we can use generic limit
              .limit(5)
              .get();

      if (snapshot.docs.isEmpty) {
        return 'No recent data available for $domain.';
      }

      final docs =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return 'ID: ${doc.id}, Data: $data';
          }).toList();
      return docs.join('\n');
    } catch (e) {
      return 'Error fetching context for $domain: $e';
    }
  }
}

final ragServiceProvider = Provider<RagService>((ref) {
  final tenantDoc = ref.watch(tenantDocProvider);
  return RagService(tenantDoc);
});
