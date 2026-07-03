import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/job_application_form.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';
import 'package:xm_system/core/providers/app_providers.dart';

class PublicCareersScreen extends ConsumerStatefulWidget {
  const PublicCareersScreen({super.key});

  @override
  ConsumerState<PublicCareersScreen> createState() =>
      _PublicCareersScreenState();
}

class _PublicCareersScreenState extends ConsumerState<PublicCareersScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentinel Careers'),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'Employee Login',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'job_requisitions',
                )
                .where('status', isEqualTo: 'Published')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final jobs = snapshot.data?.docs ?? [];

          if (jobs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No open positions at this time.'),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Text(
                        'Join Our Team',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Explore opportunities to build the future with us.',
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final job = jobs[index].data() as Map<String, dynamic>;
                  return Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    job['jobTitle'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      UIUtils.showSideSheet(
                                        context: context,
                                        title: 'Apply: ${job['jobTitle']}',
                                        builder:
                                            (ctx) => JobApplicationForm(
                                              jobId: jobs[index].id,
                                              jobTitle: job['jobTitle'],
                                            ),
                                      );
                                    },
                                    child: const Text('Apply Now'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${job['department'] ?? ''} • ${job['location'] ?? ''} • ${job['employmentType'] ?? ''}',
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Requirements:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(job['requirements'] ?? 'Not specified'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: jobs.length),
              ),
            ],
          );
        },
      ),
    );
  }
}
