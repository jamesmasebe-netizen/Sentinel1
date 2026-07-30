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
    return _TicketMessagesPanel(ticketId: ticketId);
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

// ---------------------------------------------------------------------------
// Chat UI Integration
// ---------------------------------------------------------------------------

class _TicketMessagesPanel extends ConsumerStatefulWidget {
  final String ticketId;
  const _TicketMessagesPanel({required this.ticketId});

  @override
  ConsumerState<_TicketMessagesPanel> createState() => _TicketMessagesPanelState();
}

class _TicketMessagesPanelState extends ConsumerState<_TicketMessagesPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(customerServiceServiceProvider);
      await service.createTicketMessage(
        widget.ticketId,
        TicketMessage(
          id: '',
          content: text,
          senderType: 'Agent',
          timestamp: DateTime.now(),
        ),
      );
      _controller.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(ticketMessagesStreamProvider(widget.ticketId));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0D2B), // deep navy
            Color(0xFF1A0938), // dark purple
            Color(0xFF0D0D2B),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white.withOpacity(0.05),
            width: double.infinity,
            child: const Text(
              'Ticket Conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.', style: TextStyle(color: Colors.white54)));
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _ChatBubble(message: message);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text input row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Type a reply…',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.white38, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isLoading ? null : _sendMessage,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B5EEA), Color(0xFF5C3BC4)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final isAgent = message.senderType == 'Agent' || message.senderType == 'System';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isAgent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAgent) ...[
            _avatar('CU', const Color(0xFF3F51B5)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAgent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isAgent)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(message.senderType, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  decoration: BoxDecoration(
                    gradient: isAgent
                        ? const LinearGradient(colors: [Color(0xFF6C3FC4), Color(0xFF5C3BC4)])
                        : null,
                    color: isAgent ? null : Colors.white.withOpacity(0.09),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isAgent ? 16 : 4),
                      bottomRight: Radius.circular(isAgent ? 4 : 16),
                    ),
                    border: isAgent ? null : Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Text(
                    message.content ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    message.timestamp != null ? DateFormat('HH:mm').format(message.timestamp!) : '',
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (isAgent) ...[
            const SizedBox(width: 8),
            _avatar('ME', const Color(0xFF6C3FC4)),
          ],
        ],
      ),
    );
  }

  Widget _avatar(String initials, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(initials,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
