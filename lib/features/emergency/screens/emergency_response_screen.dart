import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/emergency_drills_tab.dart';
import '../widgets/emergency_equipment_tab.dart';
import '../widgets/emergency_contacts_tab.dart';
import '../widgets/emergency_broadcast_tab.dart';

/// Emergency Response — drills, equipment inventory, contacts, broadcast.
class EmergencyResponseScreen extends ConsumerStatefulWidget {
  const EmergencyResponseScreen({super.key});
  @override
  ConsumerState<EmergencyResponseScreen> createState() => _EmergencyState();
}

class _EmergencyState extends ConsumerState<EmergencyResponseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const GHeader(
          title: 'Emergency Response',
          subtitle: 'Drills, equipment, and protocols',
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
            controller: _tabCtrl,
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
              Tab(text: 'Drills'),
              Tab(text: 'Equipment'),
              Tab(text: 'Contacts'),
              Tab(text: 'Broadcast'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              EmergencyDrillsTab(),
              EmergencyEquipmentTab(),
              EmergencyContactsTab(),
              EmergencyBroadcastTab(),
            ],
          ),
        ),
      ],
    );
  }
}
