import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/project_models.dart';

class ProjectListItem extends StatelessWidget {
  final Project project;
  final String riskLevel;

  const ProjectListItem({
    super.key,
    required this.project,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/projects/${project.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: XMTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_tree_rounded, color: XMTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GStatusTag(label: riskLevel, color: _getRiskColor(riskLevel)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${project.category} • ${project.status}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, size: 14, color: XMTheme.success),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('Safety: ${project.safetyFileScore.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.assignment_late_rounded, size: 14, color: XMTheme.warning),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('NCRs: ${project.totalNcrs}',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.attach_money, size: 14, color: XMTheme.info),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        NumberFormat.compactCurrency(symbol: 'R').format(project.budget),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(project.overallProgress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: XMTheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: project.overallProgress,
                  backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(XMTheme.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Critical':
        return XMTheme.error;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return XMTheme.warning;
      case 'Low':
        return XMTheme.success;
      default:
        return XMTheme.info;
    }
  }
}
