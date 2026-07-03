import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class IncidentReportDynamicFields extends StatelessWidget {
  final String type;

  // Injury
  final TextEditingController bodyPartController;
  final String treatmentType;
  final ValueChanged<String> onTreatmentTypeChanged;

  // Environmental
  final TextEditingController substanceController;
  final TextEditingController volumeController;
  final String envUnit;
  final ValueChanged<String> onEnvUnitChanged;

  // Property Damage
  final TextEditingController assetIdController;
  final TextEditingController damageEstimateController;

  const IncidentReportDynamicFields({
    super.key,
    required this.type,
    required this.bodyPartController,
    required this.treatmentType,
    required this.onTreatmentTypeChanged,
    required this.substanceController,
    required this.volumeController,
    required this.envUnit,
    required this.onEnvUnitChanged,
    required this.assetIdController,
    required this.damageEstimateController,
  });

  static const _treatments = [
    'First Aid',
    'Medical Treatment',
    'Hospitalization',
    'Fatality',
  ];

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'Injury':
        return _SectionCard(
          title: 'Injury Details',
          color: XMTheme.error,
          children: [
            TextFormField(
              controller: bodyPartController,
              decoration: const InputDecoration(
                labelText: 'Body Part Affected',
                prefixIcon: Icon(Icons.accessibility),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: treatmentType,
              decoration: const InputDecoration(
                labelText: 'Treatment Type',
                prefixIcon: Icon(Icons.medical_services),
              ),
              items:
                  _treatments
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
              onChanged: (v) => onTreatmentTypeChanged(v!),
            ),
          ],
        );
      case 'Environmental':
        return _SectionCard(
          title: 'Environmental Details',
          color: XMTheme.success,
          children: [
            TextFormField(
              controller: substanceController,
              decoration: const InputDecoration(
                labelText: 'Substance',
                prefixIcon: Icon(Icons.science),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: volumeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Volume'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: envUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items:
                        ['Liters', 'Gallons', 'kg', 'Tonnes']
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                    onChanged: (v) => onEnvUnitChanged(v!),
                  ),
                ),
              ],
            ),
          ],
        );
      case 'Property Damage':
        return _SectionCard(
          title: 'Property Damage Details',
          color: XMTheme.warning,
          children: [
            TextFormField(
              controller: assetIdController,
              decoration: const InputDecoration(
                labelText: 'Asset ID / Name',
                prefixIcon: Icon(Icons.inventory),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: damageEstimateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated Damage (R)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusSm),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(XMTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
