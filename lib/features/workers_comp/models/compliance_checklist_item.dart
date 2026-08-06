/// A single item in the tenant's COIDA compliance checklist.
///
/// Seeded at fixed document ids (`item_0`..`item_9`) by
/// `WorkersCompService.seedComplianceChecklist`, matching `ComplianceTab`'s previous inline
/// `_seedDefaults` batch write exactly (same field shape, same fixed-id scheme so re-seeding
/// is idempotent).
class ComplianceChecklistItem {
  final String id;
  final String label;
  final bool done;
  final int order;

  ComplianceChecklistItem({
    required this.id,
    required this.label,
    this.done = false,
    required this.order,
  });

  factory ComplianceChecklistItem.fromFirestore(Map<String, dynamic> json, String id) {
    return ComplianceChecklistItem(
      id: id,
      label: json['label']?.toString() ?? '',
      done: json['done'] == true,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'done': done,
      'order': order,
    };
  }
}
