import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class ContractorComplianceCard extends StatelessWidget {
  const ContractorComplianceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user,
            size: 48,
            color: XMTheme.success.withValues(alpha: 0.4),
          ),
          GSpacing.vMd,
          const Text('Contractor Compliance Tracking'),
          GSpacing.vSm,
          Text(
            'Insurance certificates, tax clearance, safety files',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
