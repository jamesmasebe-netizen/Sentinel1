import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_compliance_service.dart';
import '../models/compliance_prescreen_models.dart';

class AiPreScreenBadge extends ConsumerWidget {
  final String documentId;

  const AiPreScreenBadge({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(compliancePreScreenProvider(documentId));

    return asyncResult.when(
      data: (result) {
        if (result == null) return const SizedBox.shrink();

        if (result.status == PreScreenStatus.processing || result.status == PreScreenStatus.pending) {
          return const CircularProgressIndicator();
        }

        Widget icon;
        String text;
        Color color;

        if (result.hasCriticalFlags) {
          icon = const Icon(Icons.error, color: Colors.red, size: 16);
          text = 'AI Alert (${result.criticalCount} critical)';
          color = Colors.red;
        } else if (result.hasWarnings) {
          icon = const Icon(Icons.warning, color: Colors.orange, size: 16);
          text = 'AI Flagged (${result.warningCount} issues)';
          color = Colors.orange;
        } else {
          icon = const Icon(Icons.check_circle, color: Colors.green, size: 16);
          text = 'AI Verified';
          color = Colors.green;
        }

        return InkWell(
          onTap: () => _showDialog(context, result),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 4),
                Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => const Icon(Icons.error, color: Colors.red),
    );
  }

  void _showDialog(BuildContext context, CompliancePreScreenResult result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('AI Pre-Screen Results'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result.extractedDates.isNotEmpty) ...[
                  const Text('Extracted Dates:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result.extractedDates.entries.map((e) => Text('${e.key}: ${e.value}')),
                  const SizedBox(height: 16),
                ],
                if (result.extractedCertifications.isNotEmpty) ...[
                  const Text('Extracted Certifications:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result.extractedCertifications.entries.map((e) => Text('${e.key}: ${e.value}')),
                  const SizedBox(height: 16),
                ],
                if (result.flags.isNotEmpty) ...[
                  const Text('Flags:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result.flags.map((f) => Text('- ${f.field}: ${f.issue} (${f.severity})')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }
}
