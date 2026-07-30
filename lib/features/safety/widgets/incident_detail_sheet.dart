// ignore_for_file: dead_code
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'detail_row.dart';
import 'incident_status_colors.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/issue_to_resolution_bpf.dart';
import '../../../core/bpf/bpf_service.dart';
import '../../../core/bpf/bpf_orchestrator.dart';

void showIncidentDetail(
  BuildContext context,
  WidgetRef ref,
  String docId,
  Map<String, dynamic> data,
) {
  final role = ref.read(userRoleProvider);
  final firestore = ref.read(firestoreProvider);
  final isEditable = role == 'admin' || role == 'executive';

  UIUtils.showSideSheet(
    context: context,
    title: 'Incident Details',
    width: 500,
    builder: (ctx) {
      String currentStatus = data['status'] ?? 'Open';
      String currentSeverity = data['severity'] ?? 'Minor';
      String currentType = data['type'] ?? 'Injury';
      final directCostCtrl = TextEditingController(
        text: (data['directCosts'] ?? 0).toString(),
      );
      final indirectCostCtrl = TextEditingController(
        text: (data['indirectCosts'] ?? 0).toString(),
      );

      return StatefulBuilder(
        builder: (context, setDialogState) {
          bool isLoading = false;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Untitled',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                BpfRibbonWidget(
                  bpfTypeId: 'issue_to_resolution',
                  recordType: 'incident',
                  recordId: docId,
                  definition: issueToResolutionDefinition,
                ),
                const SizedBox(height: 12),
                if (!isEditable) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      GStatusTag(
                        label: currentStatus,
                        color: getStatusColor(currentStatus),
                      ),
                      GStatusTag(
                        label: currentSeverity,
                        color: getSevColor(currentSeverity),
                      ),
                      GStatusTag(label: currentType, color: XMTheme.primary),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['description'] ?? 'No description',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  DetailRow(
                    icon: Icons.person,
                    label: 'Reporter',
                    value:
                        data['isAnonymous'] == true
                            ? 'Anonymous'
                            : data['reporterName'] ?? 'Unknown',
                  ),
                  if (data['location'] != null &&
                      data['location'].toString().isNotEmpty)
                    DetailRow(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: data['location'],
                    ),
                  if (data['totalCost'] != null &&
                      (data['totalCost'] as num) > 0)
                    DetailRow(
                      icon: Icons.attach_money,
                      label: 'Total Cost',
                      value: 'R${data['totalCost']}',
                    ),
                ] else ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    items:
                        ['Open', 'Investigating', 'Resolved', 'Closed']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged:
                        isLoading
                            ? null
                            : (v) => setDialogState(() => currentStatus = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: currentSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Severity',
                      prefixIcon: Icon(Icons.warning),
                    ),
                    items:
                        ['Minor', 'Moderate', 'Major', 'Critical']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged:
                        isLoading
                            ? null
                            : (v) => setDialogState(() => currentSeverity = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: currentType,
                    decoration: const InputDecoration(
                      labelText: 'Type/Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items:
                        [
                              'Injury',
                              'Near Miss',
                              'Property Damage',
                              'Environmental',
                              'Hazard Observation',
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged:
                        isLoading
                            ? null
                            : (v) => setDialogState(() => currentType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: directCostCtrl,
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Direct Cost (R)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: indirectCostCtrl,
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Indirect Cost (R)',
                      prefixIcon: Icon(Icons.money_off),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon:
                          isLoading
                              ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.save),
                      label: const Text('Save Incident Properties'),
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                setDialogState(() => isLoading = true);
                                try {
                                  final direct =
                                      double.tryParse(directCostCtrl.text) ??
                                      0.0;
                                  final indirect =
                                      double.tryParse(indirectCostCtrl.text) ??
                                      0.0;
                                  final total = direct + indirect;

                                  await firestore
                                      .tenantCollection(
                                        ref.watch(currentTenantIdProvider) ??
                                            "",
                                        'incidents',
                                      )
                                      .doc(docId)
                                      .update({
                                        'status': currentStatus,
                                        'severity': currentSeverity,
                                        'type': currentType,
                                        'directCosts': direct,
                                        'indirectCosts': indirect,
                                        'totalCost': total,
                                        'updatedAt':
                                            DateTime.now().toIso8601String(),
                                      });

                                  if (ctx.mounted) {
                                    UIUtils.showToast(
                                      ctx,
                                      'Incident properties saved successfully',
                                      type: ToastType.success,
                                    );
                                    Navigator.pop(ctx);
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    UIUtils.showToast(
                                      ctx,
                                      'Failed to save incident properties: $e',
                                      type: ToastType.error,
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setDialogState(() => isLoading = false);
                                  }
                                }
                              },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('Escalate to CAPA'),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setDialogState(() => isLoading = true);
                              try {
                                final bpfService = ref.read(bpfServiceProvider);
                                final bpfInstances = await bpfService
                                    .streamBpfInstancesByRecord('incident', docId)
                                    .first;
                                
                                String? bpfId = bpfInstances.isNotEmpty ? bpfInstances.first.id : null;
                                if (bpfId == null) {
                                  bpfId = await bpfService.startBpf(
                                      'issue_to_resolution', 'incident_logging', 'incident', docId);
                                }

                                final orchestrator = ref.read(bpfOrchestratorProvider);
                                await orchestrator.createCapaFromIncident(
                                  docId,
                                  bpfId,
                                  data['title'] ?? 'Incident Escalation',
                                  data['description'] ?? 'Automatically generated CAPA from incident.',
                                );

                                if (ctx.mounted) {
                                  UIUtils.showToast(
                                    ctx,
                                    'Escalated to CAPA successfully',
                                    type: ToastType.success,
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  UIUtils.showToast(
                                    ctx,
                                    'Failed to escalate: $e',
                                    type: ToastType.error,
                                  );
                                }
                              } finally {
                                if (ctx.mounted) {
                                  setDialogState(() => isLoading = false);
                                }
                              }
                            },
                    ),
                  ),
                ],
                if (data['photoUrl'] != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Photo Evidence',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      data['photoUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      );
    },
  );
}
