import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../safety/screens/incidents_register_screen.dart';
import '../../../safety/screens/capa_screen.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

Future<List<Map<String, dynamic>>> fetchLinkedRisks(
  dynamic fs,
  String siteId,
  List<String> linkedIds,
) async {
  if (linkedIds.isEmpty) return [];
  final results = <Map<String, dynamic>>[];

  for (final id in linkedIds) {
    // 1. Try HIRA
    final hira =
        await fs.tenantCollection(siteId, 'risk_assessments').doc(id).get();
    if (hira.exists) {
      results.add({
        'id': id,
        'type': 'HIRA',
        'title': hira.data()['title'] ?? '',
        'rating': hira.data()['riskLevel'] ?? 'Medium',
      });
      continue;
    }
    // 2. Try DRA
    final dra =
        await fs
            .tenantCollection(siteId, 'dynamic_risk_assessments')
            .doc(id)
            .get();
    if (dra.exists) {
      results.add({
        'id': id,
        'type': 'DRA',
        'title': dra.data()['taskDescription'] ?? '',
        'rating':
            dra.data()['isSafeToProceed'] == true ? 'Safe' : 'Action Required',
      });
      continue;
    }
    // 3. Try Strategic
    final strat =
        await fs.tenantCollection(siteId, 'strategic_risks').doc(id).get();
    if (strat.exists) {
      results.add({
        'id': id,
        'type': 'Strategic',
        'title': strat.data()['title'] ?? '',
        'rating': strat.data()['riskRating'] ?? 'Medium',
      });
      continue;
    }
  }
  return results;
}

Future<Map<String, List<Map<String, dynamic>>>> loadAllAvailableRisks(
  dynamic fs,
  String siteId,
) async {
  final hiras = <Map<String, dynamic>>[];
  final dras = <Map<String, dynamic>>[];
  final strats = <Map<String, dynamic>>[];

  // HIRAs
  final hiraSnap =
      await fs
          .tenantCollection(siteId, 'risk_assessments')
          .where('siteId', isEqualTo: siteId)
          .get();
  for (final doc in hiraSnap.docs) {
    hiras.add({
      'id': doc.id,
      'type': 'HIRA',
      'title': doc.data()['title'] ?? 'Unnamed HIRA',
      'rating': doc.data()['riskLevel'] ?? 'Medium',
    });
  }

  // DRAs
  final draSnap =
      await fs
          .tenantCollection(siteId, 'dynamic_risk_assessments')
          .where('siteId', isEqualTo: siteId)
          .get();
  for (final doc in draSnap.docs) {
    dras.add({
      'id': doc.id,
      'type': 'DRA',
      'title': doc.data()['taskDescription'] ?? 'Unnamed DRA',
      'rating':
          doc.data()['isSafeToProceed'] == true ? 'Safe' : 'Action Required',
    });
  }

  // Strategic Risks
  final stratSnap =
      await fs
          .tenantCollection(siteId, 'strategic_risks')
          .where('siteId', isEqualTo: siteId)
          .get();
  for (final doc in stratSnap.docs) {
    strats.add({
      'id': doc.id,
      'type': 'Strategic',
      'title': doc.data()['title'] ?? 'Unnamed Strategic Risk',
      'rating': doc.data()['riskRating'] ?? 'Medium',
    });
  }

  return {'hiras': hiras, 'dras': dras, 'strats': strats};
}

void showRiskPickerSheet(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  ProjectTask task,
  List<String> taskLinkedRisks,
  StateSetter parentSetState,
  Function(ProjectTask) onUpdated,
) {
  final fs = ref.read(firestoreProvider);
  final siteId = ref.read(currentTenantIdProvider) ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder:
              (ctx, scrollCtrl) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.link_rounded,
                            color: XMTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Link Risk Assessment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Select OHS assessments or business risks to link',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: FutureBuilder<
                        Map<String, List<Map<String, dynamic>>>
                      >(
                        future: loadAllAvailableRisks(fs, siteId),
                        builder: (ctx, snap) {
                          if (!snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final data = snap.data!;
                          final hiras = data['hiras'] ?? [];
                          final dras = data['dras'] ?? [];
                          final strats = data['strats'] ?? [];

                          final allRisks = [...hiras, ...dras, ...strats];

                          if (allRisks.isEmpty) {
                            return const Center(
                              child: Text(
                                'No risk assessments found for this site.',
                              ),
                            );
                          }

                          return StatefulBuilder(
                            builder: (context, setPickerState) {
                              return ListView.builder(
                                controller: scrollCtrl,
                                padding: const EdgeInsets.all(16),
                                itemCount: allRisks.length,
                                itemBuilder: (ctx, i) {
                                  final risk = allRisks[i];
                                  final riskId = risk['id'] as String;
                                  final isLinked = taskLinkedRisks.contains(
                                    riskId,
                                  );

                                  return Card(
                                    elevation: 0,
                                    color:
                                        isLinked
                                            ? XMTheme.primary.withValues(
                                              alpha: 0.05,
                                            )
                                            : null,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color:
                                            isLinked
                                                ? XMTheme.primary
                                                : Theme.of(
                                                  context,
                                                ).colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      value: isLinked,
                                      title: Text(
                                        risk['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: XMTheme.primary.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              risk['type'],
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: XMTheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Rating: ${risk['rating']}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onChanged: (val) async {
                                        final docId = '${task.id}_$riskId';
                                        if (val == true) {
                                          await fs
                                              .tenantCollection(
                                                ref.watch(
                                                      currentTenantIdProvider,
                                                    ) ??
                                                    "",
                                                'projects',
                                              )
                                              .doc(projectId)
                                              .collection('taskLinkedRisks')
                                              .doc(docId)
                                              .set({
                                                'taskId': task.id,
                                                'riskId': riskId,
                                              });
                                        } else {
                                          await fs
                                              .tenantCollection(
                                                ref.watch(
                                                      currentTenantIdProvider,
                                                    ) ??
                                                    "",
                                                'projects',
                                              )
                                              .doc(projectId)
                                              .collection('taskLinkedRisks')
                                              .doc(docId)
                                              .delete();
                                        }
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        ),
  );
}

void showTaskEditor(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  List<ProjectTask> allTasks,
  ProjectTask initialTask,
  List<String> taskDependencies,
  List<String> taskLinkedRisks,
  List<String> taskLinkedIncidents,
  List<String> taskLinkedCapas,
) {
  ProjectTask task = initialTask;
  final fs = ref.read(firestoreProvider);
  final siteId = ref.read(currentTenantIdProvider) ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollCtrl) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: XMTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.assignment_rounded,
                              color: XMTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Task Control & Linkages',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final projectAsync = ref.read(
                                projectProvider(projectId),
                              );
                              final project = projectAsync.value;
                              if (project != null) {
                                final updatedTasks = List<ProjectTask>.from(
                                  project.tasks,
                                )..removeWhere((t) => t.id == task.id);
                                final updatedProject = project.copyWith(
                                  tasks: updatedTasks,
                                );
                                await ref
                                    .read(projectServiceProvider)
                                    .updateProject(updatedProject);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  UIUtils.showToast(
                                    context,
                                    'Task deleted',
                                    type: ToastType.success,
                                  );
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: XMTheme.error,
                            ),
                            tooltip: 'Delete Task',
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress Control',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // HARD BLOCK LOGIC CHECK
                            Builder(
                              builder: (ctx) {
                                bool isHardBlocked = false;
                                List<String> blockingTasks = [];
                                for (final depId in taskDependencies) {
                                  try {
                                    final depTask = allTasks.firstWhere(
                                      (t) => t.id == depId,
                                    );
                                    if (depTask.progress < 1.0) {
                                      isHardBlocked = true;
                                      blockingTasks.add(depTask.title);
                                    }
                                  } catch (_) {}
                                }

                                if (isHardBlocked) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: XMTheme.error.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: XMTheme.error.withAlpha(100),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.lock_rounded,
                                          color: XMTheme.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Hard Block Active',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: XMTheme.error,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'Dependencies not met: ${blockingTasks.join(', ')}',
                                                style: TextStyle(
                                                  color: XMTheme.error
                                                      .withAlpha(200),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: task.progress,
                                        min: 0.0,
                                        max: 1.0,
                                        divisions: 100,
                                        label:
                                            '${(task.progress * 100).toInt()}%',
                                        onChanged: (val) {
                                          setModalState(() {
                                            task = task.copyWith(progress: val);
                                          });
                                        },
                                      ),
                                    ),
                                    Text(
                                      '${(task.progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Associated Risks & Safety Assessments',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed:
                                      () => showRiskPickerSheet(
                                        context,
                                        ref,
                                        projectId,
                                        task,
                                        taskLinkedRisks,
                                        setModalState,
                                        (updatedTask) {
                                          setModalState(() {
                                            task = updatedTask;
                                          });
                                        },
                                      ),
                                  icon: const Icon(
                                    Icons.link_rounded,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Link Assessment',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: fetchLinkedRisks(
                                fs,
                                siteId,
                                taskLinkedRisks,
                              ),
                              builder: (ctx, snap) {
                                if (!snap.hasData) {
                                  return const Center(
                                    child: LinearProgressIndicator(),
                                  );
                                }
                                final risks = snap.data!;
                                if (risks.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: const Text(
                                      'No linked risk assessments for this task/process.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }
                                return Column(
                                  children:
                                      risks.map((risk) {
                                        final type = risk['type'] as String;
                                        final title = risk['title'] as String;
                                        final rating = risk['rating'] as String;
                                        Color badgeColor = Colors.grey;
                                        if (rating == 'High' ||
                                            rating == 'Critical' ||
                                            rating == 'Extreme') {
                                          badgeColor = XMTheme.error;
                                        }
                                        if (rating == 'Medium') {
                                          badgeColor = XMTheme.warning;
                                        }
                                        if (rating == 'Low' || rating == 'Safe') {
                                          badgeColor = XMTheme.success;
                                        }

                                        return Card(
                                          elevation: 0,
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          color:
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerLowest,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            side: BorderSide(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.outlineVariant,
                                            ),
                                          ),
                                          child: ListTile(
                                            title: Text(
                                              title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            subtitle: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: XMTheme.primary
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    type,
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: XMTheme.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: badgeColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    rating,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: badgeColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(
                                                Icons.link_off_rounded,
                                                color: XMTheme.error,
                                                size: 18,
                                              ),
                                              onPressed: () async {
                                                final docId =
                                                    '${task.id}_${risk['id']}';
                                                await fs
                                                    .tenantCollection(
                                                      ref.watch(
                                                            currentTenantIdProvider,
                                                          ) ??
                                                          "",
                                                      'projects',
                                                    )
                                                    .doc(projectId)
                                                    .collection(
                                                      'taskLinkedRisks',
                                                    )
                                                    .doc(docId)
                                                    .delete();
                                              },
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              'Other Linkages (Incidents, NCRs, CAPAs)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ActionChip(
                                  label: const Text(
                                    'Link Incident',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  avatar: const Icon(
                                    Icons.local_hospital,
                                    size: 14,
                                  ),
                                  onPressed:
                                      () => UIUtils.showSideSheet(
                                        context: context,
                                        title: 'Incidents Register',
                                        builder:
                                            (ctx) =>
                                                const IncidentsRegisterScreen(),
                                      ),
                                ),
                                ActionChip(
                                  label: const Text(
                                    'Link NCR',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  avatar: const Icon(
                                    Icons.assignment_late,
                                    size: 14,
                                  ),
                                  onPressed:
                                      () => UIUtils.showSideSheet(
                                        context: context,
                                        title: 'Incidents Register',
                                        builder:
                                            (ctx) =>
                                                const IncidentsRegisterScreen(),
                                      ),
                                ),
                                ActionChip(
                                  label: const Text(
                                    'Link CAPA',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  avatar: const Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                  ),
                                  onPressed:
                                      () => UIUtils.showSideSheet(
                                        context: context,
                                        title: 'CAPA Management',
                                        builder: (ctx) => const CAPAScreen(),
                                      ),
                                ),
                              ],
                            ),
                            if (taskLinkedIncidents.isNotEmpty ||
                                taskLinkedCapas.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                  ),
                                ),
                                child: const Text(
                                  'Linked items will appear here...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final projectAsync = ref.read(
                                    projectProvider(projectId),
                                  );
                                  final project = projectAsync.value;
                                  if (project != null) {
                                    final updatedTasks =
                                        project.tasks
                                            .map(
                                              (t) => t.id == task.id ? task : t,
                                            )
                                            .toList();
                                    final updatedProject = project.copyWith(
                                      tasks: updatedTasks,
                                    );
                                    await ref
                                        .read(projectServiceProvider)
                                        .updateProject(updatedProject);
                                  }
                                },
                                child: const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
