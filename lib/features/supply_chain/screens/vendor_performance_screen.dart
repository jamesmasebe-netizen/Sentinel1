import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/scm_models.dart';
import '../services/scm_service.dart';
import '../providers/scm_streams_provider.dart';
import '../../crm/providers/crm_providers.dart';
import '../../crm/models/crm_models.dart';
import '../../../core/widgets/entity_selector.dart';
import '../../../core/utils/ui_utils.dart';

class VendorPerformanceScreen extends ConsumerWidget {
  const VendorPerformanceScreen({super.key});

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Poor':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(vendorPerformanceMetricsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Performance'), elevation: 0),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (metrics) {
          if (metrics.isEmpty) {
            return const Center(child: Text('No vendor performance metrics recorded'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: metrics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = metrics[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _ratingColor(m.rating).withValues(alpha: 0.1),
                    child: Icon(Icons.assessment_outlined, color: _ratingColor(m.rating)),
                  ),
                  title: Text(m.vendorName),
                  subtitle: Text(
                    '${m.period.isEmpty ? 'No period set' : m.period} · On-time ${m.onTimeDeliveryRate.toStringAsFixed(0)}% · ${m.rating}',
                  ),
                  trailing: Text(
                    'R${m.totalSpend.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => UIUtils.showSideSheet(
                    context: context,
                    title: 'Edit Vendor Metric',
                    builder: (_) => _VendorMetricForm(initial: m),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => UIUtils.showSideSheet(
          context: context,
          title: 'New Vendor Metric',
          builder: (_) => const _VendorMetricForm(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VendorMetricForm extends ConsumerStatefulWidget {
  final VendorPerformanceMetric? initial;
  const _VendorMetricForm({this.initial});

  @override
  ConsumerState<_VendorMetricForm> createState() => _VendorMetricFormState();
}

class _VendorMetricFormState extends ConsumerState<_VendorMetricForm> {
  final _formKey = GlobalKey<FormState>();
  late final _periodCtrl = TextEditingController(text: widget.initial?.period ?? '');
  late final _onTimeCtrl = TextEditingController(text: widget.initial?.onTimeDeliveryRate.toString() ?? '0');
  late final _qualityCtrl = TextEditingController(text: widget.initial?.qualityRejectionRate.toString() ?? '0');
  late final _leadTimeCtrl = TextEditingController(text: widget.initial?.avgLeadTimeDays.toString() ?? '0');
  late final _spendCtrl = TextEditingController(text: widget.initial?.totalSpend.toString() ?? '0');

  static const _ratings = ['Excellent', 'Good', 'Average', 'Poor'];
  String _rating = 'Average';
  String? _vendorId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _vendorId = widget.initial?.vendorId;
    _rating = widget.initial?.rating ?? 'Average';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _vendorId == null) {
      UIUtils.showToast(context, 'Vendor is required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(scmServiceProvider);
      final accounts = ref.read(accountsStreamProvider).valueOrNull ?? [];
      final vendorName = accounts.where((a) => a.id == _vendorId).firstOrNull?.name ?? 'Unknown Vendor';
      final metric = VendorPerformanceMetric(
        id: widget.initial?.id ?? const Uuid().v4(),
        vendorId: _vendorId!,
        vendorName: vendorName,
        period: _periodCtrl.text.trim(),
        onTimeDeliveryRate: double.tryParse(_onTimeCtrl.text) ?? 0,
        qualityRejectionRate: double.tryParse(_qualityCtrl.text) ?? 0,
        avgLeadTimeDays: double.tryParse(_leadTimeCtrl.text) ?? 0,
        totalSpend: double.tryParse(_spendCtrl.text) ?? 0,
        rating: _rating,
        evaluatedAt: DateTime.now(),
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      );
      if (widget.initial == null) {
        await service.createVendorPerformanceMetric(metric);
      } else {
        await service.updateVendorPerformanceMetric(metric);
      }
      if (mounted) {
        UIUtils.showToast(context, 'Vendor metric saved', type: ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EntitySelector<Account>(
            asyncEntities: ref.watch(accountsStreamProvider),
            value: _vendorId,
            onChanged: (val) => setState(() => _vendorId = val),
            label: 'Vendor *',
            idMapper: (a) => a.id,
            displayMapper: (a) => a.name,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _periodCtrl,
            decoration: const InputDecoration(labelText: 'Period', hintText: 'e.g. 2026-Q3'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _onTimeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'On-Time Delivery %'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _qualityCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quality Rejection %'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _leadTimeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Avg Lead Time (Days)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _spendCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Total Spend'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _rating,
            decoration: const InputDecoration(labelText: 'Rating'),
            items: _ratings.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (val) => setState(() => _rating = val ?? _rating),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Saving...' : 'Save Vendor Metric'),
            ),
          ),
        ],
      ),
    );
  }
}
