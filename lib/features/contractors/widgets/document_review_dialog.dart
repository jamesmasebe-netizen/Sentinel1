import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/safety_file_models.dart';
import '../services/contractor_review_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class DocumentReviewDialog extends ConsumerStatefulWidget {
  final ContractorDocument document;

  const DocumentReviewDialog({super.key, required this.document});

  static void show(BuildContext context, ContractorDocument document) {
    showDialog(
      context: context,
      builder: (ctx) => DocumentReviewDialog(document: document),
    );
  }

  @override
  ConsumerState<DocumentReviewDialog> createState() => _DocumentReviewDialogState();
}

class _DocumentReviewDialogState extends ConsumerState<DocumentReviewDialog> {
  final _feedbackCtrl = TextEditingController();
  String _selectedStatus = 'Pending';
  FindingStatus _findingStatus = FindingStatus.open;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl.text = widget.document.feedback ?? '';
    _selectedStatus = widget.document.status;
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final reviewerName = user.displayName.isNotEmpty ? user.displayName : user.email;
      await ref.read(contractorReviewServiceProvider).submitDocumentReview(
            document: widget.document,
            status: _selectedStatus,
            feedback: _feedbackCtrl.text,
            findingStatus: _findingStatus,
            reviewerUid: user.uid,
            reviewerName: reviewerName,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error submitting review: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review Document: ${widget.document.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Document Status'),
            items: ['Pending', 'Resolved', 'Rejected'].map((s) {
              return DropdownMenuItem(value: s, child: Text(s));
            }).toList(),
            onChanged: (v) => setState(() => _selectedStatus = v!),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _feedbackCtrl,
            decoration: const InputDecoration(labelText: 'Finding Description / Feedback'),
            maxLines: 3,
          ),
          GSpacing.vMd,
          DropdownButtonFormField<FindingStatus>(
            value: _findingStatus,
            decoration: const InputDecoration(labelText: 'Finding Status'),
            items: FindingStatus.values.map((s) {
              return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
            }).toList(),
            onChanged: (v) => setState(() => _findingStatus = v ?? _findingStatus),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Review'),
        ),
      ],
    );
  }
}
