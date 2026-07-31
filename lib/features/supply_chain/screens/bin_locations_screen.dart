import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/scm_models.dart';
import '../services/scm_service.dart';
import '../providers/scm_streams_provider.dart';
import '../../../core/widgets/entity_selector.dart';
import '../../../core/utils/ui_utils.dart';

class BinLocationsScreen extends ConsumerWidget {
  const BinLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binsAsync = ref.watch(binLocationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bin Locations'), elevation: 0),
      body: binsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (bins) {
          if (bins.isEmpty) {
            return const Center(child: Text('No bin locations recorded'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final bin = bins[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: bin.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.grid_view_outlined,
                      color: bin.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text(bin.binCode),
                  subtitle: Text(
                    'Aisle ${bin.aisle} · Rack ${bin.rack} · ${bin.currentQuantity.toStringAsFixed(0)}/${bin.maxCapacity.toStringAsFixed(0)} capacity',
                  ),
                  onTap: () => UIUtils.showSideSheet(
                    context: context,
                    title: 'Edit Bin Location',
                    builder: (_) => _BinLocationForm(initial: bin),
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
          title: 'New Bin Location',
          builder: (_) => const _BinLocationForm(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BinLocationForm extends ConsumerStatefulWidget {
  final WarehouseBinLocation? initial;
  const _BinLocationForm({this.initial});

  @override
  ConsumerState<_BinLocationForm> createState() => _BinLocationFormState();
}

class _BinLocationFormState extends ConsumerState<_BinLocationForm> {
  final _formKey = GlobalKey<FormState>();
  late final _binCodeCtrl = TextEditingController(text: widget.initial?.binCode ?? '');
  late final _aisleCtrl = TextEditingController(text: widget.initial?.aisle ?? '');
  late final _rackCtrl = TextEditingController(text: widget.initial?.rack ?? '');
  late final _levelCtrl = TextEditingController(text: widget.initial?.level ?? '');
  late final _zoneCtrl = TextEditingController(text: widget.initial?.zone ?? '');
  late final _maxCapacityCtrl = TextEditingController(text: widget.initial?.maxCapacity.toString() ?? '0');
  String? _warehouseId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _warehouseId = widget.initial?.warehouseId;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _warehouseId == null) {
      UIUtils.showToast(context, 'Warehouse and bin code are required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(scmServiceProvider);
      final bin = WarehouseBinLocation(
        id: widget.initial?.id ?? const Uuid().v4(),
        warehouseId: _warehouseId!,
        binCode: _binCodeCtrl.text.trim(),
        aisle: _aisleCtrl.text.trim(),
        rack: _rackCtrl.text.trim(),
        level: _levelCtrl.text.trim(),
        zone: _zoneCtrl.text.trim(),
        currentQuantity: widget.initial?.currentQuantity ?? 0,
        maxCapacity: double.tryParse(_maxCapacityCtrl.text) ?? 0,
        isActive: widget.initial?.isActive ?? true,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (widget.initial == null) {
        await service.createBinLocation(bin);
      } else {
        await service.updateBinLocation(bin);
      }
      if (mounted) {
        UIUtils.showToast(context, 'Bin location saved', type: ToastType.success);
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
          EntitySelector<Warehouse>(
            asyncEntities: ref.watch(warehousesStreamProvider),
            value: _warehouseId,
            onChanged: (val) => setState(() => _warehouseId = val),
            label: 'Warehouse *',
            idMapper: (w) => w.id,
            displayMapper: (w) => w.name,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _binCodeCtrl,
            decoration: const InputDecoration(labelText: 'Bin Code *'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _aisleCtrl, decoration: const InputDecoration(labelText: 'Aisle'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _rackCtrl, decoration: const InputDecoration(labelText: 'Rack'))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _levelCtrl, decoration: const InputDecoration(labelText: 'Level'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _zoneCtrl, decoration: const InputDecoration(labelText: 'Zone'))),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _maxCapacityCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Max Capacity'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Saving...' : 'Save Bin Location'),
            ),
          ),
        ],
      ),
    );
  }
}
