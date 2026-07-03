import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class ComplianceTab extends StatelessWidget {
  const ComplianceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      ('Register with COIDA Fund (RAF)', true),
      ('Annual Return of Earnings submitted', true),
      ('W.CL.2 form filed within 7 days of incident', true),
      ('Medical reports obtained from treating doctor', false),
      ('Employee notified of claim status', false),
      ('Return-to-work plan documented', false),
      ('COIDA claim file retained for 3 years', true),
      ('Compensation Commissioner correspondence filed', false),
      ('Section 56 investigation if applicable', false),
      ('Death benefit notifications processed', false),
    ];
    final done = items.where((e) => e.$2).length;
    final progress = done / items.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GCard(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COIDA Compliance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GSpacing.vSm,
                      Text(
                        '$done / ${items.length} requirements met',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: XMTheme.success,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GSpacing.vLg,
          Text(
            'Compliance Checklist',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          GSpacing.vMd,
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.$2
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color:
                          item.$2 ? XMTheme.success : theme.colorScheme.outline,
                      size: 22,
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: Text(
                        item.$1,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              item.$2
                                  ? null
                                  : theme.colorScheme.onSurfaceVariant,
                          decoration:
                              item.$2 ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
