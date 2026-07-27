import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'drill_form_card.dart';
import 'drill_list_item.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class EmergencyDrillsTab extends ConsumerStatefulWidget {
  const EmergencyDrillsTab({super.key});

  @override
  ConsumerState<EmergencyDrillsTab> createState() => _EmergencyDrillsTabState();
}

class _EmergencyDrillsTabState extends ConsumerState<EmergencyDrillsTab> {
  bool _showDrillForm = false;

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Recent Drills',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    () => setState(() => _showDrillForm = !_showDrillForm),
                icon: Icon(_showDrillForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showDrillForm ? 'Cancel' : 'Log Drill'),
              ),
            ],
          ),
        ),
        if (_showDrillForm)
          DrillFormCard(onCancel: () => setState(() => _showDrillForm = false)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : fs
                        .tenantCollection(
                          ref.watch(currentTenantIdProvider) ?? "",
                          'emergency_drills',
                        )
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      GSpacing.vLg,
                      Text(
                        'No drills logged',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return DrillListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
