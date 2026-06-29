import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../models/project_models.dart';
import '../../../core/models/safety_models.dart';

/// Provider for the Projects collection reference
final projectsCollectionProvider = Provider<CollectionReference<Project>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('projects').withConverter<Project>(
        fromFirestore: (snapshot, _) => Project.fromFirestore(snapshot),
        toFirestore: (project, _) => project.toFirestore(),
      );
});

/// Stream of all projects for the current site
final projectsProvider = StreamProvider<List<Project>>((ref) {
  final siteId = ref.watch(currentSiteIdProvider);
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

/// Provider to calculate auto-risk level based on safety score and open NCRs
final projectRiskLevelProvider = Provider.family<String, Project>((ref, project) {
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

  ProjectService(this._firestore);

  Future<void> updateProject(Project project) async {
    await _firestore.collection('projects').doc(project.id).set(
          project.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// Evaluates compliance locks and approves a stage if valid
  Future<void> approveStage(String projectId, String stageId, String approverId) async {
    final doc = await _firestore.collection('projects').doc(projectId).get();
    if (!doc.exists) return;

    final project = Project.fromFirestore(doc);

    final stageIndex = project.stages.indexWhere((s) => s.id == stageId);
    if (stageIndex == -1) return;

    final stage = project.stages[stageIndex];

    // Compliance Check
    if (stage.requiresSafetyClearance) {
       // e.g., Requires Safety Score > 75 and 0 Critical NCRs
       if (project.safetyFileScore < 75.0) {
         throw Exception("Safety clearance failed. The Contractor Safety File Score (${project.safetyFileScore}) is below 75.");
       }
       if (project.totalNcrs > 0) {
         throw Exception("Safety clearance failed. There are open NCRs on this project.");
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
    await _firestore.collection('projects').doc(projectId).update({
      'stages': updatedStages.map((s) => s.toMap()).toList(),
    });
  }

  /// Triggers a cross-module Action Item if a critical threshold is breached
  Future<void> triggerSafetyActionItem(Project project, String title, String description) async {
    final actionItem = ActionItem(
      siteId: project.siteId,
      title: 'URGENT: $title',
      description: 'Project: ${project.name} (ID: ${project.id})\n\n$description',
      priority: 'critical',
      source: 'project',
      sourceId: project.id,
      dueDate: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now(),
    );

    await _firestore.collection('actionItems').add(actionItem.toFirestore());
  }
}

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(ref.watch(firestoreProvider));
});
