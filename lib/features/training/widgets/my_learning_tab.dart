import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/course.dart';
import '../providers/training_providers.dart';
import '../screens/course_player_screen.dart';

class MyLearningTab extends ConsumerWidget {
  const MyLearningTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(enrollmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);

    return enrollmentsAsync.when(
      data: (enrollments) {
        if (enrollments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 64, color: Theme.of(context).disabledColor),
                GSpacing.vLg,
                Text('You are not enrolled in any courses yet.', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          );
        }

        return coursesAsync.when(
          data: (courses) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: enrollments.length,
              itemBuilder: (context, index) {
                final enrollment = enrollments[index];
                final course = courses.firstWhere(
                  (c) => c.id == enrollment.courseId, 
                  orElse: () => Course(id: '', title: 'Unknown Course', description: '', instructorId: '', category: '', contentUrl: '', durationMinutes: 0)
                );

                return GCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoursePlayerScreen(course: course, enrollment: enrollment),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              course.thumbnailUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80, height: 80,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          GSpacing.hLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                GSpacing.vSm,
                                Text(
                                  'Status: ${enrollment.status}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                GSpacing.vMd,
                                LinearProgressIndicator(
                                  value: enrollment.progressPercentage,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  color: enrollment.progressPercentage == 1.0 ? XMTheme.success : Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                          GSpacing.hMd,
                          Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error loading courses: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading enrollments: $e')),
    );
  }
}
