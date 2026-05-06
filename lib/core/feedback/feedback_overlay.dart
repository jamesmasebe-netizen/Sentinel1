import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ui_indexer.dart';
import '../widgets/ds_widgets.dart';

class FeedbackOverlay extends StatefulWidget {
  final Widget child;
  final bool isEnabled;

  const FeedbackOverlay({
    super.key,
    required this.child,
    this.isEnabled = true,
  });

  @override
  State<FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends State<FeedbackOverlay> {
  Offset _position = const Offset(20, 100);
  bool _isFeedbackMode = false;

  void _submitFeedback(BuildContext context, Map<String, dynamic> snapshot, String userText) async {
    try {
      final feedbackData = {
        ...snapshot,
        'user_feedback': userText,
        'user_id': 'dev_user', // Replace with actual user ID if available
      };

      await FirebaseFirestore.instance.collection('dev_feedback').add(feedbackData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted with UI snapshot!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    // Capture state immediately when dialog is triggered
    final indexer = UIIndexer(context, screenName: ModalRoute.of(context)?.settings.name ?? 'Dashboard');
    final snapshot = indexer.captureState();
    final TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                subtitle: 'Snapshot captured for ${snapshot['screen_name']}',
              ),
              GSpacing.vMd,
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the bug or request a feature...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
              ),
              GSpacing.vLg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final text = controller.text;
                        Navigator.pop(context);
                        _submitFeedback(context, snapshot, text);
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Submit to AI'),
                    ),
                  ),
                ],
              ),
              GSpacing.vSm,
              Center(
                child: Text(
                  'Snapshot size: ${(jsonEncode(snapshot).length / 1024).toStringAsFixed(1)} KB',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
              });
            },
            onTap: () => _showFeedbackDialog(context),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bug_report_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
