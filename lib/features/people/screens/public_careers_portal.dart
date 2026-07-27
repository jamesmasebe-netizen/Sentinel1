import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../models/hr_models.dart';
import '../widgets/application_form_widget.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class PublicCareersPortal extends ConsumerStatefulWidget {
  const PublicCareersPortal({super.key});

  @override
  ConsumerState<PublicCareersPortal> createState() =>
      _PublicCareersPortalState();
}

class _PublicCareersPortalState extends ConsumerState<PublicCareersPortal> {
  JobRequisition? _selectedRequisition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Sentinel Careers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child:
              _selectedRequisition == null
                  ? _buildJobList()
                  : _buildApplicationForm(_selectedRequisition!),
        ),
      ),
    );
  }

  Widget _buildJobList() {
    final firestore = ref.watch(firestoreProvider);
    return StreamBuilder<QuerySnapshot>(
      stream:
          firestore
              .tenantCollection(
                ref.watch(currentTenantIdProvider) ?? "",
                'job_requisitions',
              )
              .where('status', isEqualTo: 'Open')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading open positions.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No open positions at the moment. Please check back later.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final req = JobRequisition.fromFirestore(docs[index]);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2.0,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  req.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Department: ${req.department}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      req.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRequisition = req;
                    });
                  },
                  child: const Text('Apply Now'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildApplicationForm(JobRequisition req) {
    return ApplicationFormWidget(
      requisition: req,
      onBack: () {
        setState(() {
          _selectedRequisition = null;
        });
      },
    );
  }
}
