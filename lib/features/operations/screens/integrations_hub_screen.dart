// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/services/integrations_service.dart';
import '../widgets/integration_config_form.dart';

class IntegrationsHubScreen extends ConsumerWidget {
  const IntegrationsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final integrationsAsync = ref.watch(integrationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gateway Integrations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Integration',
            onPressed: () => UIUtils.showSideSheet(
              context: context,
              title: 'Add Gateway Integration',
              builder: (ctx) => const IntegrationConfigForm(),
            ),
          ),
        ],
      ),
      body: integrationsAsync.when(
        data: (integrations) {
          if (integrations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.webhook, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No gateway integrations configured.'),
                  const SizedBox(height: 8),
                  const Text('Sentinel is currently running 100% independently.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => UIUtils.showSideSheet(
                      context: context,
                      title: 'Add Gateway Integration',
                      builder: (ctx) => const IntegrationConfigForm(),
                    ),
                    child: const Text('Configure Webhook Gateway'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: integrations.length,
            itemBuilder: (context, index) {
              final config = integrations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.hub),
                  ),
                  title: Text(config.name),
                  subtitle: Text('Type: ${config.type.toUpperCase()}\nWebhook: ${config.webhookUrl}'),
                  isThreeLine: true,
                  trailing: Switch(
                    value: config.isEnabled,
                    onChanged: (val) async {
                      final updated = IntegrationConfig(
                        id: config.id,
                        name: config.name,
                        type: config.type,
                        isEnabled: val,
                        webhookUrl: config.webhookUrl,
                        apiKey: config.apiKey,
                        tenantId: config.tenantId,
                      );
                      await ref.read(integrationsServiceProvider).saveIntegration(updated);
                      if (!context.mounted) return;
                      UIUtils.showToast(context, 'Integration ${val ? 'Enabled' : 'Disabled'}', type: ToastType.success);
                    },
                  ),
                  onTap: () {
                    UIUtils.showSideSheet(
                      context: context,
                      title: 'Edit Integration',
                      builder: (ctx) => IntegrationConfigForm(config: config),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
