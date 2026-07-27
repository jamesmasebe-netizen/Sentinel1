import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/hira_card.dart';
import '../widgets/hira_form.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// Baseline HIRA (Hazard Identification & Risk Assessment) — full CRUD register.
class HiraScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const HiraScreen({super.key, this.initialSearch, this.highlightId});

  @override
  ConsumerState<HiraScreen> createState() => _HiraScreenState();
}

class _HiraScreenState extends ConsumerState<HiraScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      // _search = widget.initialSearch!;
    }
    if (widget.highlightId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UIUtils.showSideSheet(
          context: context,
          title: 'Item Details',
          builder:
              (ctx) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Viewing item: ${widget.highlightId}\n(Detail view not yet implemented)',
                ),
              ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(
      children: [
        // ─── Actions Bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Text(
                'Assessment History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    () => UIUtils.showSideSheet(
                      context: context,
                      title: 'New HIRA Assessment',
                      builder: (ctx) => const HiraForm(),
                    ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Assessment'),
              ),
            ],
          ),
        ),

        // ─── Assessment List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                firestore
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'risk_assessments',
                    )
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
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
                      Icon(
                        Icons.assessment_outlined,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      GSpacing.vMd,
                      Text(
                        'No HIRA records found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return HiraCard(d: d, onTap: () => _showDetails(context, d));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(data['title'] ?? data['task'] ?? 'Details'),
            content: Text(
              'Prepared by: ${data['preparedBy'] ?? data['assessorId'] ?? 'Unknown'}\nRisk Score: ${data['riskScore'] ?? 0}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
