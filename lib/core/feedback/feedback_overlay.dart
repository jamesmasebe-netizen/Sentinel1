// ignore_for_file: use_build_context_synchronously
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'ui_indexer.dart';
import 'widgets/feedback_bottom_sheet.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';
import '../../core/providers/app_providers.dart';

class FeedbackOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final bool isEnabled;

  const FeedbackOverlay({
    super.key,
    required this.child,
    this.isEnabled = true,
  });

  @override
  ConsumerState<FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends ConsumerState<FeedbackOverlay> {
  final GlobalKey _boundaryKey = GlobalKey();
  Offset _position = const Offset(20, 100);
  bool _isUploading = false;

  Future<String?> _captureAndUploadScreenshot(String feedbackId) async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final storageRef = FirebaseStorage.instance.ref().child('feedback_screenshots/$feedbackId.png');
      
      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );
      
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      return null;
    }
  }

  void _submitFeedback(BuildContext context, Map<String, dynamic> snapshot, String userText) async {
    setState(() => _isUploading = true);
    final feedbackId = DateTime.now().millisecondsSinceEpoch.toString();
    
    try {
      // Capture and upload screenshot first
      final screenshotUrl = await _captureAndUploadScreenshot(feedbackId);

      final feedbackData = {
        ...snapshot,
        'id': feedbackId,
        'user_feedback': userText,
        'user_id': 'dev_user',
        'screenshot_url': screenshotUrl,
      };

      await FirebaseFirestore.instance.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'dev_feedback').doc(feedbackId).set(feedbackData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted with UI snapshot and screenshot!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    // Capture state immediately when dialog is triggered
    final indexer = UIIndexer(context, screenName: ModalRoute.of(context)?.settings.name ?? 'Dashboard');
    final snapshot = indexer.captureState();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedbackBottomSheet(
        snapshot: snapshot,
        isUploading: _isUploading,
        onCancel: () => Navigator.pop(context),
        onSubmit: (text) {
          Navigator.pop(context);
          _submitFeedback(context, snapshot, text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) return widget.child;

    return Stack(
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: widget.child,
        ),
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
                      color: Colors.black.withValues(alpha: 0.2),
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
