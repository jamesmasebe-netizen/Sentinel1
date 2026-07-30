import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/automation/loto_automation.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';

/// Roles authorized to remove a lockout, mirroring firestore.rules'
/// isManager() || isSheqOfficer() gate for the equipment collection.
bool isLotoReleaseAuthorized(String? role) {
  return const ['admin', 'manager', 'sheq_officer', 'safety_manager'].contains(role);
}

/// Shared "Verify & Return to Service" confirmation dialog for ending a LOTO
/// lockout. Gated to managers/SHEQ officers per the ISO 45001 / NEBOSH-based
/// F-215 decision (docs/fixes/FIX_LIST.md) — asymmetric apply/remove authority,
/// with a mandatory verification checklist persisted on the audit event.
Future<void> showLotoReturnDialog(
  BuildContext context,
  WidgetRef ref, {
  required String equipmentId,
  required String equipmentName,
  String? workOrderId,
}) {
  bool guardsRestored = false;
  bool areaClear = false;
  bool lockRemoved = false;
  bool isSubmitting = false;

  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final canSubmit = guardsRestored && areaClear && lockRemoved;
        return AlertDialog(
          title: const Text('Verify & Return to Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Confirm before removing the lockout on "$equipmentName":'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Guards restored'),
                value: guardsRestored,
                onChanged: (v) => setState(() => guardsRestored = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Area clear'),
                value: areaClear,
                onChanged: (v) => setState(() => areaClear = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Isolation device removed'),
                value: lockRemoved,
                onChanged: (v) => setState(() => lockRemoved = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: (!canSubmit || isSubmitting)
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);
                      try {
                        final profile = ref.read(userProfileProvider).valueOrNull;
                        if (profile == null) throw Exception('Not logged in');

                        await ref.read(lotoAutomationProvider).releaseLockout(
                              equipmentId: equipmentId,
                              releasedById: profile.uid,
                              workOrderId: workOrderId ?? 'Manual-Release',
                              guardsRestored: guardsRestored,
                              areaClear: areaClear,
                              isolationDeviceRemoved: lockRemoved,
                            );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          UIUtils.showToast(context, 'Equipment returned to service', type: ToastType.success);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          UIUtils.showToast(context, '$e', type: ToastType.error);
                          setState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Return to Service'),
            ),
          ],
        );
      },
    ),
  );
}
