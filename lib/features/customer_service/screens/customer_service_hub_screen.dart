import 'package:flutter/material.dart';
import 'omnichannel_ticket_screen.dart';
import 'knowledge_base_screen.dart';

class CustomerServiceHubScreen extends StatelessWidget {
  const CustomerServiceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Service Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum),
            tooltip: 'Omnichannel Ticketing',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OmnichannelTicketScreen(),
                  ),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Knowledge Base',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KnowledgeBaseScreen(),
                  ),
                ),
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
              child: Card(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            index % 3 == 0 ? Colors.red : Colors.green,
                        child: Icon(
                          index % 3 == 0 ? Icons.warning : Icons.check,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Case #${1000 + index} - Issue with ${['Login', 'Billing', 'App Crash'][index % 3]}',
                      ),
                      subtitle: Text(
                        'Opened ${index + 1} hours ago • Assigned to Tier ${index % 2 + 1}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OmnichannelTicketScreen(),
                            ),
                          );
                        },
                        child: const Text('View Ticket'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
