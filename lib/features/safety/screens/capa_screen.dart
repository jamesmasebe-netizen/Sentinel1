// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/capa_form.dart';
import '../widgets/capa_card.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// CAPA Management Screen — Create, track, and update corrective/preventive actions.
/// Mirrors React CAPA tab: linked incidents, RCA, assignment, due dates, status workflow.
class CAPAScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const CAPAScreen({super.key, this.initialSearch, this.highlightId});

  @override
  ConsumerState<CAPAScreen> createState() => _CAPAScreenState();
}

class _CAPAScreenState extends ConsumerState<CAPAScreen> {
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

  void _showCAPAForm(BuildContext context, String siteId) {
    UIUtils.showSideSheet(
      context: context,
      title: 'New Corrective Action',
      builder: (ctx) => CAPAForm(onCancel: () => Navigator.pop(ctx)),
    );
  }

  bool _isUpdatingStatus = false;

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(
      children: [
        // ─── Header ───
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CAPA Register',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                onPressed: () => _showCAPAForm(context, siteId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New CAPA'),
              ),
            ],
          ),
        ),

        // ─── CAPA List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                firestore
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'capas',
                    )
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final capas = snapshot.data?.docs;
              if (capas == null || capas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fact_check_rounded,
                        size: 48,
                        color: XMTheme.success.withValues(alpha: 0.3),
                      ),
                      GSpacing.vMd,
                      const Text('No CAPAs found'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: capas.length,
                itemBuilder: (context, index) {
                  final doc = capas[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return CAPACard(
                    docId: doc.id,
                    data: data,
                    onStatusUpdate:
                        _isUpdatingStatus
                            ? (_) async {}
                            : (newStatus) async {
                              setState(() => _isUpdatingStatus = true);
                              try {
                                await firestore
                                    .tenantCollection(
                                      ref.watch(currentTenantIdProvider) ?? "",
                                      'capas',
                                    )
                                    .doc(doc.id)
                                    .update({
                                      'status': newStatus,
                                      'updatedAt':
                                          DateTime.now().toIso8601String(),
                                    });
                                if (mounted) {
                                  UIUtils.showToast(
                                    context,
                                    'CAPA status updated to $newStatus',
                                    type: ToastType.success,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  UIUtils.showToast(
                                    context,
                                    'Failed to update CAPA status: $e',
                                    type: ToastType.error,
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isUpdatingStatus = false);
                                }
                              }
                            },
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
