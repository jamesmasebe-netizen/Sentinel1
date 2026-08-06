import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/models/safety_models.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/strategic_risk.dart';
import '../services/hira_service.dart';
import '../services/strategic_risk_service.dart';

/// Live likelihood/risk-rating distribution over `risk_assessments` (HIRA)
/// and `strategic_risks` — both write a `likelihood` field from the same
/// 5-value scale and a computed `riskRating` from the same 4-bucket scale
/// (strategic_risks uses 'Critical' where HIRA uses 'Extreme' for the top
/// bucket; treated as equivalent here). `dynamic_risk_assessments` is
/// intentionally excluded until F-306 gives it a comparable rating field.
class RiskMatrixWidget extends ConsumerWidget {
  const RiskMatrixWidget({super.key});

  static const _likelihoods = [
    'Rare',
    'Unlikely',
    'Possible',
    'Likely',
    'Almost Certain',
  ];
  static const _levels = ['Extreme', 'High', 'Medium', 'Low'];

  int? _rowIndex(String? rating) {
    switch (rating) {
      case 'Extreme':
      case 'Critical':
        return 0;
      case 'High':
        return 1;
      case 'Medium':
        return 2;
      case 'Low':
        return 3;
    }
    return null;
  }

  List<List<int>> _bucket(
    List<RiskAssessment> hiraDocs,
    List<StrategicRisk> stratDocs,
  ) {
    final grid = List.generate(
      _levels.length,
      (_) => List.filled(_likelihoods.length, 0),
    );
    void tally(String? riskRating, String? likelihood) {
      final row = _rowIndex(riskRating);
      final col = _likelihoods.indexOf(likelihood ?? '');
      if (row != null && col >= 0) grid[row][col]++;
    }

    for (final d in hiraDocs) {
      tally(d.riskRating, d.likelihood);
    }
    for (final d in stratDocs) {
      tally(d.riskRating, d.likelihood);
    }
    return grid;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hiraAsync = ref.watch(hiraAllAssessmentsProvider);
    final stratAsync = ref.watch(strategicRiskAllProvider);

    final grid = _bucket(
      hiraAsync.valueOrNull ?? const [],
      stratAsync.valueOrNull ?? const [],
    );
    final maxCount = grid.expand((r) => r).fold(0, (a, b) => a > b ? a : b);

    return GCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 80),
              ..._likelihoods.map(
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
          ...List.generate(_levels.length, (row) {
            final color = switch (_levels[row]) {
              'Extreme' => XMTheme.riskExtreme,
              'High' => XMTheme.riskHigh,
              'Medium' => XMTheme.riskMedium,
              _ => XMTheme.riskLow,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      _levels[row],
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  ...List.generate(_likelihoods.length, (col) {
                    final count = grid[row][col];
                    final intensity = maxCount == 0 ? 0.0 : count / maxCount;
                    final cellColor = color.withValues(
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
                            color: color.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
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
