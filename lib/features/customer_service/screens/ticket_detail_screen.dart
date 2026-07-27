import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/customer_service_models.dart';
import '../services/customer_service_service.dart';

final ticketMessagesStreamProvider =
    StreamProvider.family<List<TicketMessage>, String>((ref, ticketId) {
      final service = ref.watch(customerServiceServiceProvider);
      return service.streamTicketMessages(ticketId);
    });

final ticketSlaStreamProvider =
    StreamProvider.family<List<SlaInstance>, String>((ref, ticketId) {
      final service = ref.watch(customerServiceServiceProvider);
      return service.streamSlaInstances(ticketId);
    });

final ticketFutureProvider = FutureProvider.family<Ticket?, String>((
  ref,
  ticketId,
) {
  final service = ref.watch(customerServiceServiceProvider);
  return service.getTicket(ticketId);
});

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketFutureProvider(ticketId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket Details - $ticketId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(ticketFutureProvider(ticketId));
            },
          ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (ticket) {
          if (ticket == null) {
            return const Center(child: Text('Ticket not found'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildPropertiesPanel(context, ticket),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(flex: 4, child: _buildMessagesPanel(context, ref)),
                    const VerticalDivider(width: 1),
                    Expanded(flex: 2, child: _buildSlaPanel(context, ref)),
                  ],
                );
              } else {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPropertiesPanel(context, ticket),
                      const Divider(),
                      SizedBox(
                        height: 500,
                        child: _buildMessagesPanel(context, ref),
                      ),
                      const Divider(),
                      SizedBox(
                        height: 400,
                        child: _buildSlaPanel(context, ref),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildPropertiesPanel(BuildContext context, Ticket ticket) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          ticket.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'Ticket Information',
          children: [
            _buildDetailRow('Status', ticket.status),
            _buildDetailRow('Priority', ticket.priority),
            _buildDetailRow('Severity', ticket.severity),
            _buildDetailRow('Channel', ticket.channel),
            _buildDetailRow('Assigned To', ticket.assignedTo ?? 'Unassigned'),
            if (ticket.resolutionType != null)
              _buildDetailRow('Resolution', ticket.resolutionType!),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'Dates & Times',
          children: [
            _buildDetailRow(
              'Created At',
              ticket.createdAt != null
                  ? dateFormat.format(ticket.createdAt!)
                  : 'N/A',
            ),
            _buildDetailRow(
              'Updated At',
              ticket.updatedAt != null
                  ? dateFormat.format(ticket.updatedAt!)
                  : 'N/A',
            ),
            _buildDetailRow(
              'Resolved At',
              ticket.resolvedAt != null
                  ? dateFormat.format(ticket.resolvedAt!)
                  : 'N/A',
            ),
            _buildDetailRow(
              'Closed At',
              ticket.closedAt != null
                  ? dateFormat.format(ticket.closedAt!)
                  : 'N/A',
            ),
          ],
        ),
        if (ticket.description != null && ticket.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            title: 'Description',
            children: [Text(ticket.description!)],
          ),
        ],
        if (ticket.copilotSummary != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            title: 'Copilot Summary',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ticket.copilotSummary!)),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMessagesPanel(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(ticketMessagesStreamProvider(ticketId));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey.shade50,
          width: double.infinity,
          child: const Text(
            'Messages Stream',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(child: Text('No messages yet.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isAgent =
                      message.senderType == 'Agent' ||
                      message.senderType == 'System';
                  return Align(
                    alignment:
                        isAgent ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color:
                            isAgent
                                ? Colors.blue.shade50
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isAgent
                                  ? Colors.blue.shade200
                                  : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAgent ? Icons.support_agent : Icons.person,
                                size: 16,
                                color:
                                    isAgent
                                        ? Colors.blue
                                        : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                message.senderType,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color:
                                      isAgent
                                          ? Colors.blue
                                          : Colors.grey.shade800,
                                ),
                              ),
                              if (message.timestamp != null) ...[
                                const Spacer(),
                                Text(
                                  DateFormat(
                                    'HH:mm',
                                  ).format(message.timestamp!),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(message.content ?? ''),
                          if (message.sentimentScore != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Sentiment: ${message.sentimentScore!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    message.sentimentScore! > 0.5
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Reply...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    // Send message action
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlaPanel(BuildContext context, WidgetRef ref) {
    final slaAsync = ref.watch(ticketSlaStreamProvider(ticketId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          color: Colors.grey.shade50,
          child: const Text(
            'SLA KPI Instances',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: slaAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (slas) {
              if (slas.isEmpty) {
                return const Center(child: Text('No SLAs for this ticket.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: slas.length,
                itemBuilder: (context, index) {
                  final sla = slas[index];
                  Color statusColor = Colors.grey;
                  if (sla.status == 'In Progress') statusColor = Colors.blue;
                  if (sla.status == 'Warning') statusColor = Colors.orange;
                  if (sla.status == 'Failed') statusColor = Colors.red;
                  if (sla.status == 'Succeeded') statusColor = Colors.green;

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sla.kpiType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  sla.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: statusColor,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (sla.failureTime != null)
                            _buildDetailRow(
                              'Failure Time',
                              DateFormat(
                                'MMM dd, HH:mm',
                              ).format(sla.failureTime!),
                            ),
                          if (sla.warningTime != null)
                            _buildDetailRow(
                              'Warning Time',
                              DateFormat(
                                'MMM dd, HH:mm',
                              ).format(sla.warningTime!),
                            ),
                          if (sla.succeededOn != null)
                            _buildDetailRow(
                              'Succeeded On',
                              DateFormat(
                                'MMM dd, HH:mm',
                              ).format(sla.succeededOn!),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
