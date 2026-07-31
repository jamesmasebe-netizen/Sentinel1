import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/utils/ui_utils.dart';

class EditProfileForm extends ConsumerStatefulWidget {
  final UserProfile profile;
  const EditProfileForm({super.key, required this.profile});

  @override
  ConsumerState<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<EditProfileForm> {
  late final _nameCtrl = TextEditingController(text: widget.profile.displayName);
  late final _departmentCtrl = TextEditingController(text: widget.profile.department ?? '');
  late final _jobTitleCtrl = TextEditingController(text: widget.profile.jobTitle ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _departmentCtrl.dispose();
    _jobTitleCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authServiceProvider).updateProfile({
        'displayName': _nameCtrl.text.trim(),
        'department': _departmentCtrl.text.trim(),
        'jobTitle': _jobTitleCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        UIUtils.showToast(context, 'Profile updated', type: ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error updating profile: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Display Name *'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _departmentCtrl,
          decoration: const InputDecoration(labelText: 'Department'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _jobTitleCtrl,
          decoration: const InputDecoration(labelText: 'Job Title'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(labelText: 'Phone'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSubmitting ? 'Saving...' : 'Save Changes'),
          ),
        ),
      ],
    );
  }
}
