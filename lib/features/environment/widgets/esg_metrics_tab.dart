import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class EsgMetricsTab extends ConsumerStatefulWidget {
  const EsgMetricsTab({super.key});

  @override
  ConsumerState<EsgMetricsTab> createState() => _EsgMetricsTabState();
}

class _EsgMetricsTabState extends ConsumerState<EsgMetricsTab> {
  bool _isSubmitting = false;

  // ESG metric form
  String _esgCategory = 'Scope 1';
  String _esgUnit = 'tCO2e';
  final String _esgPeriod = '2026';
  final _esgValueCtrl = TextEditingController();

  @override
  void dispose() {
    _esgValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitMetric() async {
    if (_esgValueCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Value is required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'esg_metrics',
            data: {
              'category': _esgCategory,
              'value': double.tryParse(_esgValueCtrl.text) ?? 0,
              'unit': _esgUnit,
              'period': _esgPeriod,
              'authorId': p.uid,
              'siteId': p.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'ESG metric added successfully');
        setState(() {
          _esgValueCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildResourceForm() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _esgCategory,
                decoration: const InputDecoration(labelText: 'ESG Category'),
                items:
                    [
                          'Scope 1',
                          'Scope 2',
                          'Scope 3',
                          'Water',
                          'Waste',
                          'Diversity',
                          'Training',
                          'Ethics',
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => setLocalState(() => _esgCategory = v!),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _esgValueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Metric Value *',
                      ),
                    ),
                  ),
                  GSpacing.hMd,
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: _esgUnit,
                      onChanged: (v) => _esgUnit = v,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              GSpacing.vLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitMetric,
                  child: Text(
                    _isSubmitting ? 'Adding Metric...' : 'Add Metric',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESG Performance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.icon(
                onPressed:
                    () => UIUtils.showSideSheet(
                      context: context,
                      title: 'Resource Usage',
                      builder: (ctx) => _buildResourceForm(),
                    ),
                icon: const Icon(Icons.eco_outlined, size: 18),
                label: const Text('Add Metric'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : fs
                        .tenantCollection(
                          ref.watch(currentTenantIdProvider) ?? "",
                          'esg_metrics',
                        )
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No ESG metrics recorded'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _MetricListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MetricListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MetricListItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GStatusTag(label: data['category'] ?? 'ESG', color: XMTheme.primary),
          GSpacing.hLg,
          Text(
            '${data['value']} ${data['unit']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          Text(
            data['period'] ?? '2026',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
