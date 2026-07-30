import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pmo_models.dart';
import '../../../core/providers/app_providers.dart';

import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

final pmoServiceProvider = Provider<PmoService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final tenantId = ref.watch(currentTenantIdProvider) ?? "";
  return PmoService(firestore, tenantId);
});

class PmoService {
  final FirebaseFirestore _firestore;
  final String _tenantId;

  PmoService(this._firestore, this._tenantId);

  // --- Project CRUD ---
  Future<void> createProject(Project project) async {
    await _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(project.projectId)
        .set(project.toJson());
  }

  Future<Project?> getProject(String projectId) async {
    final doc = await _firestore.tenantCollection(_tenantId, 'projects').doc(projectId).get();
    if (!doc.exists) return null;
    return Project.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateProject(Project project) async {
    await _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(project.projectId)
        .update(project.toJson());
  }

  Future<void> deleteProject(String projectId) async {
    await _firestore.tenantCollection(_tenantId, 'projects').doc(projectId).delete();
  }

  Stream<List<Project>> streamProjects() {
    return _firestore
        .tenantCollection(_tenantId, 'projects')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Project.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  Stream<Project?> streamProject(String projectId) {
    return _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(projectId)
        .snapshots()
        .map(
          (doc) => doc.exists ? Project.fromJson(doc.data()!, doc.id) : null,
        );
  }

  // --- WbsTask CRUD ---
  Future<void> createWbsTask(String projectId, WbsTask task) async {
    await _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(projectId)
        .collection('wbs')
        .doc(task.taskId)
        .set(task.toJson());
  }

  Future<WbsTask?> getWbsTask(String projectId, String taskId) async {
    final doc =
        await _firestore
            .tenantCollection(_tenantId, 'projects')
            .doc(projectId)
            .collection('wbs')
            .doc(taskId)
            .get();
    if (!doc.exists) return null;
    return WbsTask.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateWbsTask(String projectId, WbsTask task) async {
    await _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(projectId)
        .collection('wbs')
        .doc(task.taskId)
        .update(task.toJson());
  }

  Future<void> deleteWbsTask(String projectId, String taskId) async {
    await _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(projectId)
        .collection('wbs')
        .doc(taskId)
        .delete();
  }

  Stream<List<WbsTask>> streamWbsTasks(String projectId) {
    return _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(projectId)
        .collection('wbs')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => WbsTask.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  Stream<WbsTask?> streamWbsTask(String projectId, String taskId) {
    return _firestore
        .tenantCollection(_tenantId, 'projects')
        .doc(projectId)
        .collection('wbs')
        .doc(taskId)
        .snapshots()
        .map(
          (doc) => doc.exists ? WbsTask.fromJson(doc.data()!, doc.id) : null,
        );
  }

  // --- TimeEntry CRUD ---
  Future<void> createTimeEntry(TimeEntry entry) async {
    await _firestore
        .tenantCollection(_tenantId, 'time_entries')
        .doc(entry.entryId)
        .set(entry.toJson());
  }

  Future<TimeEntry?> getTimeEntry(String entryId) async {
    final doc = await _firestore.tenantCollection(_tenantId, 'time_entries').doc(entryId).get();
    if (!doc.exists) return null;
    return TimeEntry.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateTimeEntry(TimeEntry entry) async {
    await _firestore
        .tenantCollection(_tenantId, 'time_entries')
        .doc(entry.entryId)
        .update(entry.toJson());
  }

  Future<void> deleteTimeEntry(String entryId) async {
    await _firestore.tenantCollection(_tenantId, 'time_entries').doc(entryId).delete();
  }

  Stream<List<TimeEntry>> streamTimeEntriesForProject(String projectId) {
    return _firestore
        .tenantCollection(_tenantId, 'time_entries')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TimeEntry.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  // --- Expense CRUD ---
  Future<void> createExpense(Expense expense) async {
    await _firestore
        .tenantCollection(_tenantId, 'expenses')
        .doc(expense.expenseId)
        .set(expense.toJson());
  }

  Future<Expense?> getExpense(String expenseId) async {
    final doc = await _firestore.tenantCollection(_tenantId, 'expenses').doc(expenseId).get();
    if (!doc.exists) return null;
    return Expense.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateExpense(Expense expense) async {
    await _firestore
        .tenantCollection(_tenantId, 'expenses')
        .doc(expense.expenseId)
        .update(expense.toJson());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _firestore.tenantCollection(_tenantId, 'expenses').doc(expenseId).delete();
  }

  Stream<List<Expense>> streamExpensesForProject(String projectId) {
    return _firestore
        .tenantCollection(_tenantId, 'expenses')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Expense.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  // --- Actual CRUD ---
  Future<void> createActual(Actual actual) async {
    await _firestore
        .tenantCollection(_tenantId, 'actuals')
        .doc(actual.actualId)
        .set(actual.toJson());
  }

  Future<Actual?> getActual(String actualId) async {
    final doc = await _firestore.tenantCollection(_tenantId, 'actuals').doc(actualId).get();
    if (!doc.exists) return null;
    return Actual.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateActual(Actual actual) async {
    await _firestore
        .tenantCollection(_tenantId, 'actuals')
        .doc(actual.actualId)
        .update(actual.toJson());
  }

  Future<void> deleteActual(String actualId) async {
    await _firestore.tenantCollection(_tenantId, 'actuals').doc(actualId).delete();
  }

  Stream<List<Actual>> streamActualsForProject(String projectId) {
    return _firestore
        .tenantCollection(_tenantId, 'actuals')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Actual.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }
}
