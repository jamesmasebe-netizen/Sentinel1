import 'package:cloud_firestore/cloud_firestore.dart';

/// Fields genuinely shared by every incident-shaped record in the app
/// (Safety `Incident` today; `environment`'s spill records are the next
/// evaluated candidate — see F-019 in docs/fixes/FIX_LIST.md). Deliberately
/// minimal: only what every candidate actually has in common, per
/// .agents/AGENTS.md §5's "Polymorphism for Shared Concepts" mandate.
abstract class BaseIncident {
  final String? id;
  final String tenantId;
  final String description;
  final String severity;
  final String status;
  final String? location;
  final DateTime? dateOfIncident;
  final String? reporterId;
  final String? reporterName;

  const BaseIncident({
    this.id,
    required this.tenantId,
    required this.description,
    required this.severity,
    required this.status,
    this.location,
    this.dateOfIncident,
    this.reporterId,
    this.reporterName,
  });

  /// Parses a Firestore Timestamp or the ISO-8601 date strings this
  /// codebase's forms commonly write instead — both are live in production
  /// data, so a strict `as Timestamp?` cast is not safe here.
  static DateTime? parseFlexibleDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
