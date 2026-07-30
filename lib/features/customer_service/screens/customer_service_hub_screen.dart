import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'knowledge_base_screen.dart';
import 'ticket_detail_screen.dart';
import '../widgets/ticket_form.dart';
import '../services/customer_service_service.dart';
import '../../../core/utils/ui_utils.dart';

class CustomerServiceHubScreen extends ConsumerWidget {
  const CustomerServiceHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Service Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Knowledge Base',
            onPressed: () {
              UIUtils.showSideSheet(
                context: context,
                title: 'Knowledge Base',
                builder: (_) => const KnowledgeBaseScreen(),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SLA Metrics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'First Response Time',
                    '15 mins',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Resolution Time',
                    '2.5 hours',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'CSAT Score',
                    '4.8/5.0',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'SLA Breach Risk',
                    '3 Tickets',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Open Cases',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ref.watch(ticketsProvider).when(
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return const Center(child: Text('No open cases.'));
                  }
                  return Card(
                    child: ListView.builder(
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: ticket.status == 'Resolved' ? Colors.green : Colors.red,
                            child: Icon(
                              ticket.status == 'Resolved' ? Icons.check : Icons.warning,
                              color: Colors.white,
                            ),
                          ),
                          title: Text('${ticket.ticketId} - ${ticket.title}'),
                          subtitle: Text('Status: ${ticket.status} • Priority: ${ticket.priority}'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              UIUtils.showSideSheet(
                                context: context,
                                title: 'Ticket Detail',
                                builder: (_) => TicketDetailScreen(ticketId: ticket.id),
                              );
                            },
                            child: const Text('View Ticket'),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'New Ticket',
            builder: (_) => const TicketForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
