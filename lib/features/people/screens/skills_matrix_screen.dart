import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/skill_assessment_form.dart';
import '../widgets/skill_matrix_card.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

/// Skills Matrix — grid of employees × skill competencies.
class SkillsMatrixScreen extends ConsumerStatefulWidget {
  const SkillsMatrixScreen({super.key});
  @override
  ConsumerState<SkillsMatrixScreen> createState() => _SkillsMatrixScreenState();
}

class _SkillsMatrixScreenState extends ConsumerState<SkillsMatrixScreen> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Column(
        children: [
          const GHeader(
            title: 'Skills Matrix',
            subtitle: 'Skill assessments, levels, and proficiency tracking',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Capability Assessments',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.assessment, size: 18),
                  label: Text(_showForm ? 'Cancel' : 'New Assessment'),
                ),
              ],
            ),
          ),
          GSpacing.vMd,
          if (_showForm) SkillAssessmentForm(onCancel: () => setState(() => _showForm = false)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'skills_matrix')
                  .where('siteId', isEqualTo: siteId)
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (ctx, snap) {
                final docs = snap.data?.docs ?? [];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grid_on,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        GSpacing.vMd,
                        const Text('No skill records yet'),
                      ],
                    ),
                  );
                }

                // Group by employee
                final byEmployee = <String, List<Map<String, dynamic>>>{};
                for (final doc in docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = d['employeeName'] ?? 'Unknown';
                  byEmployee.putIfAbsent(name, () => []).add(d);
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: byEmployee.entries.map((entry) {
                    return SkillMatrixCard(employeeName: entry.key, skills: entry.value);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
