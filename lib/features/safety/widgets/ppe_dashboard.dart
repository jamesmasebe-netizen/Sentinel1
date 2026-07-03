import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class PPEDashboard extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final List<Map<String, dynamic>> upcoming;

  const PPEDashboard({
    super.key,
    required this.records,
    required this.upcoming,
  });

  @override
  Widget build(BuildContext context) {
    final compliant = records.where((r) => r['status'] == 'Compliant').length;
    final nonCompliant = records.where((r) => r['status'] == 'Non-Compliant').length;
    final expired = records.where((r) => r['status'] == 'Expired').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatCard(icon: Icons.engineering, label: 'Total', value: '${records.length}', color: XMTheme.info),
            _StatCard(icon: Icons.check_circle, label: 'Compliant', value: '$compliant', color: XMTheme.success),
            _StatCard(icon: Icons.cancel, label: 'Non-Compliant', value: '$nonCompliant', color: XMTheme.error),
            _StatCard(icon: Icons.calendar_today, label: 'Expired', value: '$expired', color: XMTheme.warning),
          ],
        ),
        GSpacing.vMd,
        if (upcoming.isNotEmpty) ...[
          GCard(
            color: XMTheme.info.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active, color: XMTheme.info, size: 18),
                    GSpacing.hSm,
                    Text('Smart Reminders', style: TextStyle(fontWeight: FontWeight.w600, color: XMTheme.info, fontSize: 14)),
                  ],
                ),
                GSpacing.vSm,
                ...upcoming.map((r) {
                  final daysLeft = DateTime.parse(r['expiryDate']).difference(DateTime.now()).inDays;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['employeeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(r['ppeType'] ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: XMTheme.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(XMTheme.radiusXl),
                          ),
                          child: Text('$daysLeft days left', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: XMTheme.warning)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          GSpacing.vMd,
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GCard(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            GSpacing.vSm,
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
            Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
