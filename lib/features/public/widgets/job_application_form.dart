import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../services/public_careers_service.dart';

class JobApplicationForm extends ConsumerStatefulWidget {
  final String jobId;
  final String jobTitle;
  final String tenantId;

  const JobApplicationForm({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.tenantId,
  });

  @override
  ConsumerState<JobApplicationForm> createState() => _JobApplicationFormState();
}

class _JobApplicationFormState extends ConsumerState<JobApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _phone = '';
  String _resumeLink = '';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      await ref.read(publicCareersServiceProvider).submitApplication(
            tenantId: widget.tenantId,
            jobId: widget.jobId,
            jobTitle: widget.jobTitle,
            applicantName: _name,
            email: _email,
            phone: _phone,
            resumeLink: _resumeLink,
          );

      if (mounted) {
        UIUtils.showToast(
          context,
          'Application submitted successfully!',
          type: ToastType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(
          context,
          'Error submitting application: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator:
                  (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => _name = val!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator:
                  (val) =>
                      val == null || val.isEmpty || !val.contains('@')
                          ? 'Valid email required'
                          : null,
              onSaved: (val) => _email = val!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onSaved: (val) => _phone = val?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Resume Link (Google Drive, LinkedIn, etc.)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Required';
                final uri = Uri.tryParse(val.trim());
                if (uri == null || !uri.isAbsolute || uri.host.isEmpty) {
                  return 'Enter a valid URL (e.g. https://drive.google.com/...)';
                }
                return null;
              },
              onSaved: (val) => _resumeLink = val!.trim(),
            ),
            const SizedBox(height: 32),
            UIUtils.buildFormButtons(
              context: context,
              onSave: _submit,
              isSubmitting: _isLoading,
              saveLabel: 'Submit Application',
            ),
          ],
        ),
      ),
    );
  }
}
