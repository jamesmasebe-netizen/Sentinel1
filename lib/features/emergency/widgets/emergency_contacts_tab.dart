import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../services/emergency_service.dart';
import 'emergency_contact_form_card.dart';
import 'property_filter_dropdown.dart';

// Display-only metadata (icon/color) for the well-known default contacts, matched back to
// EmergencyService.defaultContacts by name — the (name, number) pairs actually written live on
// the service, this list is UI-only.
const _defaultContactDisplay = [
  {'name': 'Fire Department', 'icon': Icons.local_fire_department, 'color': XMTheme.error},
  {'name': 'Ambulance / EMS', 'icon': Icons.local_hospital, 'color': XMTheme.info},
  {'name': 'Police / SAPS', 'icon': Icons.local_police, 'color': XMTheme.primary},
  {'name': 'Poison Information', 'icon': Icons.warning, 'color': XMTheme.warning},
];

class EmergencyContactsTab extends ConsumerStatefulWidget {
  const EmergencyContactsTab({super.key});

  @override
  ConsumerState<EmergencyContactsTab> createState() => _EmergencyContactsTabState();
}

class _EmergencyContactsTabState extends ConsumerState<EmergencyContactsTab> {
  bool _showForm = false;
  bool _isSeeding = false;
  String? _propertyFilter;

  Future<void> _seedDefaults() async {
    setState(() => _isSeeding = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(emergencyServiceProvider).seedDefaultContacts(authorId: p.uid);
      if (mounted) UIUtils.showToast(context, 'Default contacts added', type: ToastType.success);
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(emergencyContactsProvider);

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
              PropertyFilterDropdown(
                value: _propertyFilter,
                onChanged: (val) => setState(() => _propertyFilter = val),
              ),
              const SizedBox(width: 8),
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
          child: contactsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (allContacts) {
              final contacts = _propertyFilter == null
                  ? allContacts
                  : allContacts.where((c) => c.propertyId == _propertyFilter).toList();
              if (contacts.isEmpty) {
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
                itemCount: contacts.length,
                itemBuilder: (context, i) {
                  return _ContactCard(
                    name: contacts[i].name,
                    number: contacts[i].number,
                    propertyName: contacts[i].propertyName,
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
  final String? propertyName;

  const _ContactCard({required this.name, required this.number, this.propertyName});

  IconData get _icon {
    final match = _defaultContactDisplay.firstWhere(
      (c) => c['name'] == name,
      orElse: () => const {'icon': Icons.person},
    );
    return match['icon'] as IconData;
  }

  Color get _color {
    final match = _defaultContactDisplay.firstWhere(
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
        subtitle: Text(
          propertyName == null ? number : '$number · $propertyName',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton.filledTonal(
          onPressed: () => _call(context),
          icon: const Icon(Icons.phone),
          color: _color,
        ),
      ),
    );
  }
}
