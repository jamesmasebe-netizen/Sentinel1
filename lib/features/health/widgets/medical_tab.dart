import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'medical_form.dart';
import 'medical_list_item.dart';
import 'oh_stat_chip.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class MedicalsTab extends ConsumerStatefulWidget {
  const MedicalsTab({super.key});

  @override
  ConsumerState<MedicalsTab> createState() => _MedicalsTabState();
}

class _MedicalsTabState extends ConsumerState<MedicalsTab> {


  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const OHStatChip(label: 'Fit', count: '85%', color: XMTheme.success),
                      GSpacing.hMd,
                      const OHStatChip(label: 'Restricted', count: '12%', color: XMTheme.warning),
                      GSpacing.hMd,
                      const OHStatChip(label: 'Unfit', count: '3%', color: XMTheme.error),
                    ],
                  ),
                ),
              ),
              GSpacing.hMd,
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New Medical Record',
                  builder: (ctx) => const MedicalForm(),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Record'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'medical_records')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_heart_outlined, size: 48, color: Theme.of(context).disabledColor),
                      GSpacing.vMd,
                      Text('No medical records found', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return MedicalListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


