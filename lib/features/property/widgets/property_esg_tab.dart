import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../providers/property_providers.dart';
import '../models/property_models.dart';
import 'property_utility_form.dart';

class PropertyEsgTab extends ConsumerWidget {
  final Property property;
  const PropertyEsgTab({super.key, required this.property});

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: XMTheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, color: XMTheme.primary),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityCard(String title, List<double> values, Color color) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            SizedBox(
              height: 100,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          values
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilitiesAsync = ref.watch(propertyUtilitiesProvider(property.id));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader(
          context,
          'Environmental Impact & Utilities',
          Icons.eco_outlined,
          () => UIUtils.showSideSheet(
            context: context,
            title: 'Add Utility Usage',
            builder: (_) => PropertyUtilityForm(propertyId: property.id),
          ),
        ),
        utilitiesAsync.when(
          data:
              (data) => Column(
                children: [
                  _buildUtilityCard(
                    'Electricity (kWh)',
                    data.map((d) => d.electricity).toList(),
                    XMTheme.warning,
                  ),
                  const SizedBox(height: 24),
                  _buildUtilityCard(
                    'Water (kL)',
                    data.map((d) => d.water).toList(),
                    Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  _buildUtilityCard(
                    'Carbon Footprint (tCO2e)',
                    data.map((d) => d.carbon).toList(),
                    XMTheme.error,
                  ),
                ],
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }
}
