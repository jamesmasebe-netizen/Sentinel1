import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../models/hr_models.dart';
import '../providers/hr_providers.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class RecruitmentDashboardScreen extends ConsumerStatefulWidget {
  const RecruitmentDashboardScreen({super.key});

  @override
  ConsumerState<RecruitmentDashboardScreen> createState() =>
      _RecruitmentDashboardScreenState();
}

class _RecruitmentDashboardScreenState
    extends ConsumerState<RecruitmentDashboardScreen> {
  String? _selectedRequisitionId;

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

  @override
  Widget build(BuildContext context) {
    final requisitionsAsync = ref.watch(jobRequisitionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recruitment Dashboard')),
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
                    setState(() {
                      _selectedRequisitionId = val;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
            ),
          ),
          Expanded(
            child:
                _selectedRequisitionId == null
                    ? const Center(child: Text('Please select a requisition.'))
                    : _buildKanbanBoard(),
          ),
        ],
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
}
