import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

// Placeholder models or direct Firestore data
class SafetyIncident {
  final String id;
  final String title;
  final String status;
  final DateTime date;

  SafetyIncident({required this.id, required this.title, required this.status, required this.date});

  factory SafetyIncident.fromFirestore(Map<String, dynamic> data, String id) {
    return SafetyIncident(
      id: id,
      title: data['title'] ?? 'Unknown Incident',
      status: data['status'] ?? 'Open',
      date: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}

class WorkPermit {
  final String id;
  final String type;
  final String status;

  WorkPermit({required this.id, required this.type, required this.status});

  factory WorkPermit.fromFirestore(Map<String, dynamic> data, String id) {
    return WorkPermit(
      id: id,
      type: data['type'] ?? 'General',
      status: data['status'] ?? 'Draft',
    );
  }
}

final propertyIncidentsProvider = StreamProvider.family<List<SafetyIncident>, String>((ref, propertyId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('incidents')
      .where('propertyId', isEqualTo: propertyId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => SafetyIncident.fromFirestore(doc.data(), doc.id)).toList());
});

final propertyPermitsProvider = StreamProvider.family<List<WorkPermit>, String>((ref, propertyId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('permits')
      .where('propertyId', isEqualTo: propertyId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => WorkPermit.fromFirestore(doc.data(), doc.id)).toList());
});
