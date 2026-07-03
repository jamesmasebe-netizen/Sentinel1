import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../models/project_models.dart';

class ProjectStagesPreview extends StatelessWidget {
  final List<ProjectStage> stages;

  const ProjectStagesPreview({super.key, required this.stages});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: XMTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: XMTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: XMTheme.primary, size: 16),
              SizedBox(width: 6),
              Text(
                'Project Stages (auto-configured)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: XMTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...stages.map(
            (stage) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    stage.requiresSafetyClearance
                        ? Icons.lock_rounded
                        : Icons.radio_button_unchecked,
                    size: 14,
                    color:
                        stage.requiresSafetyClearance
                            ? XMTheme.warning
                            : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stage.stageName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (stage.requiresSafetyClearance)
                    const Text(
                      'Safety lock',
                      style: TextStyle(fontSize: 10, color: XMTheme.warning),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
