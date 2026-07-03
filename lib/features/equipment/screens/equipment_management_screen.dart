import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/equipment_asset_tab.dart';
import '../widgets/equipment_inspections_tab.dart';
import '../widgets/maintenance_log_dialog.dart';

/// Equipment Management — asset register, inspection schedule, maintenance log.
class EquipmentManagementScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const EquipmentManagementScreen({
    super.key,
    this.initialSearch,
    this.highlightId,
  });

  @override
  ConsumerState<EquipmentManagementScreen> createState() => _EquipState();
}

class _EquipState extends ConsumerState<EquipmentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
    final theme = Theme.of(context);
    return Column(
      children: [
        const GHeader(
          title: 'Equipment Management',
          subtitle: 'Asset register and inspections',
        ),
        // Premium Sub-Header for Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tab,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Assets'),
              Tab(text: 'Inspections'),
              Tab(text: 'Maintenance'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              EquipmentAssetTab(initialSearch: widget.initialSearch),
              const EquipmentInspectionsTab(),
              const MaintenanceLogDialog(),
            ],
          ),
        ),
      ],
    );
  }
}
