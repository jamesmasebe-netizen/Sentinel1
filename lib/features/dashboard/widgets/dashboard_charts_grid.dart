import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'ltifr_history_chart.dart';
import 'incidents_category_chart.dart';
import 'ohs_compliance_chart.dart';
import 'hira_heatmap_chart.dart';
import 'mandatory_training_chart.dart';
import 'capa_resolution_chart.dart';
import 'waste_management_chart.dart';
import 'incident_heatmap_scatter_plot.dart';
import 'incident_mapping_map.dart';

class DashboardChartsGrid extends StatelessWidget {
  final int crossAxisCount;

  const DashboardChartsGrid({super.key, required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * 20)) /
            crossAxisCount;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildChartContainer(
              context,
              itemWidth,
              '1. LTIFR History (6 Mo)',
              const LtifrHistoryChart(),
              onTap: () => context.go('/safety'),
            ),
            _buildChartContainer(
              context,
              itemWidth,
              '2. Incidents by Category',
              const IncidentsCategoryChart(),
              onTap: () => context.go('/safety'),
            ),
            _buildChartContainer(
              context,
              itemWidth,
              '3. OHS Act Compliance %',
              const OhsComplianceChart(),
              onTap: () => context.go('/safety'),
            ),
            _buildChartContainer(
              context,
              itemWidth,
              '4. HIRA Risk Matrix',
              const HiraHeatmapChart(),
              onTap: () => context.go('/risk'),
            ),
            _buildChartContainer(
              context,
              itemWidth,
              '5. Mandatory Training',
              const MandatoryTrainingChart(),
              onTap: () => context.go('/people'),
            ),
            _buildChartContainer(
              context,
              itemWidth,
              '6. CAPA Resolution',
              const CapaResolutionChart(),
              onTap: () => context.go('/safety'),
            ),
            _buildChartContainer(
              context,
              itemWidth,
              '7. Waste Mgmt (Tons)',
              const WasteManagementChart(),
              onTap: () => context.go('/environment'),
            ),
            _buildChartContainer(
              context,
              itemWidth,
              '8. Incident Heatmap (Time)',
              const IncidentHeatmapScatterPlot(),
              onTap: () => context.go('/safety'),
            ),
            _buildChartContainer(
              context,
              crossAxisCount == 3 ? itemWidth : constraints.maxWidth,
              '9. Incident Mapping (HQ)',
              const IncidentMappingMap(),
              onTap: () => context.go('/properties'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartContainer(
    BuildContext context,
    double width,
    String title,
    Widget child, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: 300,
      child: GCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ],
            ),
            GSpacing.vLg,
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
