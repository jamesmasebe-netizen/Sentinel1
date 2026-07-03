import 'dart:convert';
import 'package:flutter/material.dart';
import '../../widgets/ds_widgets.dart';

class FeedbackBottomSheet extends StatefulWidget {
  final Map<String, dynamic> snapshot;
  final bool isUploading;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  const FeedbackBottomSheet({
    super.key,
    required this.snapshot,
    required this.isUploading,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GHeader(
              title: 'Developer Feedback',
              subtitle:
                  'Snapshot captured for ${widget.snapshot['screen_name']}',
            ),
            GSpacing.vMd,
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the bug or request a feature...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
            GSpacing.vLg,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        widget.isUploading
                            ? null
                            : () {
                              widget.onSubmit(_controller.text);
                            },
                    icon:
                        widget.isUploading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.send_rounded),
                    label: Text(
                      widget.isUploading ? 'Uploading...' : 'Submit to AI',
                    ),
                  ),
                ),
              ],
            ),
            GSpacing.vSm,
            Center(
              child: Text(
                'Snapshot size: ${(jsonEncode(widget.snapshot).length / 1024).toStringAsFixed(1)} KB',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
