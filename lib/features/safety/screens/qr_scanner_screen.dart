import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../services/passport_compliance_checker.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);

        try {
          final payload = jsonDecode(barcode.rawValue!);
          if (payload['type'] == 'contractor_passport') {
            await _handleContractorScan(payload);
          } else if (payload['type'] == 'employee_passport') {
            await _handleEmployeeScan(payload);
          } else {
            _showError('Invalid QR Code Type');
          }
        } catch (e) {
          _showError('Invalid QR format. Could not parse data.');
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  Future<void> _handleEmployeeScan(Map<String, dynamic> payload) async {
    final tenantId = ref.read(currentTenantIdProvider) ?? '';
    final fs = ref.read(firestoreProvider);
    final employeeId = payload['employeeId'] as String? ?? '';

    if (employeeId.isEmpty) {
      _showError('No Employee ID in QR payload');
      return;
    }

    try {
      // 1. Fetch employee profile
      final empDoc =
          await fs
              .tenantCollection(tenantId, 'employees')
              .doc(employeeId)
              .get();
      final empData = empDoc.data() ?? {};
      final fullName = empData['fullName'] ?? 'Unknown';
      final department = empData['department'] ?? 'N/A';
      final jobTitle = empData['jobTitle'] ?? 'N/A';
      final managerId = empData['managerId'] as String?;
      final status = empData['status'] ?? 'Unknown';

      // 2. Resolve supervisor name
      String supervisorName = 'N/A';
      if (managerId != null && managerId.isNotEmpty) {
        final mgrDoc =
            await fs
                .tenantCollection(tenantId, 'employees')
                .doc(managerId)
                .get();
        final mgrData = mgrDoc.data() ?? {};
        supervisorName = mgrData['fullName'] ?? managerId;
      }

      // 3. Fetch company (check if assigned to a contractor)
      String company = 'Internal Employee';
      final contractorsSnap =
          await fs
              .tenantCollection(tenantId, 'contractors')
              .where('employeeIds', arrayContains: employeeId)
              .limit(1)
              .get();
      if (contractorsSnap.docs.isNotEmpty) {
        company =
            (contractorsSnap.docs.first.data())['companyName'] ?? 'External';
      }

      // 4. Fetch project allocation
      final projectsSnap =
          await fs
              .tenantCollection(tenantId, 'projects')
              .where('allocatedEmployeeIds', arrayContains: employeeId)
              .get();
      final allocatedProjects =
          projectsSnap.docs.map((d) => (d.data())['name'] ?? d.id).toList();

      // 5. Determine compliance via the single shared checker — see F-103 in
      // docs/fixes/FIX_LIST.md. status == 'Active' alone is not sufficient;
      // this also checks medical cert / training / induction / PTW state.
      final result = await ref
          .read(passportComplianceCheckerProvider)
          .checkEmployeeCompliance(employeeId);
      final issues = List<String>.from(result.issues);
      if (status != 'Active') issues.add('Employee status: $status');

      if (!mounted) return;
      _showEmployeeResult(
        fullName: fullName,
        employeeId: employeeId,
        company: company,
        department: department,
        jobTitle: jobTitle,
        supervisorName: supervisorName,
        projects: allocatedProjects,
        result: result,
        issues: issues,
        isCompliant: result.level == ComplianceLevel.compliant && status == 'Active',
      );
    } catch (e) {
      _showError('Failed to fetch employee data: $e');
    }
  }

  Future<void> _handleContractorScan(Map<String, dynamic> payload) async {
    final tenantId = ref.read(currentTenantIdProvider) ?? '';
    final fs = ref.read(firestoreProvider);
    final contractorId = payload['contractorId'] as String? ?? '';
    final projectId = payload['projectId'] as String? ?? '';
    final timestampStr = payload['timestamp'] as String?;

    bool isStale = false;
    if (timestampStr != null) {
      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp != null) {
        final age = DateTime.now().difference(timestamp);
        if (age.inHours > 24) {
          isStale = true;
        }
      }
    }

    if (contractorId.isEmpty) {
      _showError('No Contractor ID in QR payload');
      return;
    }

    try {
      // 1. Fetch contractor profile
      final contractorDoc =
          await fs
              .tenantCollection(tenantId, 'contractors')
              .doc(contractorId)
              .get();
      final contractorData = contractorDoc.data() ?? {};
      final companyName = contractorData['companyName'] ?? 'Unknown';
      final scopeOfWork = contractorData['scopeOfWork'] ?? 'N/A';
      final safetyRating = contractorData['safetyRating']?.toString() ?? 'N/A';
      final complianceStatus = contractorData['complianceStatus'] ?? 'Unknown';

      // 2. Fetch project name
      String projectName = projectId;
      if (projectId.isNotEmpty) {
        final projDoc =
            await fs
                .tenantCollection(tenantId, 'projects')
                .doc(projectId)
                .get();
        if (projDoc.exists) {
          projectName = (projDoc.data()?['name'] as String?) ?? projectId;
        }
      }

      // 3. Determine compliance via the single shared checker — see F-103 in
      // docs/fixes/FIX_LIST.md.
      final result = await ref
          .read(passportComplianceCheckerProvider)
          .checkContractorCompliance(contractorId);
      final issues = List<String>.from(result.issues);
      final statusLower = complianceStatus.toLowerCase();
      if (statusLower != 'compliant' && statusLower != 'approved') {
        issues.add('Compliance status: $complianceStatus');
      }
      final isCompliant = result.level == ComplianceLevel.compliant &&
          (statusLower == 'compliant' || statusLower == 'approved');

      if (!mounted) return;
      _showContractorResult(
        companyName: companyName,
        contractorId: contractorId,
        projectName: projectName,
        scopeOfWork: scopeOfWork,
        safetyRating: safetyRating,
        result: result,
        issues: issues,
        isCompliant: isCompliant,
        isStale: isStale,
      );
    } catch (e) {
      _showError('Failed to fetch contractor data: $e');
    }
  }

  void _showEmployeeResult({
    required String fullName,
    required String employeeId,
    required String company,
    required String department,
    required String jobTitle,
    required String supervisorName,
    required List<dynamic> projects,
    required ComplianceCheckResult result,
    required List<String> issues,
    required bool isCompliant,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status banner
                      Row(
                        children: [
                          Icon(
                            isCompliant
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isCompliant ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          GSpacing.hMd,
                          Text(
                            isCompliant ? 'Access Approved' : 'Access Denied',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: isCompliant ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GSpacing.vLg,

                      // Identity
                      _buildDetailRow('Name', fullName),
                      _buildDetailRow('Employee ID', employeeId),
                      _buildDetailRow('Company', company),
                      _buildDetailRow('Department', department),
                      _buildDetailRow('Job Title', jobTitle),
                      _buildDetailRow('Supervisor', supervisorName),
                      GSpacing.vLg,

                      // Project allocation
                      const Divider(),
                      GSpacing.vSm,
                      const Text(
                        'Project Allocation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      GSpacing.vSm,
                      if (projects.isEmpty)
                        const Text(
                          'Not allocated to any project',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...projects.map(
                          (p) => ListTile(
                            leading: const Icon(
                              Icons.folder_open,
                              color: Colors.blue,
                            ),
                            title: Text(p.toString()),
                            dense: true,
                          ),
                        ),
                      GSpacing.vLg,

                      // Training / Medical / Induction
                      const Divider(),
                      GSpacing.vSm,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'OHS Compliance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${result.validTrainingCount} valid, ${result.expiredTrainingCount} expired',
                            style: TextStyle(
                              color: result.expiredTrainingCount > 0 ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      GSpacing.vSm,
                      ListTile(
                        dense: true,
                        leading: Icon(
                          result.medicalCertValid ? Icons.verified : Icons.error_outline,
                          color: result.medicalCertValid ? Colors.green : Colors.red,
                        ),
                        title: const Text('Medical Certificate'),
                        subtitle: Text(
                          result.hasMedicalCert
                              ? (result.medicalCertValid ? 'Valid' : 'Expired')
                              : 'Not on file',
                        ),
                      ),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          result.inductionCompleted ? Icons.verified : Icons.error_outline,
                          color: result.inductionCompleted ? Colors.green : Colors.red,
                        ),
                        title: const Text('Site Induction'),
                        subtitle: Text(result.inductionCompleted ? 'Completed' : 'Not completed'),
                      ),
                      GSpacing.vLg,

                      // Permits
                      const Divider(),
                      GSpacing.vSm,
                      const Text(
                        'Active Permits to Work',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      GSpacing.vSm,
                      Text(
                        '${result.activePtwCount} active permit(s)',
                        style: TextStyle(
                          color: result.activePtwCount > 0 ? Colors.green : Colors.grey,
                        ),
                      ),
                      if (issues.isNotEmpty) ...[
                        GSpacing.vLg,
                        const Divider(),
                        GSpacing.vSm,
                        const Text(
                          'Issues',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                        ),
                        GSpacing.vSm,
                        ...issues.map(
                          (i) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                            title: Text(i),
                          ),
                        ),
                      ],
                      GSpacing.vLg,

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => _isProcessing = false);
                          },
                          child: const Text('Acknowledge'),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showContractorResult({
    required String companyName,
    required String contractorId,
    required String projectName,
    required String scopeOfWork,
    required String safetyRating,
    required ComplianceCheckResult result,
    required List<String> issues,
    required bool isCompliant,
    required bool isStale,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCompliant
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isCompliant ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          GSpacing.hMd,
                          Text(
                            isCompliant ? 'Access Approved' : 'Access Denied',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: isCompliant ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (isStale) ...[
                        GSpacing.vSm,
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              GSpacing.hSm,
                              const Expanded(
                                child: Text(
                                  'QR code is stale (generated >24h ago). Request a fresh passport.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      GSpacing.vLg,
                      _buildDetailRow('Company', companyName),
                      _buildDetailRow('Contractor ID', contractorId),
                      _buildDetailRow('Project', projectName),
                      _buildDetailRow('Approved Scope', scopeOfWork),
                      _buildDetailRow('Safety Rating', safetyRating),
                      GSpacing.vLg,
                      const Divider(),
                      GSpacing.vMd,
                      const Text(
                        'Safety File Compliance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      GSpacing.vSm,
                      ListTile(
                        leading: Icon(
                          Icons.health_and_safety,
                          color: result.level == ComplianceLevel.compliant
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(
                          result.level == ComplianceLevel.compliant
                              ? 'Compliant'
                              : 'Needs attention',
                        ),
                      ),
                      GSpacing.vMd,
                      const Text(
                        'Active Permits to Work',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      GSpacing.vSm,
                      Text(
                        '${result.activePtwCount} active permit(s)',
                        style: TextStyle(
                          color: result.activePtwCount > 0 ? Colors.green : Colors.grey,
                        ),
                      ),
                      if (issues.isNotEmpty) ...[
                        GSpacing.vLg,
                        const Divider(),
                        GSpacing.vSm,
                        const Text(
                          'Issues',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                        ),
                        GSpacing.vSm,
                        ...issues.map(
                          (i) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                            title: Text(i),
                          ),
                        ),
                      ],
                      GSpacing.vLg,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => _isProcessing = false);
                          },
                          child: const Text('Acknowledge'),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Passport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          // Overlay to guide user
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
