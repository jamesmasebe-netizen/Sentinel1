import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pmo_models.dart';
import '../services/pmo_service.dart';

final pmoProjectStreamProvider = StreamProvider.family<Project?, String>((
  ref,
  projectId,
) {
  return ref.watch(pmoServiceProvider).streamProject(projectId);
});

final pmoWbsTasksStreamProvider = StreamProvider.family<List<WbsTask>, String>((
  ref,
  projectId,
) {
  return ref.watch(pmoServiceProvider).streamWbsTasks(projectId);
});

final pmoWbsTaskStreamProvider =
    StreamProvider.family<WbsTask?, ({String projectId, String taskId})>((
      ref,
      args,
    ) {
      return ref
          .watch(pmoServiceProvider)
          .streamWbsTask(args.projectId, args.taskId);
    });

final pmoTimeEntriesStreamProvider =
    StreamProvider.family<List<TimeEntry>, String>((ref, projectId) {
      return ref
          .watch(pmoServiceProvider)
          .streamTimeEntriesForProject(projectId);
    });

final pmoExpensesStreamProvider = StreamProvider.family<List<Expense>, String>((
  ref,
  projectId,
) {
  return ref.watch(pmoServiceProvider).streamExpensesForProject(projectId);
});
