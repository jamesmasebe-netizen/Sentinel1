import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';
import 'campaign_detail_screen.dart';

class CampaignListScreen extends ConsumerWidget {
  const CampaignListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(crmServiceProvider).streamCampaigns();
    return Scaffold(
      appBar: AppBar(title: const Text('Campaigns')),
      body: StreamBuilder<List<Campaign>>(
        stream: campaignsAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final campaigns = snapshot.data ?? [];
          if (campaigns.isEmpty) {
            return const Center(child: Text('No campaigns found.'));
          }
          return ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return ListTile(
                title: Text(campaign.name),
                subtitle: Text(
                  'Status: ${campaign.status} | Budget: \$${campaign.budget}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CampaignDetailScreen(campaignId: campaign.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement Create Campaign
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
