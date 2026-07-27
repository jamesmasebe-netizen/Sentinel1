import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

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

      // 4. Fetch active training records
      final trainingSnap =
          await fs
              .tenantCollection(tenantId, 'training_records')
              .where('employeeId', isEqualTo: employeeId)
              .get();
      final validTrainings =
          trainingSnap.docs.map((d) => d.data()).where((t) {
            final expiry = t['expiryDate'];
            if (expiry == null) return true; // no expiry = still valid
            final expiryDate = DateTime.tryParse(expiry.toString());
            return expiryDate != null && expiryDate.isAfter(DateTime.now());
          }).toList();

      // 5. Fetch active permits (PTWs) where this employee is a worker
      final permitsSnap =
          await fs
              .tenantCollection(tenantId, 'permits')
              .where('status', whereIn: ['active', 'approved'])
              .get();
      final activePermits =
          permitsSnap.docs.map((d) => {'id': d.id, ...d.data()}).where((p) {
            final workers = p['workers'] as List<dynamic>? ?? [];
            return workers.any((w) {
              if (w is Map) return w['employeeId'] == employeeId;
              return w.toString() == employeeId;
            });
          }).toList();

      // 6. Fetch project allocation
      final projectsSnap =
          await fs
              .tenantCollection(tenantId, 'projects')
              .where('allocatedEmployeeIds', arrayContains: employeeId)
              .get();
      final allocatedProjects =
          projectsSnap.docs.map((d) => (d.data())['name'] ?? d.id).toList();

      // Determine compliance
      final isCompliant = status == 'Active';

      if (!mounted) return;
      _showEmployeeResult(
        fullName: fullName,
        employeeId: employeeId,
        company: company,
        department: department,
        jobTitle: jobTitle,
        supervisorName: supervisorName,
        trainings: validTrainings,
        permits: activePermits,
        projects: allocatedProjects,
        isCompliant: isCompliant,
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

      // 3. Fetch active permits for this contractor
      final permitsSnap =
          await fs
              .tenantCollection(tenantId, 'permits')
              .where('status', whereIn: ['active', 'approved'])
              .get();
      final activePermits =
          permitsSnap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .where((p) => p['requesterId'] == contractorId)
              .toList();

      // 4. Fetch safety file score from documents
      final docsSnap =
          await fs
              .tenantCollection(tenantId, 'contractor_documents')
              .where('submissionId', isEqualTo: contractorId)
              .get();
      final totalDocs = docsSnap.docs.length;
      final approvedDocs =
          docsSnap.docs.where((d) => (d.data())['status'] == 'Resolved').length;
      final safetyFileScore =
          totalDocs > 0 ? ((approvedDocs / totalDocs) * 100).round() : 0;

      final isCompliant =
          complianceStatus.toLowerCase() == 'compliant' ||
          complianceStatus.toLowerCase() == 'approved';

      if (!mounted) return;
      _showContractorResult(
        companyName: companyName,
        contractorId: contractorId,
        projectName: projectName,
        scopeOfWork: scopeOfWork,
        safetyRating: safetyRating,
        safetyFileScore: safetyFileScore,
        permits: activePermits,
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
    required List<Map<String, dynamic>> trainings,
    required List<Map<String, dynamic>> permits,
    required List<dynamic> projects,
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

                      // Training
                      const Divider(),
                      GSpacing.vSm,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'OHS Training',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${trainings.length} valid',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                      GSpacing.vSm,
                      if (trainings.isEmpty)
                        const Text(
                          'No valid training records found',
                          style: TextStyle(color: Colors.orange),
                        )
                      else
                        ...trainings.map(
                          (t) => ListTile(
                            leading: const Icon(
                              Icons.verified,
                              color: Colors.green,
                            ),
                            title: Text(
                              t['courseName'] ?? t['title'] ?? 'Training',
                            ),
                            subtitle: Text(
                              t['expiryDate'] != null
                                  ? 'Expires: ${t['expiryDate']}'
                                  : 'No expiry',
                            ),
                            dense: true,
                          ),
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
                      if (permits.isEmpty)
                        const Text(
                          'No active permits',
                          style: TextStyle(color: Colors.orange),
                        )
                      else
                        ...permits.map(
                          (p) => ListTile(
                            leading: const Icon(
                              Icons.assignment_turned_in,
                              color: Colors.green,
                            ),
                            title: Text(
                              p['title'] ?? 'Permit ${p['permitNumber'] ?? ''}',
                            ),
                            subtitle: Text(
                              'Type: ${p['type'] ?? 'N/A'} • Status: ${p['status']}',
                            ),
                            dense: true,
                          ),
                        ),
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
    required int safetyFileScore,
    required List<Map<String, dynamic>> permits,
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
                          color:
                              safetyFileScore >= 80
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                        title: Text('Safety File Score: $safetyFileScore%'),
                        subtitle: Text(
                          safetyFileScore >= 80
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
                      if (permits.isEmpty)
                        const Text(
                          'No active permits',
                          style: TextStyle(color: Colors.orange),
                        )
                      else
                        ...permits.map(
                          (p) => ListTile(
                            leading: const Icon(
                              Icons.assignment_turned_in,
                              color: Colors.green,
                            ),
                            title: Text(
                              p['title'] ?? 'Permit ${p['permitNumber'] ?? ''}',
                            ),
                            subtitle: Text(
                              'Type: ${p['type'] ?? 'N/A'} • Status: ${p['status']}',
                            ),
                            dense: true,
                          ),
                        ),
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
