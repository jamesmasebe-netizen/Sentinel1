import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/services/integrations_service.dart';
import '../providers/hr_providers.dart';
import '../widgets/manual_payslip_form.dart';

class PayrollDashboardScreen extends ConsumerWidget {
  const PayrollDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollLedgersAsync = ref.watch(payrollLedgerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync with External Gateway',
            onPressed: () async {
              UIUtils.showToast(context, 'Starting gateway sync...', type: ToastType.success);
              final siteId = ref.read(currentTenantIdProvider);
              if (siteId != null) {
                final success = await ref.read(integrationsServiceProvider).syncDataToGateway(
                  siteId, 
                  'payroll', 
                  {'action': 'sync_ledgers', 'timestamp': DateTime.now().toIso8601String()}
                );
                if (context.mounted) {
                  if (success) {
                    UIUtils.showToast(context, 'Sync completed successfully (or running standalone).', type: ToastType.success);
                  } else {
                    UIUtils.showToast(context, 'Gateway Sync Failed. Check Webhook Config.', type: ToastType.error);
                  }
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Generate Manual Payslip',
            onPressed: () {
              UIUtils.showSideSheet(
                context: context,
                title: 'Generate Manual Payslip',
                builder: (ctx) => const ManualPayslipForm(),
              );
            },
          ),
        ],
      ),
      body: payrollLedgersAsync.when(
        data: (ledgers) {
          if (ledgers.isEmpty) {
            return const Center(child: Text('No payroll records found.'));
          }
          return ListView.builder(
            itemCount: ledgers.length,
            itemBuilder: (context, index) {
              final ledger = ledgers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${ledger.employeeName} - ${ledger.periodStart.toLocal().toString().split(' ')[0]} to ${ledger.periodEnd.toLocal().toString().split(' ')[0]}'),
                  subtitle: Text('Status: ${ledger.status} | Net Pay: \$${ledger.netPay.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.receipt_long),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading payroll: $e')),
      ),
    );
  }
}
