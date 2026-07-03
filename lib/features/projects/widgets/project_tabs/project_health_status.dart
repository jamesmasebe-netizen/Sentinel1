import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/widgets/ds_widgets.dart';
import '../../models/project_models.dart';

class ProjectHealthStatus extends StatelessWidget {
  final Project project;

  const ProjectHealthStatus({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.analytics_rounded, color: XMTheme.primary, size: 36),
                GSpacing.vSm,
                const Text('Schedule Variance', style: TextStyle(fontSize: 12)),
                Text('${(project.overallProgress * 100).toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        GSpacing.hMd,
        Expanded(
          child: GCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.shield_rounded, color: XMTheme.success, size: 36),
                GSpacing.vSm,
                const Text('Safety Compliance', style: TextStyle(fontSize: 12)),
                Text('${project.safetyFileScore.toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        GSpacing.hMd,
        Expanded(
          child: GCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.warning_rounded, color: XMTheme.warning, size: 36),
                GSpacing.vSm,
                const Text('Overall Risk', style: TextStyle(fontSize: 12)),
                Text(project.overallRiskLevel, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
