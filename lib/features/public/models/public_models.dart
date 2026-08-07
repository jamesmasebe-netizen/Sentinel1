import 'package:cloud_firestore/cloud_firestore.dart';

/// A published job listing shown on the unauthenticated public careers page. Field names
/// (jobTitle/department/location/employmentType/requirements/status) match what
/// public_careers_screen.dart has always read from `tenants/{tenantId}/job_requisitions` — the
/// only reachable reader of this collection anywhere in the app (see T3-PUBLIC in
/// docs/testing/TEST_BACKLOG.md for the wider finding: nothing in the app currently creates a
/// job_requisitions document with this shape, since the one internal screen that could
/// (JobRequisitionsScreen) is unreached dead code, and the JobRequisition model used elsewhere in
/// `people` uses an incompatible field set — title/department/description/status/postedDate,
/// no jobTitle/location/employmentType/requirements. Not reconciled here; this model documents
/// the shape the live public screen actually depends on).
class PublicJobPosting {
  final String id;
  final String jobTitle;
  final String department;
  final String location;
  final String employmentType;
  final String requirements;
  final String status;

  PublicJobPosting({
    required this.id,
    this.jobTitle = '',
    this.department = '',
    this.location = '',
    this.employmentType = '',
    this.requirements = '',
    this.status = '',
  });

  factory PublicJobPosting.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PublicJobPosting(
      id: doc.id,
      jobTitle: data['jobTitle'] ?? 'Unknown',
      department: data['department'] ?? '',
      location: data['location'] ?? '',
      employmentType: data['employmentType'] ?? '',
      requirements: data['requirements'] ?? 'Not specified',
      status: data['status'] ?? '',
    );
  }
}
