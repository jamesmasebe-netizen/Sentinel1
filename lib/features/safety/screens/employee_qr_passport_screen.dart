import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../../core/widgets/ds_widgets.dart';
import '../services/passport_compliance_checker.dart';

class EmployeeQrPassportScreen extends ConsumerWidget {
  final Map<String, dynamic> employeeData;

  const EmployeeQrPassportScreen({super.key, required this.employeeData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Generate the payload
    final payload = {
      'type': 'employee_passport',
      'employeeId': employeeData['id'] ?? 'unknown',
    };
    final payloadString = jsonEncode(payload);

    final checker = ref.watch(passportComplianceCheckerProvider);
    final employeeId = employeeData['id'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Individual Passport')),
      body: FutureBuilder<ComplianceCheckResult>(
        future: checker.checkEmployeeCompliance(employeeId),
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
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.black54,
                        ),
                      ),
                      GSpacing.vLg,
                      Text(
                        employeeData['name'] ?? 'Unknown Employee',
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
                        'Company: ${employeeData['company'] ?? 'Internal'}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                      Text(
                        'Project: ${employeeData['projectId'] ?? 'N/A'}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
                        'Scan this QR code at security checkpoints to verify compliance, valid training, and active permits.',
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
            'Medical Certificate',
            result.hasMedicalCert
                ? (result.medicalCertValid ? 'Valid' : 'Expired')
                : 'Missing',
            result.hasMedicalCert && result.medicalCertValid,
          ),
          GSpacing.vSm,
          _buildStatusRow(
            'Training Records',
            '${result.validTrainingCount} valid, ${result.expiredTrainingCount} expired',
            result.expiredTrainingCount == 0,
          ),
          GSpacing.vSm,
          _buildStatusRow(
            'Active Permits',
            '${result.activePtwCount} permit(s)',
            true, // Neutral
          ),
          GSpacing.vSm,
          _buildStatusRow(
            'Site Induction',
            result.inductionCompleted ? 'Completed' : 'Missing',
            result.inductionCompleted,
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
