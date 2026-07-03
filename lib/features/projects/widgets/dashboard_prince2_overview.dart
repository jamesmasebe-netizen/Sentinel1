import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/project_models.dart';
import 'dashboard_prince2_domain_tile.dart';

class DashboardPrince2Overview extends StatelessWidget {
  final List<Project> projects;
  final double avgSafety;
  final int totalNcrs;
  final int highRisk;
  final int onTrack;

  const DashboardPrince2Overview({
    super.key,
    required this.projects,
    required this.avgSafety,
    required this.totalNcrs,
    required this.highRisk,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    final totalBudget = projects.fold(0.0, (s, p) => s + (p.budget ));
    final completedCount = projects.where((p) => p.status == 'Completed').length;
    final onHoldCount = projects.where((p) => p.status == 'On Hold').length;
    final draftCount = projects.where((p) => p.status == 'Draft').length;
    final completedStages = projects.fold<int>(
        0, (s, p) => s + (p.stages ).where((st) => st.status == 'Completed').length);
    final totalStages = projects.fold<int>(0, (s, p) => s + (p.stages ).length);
    final stageProgress = totalStages == 0 ? 0.0 : completedStages / totalStages;
    final criticalTaskCount =
        projects.fold<int>(0, (s, p) => s + (p.tasks ).where((t) => t.riskLevel == 'Critical').length);
    final overallPortfolioProgress = projects.isEmpty
        ? 0.0
        : projects.fold(0.0, (s, p) => s + (p.overallProgress )) / projects.length;

    return GCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: XMTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Portfolio Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: XMTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${projects.length} Project${projects.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: XMTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Portfolio Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${(overallPortfolioProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: XMTheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: overallPortfolioProgress,
              minHeight: 8,
              backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(XMTheme.primary),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 560;
            final domains = [
              DashboardPrince2DomainTile(
                  icon: Icons.account_balance_rounded,
                  label: 'Finance',
                  color: XMTheme.info,
                  headline: NumberFormat.compactCurrency(symbol: 'R').format(totalBudget),
                  detail: 'Total portfolio budget',
                  status: totalBudget > 5000000 ? 'High Spend' : 'Normal',
                  statusColor: totalBudget > 5000000 ? XMTheme.warning : XMTheme.success),
              DashboardPrince2DomainTile(
                  icon: Icons.warning_amber_rounded,
                  label: 'Risk',
                  color: highRisk > 0 ? XMTheme.error : XMTheme.success,
                  headline: '$highRisk',
                  detail: 'High/Critical risk projects',
                  status: highRisk == 0
                      ? 'All Clear'
                      : criticalTaskCount > 0
                          ? '$criticalTaskCount Critical Tasks'
                          : 'Needs Review',
                  statusColor: highRisk == 0 ? XMTheme.success : XMTheme.error),
              DashboardPrince2DomainTile(
                  icon: Icons.health_and_safety_rounded,
                  label: 'OHS',
                  color: avgSafety >= 75 ? XMTheme.success : XMTheme.warning,
                  headline: '${avgSafety.toStringAsFixed(1)}%',
                  detail: 'Avg safety file score',
                  status: totalNcrs == 0 ? 'No Open NCRs' : '$totalNcrs Open NCRs',
                  statusColor: totalNcrs == 0 ? XMTheme.success : XMTheme.error),
              DashboardPrince2DomainTile(
                  icon: Icons.timeline_rounded,
                  label: 'Stages',
                  color: XMTheme.secondaryLight,
                  headline: '$completedStages/$totalStages',
                  detail: 'Project stages completed',
                  status: '${(stageProgress * 100).toStringAsFixed(0)}% done',
                  statusColor: stageProgress >= 0.7 ? XMTheme.success : XMTheme.warning),
              DashboardPrince2DomainTile(
                  icon: Icons.pause_circle_rounded,
                  label: 'Status Mix',
                  color: XMTheme.warning,
                  headline: '$onTrack on track',
                  detail: '$draftCount Draft • $onHoldCount On Hold • $completedCount Done',
                  status: onHoldCount > 0 ? '$onHoldCount On Hold' : 'Healthy',
                  statusColor: onHoldCount > 0 ? XMTheme.warning : XMTheme.success),
              DashboardPrince2DomainTile(
                  icon: Icons.task_alt_rounded,
                  label: 'Quality',
                  color: XMTheme.success,
                  headline: '${(overallPortfolioProgress * 100).toStringAsFixed(0)}%',
                  detail: 'Avg project completion',
                  status: criticalTaskCount > 0 ? '$criticalTaskCount Critical Tasks' : 'On Track',
                  statusColor: criticalTaskCount > 0 ? XMTheme.error : XMTheme.success),
            ];
            if (isWide) {
              return GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.0,
                children: domains,
              );
            }
            return Column(
              children: domains.expand((d) => [d, const SizedBox(height: 10)]).toList()..removeLast(),
            );
          }),
        ],
      ),
    );
  }
}
