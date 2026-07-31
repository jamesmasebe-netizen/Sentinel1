import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import 'emergency_contact_form_card.dart';

const _defaultContacts = [
  {'name': 'Fire Department', 'number': '10111', 'icon': Icons.local_fire_department, 'color': XMTheme.error},
  {'name': 'Ambulance / EMS', 'number': '10177', 'icon': Icons.local_hospital, 'color': XMTheme.info},
  {'name': 'Police / SAPS', 'number': '10111', 'icon': Icons.local_police, 'color': XMTheme.primary},
  {'name': 'Poison Information', 'number': '0800 111 990', 'icon': Icons.warning, 'color': XMTheme.warning},
];

class EmergencyContactsTab extends ConsumerStatefulWidget {
  const EmergencyContactsTab({super.key});

  @override
  ConsumerState<EmergencyContactsTab> createState() => _EmergencyContactsTabState();
}

class _EmergencyContactsTabState extends ConsumerState<EmergencyContactsTab> {
  bool _showForm = false;
  bool _isSeeding = false;

  Future<void> _seedDefaults() async {
    setState(() => _isSeeding = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      final tenantId = ref.read(currentTenantIdProvider) ?? '';
      final fs = ref.read(firestoreServiceProvider);
      for (final c in _defaultContacts) {
        await fs.createDocument(
          tenantId: tenantId,
          collection: 'emergency_contacts',
          data: {
            'name': c['name'],
            'number': c['number'],
            'authorId': p.uid,
            'siteId': p.tenantId,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }
      if (mounted) UIUtils.showToast(context, 'Default contacts added', type: ToastType.success);
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Text(
                'Emergency Contacts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showForm ? 'Cancel' : 'Add Contact'),
              ),
            ],
          ),
        ),
        if (_showForm) EmergencyContactFormCard(onCancel: () => setState(() => _showForm = false)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .tenantCollection(siteId, 'emergency_contacts')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contact_phone_outlined, size: 64, color: Theme.of(context).disabledColor),
                      GSpacing.vLg,
                      const Text('No emergency contacts recorded yet'),
                      GSpacing.vMd,
                      FilledButton.tonal(
                        onPressed: _isSeeding ? null : _seedDefaults,
                        child: Text(_isSeeding ? 'Adding...' : 'Add Default Emergency Numbers'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _ContactCard(
                    name: data['name'] ?? 'Unknown',
                    number: data['number'] ?? '',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name, number;

  const _ContactCard({required this.name, required this.number});

  IconData get _icon {
    final match = _defaultContacts.firstWhere(
      (c) => c['name'] == name,
      orElse: () => const {'icon': Icons.person},
    );
    return match['icon'] as IconData;
  }

  Color get _color {
    final match = _defaultContacts.firstWhere(
      (c) => c['name'] == name,
      orElse: () => const {'color': XMTheme.success},
    );
    return match['color'] as Color;
  }

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'\s+'), ''));
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          UIUtils.showToast(context, 'Unable to dial on this device', type: ToastType.error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showToast(context, 'Unable to dial: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      color: _color.withValues(alpha: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon, color: _color, size: 24),
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(number, style: Theme.of(context).textTheme.bodySmall),
        trailing: IconButton.filledTonal(
          onPressed: () => _call(context),
          icon: const Icon(Icons.phone),
          color: _color,
        ),
      ),
    );
  }
}
