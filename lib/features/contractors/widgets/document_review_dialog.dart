import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/safety_file_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

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
  String _findingStatus = 'Open';

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
    final db = ref.read(firestoreProvider);
    final tenantId = ref.read(currentTenantIdProvider) ?? "";
    final user = ref.read(userProfileProvider).valueOrNull;

    final updates = <String, dynamic>{
      'status': _selectedStatus,
      'feedback': _feedbackCtrl.text,
    };

    if (user != null && _feedbackCtrl.text.isNotEmpty) {
      final newFinding = {
        'description': _feedbackCtrl.text,
        'status': _findingStatus,
        'reportedBy': user.displayName.isNotEmpty ? user.displayName : user.email,
        'createdAt': DateTime.now().toIso8601String(),
      };
      updates['findings'] = FieldValue.arrayUnion([newFinding]);
    }

    // Update document
    await db.tenantCollection(tenantId, 'contractor_documents').doc(widget.document.id).update(updates);

    // Generate finding in findings collection
    if (user != null && _feedbackCtrl.text.isNotEmpty) {
      await db.tenantCollection(tenantId, 'findings').add({
        'submissionId': widget.document.submissionId,
        'documentId': widget.document.id,
        'status': _findingStatus,
        'type': 'observation',
        'description': _feedbackCtrl.text,
        'contractorAction': '',
        'reportedBy': user.displayName.isNotEmpty ? user.displayName : user.email,
        'reviewerUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedBy': user.uid,
        'modifiedAt': FieldValue.serverTimestamp(),
        'statusHistory': [
          {
            'status': _findingStatus,
            'timestamp': DateTime.now().toIso8601String(),
            'comment': 'Initial review finding',
            'userId': user.uid,
          }
        ],
      });
    }

    if (mounted) {
      Navigator.pop(context);
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
          DropdownButtonFormField<String>(
            value: _findingStatus,
            decoration: const InputDecoration(labelText: 'Finding Status'),
            items: ['Open', 'Resolved'].map((s) {
              return DropdownMenuItem(value: s, child: Text(s));
            }).toList(),
            onChanged: (v) => setState(() => _findingStatus = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitReview,
          child: const Text('Submit Review'),
        ),
      ],
    );
  }
}
