import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/tenant_firestore_extension.dart';

/// Immutable model representing an audit log entry.
class AuditLogEntry {
  final String action;
  final Map<String, dynamic> metadata;
  final String tenantId;
  final DateTime timestamp;

  AuditLogEntry({
    required this.action,
    required this.metadata,
    required this.tenantId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'metadata': metadata,
      'tenantId': tenantId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      action: map['action'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      tenantId: map['tenantId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

/// Service for writing immutable audit logs to Firestore.
class AuditLogService {
  final FirebaseFirestore _firestore;

  AuditLogService(this._firestore);

  /// Logs an action to the tenant's audit_logs collection.
  Future<void> logAction(String action, Map<String, dynamic> metadata, String tenantId) async {
    if (tenantId.isEmpty) return;

    final entry = AuditLogEntry(
      action: action,
      metadata: metadata,
      tenantId: tenantId,
      timestamp: DateTime.now().toUtc(),
    );

    await _firestore
        .tenantCollection(tenantId, 'audit_logs')
        .add(entry.toMap());
  }
}
