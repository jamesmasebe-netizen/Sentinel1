import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import '../../../risk/screens/hira_screen.dart';
import 'action_item_card.dart';
import 'permit_card.dart';
import 'risk_assessment_card.dart';
import 'safety_compliance_data_fetcher.dart';

class SafetyTab extends ConsumerWidget {
  final Project project;
  const SafetyTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreProvider);
    final riskIdsAsync = ref.watch(projectRiskAssessmentsProvider(project.id));

    return riskIdsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (riskAssessmentIds) => FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: fetchSafetyComplianceData(fs, project, riskAssessmentIds),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!;
        final risks = data['risks'] ?? [];
        final permits = data['permits'] ?? [];
        final actions = data['actions'] ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Safety & Compliance Metrics', style: Theme.of(context).textTheme.titleLarge),
              GSpacing.vLg,
              Row(
                children: [
                  Expanded(
                    child: GCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.shield, color: XMTheme.success, size: 48),
                          GSpacing.vSm,
                          const Text('Contractor Safety File'),
                          Text('${project.safetyFileScore.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
                          const Icon(Icons.assignment_late, color: XMTheme.error, size: 48),
                          GSpacing.vSm,
                          const Text('Open OHS NCRs'),
                          Text('${project.totalNcrs}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              GSpacing.vXl,

              // ─── Associated Risk Assessments ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: XMTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      Text('Risk Assessments (${risks.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      UIUtils.showSideSheet(context: context, title: 'HIRA Risk Assessment', builder: (ctx) => const HiraScreen());
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Risk'),
                  ),
                ],
              ),
              GSpacing.vMd,
              if (risks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: const Text('No Risk Assessments currently linked.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else
                ...risks.map((risk) => RiskAssessmentCard(risk: risk)),
              GSpacing.vXl,

              // ─── Related Permits to Work ───
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded, color: XMTheme.success, size: 20),
                  const SizedBox(width: 8),
                  Text('Related Permits to Work (${permits.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              GSpacing.vMd,
              if (permits.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: const Text('No permits found referencing this project\'s assessments.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else
                ...permits.map((p) => PermitCard(p: p)),
              GSpacing.vXl,

              // ─── Open Action Items ───
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: XMTheme.error, size: 20),
                  const SizedBox(width: 8),
                  Text('Open Project Action Items (${actions.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              GSpacing.vMd,
              if (actions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: const Text('No open action items for this project.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else
                ...actions.map((act) => ActionItemCard(act: act)),
            ],
          ),
        );
      },
    ),
    );
  }

}
