import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';

class WasteForm extends ConsumerStatefulWidget {
  const WasteForm({super.key});

  @override
  ConsumerState<WasteForm> createState() => _WasteFormState();
}

class _WasteFormState extends ConsumerState<WasteForm> {
  bool _isSubmitting = false;

  String _wasteType = 'General';
  String _wasteUnit = 'kg';
  final String _wasteStatus = 'Pending Pickup';
  final _qtyCtrl = TextEditingController();
  final _transporterCtrl = TextEditingController();
  final _facilityCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _transporterCtrl.dispose();
    _facilityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitWaste() async {
    if (_qtyCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Quantity is required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'waste_manifests',
        data: {
          'wasteType': _wasteType,
          'quantity': double.tryParse(_qtyCtrl.text) ?? 0,
          'unit': _wasteUnit,
          'transporterName': _transporterCtrl.text.trim(),
          'disposalFacility': _facilityCtrl.text.trim(),
          'status': _wasteStatus,
          'authorId': p.uid,
          'siteId': p.tenantId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Waste manifest added successfully');
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _wasteType,
            decoration: const InputDecoration(labelText: 'Waste Type'),
            items: ['Hazardous', 'General', 'Recyclable', 'Medical', 'E-Waste']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _wasteType = v!),
          ),
          GSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                ),
              ),
              GSpacing.hMd,
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  value: _wasteUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: ['kg', 'tons', 'liters', 'm3']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _wasteUnit = v!),
                ),
              ),
            ],
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _transporterCtrl,
            decoration: const InputDecoration(labelText: 'Transporter Name', prefixIcon: Icon(Icons.local_shipping_outlined)),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _facilityCtrl,
            decoration: const InputDecoration(labelText: 'Disposal Facility', prefixIcon: Icon(Icons.factory_outlined)),
          ),
          GSpacing.vLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitWaste,
              child: Text(_isSubmitting ? 'Saving...' : 'Save Manifest'),
            ),
          ),
        ],
      ),
    );
  }
}
