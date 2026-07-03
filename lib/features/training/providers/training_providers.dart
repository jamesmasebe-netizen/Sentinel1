import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

final coursesProvider = StreamProvider<List<Course>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.tenantCollection("", 'courses').snapshots().map((snap) {
    if (snap.docs.isEmpty) {
      _seedDummyCourses(firestore);
      return [];
    }
    return snap.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
  });
});

final enrollmentsProvider = StreamProvider<List<Enrollment>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;

  if (profile == null) return Stream.value([]);

  return firestore
      .tenantCollection("", 'enrollments')
      .where('employeeId', isEqualTo: profile.uid)
      .snapshots()
      .map(
        (snap) =>
            snap.docs
                .map((doc) => Enrollment.fromMap(doc.data(), doc.id))
                .toList(),
      );
});

void _seedDummyCourses(FirebaseFirestore firestore) {
  final dummyCourses = [
    {
      'title': 'Safety Basics 101',
      'description': 'An introduction to workplace safety and regulations.',
      'thumbnailUrl': 'https://via.placeholder.com/300x150',
      'instructor': 'Jane Doe',
      'category': 'Safety',
      'contentUrl': 'https://example.com/video1',
      'durationMinutes': 45,
    },
    {
      'title': 'Advanced Equipment Handling',
      'description': 'Learn to handle heavy machinery safely and efficiently.',
      'thumbnailUrl': 'https://via.placeholder.com/300x150',
      'instructor': 'John Smith',
      'category': 'Equipment',
      'contentUrl': 'https://example.com/video2',
      'durationMinutes': 90,
    },
    {
      'title': 'First Aid & CPR',
      'description':
          'Emergency response and first aid procedures for the workplace.',
      'thumbnailUrl': 'https://via.placeholder.com/300x150',
      'instructor': 'Dr. Alan Grant',
      'category': 'Health',
      'contentUrl': 'https://example.com/video3',
      'durationMinutes': 120,
    },
  ];

  for (var i = 0; i < dummyCourses.length; i++) {
    firestore
        .tenantCollection("", 'courses')
        .doc('CRS-00${i + 1}')
        .set(dummyCourses[i]);
  }
}
