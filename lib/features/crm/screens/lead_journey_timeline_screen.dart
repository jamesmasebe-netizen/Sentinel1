import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';

class LeadJourneyTimelineScreen extends ConsumerWidget {
  final String leadId;
  const LeadJourneyTimelineScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lead Journey Timeline')),
      body: StreamBuilder<List<CustomerJourney>>(
        stream: ref.read(crmServiceProvider).streamJourneysForLead(leadId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final journeys = snapshot.data ?? [];
          if (journeys.isEmpty) {
            return const Center(
              child: Text('No journey data available for this lead.'),
            );
          }
          return ListView.builder(
            itemCount: journeys.length,
            itemBuilder: (context, index) {
              final journey = journeys[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stage: ${journey.currentStage}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('Score: ${journey.totalScore}'),
                      const Divider(),
                      const Text('Touchpoints:'),
                      ...journey.touchpoints.map(
                        (tp) => ListTile(
                          leading: const Icon(Icons.touch_app),
                          title: Text(tp['type'] ?? 'Touchpoint'),
                          subtitle: Text(tp['date']?.toString() ?? ''),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
