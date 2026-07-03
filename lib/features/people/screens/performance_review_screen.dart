import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/hr_models.dart';
import '../providers/hr_providers.dart';
import '../widgets/employee_selector.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class PerformanceReviewScreen extends ConsumerWidget {
  const PerformanceReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceReviewsAsync = ref.watch(performanceReviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('360 Performance Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New 360 Review',
            onPressed: () {
              UIUtils.showSideSheet(
                context: context,
                title: 'New Performance Review',
                builder: (ctx) => const _PerformanceReviewForm(),
              );
            },
          ),
        ],
      ),
      body: performanceReviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return const Center(child: Text('No performance reviews found.'));
          }
          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Review for Employee: ${review.employeeId}'),
                  subtitle: Text(
                    'Score: ${review.score.toStringAsFixed(1)}/5.0\nPeriod: ${review.reviewPeriod}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.star),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading reviews: $e')),
      ),
    );
  }
}

class _PerformanceReviewForm extends ConsumerStatefulWidget {
  const _PerformanceReviewForm();

  @override
  ConsumerState<_PerformanceReviewForm> createState() =>
      _PerformanceReviewFormState();
}

class _PerformanceReviewFormState
    extends ConsumerState<_PerformanceReviewForm> {
  final _formKey = GlobalKey<FormState>();
  String? _employeeId;
  String? _reviewerId;
  String _reviewPeriod = 'Q3 2026';
  double _score = 3.0;
  String _feedback = '';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_employeeId == null || _reviewerId == null) {
      UIUtils.showToast(
        context,
        'Please select both employee and reviewer',
        type: ToastType.error,
      );
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final siteId = ref.read(currentTenantIdProvider);
      if (siteId == null) throw Exception('No site ID found');

      final docRef =
          FirebaseFirestore.instance
              .tenantCollection(
                ref.watch(currentTenantIdProvider) ?? "",
                'performance_reviews',
              )
              .doc();

      final review = PerformanceReview(
        id: docRef.id,
        employeeId: _employeeId!,
        reviewerId: _reviewerId!,
        reviewPeriod: _reviewPeriod,
        score: _score,
        feedback: _feedback,
        completedDate: DateTime.now(),
        siteId: siteId,
      );

      await docRef.set(review.toFirestore());

      if (mounted) {
        UIUtils.showToast(
          context,
          'Review submitted successfully',
          type: ToastType.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(
          context,
          'Failed to submit review: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            EmployeeSelector(
              label: 'Employee Being Reviewed',
              value: _employeeId,
              onChanged: (val) {
                setState(() {
                  _employeeId = val;
                });
              },
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            EmployeeSelector(
              label: 'Reviewer',
              value: _reviewerId,
              onChanged: (val) {
                setState(() {
                  _reviewerId = val;
                });
              },
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Review Period',
                border: OutlineInputBorder(),
              ),
              initialValue: _reviewPeriod,
              validator:
                  (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => _reviewPeriod = val ?? '',
            ),
            const SizedBox(height: 16),
            Text(
              'Score: ${_score.toStringAsFixed(1)} / 5.0',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _score,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              label: _score.toStringAsFixed(1),
              onChanged: (val) {
                setState(() {
                  _score = val;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator:
                  (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => _feedback = val ?? '',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
