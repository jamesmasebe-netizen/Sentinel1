import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/hr_models.dart';
import '../services/hr_service.dart';

class JobRoleForm extends ConsumerStatefulWidget {
  final JobRole? jobRole;

  const JobRoleForm({super.key, this.jobRole});

  @override
  ConsumerState<JobRoleForm> createState() => _JobRoleFormState();
}

class _JobRoleFormState extends ConsumerState<JobRoleForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isLegalAppointment = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.jobRole?.title);
    _descController = TextEditingController(text: widget.jobRole?.description);
    _isLegalAppointment = widget.jobRole?.isLegalAppointment ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final role = JobRole(
        id: widget.jobRole?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        isLegalAppointment: _isLegalAppointment,
      );

      final service = ref.read(hrServiceProvider);
      if (widget.jobRole == null) {
        await service.createJobRole(role);
        if (mounted) UIUtils.showToast(context, 'Job Role created', type: ToastType.success);
      } else {
        await service.updateJobRole(role.id, {
          'title': role.title,
          'description': role.description,
          'isLegalAppointment': role.isLegalAppointment,
        });
        if (mounted) UIUtils.showToast(context, 'Job Role updated', type: ToastType.success);
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
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Job Title'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          GSpacing.vMd,
          SwitchListTile(
            title: const Text('Is Legal Appointment?'),
            subtitle: const Text('Does this role qualify for OHS legal appointments?'),
            value: _isLegalAppointment,
            onChanged: (val) {
              setState(() {
                _isLegalAppointment = val;
              });
            },
          ),
          GSpacing.vLg,
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : Text(widget.jobRole == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }
}
