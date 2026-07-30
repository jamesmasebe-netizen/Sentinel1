import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../models/project_models.dart';
import '../../../core/models/safety_models.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../../../core/bpf/bpf_service.dart';

/// Provider for the Projects collection reference
final projectsCollectionProvider = Provider<CollectionReference<Project>>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'projects')
      .withConverter<Project>(
        fromFirestore: (snapshot, _) => Project.fromFirestore(snapshot),
        toFirestore: (project, _) => project.toFirestore(),
      );
});

/// Stream of all projects for the current site
final projectsProvider = StreamProvider<List<Project>>((ref) {
  final siteId = ref.watch(currentTenantIdProvider);
  if (siteId == null) return const Stream.empty();

  final collection = ref.watch(projectsCollectionProvider);
  return collection
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

/// Stream of a specific project by ID
final projectProvider = StreamProvider.family<Project?, String>((ref, id) {
  final collection = ref.watch(projectsCollectionProvider);
  return collection.doc(id).snapshots().map((snapshot) {
    if (!snapshot.exists) return null;
    return snapshot.data();
  });
});

/// Stream of expenses for a specific project
final projectExpensesProvider =
    StreamProvider.family<List<ProjectExpense>, String>((ref, projectId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'expenses',
          )
          .where('projectId', isEqualTo: projectId)
          .orderBy('loggedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => ProjectExpense.fromFirestore(doc))
                    .toList(),
          );
    });

/// Provider to calculate auto-risk level based on safety score and open NCRs
final projectRiskLevelProvider = Provider.family<String, Project>((
  ref,
  project,
) {
  // Logic:
  // Safety Score < 50 OR Critical tasks -> Critical Risk
  // Safety Score 50-70 OR >2 Major NCRs -> High Risk
  // Safety Score 71-85 -> Medium Risk
  // Safety Score > 85 -> Low Risk

  if (project.safetyFileScore < 50.0 || project.totalNcrs >= 5) {
    return 'Critical';
  }

  if (project.safetyFileScore <= 70.0 || project.totalNcrs >= 2) {
    return 'High';
  }

  // Look at tasks
  final hasCriticalTasks = project.tasks.any((t) => t.riskLevel == 'Critical');
  final hasHighTasks = project.tasks.any((t) => t.riskLevel == 'High');

  if (hasCriticalTasks) return 'Critical';
  if (hasHighTasks) return 'High';

  if (project.safetyFileScore > 85.0 && project.totalNcrs == 0) {
    return 'Low';
  }

  return 'Medium'; // default fallback
});

/// Service class to manage Project business logic
class ProjectService {
  final FirebaseFirestore _firestore;
  final String _tenantId;
  final BpfService _bpfService;

  ProjectService(this._firestore, this._tenantId, this._bpfService);

  Future<void> updateProject(Project project) async {
    await _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(project.id)
        .set(project.toFirestore(), SetOptions(merge: true));
  }

  /// Generates a short, sequential project ID like PRJ-001, PRJ-002, etc.
  /// Uses a Firestore counter document to ensure uniqueness.
  Future<String> _generateProjectId() async {
    final counterRef = _firestore
        .tenantCollection(_tenantId, 'counters')
        .doc('projects');

    return _firestore.runTransaction<String>((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int nextNumber;
      if (!counterDoc.exists) {
        nextNumber = 1;
        transaction.set(counterRef, {'lastNumber': 1});
      } else {
        final lastNumber = counterDoc.data()?['lastNumber'] as int? ?? 0;
        nextNumber = lastNumber + 1;
        transaction.update(counterRef, {'lastNumber': nextNumber});
      }

      return 'PRJ-${nextNumber.toString().padLeft(3, '0')}';
    });
  }

  Future<String> createProject(Project project) async {
    final shortId = await _generateProjectId();
    await _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(shortId)
        .set(project.toFirestore());

    // F-008: start the project_lifecycle BPF instance so the ribbon has
    // something to render and approveStage() has an instance to mirror.
    if (project.stages.isNotEmpty) {
      await _bpfService.startBpf(
        'project_lifecycle',
        project.stages.first.id,
        'project',
        shortId,
      );
    }

    return shortId;
  }



  Future<void> addTimeEntry(ProjectTimeEntry entry) async {
    await _firestore
        .tenantCollection(_tenantId, 'timeEntries')
        .doc(entry.id)
        .set(entry.toFirestore());
  }

  /// Evaluates compliance locks and approves a stage if valid
  Future<void> approveStage(
    String projectId,
    String stageId,
    String approverId,
  ) async {
    final doc =
        await _firestore
            .tenantCollection(_tenantId, 'projects')
            .doc(projectId)
            .get();
    if (!doc.exists) return;

    final project = Project.fromFirestore(doc);

    final stageIndex = project.stages.indexWhere((s) => s.id == stageId);
    if (stageIndex == -1) return;

    final stage = project.stages[stageIndex];

    // Compliance Check
    if (stage.requiresSafetyClearance) {
      // e.g., Requires Safety Score > 75 and 0 Critical NCRs
      if (project.safetyFileScore < 75.0) {
        throw Exception(
          "Safety clearance failed. The Contractor Safety File Score (${project.safetyFileScore}) is below 75.",
        );
      }
      if (project.totalNcrs > 0) {
        throw Exception(
          "Safety clearance failed. There are open NCRs on this project.",
        );
      }
    }

    // Update Stage
    final updatedStages = List<ProjectStage>.from(project.stages);
    updatedStages[stageIndex] = ProjectStage(
      id: stage.id,
      stageName: stage.stageName,
      order: stage.order,
      status: 'Completed',
      approvedBy: approverId,
      approvedAt: DateTime.now(),
      requiresSafetyClearance: stage.requiresSafetyClearance,
    );

    // Update Project
    await _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(projectId)
        .update({'stages': updatedStages.map((s) => s.toMap()).toList()});

    // F-008: Advance BPF to mirror project stage
    try {
      final bpfQuery = await _firestore
          .tenantCollection(_tenantId, 'bpf_instances')
          .where('linkedRecordIds.project', isEqualTo: projectId)
          .limit(1)
          .get();

      if (bpfQuery.docs.isNotEmpty) {
        final bpfId = bpfQuery.docs.first.id;
        // BPF stage IDs map 1:1 to Project stage IDs (e.g. 'stage_0', 'stage_1')
        await _bpfService.advanceStage(bpfId, stageId);
      }
    } catch (e) {
      // Ignore BPF errors to not block the main project stage approval
    }
  }

  /// Triggers a cross-module Action Item if a critical threshold is breached
  Future<void> triggerSafetyActionItem(
    Project project,
    String title,
    String description,
  ) async {
    final actionItem = ActionItem(
      tenantId: project.tenantId,
      title: 'URGENT: $title',
      description:
          'Project: ${project.name} (ID: ${project.id})\n\n$description',
      priority: 'critical',
      source: 'project',
      sourceId: project.id,
      dueDate: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now(),
    );

    await _firestore
        .tenantCollection(_tenantId, 'actionItems')
        .add(actionItem.toFirestore());
  }

  /// Add a new expense and increment actual spend on the project atomically
  Future<void> addExpense(ProjectExpense expense) async {
    final expenseRef = _firestore.tenantCollection(_tenantId, 'expenses').doc();
    final projectRef = _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(expense.projectId);

    final expenseWithId = ProjectExpense(
      id: expenseRef.id,
      projectId: expense.projectId,
      tenantId: expense.tenantId,
      description: expense.description,
      amount: expense.amount,
      category: expense.category,
      loggedAt: expense.loggedAt,
      loggedBy: expense.loggedBy,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(expenseRef, expenseWithId.toFirestore());
      transaction.update(projectRef, {
        'actualSpend': FieldValue.increment(expense.amount),
      });
    });
  }

  /// Delete an expense and decrement actual spend on the project atomically
  Future<void> deleteExpense(
    String expenseId,
    String projectId,
    double amount,
  ) async {
    final expenseRef = _firestore
        .tenantCollection(_tenantId, 'expenses')
        .doc(expenseId);
    final projectRef = _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(projectId);

    await _firestore.runTransaction((transaction) async {
      transaction.delete(expenseRef);
      transaction.update(projectRef, {
        'actualSpend': FieldValue.increment(-amount),
      });
    });
  }
}

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(
    ref.watch(firestoreProvider),
    ref.watch(currentTenantIdProvider) ?? '',
    ref.watch(bpfServiceProvider),
  );
});

/// Fetches a project's linked risk assessments (HIRAs/DRAs)
final projectRiskAssessmentsProvider =
    StreamProvider.family<List<String>, String>((ref, projectId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'projects',
          )
          .doc(projectId)
          .collection('riskAssessments')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
    });

/// Fetches a project's linked contractors
final projectContractorsProvider = StreamProvider.family<List<String>, String>((
  ref,
  projectId,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'projects')
      .doc(projectId)
      .collection('contractors')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
});

/// Fetches a project's linked incidents
final projectIncidentsProvider = StreamProvider.family<List<String>, String>((
  ref,
  projectId,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'projects')
      .doc(projectId)
      .collection('incidents')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
});

/// Fetches a project's linked CAPAs
final projectCapasProvider = StreamProvider.family<List<String>, String>((
  ref,
  projectId,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'projects')
      .doc(projectId)
      .collection('capas')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
});

/// Fetches a project's task dependencies
final projectDependenciesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'projects',
          )
          .doc(projectId)
          .collection('taskDependencies')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
          );
    });

/// Fetches a project's task linked Risks
final projectLinkedRisksProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'projects',
          )
          .doc(projectId)
          .collection('taskLinkedRisks')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
          );
    });

/// Fetches a project's linked NCRs
final projectLinkedNcrsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'projects',
          )
          .doc(projectId)
          .collection('taskLinkedNcrs')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
          );
    });

/// Fetches a project's linked Incidents
final projectLinkedIncidentsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'projects',
          )
          .doc(projectId)
          .collection('taskLinkedIncidents')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
          );
    });

/// Fetches a project's linked CAPAs
final projectLinkedCapasProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'projects',
          )
          .doc(projectId)
          .collection('taskLinkedCapas')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
          );
    });
