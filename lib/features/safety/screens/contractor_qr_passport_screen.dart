import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../../core/widgets/ds_widgets.dart';
import '../services/passport_compliance_checker.dart';

class ContractorQrPassportScreen extends ConsumerWidget {
  final Map<String, dynamic> contractorData;
  final String projectId;

  const ContractorQrPassportScreen({
    super.key,
    required this.contractorData,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Generate the payload
    final payload = {
      'type': 'contractor_passport',
      'contractorId': contractorData['id'] ?? 'unknown',
      'projectId': projectId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final payloadString = jsonEncode(payload);

    final checker = ref.watch(passportComplianceCheckerProvider);
    final contractorId = contractorData['id'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Contractor Safety Passport')),
      body: FutureBuilder<ComplianceCheckResult>(
        future: checker.checkContractorCompliance(contractorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data;

          Color headerColor = Colors.grey;
          if (result != null) {
            switch (result.level) {
              case ComplianceLevel.compliant:
                headerColor = Colors.green;
                break;
              case ComplianceLevel.warning:
                headerColor = Colors.orange;
                break;
              case ComplianceLevel.nonCompliant:
                headerColor = Colors.red;
                break;
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [headerColor, headerColor.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                      GSpacing.vLg,
                      Text(
                        contractorData['companyName'] ?? 'Unknown Contractor',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      GSpacing.vSm,
                      Text(
                        'Approved Scope: ${contractorData['scopeOfWork'] ?? 'General'}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: payloadString,
                          version: QrVersions.auto,
                          size: 250.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      GSpacing.vXl,
                      if (result != null) ...[
                        _buildComplianceStatusCard(context, result),
                      ],
                      GSpacing.vXl,
                      const Text(
                        'Scan this QR code at security checkpoints to verify compliance, scope of work, and active permits.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComplianceStatusCard(
    BuildContext context,
    ComplianceCheckResult result,
  ) {
    return GCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Status',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          GSpacing.vLg,
          _buildStatusRow(
            'Safety File Score',
            result.issues.any((i) => i.contains('Safety file score below'))
                ? '< ${PassportComplianceChecker.safetyScoreThreshold}%'
                : '≥ ${PassportComplianceChecker.safetyScoreThreshold}%',
            !result.issues.any((i) => i.contains('Safety file score below')) &&
                !result.issues.contains('No safety file found'),
          ),
          GSpacing.vSm,
          _buildStatusRow(
            'Active Permits',
            '${result.activePtwCount} permit(s)',
            true, // Neutral
          ),
          if (result.issues.isNotEmpty) ...[
            GSpacing.vLg,
            const Text(
              'Issues:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            GSpacing.vSm,
            ...result.issues.map(
              (i) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  GSpacing.hSm,
                  Expanded(
                    child: Text(i, style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isOk) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            GSpacing.hSm,
            Icon(
              isOk ? Icons.check_circle : Icons.cancel,
              color: isOk ? Colors.green : Colors.red,
              size: 20,
            ),
          ],
        ),
      ],
    );
  }
}
