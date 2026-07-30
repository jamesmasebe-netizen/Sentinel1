import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/hr_models.dart';
import '../services/hr_service.dart';

class DepartmentForm extends ConsumerStatefulWidget {
  final Department? department;

  const DepartmentForm({super.key, this.department});

  @override
  ConsumerState<DepartmentForm> createState() => _DepartmentFormState();
}

class _DepartmentFormState extends ConsumerState<DepartmentForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.department?.name);
    _descController = TextEditingController(text: widget.department?.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final dept = Department(
        id: widget.department?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
      );

      final service = ref.read(hrServiceProvider);
      if (widget.department == null) {
        await service.createDepartment(dept);
        if (mounted) UIUtils.showToast(context, 'Department created', type: ToastType.success);
      } else {
        await service.updateDepartment(dept.id, {
          'name': dept.name,
          'description': dept.description,
        });
        if (mounted) UIUtils.showToast(context, 'Department updated', type: ToastType.success);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Department Name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          GSpacing.vLg,
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : Text(widget.department == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }
}
