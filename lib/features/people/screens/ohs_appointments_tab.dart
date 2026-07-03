import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class OHSAppointmentsTab extends ConsumerWidget {
  final String employeeId;
  const OHSAppointmentsTab({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Legal Appointments (OHS Act 85 of 1993)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              FilledButton.icon(
                onPressed: () {
                  // Show appoint dialog
                },
                icon: const Icon(Icons.add_moderator, size: 18),
                label: const Text('New Appointment'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: firestore
                .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'ohs_appointments')
                .where('assigneeId', isEqualTo: employeeId)
                .orderBy('appointedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.shield_outlined, size: 48, color: XMTheme.secondaryLight.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('No legal appointments found for this employee.'),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final isRevoked = data['status'] == 'Revoked';

                  return GCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isRevoked ? XMTheme.error.withValues(alpha: 0.1) : XMTheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            isRevoked ? Icons.block : Icons.verified_user,
                            color: isRevoked ? XMTheme.error : XMTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['appointmentType'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Section: ${data['section'] ?? ''}', style: TextStyle(color: XMTheme.secondaryLight, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Appointed: ${data['appointedAt'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(data['appointedAt'])) : 'Unknown'}', style: TextStyle(color: XMTheme.secondaryLight, fontSize: 12)),
                            ],
                          ),
                        ),
                        GStatusTag(
                          label: data['status'] ?? 'Active',
                          color: isRevoked ? XMTheme.error : XMTheme.success,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
