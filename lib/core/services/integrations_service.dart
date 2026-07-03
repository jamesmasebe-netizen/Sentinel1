import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../providers/app_providers.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class IntegrationConfig {
  final String id;
  final String name;
  final String type; // e.g., 'payroll', 'recruitment', 'equipment'
  final bool isEnabled;
  final String webhookUrl;
  final String apiKey;
  final String tenantId;

  IntegrationConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.isEnabled,
    required this.webhookUrl,
    required this.apiKey,
    required this.tenantId,
  });

  factory IntegrationConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IntegrationConfig(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      isEnabled: data['isEnabled'] ?? false,
      webhookUrl: data['webhookUrl'] ?? '',
      apiKey: data['apiKey'] ?? '',
      tenantId: data['tenantId'] ?? data['siteId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'isEnabled': isEnabled,
      'webhookUrl': webhookUrl,
      'apiKey': apiKey,
      'tenantId': tenantId,
    };
  }
}

class IntegrationsService {
  final FirebaseFirestore _firestore;

  IntegrationsService(this._firestore);

  Stream<List<IntegrationConfig>> watchIntegrations(String tenantId) {
    return _firestore
        .tenantCollection(tenantId, 'integrations')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => IntegrationConfig.fromFirestore(d)).toList(),
        );
  }

  Future<void> saveIntegration(IntegrationConfig config) async {
    final docRef = _firestore
        .tenantCollection(config.tenantId, 'integrations')
        .doc(config.id.isEmpty ? null : config.id);
    await docRef.set(config.toFirestore());
  }

  Future<void> deleteIntegration(String tenantId, String id) async {
    await _firestore
        .tenantCollection(tenantId, 'integrations')
        .doc(id)
        .delete();
  }

  /// Low-cost Gateway Push strategy: Send JSON data to a webhook endpoint
  Future<bool> syncDataToGateway(
    String tenantId,
    String integrationType,
    Map<String, dynamic> payload,
  ) async {
    try {
      final snap =
          await _firestore
              .tenantCollection(tenantId, 'integrations')
              .where('type', isEqualTo: integrationType)
              .where('isEnabled', isEqualTo: true)
              .limit(1)
              .get();

      if (snap.docs.isEmpty) {
        // App acts independently if no gateway is configured or enabled.
        return true;
      }

      final config = IntegrationConfig.fromFirestore(snap.docs.first);

      if (config.webhookUrl.isEmpty) return true;

      final response = await http.post(
        Uri.parse(config.webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          if (config.apiKey.isNotEmpty)
            'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode(payload),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Gateway Sync Error: $e');
      return false;
    }
  }
}

final integrationsServiceProvider = Provider<IntegrationsService>((ref) {
  final fs = ref.watch(firestoreProvider);
  return IntegrationsService(fs);
});

final integrationsProvider = StreamProvider<List<IntegrationConfig>>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) return const Stream.empty();
  return ref.watch(integrationsServiceProvider).watchIntegrations(tenantId);
});
