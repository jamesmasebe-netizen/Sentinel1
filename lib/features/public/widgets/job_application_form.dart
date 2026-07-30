import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class JobApplicationForm extends StatefulWidget {
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
  State<JobApplicationForm> createState() => _JobApplicationFormState();
}

class _JobApplicationFormState extends State<JobApplicationForm> {
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
      await FirebaseFirestore.instance
          .tenantCollection(widget.tenantId, 'job_applications')
          .add({
            'jobId': widget.jobId,
            'jobTitle': widget.jobTitle,
            'applicantName': _name,
            'email': _email,
            'phone': _phone,
            'resumeLink': _resumeLink,
            'status': 'New',
            'appliedAt': FieldValue.serverTimestamp(),
            'isExternal': true,
          });

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
              validator:
                  (val) => val == null || val.isEmpty ? 'Required' : null,
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
