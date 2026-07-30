import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import '../providers/scm_streams_provider.dart';

class MrpDashboardScreen extends ConsumerStatefulWidget {
  const MrpDashboardScreen({super.key});

  @override
  ConsumerState<MrpDashboardScreen> createState() => _MrpDashboardScreenState();
}

class _MrpDashboardScreenState extends ConsumerState<MrpDashboardScreen> {
  bool _isRunningMrp = false;

  Future<void> _runMrp() async {
    setState(() => _isRunningMrp = true);
    try {
      final tenantId = ref.read(currentTenantIdProvider);
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('runMrp');
      final result = await callable.call({'tenantId': tenantId});
      
      if (!mounted) return;
      UIUtils.showToast(context, 'MRP Run Complete. ${result.data['suggestionsGenerated']} suggestions generated.');
    } catch (e) {
      if (!mounted) return;
      UIUtils.showToast(context, 'MRP Run Failed: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isRunningMrp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mrpSuggestionsAsync = ref.watch(mrpSuggestionsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          GHeader(
            title: 'Master Planning (MRP) Engine',
            trailing: ElevatedButton.icon(
              onPressed: _isRunningMrp ? null : _runMrp,
              icon: _isRunningMrp
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_isRunningMrp ? 'Running Engine...' : 'Run MRP Analysis'),
            ),
          ),
          Expanded(
            child: mrpSuggestionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (suggestions) {
                if (suggestions.isEmpty) {
                  return const Center(child: Text('No MRP suggestions. Supply matches Demand.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final sug = suggestions[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.inventory_2, color: Colors.blue),
                        ),
                        title: Text('Item ID: ${sug.itemId}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Shortage: ${sug.suggestedQuantity} units'),
                            Text('Reason: ${sug.reason}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // TODO: Convert to Purchase Order / Prod Order
                            UIUtils.showToast(context, 'Conversion to PO coming soon...');
                          },
                          child: Text('Create ${sug.type}'),
                        ),
                      ),
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
}
