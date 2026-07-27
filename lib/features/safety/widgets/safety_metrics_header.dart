import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'stream_metric_card.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class SafetyMetricsHeader extends ConsumerWidget {
  const SafetyMetricsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    final openIncidentsStream =
        siteId == null
            ? Stream.value('0')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'incidents',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map(
                  (s) =>
                      s.docs
                          .where((d) => d.data()['status'] != 'Closed')
                          .length
                          .toString(),
                );

    final activePermitsStream =
        siteId == null
            ? Stream.value('0')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'permits',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map(
                  (s) =>
                      s.docs
                          .where((d) => d.data()['status'] == 'Active')
                          .length
                          .toString(),
                );

    final hazardsStream =
        siteId == null
            ? Stream.value('0')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'hazards',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map((s) => s.docs.length.toString());

    final capaCompletionStream =
        siteId == null
            ? Stream.value('100%')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'capas',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map((s) {
                  if (s.docs.isEmpty) return '100%';
                  final closed =
                      s.docs.where((d) {
                        final status = d.data()['status'] ?? '';
                        return status == 'Closed' || status == 'Completed';
                      }).length;
                  return '${((closed / s.docs.length) * 100).toStringAsFixed(0)}%';
                });

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      sliver: SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamMetricCard(
                  title: 'Open Incidents',
                  valueStream: openIncidentsStream,
                  icon: Icons.report_problem,
                  color: XMTheme.error,
                  isWide: isWide,
                  initialValue: '0',
                ),
                if (isWide) GSpacing.hMd else GSpacing.vMd,
                StreamMetricCard(
                  title: 'Active Permits',
                  valueStream: activePermitsStream,
                  icon: Icons.assignment,
                  color: XMTheme.primary,
                  isWide: isWide,
                  initialValue: '0',
                ),
                if (isWide) GSpacing.hMd else GSpacing.vMd,
                StreamMetricCard(
                  title: 'Hazards Reported',
                  valueStream: hazardsStream,
                  icon: Icons.warning_rounded,
                  color: XMTheme.warning,
                  isWide: isWide,
                  initialValue: '0',
                ),
                if (isWide) GSpacing.hMd else GSpacing.vMd,
                StreamMetricCard(
                  title: 'CAPA Completion',
                  valueStream: capaCompletionStream,
                  icon: Icons.check_circle_rounded,
                  color: XMTheme.success,
                  isWide: isWide,
                  initialValue: '100%',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
