import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

class EmergencyContactsTab extends StatelessWidget {
  const EmergencyContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Emergency Contacts',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        GSpacing.vLg,
        const _ContactCard(
          name: 'Fire Department',
          number: '10111',
          icon: Icons.local_fire_department,
          color: XMTheme.error,
        ),
        const _ContactCard(
          name: 'Ambulance / EMS',
          number: '10177',
          icon: Icons.local_hospital,
          color: XMTheme.info,
        ),
        const _ContactCard(
          name: 'Police / SAPS',
          number: '10111',
          icon: Icons.local_police,
          color: XMTheme.primary,
        ),
        const _ContactCard(
          name: 'Poison Information',
          number: '0800 111 990',
          icon: Icons.warning,
          color: XMTheme.warning,
        ),
        const _ContactCard(
          name: 'SHE Manager',
          number: 'On-site ext. 201',
          icon: Icons.person,
          color: XMTheme.success,
        ),
        const _ContactCard(
          name: 'Environmental Officer',
          number: 'On-site ext. 205',
          icon: Icons.eco,
          color: XMTheme.success,
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name, number;
  final IconData icon;
  final Color color;

  const _ContactCard({
    required this.name,
    required this.number,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withValues(alpha: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(number, style: Theme.of(context).textTheme.bodySmall),
        trailing: IconButton.filledTonal(
          onPressed: () {
            UIUtils.showToast(context, 'Dialing $number...');
          },
          icon: const Icon(Icons.phone),
          color: color,
        ),
      ),
    );
  }
}
