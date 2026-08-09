import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../models/safety_file_models.dart';

final contractorReviewServiceProvider = Provider<ContractorReviewService>((ref) {
  return ContractorReviewService(
    ref.watch(firestoreServiceProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Service layer for contractor document review + finding status updates
/// (`DocumentReviewDialog`, `SafetyFileSubmissionView`). Both writes previously went straight to
/// Firestore (`db.tenantCollection(...).update()/.add()`), bypassing FirestoreService entirely —
/// mirroring the same gap PropertyService/EnvironmentService fixed in this module. Dates are
/// written as ISO 8601 strings rather than `FieldValue.serverTimestamp()`/`arrayUnion()`: writes
/// queued via FirestoreService are JSON-encoded into the offline sync queue (see
/// OfflineSyncService.queueOperation), and Firestore's FieldValue sentinels aren't
/// JSON-serializable — the same reason EnvironmentService/ComplianceService use
/// `DateTime.now().toIso8601String()` instead. `statusHistory` is appended client-side (the caller
/// already has the current list from the live stream, so no extra read is needed to preserve
/// arrayUnion's append semantics).
class ContractorReviewService {
  final FirestoreService _firestoreService;
  final String _tenantId;

  ContractorReviewService(this._firestoreService, this._tenantId);

  /// Updates a contractor document's review status/feedback, and — when feedback is given — files
  /// a new Finding for it.
  Future<void> submitDocumentReview({
    required ContractorDocument document,
    required String status,
    required String feedback,
    required FindingStatus findingStatus,
    required String reviewerUid,
    required String reviewerName,
  }) async {
    await _firestoreService.updateDocument(
      tenantId: _tenantId,
      collection: 'contractor_documents',
      documentId: document.id,
      data: {'status': status, 'feedback': feedback},
    );

    if (feedback.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'findings',
      data: {
        'submissionId': document.submissionId,
        'documentId': document.id,
        // requirementId intentionally omitted: no requirement-reference field
        // exists anywhere on ContractorDocument/SafetyFileSubmission to source
        // it from — flagged as an Open Question per F-222 in FIX_LIST.md
        // rather than inventing a value. Defaults to 0 via Finding.fromFirestore.
        'siteId': _tenantId,
        'status': findingStatus.name,
        'type': FindingType.observation.name,
        'description': feedback,
        'contractorAction': '',
        'reportedBy': reviewerName,
        'reviewerUid': reviewerUid,
        'reviewerName': reviewerName,
        'createdAt': now,
        'modifiedBy': reviewerUid,
        'modifiedAt': now,
        'statusHistory': [
          {
            'status': findingStatus.name,
            'timestamp': now,
            'comment': 'Initial review finding',
            'userId': reviewerUid,
          },
        ],
      },
    );
  }

  /// Appends a status-history entry and updates a Finding's status.
  Future<void> updateFindingStatus({
    required Finding finding,
    required FindingStatus newStatus,
    required String comment,
    required String userId,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _firestoreService.updateDocument(
      tenantId: _tenantId,
      collection: 'findings',
      documentId: finding.findingId,
      data: {
        'status': newStatus.name,
        'modifiedBy': userId,
        'modifiedAt': now,
        'statusHistory': [
          ...finding.statusHistory,
          {
            'status': newStatus.name,
            'timestamp': now,
            'comment': comment,
            'userId': userId,
          },
        ],
      },
    );
  }
}
