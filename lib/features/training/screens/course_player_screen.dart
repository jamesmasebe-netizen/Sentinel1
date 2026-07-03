import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../../../core/providers/app_providers.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class CoursePlayerScreen extends ConsumerStatefulWidget {
  final Course course;
  final Enrollment? enrollment;

  const CoursePlayerScreen({super.key, required this.course, this.enrollment});

  @override
  ConsumerState<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends ConsumerState<CoursePlayerScreen> {
  bool _isLoading = false;

  Future<void> _markComplete() async {
    setState(() => _isLoading = true);
    try {
      final firestore = ref.read(firestoreProvider);
      final profile = ref.read(userProfileProvider).valueOrNull;

      if (profile == null) throw Exception('Not logged in');

      if (widget.enrollment != null) {
        await firestore
            .tenantCollection(
              ref.watch(currentTenantIdProvider) ?? "",
              'enrollments',
            )
            .doc(widget.enrollment!.id)
            .update({'progressPercentage': 1.0, 'status': 'Completed'});
      } else {
        await firestore
            .tenantCollection(
              ref.watch(currentTenantIdProvider) ?? "",
              'enrollments',
            )
            .add({
              'courseId': widget.course.id,
              'employeeId': profile.uid,
              'progressPercentage': 1.0,
              'status': 'Completed',
              'enrollmentDate': DateTime.now().toIso8601String(),
            });
      }

      if (mounted) {
        UIUtils.showToast(context, 'Course marked as completed!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(
          context,
          'Error marking course complete: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player Placeholder
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Colors.white.withAlpha(200),
                      ),
                      GSpacing.vMd,
                      Text(
                        'Video Player Placeholder',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GSpacing.vLg,
            Text(
              widget.course.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            GSpacing.vSm,
            Row(
              children: [
                Icon(Icons.person, size: 16, color: theme.colorScheme.primary),
                GSpacing.hSm,
                Text(
                  'Instructor: ${widget.course.instructorId}',
                  style: theme.textTheme.bodyMedium,
                ),
                GSpacing.hLg,
                Icon(Icons.timer, size: 16, color: theme.colorScheme.primary),
                GSpacing.hSm,
                Text(
                  '${widget.course.durationMinutes} mins',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            GSpacing.vLg,
            Text(
              'About this course',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            GSpacing.vMd,
            Text(widget.course.description, style: theme.textTheme.bodyLarge),
            GSpacing.vXl,
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _markComplete,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Mark Complete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
