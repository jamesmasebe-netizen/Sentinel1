import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class IncidentTypeSeverityFields extends StatelessWidget {
  final String type;
  final ValueChanged<String?> onTypeChanged;
  final String severity;
  final ValueChanged<String?> onSeverityChanged;

  const IncidentTypeSeverityFields({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.severity,
    required this.onSeverityChanged,
  });

  static const _types = [
    'Injury',
    'Near Miss',
    'Property Damage',
    'Environmental',
    'Hazard Observation',
  ];
  static const _severities = ['Minor', 'Moderate', 'Major', 'Critical'];

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return XMTheme.severityCritical;
      case 'Major':
        return XMTheme.severityMajor;
      case 'Moderate':
        return XMTheme.severityModerate;
      case 'Minor':
        return XMTheme.severityMinor;
      default:
        return XMTheme.severityNegligible;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(
              labelText: 'Type',
              prefixIcon: Icon(Icons.category),
            ),
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: onTypeChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: severity,
            decoration: const InputDecoration(
              labelText: 'Severity',
              prefixIcon: Icon(Icons.warning),
            ),
            items: _severities
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _severityColor(s),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(s),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: onSeverityChanged,
          ),
        ),
      ],
    );
  }
}
