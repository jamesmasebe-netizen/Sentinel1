import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/medical_record.dart';
import '../services/health_service.dart';
import 'medical_form.dart';
import 'medical_list_item.dart';
import 'oh_stat_chip.dart';

class MedicalsTab extends ConsumerWidget {
  const MedicalsTab({super.key});

  String _pct(int count, int total) =>
      total == 0 ? '0%' : '${(count / total * 100).round()}%';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(medicalRecordsProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (records) {
        var fit = 0, restricted = 0, unfit = 0;
        for (final MedicalRecord record in records) {
          if (record.status == 'Unfit') {
            unfit++;
          } else if (record.status.contains('Restriction')) {
            restricted++;
          } else {
            fit++;
          }
        }
        final total = records.length;

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
                  records.isEmpty
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
                        itemCount: records.length,
                        itemBuilder: (ctx, i) => MedicalListItem(record: records[i]),
                      ),
            ),
          ],
        );
      },
    );
  }
}
