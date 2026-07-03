import 'package:flutter/material.dart';
import '../models/safety_file_models.dart';
import '../../../core/widgets/ds_widgets.dart';

class FindingUpdateDialog extends StatefulWidget {
  final Finding finding;
  final void Function(Finding, FindingStatus, String) onUpdate;

  const FindingUpdateDialog({
    super.key,
    required this.finding,
    required this.onUpdate,
  });

  static void show(
    BuildContext context,
    Finding finding,
    void Function(Finding, FindingStatus, String) onUpdate,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => FindingUpdateDialog(
        finding: finding,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<FindingUpdateDialog> createState() => _FindingUpdateDialogState();
}

class _FindingUpdateDialogState extends State<FindingUpdateDialog> {
  final _commentCtrl = TextEditingController();
  FindingStatus? _selectedStatus;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Finding Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<FindingStatus>(
            decoration: const InputDecoration(labelText: 'New Status'),
            items: FindingStatus.values.map((s) {
              return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
            }).toList(),
            onChanged: (v) => setState(() => _selectedStatus = v),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _commentCtrl,
            decoration: const InputDecoration(labelText: 'Comment / Reason'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_selectedStatus != null && _commentCtrl.text.isNotEmpty) {
              widget.onUpdate(widget.finding, _selectedStatus!, _commentCtrl.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
