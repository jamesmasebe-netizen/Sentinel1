import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/waste_manifests_tab.dart';
import '../widgets/spill_logs_tab.dart';
import '../widgets/esg_metrics_tab.dart';
import '../widgets/environmental_analytics_tab.dart';

/// Environmental & ESG Management — waste manifests, spill response, emissions tracking, water/energy.
class EnvironmentalScreen extends ConsumerStatefulWidget {
  const EnvironmentalScreen({super.key});
  @override
  ConsumerState<EnvironmentalScreen> createState() => _EnvState();
}

class _EnvState extends ConsumerState<EnvironmentalScreen>
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
          title: 'Environmental & ESG',
          subtitle: 'Waste manifests, spill response, and emissions',
        ),
        // Standardized Sub-Header for Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Waste'),
              Tab(text: 'Spills'),
              Tab(text: 'ESG Metrics'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              WasteManifestsTab(),
              SpillLogsTab(),
              EsgMetricsTab(),
              EnvironmentalAnalyticsTab(),
            ],
          ),
        ),
      ],
    );
  }
}
