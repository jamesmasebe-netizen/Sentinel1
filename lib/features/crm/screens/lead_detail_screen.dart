import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/crm_models.dart';
import '../providers/crm_providers.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/lead_to_cash_bpf.dart';
import '../../../core/bpf/bpf_orchestrator.dart';
import '../../../core/bpf/bpf_service.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:go_router/go_router.dart';
import 'opportunity_detail_screen.dart';

class LeadDetailScreen extends ConsumerWidget {
  final String leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsyncValue = ref.watch(leadStreamProvider(leadId));

    return Scaffold(
      body: leadAsyncValue.when(
        data: (lead) {
          if (lead == null) {
            return const Center(child: Text('Lead not found'));
          }

          final fullName = '${lead.firstName} ${lead.lastName}'.trim();
          final displayName = fullName.isNotEmpty ? fullName : 'Unnamed Lead';

          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text(displayName),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Implement edit
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BpfRibbonWidget(
                        bpfTypeId: 'lead_to_cash',
                        recordType: 'leadId',
                        recordId: lead.id,
                        definition: leadToCashDefinition,
                      ),
                      _buildOverviewCard(context, lead),
                      const SizedBox(height: 16),
                      if (lead.aiLeadScore > 0) ...[
                        _buildAiScoreCard(context, lead),
                        const SizedBox(height: 16),
                      ],
                      _buildDetailsCard(context, lead),
                      const SizedBox(height: 24),
                      Text(
                        'Activity History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildActivityHistory(context, lead),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed:
                              lead.isConverted
                                  ? null
                                  : () async {
                                      try {
                                        final orchestrator = ref.read(bpfOrchestratorProvider);
                                        final bpfService = ref.read(bpfServiceProvider);
                                        String? bpfId;
                                        final bpfs = await bpfService.streamBpfInstancesByRecord('leadId', lead.id).first;
                                        if (bpfs.isNotEmpty) {
                                          bpfId = bpfs.first.id;
                                        } else {
                                          bpfId = await bpfService.startBpf('lead_to_cash', 'lead', 'leadId', lead.id);
                                        }
                                        final oppId = await orchestrator.convertLeadToOpportunity(lead, bpfId);
                                        if (context.mounted) {
                                          UIUtils.showToast(context, 'Lead converted successfully');
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => OpportunityDetailScreen(opportunityId: oppId),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          UIUtils.showToast(context, 'Error converting lead: $e');
                                        }
                                      }
                                    },
                          icon: const Icon(Icons.transform),
                          label: Text(
                            lead.isConverted
                                ? 'Already Converted'
                                : 'Convert Lead',
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, Lead lead) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Company',
                    lead.company.isNotEmpty ? lead.company : 'N/A',
                    Icons.business,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Status',
                    lead.status,
                    Icons.flag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Rating',
                    lead.rating,
                    Icons.star_rate,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Lead Source',
                    lead.leadSource.isNotEmpty ? lead.leadSource : 'Unknown',
                    Icons.source,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiScoreCard(BuildContext context, Lead lead) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.secondary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Lead Score',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: lead.aiLeadScore / 100,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${lead.aiLeadScore.toInt()}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Lead lead) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(
              context,
              'Email',
              lead.email.isNotEmpty ? lead.email : 'N/A',
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Phone',
              lead.phone.isNotEmpty ? lead.phone : 'N/A',
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Owner ID',
              lead.ownerId.isNotEmpty ? lead.ownerId : 'Unassigned',
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Is Converted',
              lead.isConverted ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHistory(BuildContext context, Lead lead) {
    // Placeholder timeline
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTimelineItem(
              context,
              'Lead Created',
              lead.createdAt != null
                  ? DateFormat.yMMMd().add_jm().format(lead.createdAt!)
                  : 'Unknown',
              Icons.person_add,
              isFirst: true,
            ),
            if (lead.updatedAt != null && lead.updatedAt != lead.createdAt)
              _buildTimelineItem(
                context,
                'Lead Updated',
                DateFormat.yMMMd().add_jm().format(lead.updatedAt!),
                Icons.update,
                isLast: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    String time,
    IconData icon, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 2,
              height: 16,
              color:
                  isFirst
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.outlineVariant,
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            Container(
              width: 2,
              height: 24,
              color:
                  isLast
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
