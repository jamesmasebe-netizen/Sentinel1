import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class DashboardKPIs extends StatelessWidget {
  final int active;
  final int highRisk;
  final double budget;
  final double avgSafety;

  const DashboardKPIs({
    super.key,
    required this.active,
    required this.highRisk,
    required this.budget,
    required this.avgSafety,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.compactCurrency(symbol: 'R');
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final chips = [
          _kpiChip(
            'Active Projects',
            active.toString(),
            Icons.folder_open_rounded,
            XMTheme.primary,
            isWide,
          ),
          _kpiChip(
            'Portfolio Budget',
            currencyFmt.format(budget),
            Icons.account_balance_rounded,
            XMTheme.info,
            isWide,
          ),
          _kpiChip(
            'High/Critical Risk',
            highRisk.toString(),
            Icons.warning_amber_rounded,
            XMTheme.error,
            isWide,
          ),
          _kpiChip(
            'Avg Safety Score',
            '${avgSafety.toStringAsFixed(1)}%',
            Icons.shield_rounded,
            XMTheme.success,
            isWide,
          ),
        ];
        if (isWide) {
          return Row(
            children:
                chips.expand((w) => [w, const SizedBox(width: 12)]).toList()
                  ..removeLast(),
          );
        }
        return Column(
          children:
              chips.expand((w) => [w, const SizedBox(height: 10)]).toList()
                ..removeLast(),
        );
      },
    );
  }

  Widget _kpiChip(
    String title,
    String value,
    IconData icon,
    Color color,
    bool expand,
  ) {
    final card = GCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (expand) return Expanded(child: card);
    return card;
  }
}
