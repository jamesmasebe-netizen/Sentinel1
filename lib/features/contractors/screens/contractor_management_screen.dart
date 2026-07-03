import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/add_contractor_form.dart';
import '../widgets/contractor_list.dart';
import '../widgets/contractor_compliance_card.dart';

/// Contractor Management — contractor register, compliance status, permit linkage.
class ContractorManagementScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const ContractorManagementScreen({
    super.key,
    this.initialSearch,
    this.highlightId,
  });

  @override
  ConsumerState<ContractorManagementScreen> createState() => _ContractorState();
}

class _ContractorState extends ConsumerState<ContractorManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _showForm = false;
  String _searchQuery = '', _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    if (widget.initialSearch != null) {
      _searchQuery = widget.initialSearch!.toLowerCase();
    }
    if (widget.highlightId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
                UIUtils.showSideSheet(
          context: context,
          title: 'Item Details',
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Viewing item: ${widget.highlightId}\n(Detail view not yet implemented)'),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Management'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.business, size: 16), text: 'Register'),
            Tab(icon: Icon(Icons.verified_user, size: 16), text: 'Compliance'),
            Tab(icon: Icon(Icons.assignment_ind, size: 16), text: 'Inductions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_registerTab(), const ContractorComplianceCard(), _inductionsTab()],
      ),
    );
  }

  Widget _registerTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged:
                      (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search contractors…',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              GSpacing.hMd,
              DropdownButton<String>(
                value: _statusFilter,
                isDense: true,
                underline: const SizedBox(),
                items:
                    ['All', 'Active', 'Inactive', 'Suspended']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
              GSpacing.hSm,
              FilledButton(
                onPressed: () => setState(() => _showForm = !_showForm),
                child: Icon(_showForm ? Icons.close : Icons.add, size: 18),
              ),
            ],
          ),
        ),
        if (_showForm)
          AddContractorForm(
            onCancel: () => setState(() => _showForm = false),
          ),
        Expanded(
          child: ContractorList(
            searchQuery: _searchQuery,
            statusFilter: _statusFilter,
          ),
        ),
      ],
    );
  }

  Widget _inductionsTab() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.assignment_ind,
          size: 48,
          color: XMTheme.primary.withValues(alpha: 0.4),
        ),
        GSpacing.vMd,
        const Text('Contractor Induction Records'),
        GSpacing.vSm,
        Text(
          'Site induction completion tracking per contractor',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
