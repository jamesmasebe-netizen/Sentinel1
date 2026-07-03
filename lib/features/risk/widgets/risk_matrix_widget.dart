import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class RiskMatrixWidget extends StatelessWidget {
  const RiskMatrixWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levels = ['Extreme', 'High', 'Medium', 'Low'];
    final colors = [
      XMTheme.riskExtreme,
      XMTheme.riskHigh,
      XMTheme.riskMedium,
      XMTheme.riskLow,
    ];

    return GCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 80),
              ...[
                'Rare',
                'Unlikely',
                'Possible',
                'Likely',
                'Almost Certain',
              ].map(
                (l) => Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          GSpacing.vSm,
          ...List.generate(4, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      levels[row],
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors[row],
                      ),
                    ),
                  ),
                  ...List.generate(5, (col) {
                    final intensity = (4 - row + col) / 8;
                    final cellColor = colors[row].withValues(
                      alpha: 0.1 + intensity * 0.6,
                    );
                    return Expanded(
                      child: Container(
                        height: 42,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors[row].withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${(row + col + 1)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors[row],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
