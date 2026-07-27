import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'equipment_form_card.dart';
import 'equipment_list_item.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class EmergencyEquipmentTab extends ConsumerStatefulWidget {
  const EmergencyEquipmentTab({super.key});

  @override
  ConsumerState<EmergencyEquipmentTab> createState() =>
      _EmergencyEquipmentTabState();
}

class _EmergencyEquipmentTabState extends ConsumerState<EmergencyEquipmentTab> {
  bool _showEquipForm = false;

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
                'Safety Equipment',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    () => setState(() => _showEquipForm = !_showEquipForm),
                icon: Icon(_showEquipForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showEquipForm ? 'Cancel' : 'Add Item'),
              ),
            ],
          ),
        ),
        if (_showEquipForm)
          EquipmentFormCard(
            onCancel: () => setState(() => _showEquipForm = false),
          ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : fs
                        .tenantCollection(
                          ref.watch(currentTenantIdProvider) ?? "",
                          'emergency_equipment',
                        )
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(100)
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
                        Icons.build_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      GSpacing.vLg,
                      Text(
                        'No equipment found',
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
                  return EquipmentListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
