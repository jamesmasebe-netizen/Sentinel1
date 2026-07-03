import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class DRACard extends StatelessWidget {
  final Map<String, dynamic> data;
  const DRACard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hazards = (data['hazardsIdentified'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final controls = (data['controlsApplied'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final isSafe = data['isSafeToProceed'] == true;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (isSafe ? XMTheme.success : XMTheme.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(isSafe ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isSafe ? XMTheme.success : XMTheme.error, size: 22),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['taskDescription'] ?? 'Untitled Assessment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    GSpacing.vXs,
                    Text(UIUtils.formatTimestamp(data['createdAt']), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              GStatusTag(label: isSafe ? 'SAFE' : 'UNSAFE', color: isSafe ? XMTheme.success : XMTheme.error),
            ],
          ),
          GSpacing.vMd,
          if (data['location'] != null && data['location'].toString().isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.primary),
                GSpacing.hSm,
                Text(data['location'], style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            GSpacing.vMd,
          ],
          const Divider(height: 1, thickness: 0.5),
          GSpacing.vMd,
          Text('HAZARDS IDENTIFIED', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error, letterSpacing: 1.1)),
          GSpacing.vSm,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hazards.map((h) => _TinyBadge(label: h, color: theme.colorScheme.error)).toList(),
          ),
          GSpacing.vMd,
          Text('CONTROLS APPLIED', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.1)),
          GSpacing.vSm,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controls.map((c) => _TinyBadge(label: c, color: theme.colorScheme.primary)).toList(),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
