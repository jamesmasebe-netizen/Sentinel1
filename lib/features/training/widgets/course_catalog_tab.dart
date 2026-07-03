import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../providers/training_providers.dart';
import '../screens/course_player_screen.dart';

class CourseCatalogTab extends ConsumerWidget {
  const CourseCatalogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books, size: 64, color: Theme.of(context).disabledColor),
                GSpacing.vLg,
                Text('No courses available in the catalog.', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 500 ? 3 : 2;
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return GCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            course.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              GSpacing.vSm,
                              Text(
                                course.instructorId,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: FilledButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CoursePlayerScreen(course: course),
                                      ),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  child: const Text('Start Course', style: TextStyle(fontSize: 12)),
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
          }
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading catalog: $e')),
    );
  }
}
