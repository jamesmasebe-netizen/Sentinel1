import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../models/hr_models.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

final leaveRequestsProvider = StreamProvider.autoDispose<List<LeaveRequest>>((
  ref,
) {
  final siteId = ref.watch(currentTenantIdProvider);
  if (siteId == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .tenantCollection(
        ref.watch(currentTenantIdProvider) ?? "",
        'leave_requests',
      )
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => LeaveRequest.fromFirestore(d)).toList(),
      );
});

final payrollLedgerProvider = StreamProvider.autoDispose<List<PayrollLedger>>((
  ref,
) {
  final siteId = ref.watch(currentTenantIdProvider);
  if (siteId == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .tenantCollection(
        ref.watch(currentTenantIdProvider) ?? "",
        'payroll_ledgers',
      )
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => PayrollLedger.fromFirestore(d)).toList(),
      );
});

final jobRequisitionsProvider =
    StreamProvider.autoDispose<List<JobRequisition>>((ref) {
      final siteId = ref.watch(currentTenantIdProvider);
      if (siteId == null) return Stream.value([]);

      return ref
          .watch(firestoreProvider)
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'job_requisitions',
          )
          .where('siteId', isEqualTo: siteId)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) => JobRequisition.fromFirestore(d)).toList(),
          );
    });

final candidatesProvider = StreamProvider.autoDispose.family<
  List<Candidate>,
  String
>((ref, requisitionId) {
  if (requisitionId.isEmpty) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'candidates')
      .where('requisitionId', isEqualTo: requisitionId)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Candidate.fromFirestore(d)).toList());
});

final performanceReviewsProvider =
    StreamProvider.autoDispose<List<PerformanceReview>>((ref) {
      final siteId = ref.watch(currentTenantIdProvider);
      if (siteId == null) return Stream.value([]);

      return ref
          .watch(firestoreProvider)
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'performance_reviews',
          )
          .where('siteId', isEqualTo: siteId)
          .snapshots()
          .map(
            (snap) =>
                snap.docs
                    .map((d) => PerformanceReview.fromFirestore(d))
                    .toList(),
          );
    });

final ohsAppointmentsProvider =
    StreamProvider.autoDispose<List<OHSAppointment>>((ref) {
      final siteId = ref.watch(currentTenantIdProvider);
      if (siteId == null) return Stream.value([]);

      return ref
          .watch(firestoreProvider)
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'ohs_appointments',
          )
          .where('siteId', isEqualTo: siteId)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) => OHSAppointment.fromFirestore(d)).toList(),
          );
    });
