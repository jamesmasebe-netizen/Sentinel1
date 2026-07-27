import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;
  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campaign Details')),
      body: FutureBuilder<Campaign?>(
        future: ref.read(crmServiceProvider).getCampaign(campaignId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final campaign = snapshot.data;
          if (campaign == null) {
            return const Center(child: Text('Campaign not found.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${campaign.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Status: ${campaign.status}'),
                Text('Type: ${campaign.type}'),
                Text('Budget: \$${campaign.budget}'),
                Text('Target Audience: ${campaign.targetAudience}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
