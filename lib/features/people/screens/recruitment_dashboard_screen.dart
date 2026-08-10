import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/hr_models.dart';
import '../providers/hr_providers.dart';
import '../services/hr_service.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import 'job_requisitions_screen.dart';

class RecruitmentDashboardScreen extends ConsumerStatefulWidget {
  const RecruitmentDashboardScreen({super.key});

  @override
  ConsumerState<RecruitmentDashboardScreen> createState() =>
      _RecruitmentDashboardScreenState();
}

class _RecruitmentDashboardScreenState
    extends ConsumerState<RecruitmentDashboardScreen> {
  String? _selectedRequisitionId;
  JobRequisition? _selectedRequisition;

  final List<String> _stages = [
    'Applied',
    'Screening',
    'Interview',
    'Offer',
    'Hired',
    'Rejected',
  ];

  Future<void> _updateCandidateStage(
    Candidate candidate,
    String newStage,
  ) async {
    if (candidate.stage == newStage) return;

    await ref
        .read(firestoreProvider)
        .tenantCollection(
          ref.watch(currentTenantIdProvider) ?? "",
          'candidates',
        )
        .doc(candidate.id)
        .update({'stage': newStage});
  }

  Future<void> _convertApplication(JobApplication application) async {
    final requisition = _selectedRequisition;
    if (requisition == null) return;
    try {
      await ref.read(hrServiceProvider).convertApplicationToCandidate(
            application,
            requisitionId: requisition.id,
            department: requisition.department,
          );
      if (mounted) {
        UIUtils.showToast(context, 'Converted to candidate', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error converting application: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requisitionsAsync = ref.watch(jobRequisitionsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recruitment Dashboard'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JobRequisitionsScreen()),
              ),
              icon: const Icon(Icons.list_alt, color: Colors.white),
              label: const Text('Requisitions', style: TextStyle(color: Colors.white)),
            ),
          ],
          bottom: _selectedRequisitionId == null
              ? null
              : const TabBar(
                  tabs: [
                    Tab(text: 'Pipeline'),
                    Tab(text: 'Applications Inbox'),
                  ],
                ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: requisitionsAsync.when(
                data: (requisitions) {
                  if (requisitions.isEmpty) {
                    return const Text('No open requisitions.');
                  }
                  // Auto-select first if none selected
                  if (_selectedRequisitionId == null && requisitions.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedRequisitionId = requisitions.first.id;
                        _selectedRequisition = requisitions.first;
                      });
                    });
                  }
                  return DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select Job Requisition'),
                    value: _selectedRequisitionId,
                    items:
                        requisitions.map((req) {
                          return DropdownMenuItem(
                            value: req.id,
                            child: Text('${req.title} (${req.department})'),
                          );
                        }).toList(),
                    onChanged: (val) {
                      JobRequisition? matched;
                      for (final r in requisitions) {
                        if (r.id == val) {
                          matched = r;
                          break;
                        }
                      }
                      setState(() {
                        _selectedRequisitionId = val;
                        _selectedRequisition = matched;
                      });
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('Error: $err'),
              ),
            ),
            Expanded(
              child: _selectedRequisitionId == null
                  ? const Center(child: Text('Please select a requisition.'))
                  : TabBarView(
                      children: [
                        _buildKanbanBoard(),
                        _buildApplicationsInbox(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanBoard() {
    final candidatesAsync = ref.watch(
      candidatesProvider(_selectedRequisitionId!),
    );

    return candidatesAsync.when(
      data: (candidates) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                _stages.map((stage) {
                  final stageCandidates =
                      candidates.where((c) => c.stage == stage).toList();
                  return _buildKanbanColumn(stage, stageCandidates);
                }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildKanbanColumn(String stage, List<Candidate> candidates) {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade700,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8.0),
              ),
            ),
            child: Text(
              '$stage (${candidates.length})',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: DragTarget<Candidate>(
              onAcceptWithDetails: (details) {
                _updateCandidateStage(details.data, stage);
              },
              builder: (context, candidateData, rejectedData) {
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    return Draggable<Candidate>(
                      data: candidate,
                      feedback: Material(
                        elevation: 4.0,
                        child: Container(
                          width: 234,
                          padding: const EdgeInsets.all(12.0),
                          color: Colors.white,
                          child: Text(
                            candidate.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: _buildCandidateCard(candidate),
                      ),
                      child: _buildCandidateCard(candidate),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(Candidate candidate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              candidate.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              candidate.email,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Applied: ${candidate.appliedDate.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsInbox() {
    final applicationsAsync = ref.watch(
      jobApplicationsProvider(_selectedRequisitionId!),
    );

    return applicationsAsync.when(
      data: (applications) {
        final pending = applications.where((a) => a.status != 'Converted').toList();
        if (pending.isEmpty) {
          return const Center(child: Text('No pending applications for this requisition.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final application = pending[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(application.applicantName),
                subtitle: Text(
                  '${application.email}${application.phone.isNotEmpty ? ' • ${application.phone}' : ''}\n'
                  'Applied: ${application.appliedAt.toLocal().toString().split(' ')[0]}',
                ),
                isThreeLine: true,
                trailing: FilledButton(
                  onPressed: () => _convertApplication(application),
                  child: const Text('Convert to Candidate'),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
