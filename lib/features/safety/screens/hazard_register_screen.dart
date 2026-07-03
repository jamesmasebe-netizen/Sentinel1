import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/hazard_card.dart';
import '../widgets/hazard_form_sheet.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

/// Hazard Register — CRUD for site hazards with severity, location, and description.
/// Mirrors React HazardRegister: create form, severity chips, location tagging.
class HazardRegisterScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const HazardRegisterScreen({super.key, this.initialSearch, this.highlightId});

  @override
  ConsumerState<HazardRegisterScreen> createState() =>
      _HazardRegisterScreenState();
}

class _HazardRegisterScreenState extends ConsumerState<HazardRegisterScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      // _search = widget.initialSearch!;
    }
    if (widget.highlightId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UIUtils.showSideSheet(
          context: context,
          title: 'Item Details',
          builder:
              (ctx) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Viewing item: ${widget.highlightId}\n(Detail view not yet implemented)',
                ),
              ),
        );
      });
    }
  }

  void _showHazardForm(BuildContext context) {
    UIUtils.showSideSheet(
      context: context,
      title: 'Report New Hazard',
      builder:
          (ctx) => HazardFormSheet(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    if (siteId == null) {
      return const Center(child: Text('No site assigned'));
    }

    return Column(
      children: [
        GHeader(
          title: 'Hazard Register',
          subtitle: 'Track and mitigate workplace hazards',
          trailing: FilledButton.icon(
            onPressed: () => _showHazardForm(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Report Hazard'),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                firestore
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'hazards',
                    )
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: XMTheme.success.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text('No hazards registered'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return HazardCard(data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
