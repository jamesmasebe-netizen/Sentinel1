import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'hub_cards.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';
import 'package:xm_system/core/providers/app_providers.dart';

class OperationsHubMetrics extends ConsumerWidget {
  final String? siteId;
  final FirebaseFirestore fs;

  const OperationsHubMetrics({super.key, required this.siteId, required this.fs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LiveMetricCard(
                  title: 'Open Actions',
                  countStream: siteId == null ? const Stream.empty() : fs
                      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'actionItems')
                      .where('siteId', isEqualTo: siteId)
                      .where('status', isNotEqualTo: 'closed')
                      .snapshots()
                      .map((s) => s.docs.length),
                  icon: Icons.pending_actions_rounded,
                  color: XMTheme.warning,
                  isWide: isWide,
                ),
                if (isWide) GSpacing.hMd else GSpacing.vMd,
                LiveMetricCard(
                  title: 'Properties',
                  countStream: siteId == null ? const Stream.empty() : fs
                      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'properties')
                      .where('siteId', isEqualTo: siteId)
                      .snapshots()
                      .map((s) => s.docs.length),
                  icon: Icons.domain_rounded,
                  color: XMTheme.primary,
                  isWide: isWide,
                ),
                if (isWide) GSpacing.hMd else GSpacing.vMd,
                LiveMetricCard(
                  title: 'Active Contractors',
                  countStream: siteId == null ? const Stream.empty() : fs
                      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'contractors')
                      .where('siteId', isEqualTo: siteId)
                      .where('status', isEqualTo: 'Active')
                      .snapshots()
                      .map((s) => s.docs.length),
                  icon: Icons.engineering_rounded,
                  color: XMTheme.success,
                  isWide: isWide,
                ),
                if (isWide) GSpacing.hMd else GSpacing.vMd,
                LiveMetricCard(
                  title: 'Env Alerts',
                  countStream: siteId == null ? const Stream.empty() : fs
                      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'incidents')
                      .where('siteId', isEqualTo: siteId)
                      .where('resolved', isEqualTo: false)
                      .snapshots()
                      .map((s) => s.docs.length),
                  icon: Icons.eco_rounded,
                  color: XMTheme.error,
                  isWide: isWide,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
