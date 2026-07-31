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
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class MedicalsTab extends ConsumerStatefulWidget {
  const MedicalsTab({super.key});

  @override
  ConsumerState<MedicalsTab> createState() => _MedicalsTabState();
}

class _MedicalsTabState extends ConsumerState<MedicalsTab> {
  String _pct(int count, int total) =>
      total == 0 ? '0%' : '${(count / total * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot>(
      stream:
          siteId == null
              ? null
              : fs
                  .tenantCollection(siteId, 'medical_records')
                  .where('siteId', isEqualTo: siteId)
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        var fit = 0, restricted = 0, unfit = 0;
        for (final doc in docs) {
          final status = (doc.data() as Map<String, dynamic>)['status'] as String? ?? 'Fit';
          if (status == 'Unfit') {
            unfit++;
          } else if (status.contains('Restriction')) {
            restricted++;
          } else {
            fit++;
          }
        }
        final total = docs.length;

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
                          OHStatChip(
                            label: 'Fit',
                            count: _pct(fit, total),
                            color: XMTheme.success,
                          ),
                          GSpacing.hMd,
                          OHStatChip(
                            label: 'Restricted',
                            count: _pct(restricted, total),
                            color: XMTheme.warning,
                          ),
                          GSpacing.hMd,
                          OHStatChip(
                            label: 'Unfit',
                            count: _pct(unfit, total),
                            color: XMTheme.error,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GSpacing.hMd,
                  FilledButton.icon(
                    onPressed:
                        () => UIUtils.showSideSheet(
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
              child:
                  docs.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monitor_heart_outlined,
                              size: 48,
                              color: Theme.of(context).disabledColor,
                            ),
                            GSpacing.vMd,
                            Text(
                              'No medical records found',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          return MedicalListItem(data: d);
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}
