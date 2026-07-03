import 'package:cloud_firestore/cloud_firestore.dart';

extension TenantFirestore on FirebaseFirestore {
  CollectionReference<Map<String, dynamic>> tenantCollection(
    String tenantId,
    String collectionPath,
  ) {
    return collection('tenants').doc(tenantId).collection(collectionPath);
  }
}
