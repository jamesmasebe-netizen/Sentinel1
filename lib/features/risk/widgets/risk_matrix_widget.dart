import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// Live likelihood/risk-rating distribution over `risk_assessments` (HIRA)
/// and `strategic_risks` — both write a `likelihood` field from the same
/// 5-value scale and a computed `riskRating` from the same 4-bucket scale
/// (strategic_risks uses 'Critical' where HIRA uses 'Extreme' for the top
/// bucket; treated as equivalent here). `dynamic_risk_assessments` is
/// intentionally excluded until F-306 gives it a comparable rating field.
class RiskMatrixWidget extends ConsumerWidget {
  const RiskMatrixWidget({super.key});

  static const _likelihoods = ['Rare', 'Unlikely', 'Possible', 'Likely', 'Almost Certain'];
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

  List<List<int>> _bucket(List<QueryDocumentSnapshot> docs) {
    final grid = List.generate(_levels.length, (_) => List.filled(_likelihoods.length, 0));
    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final row = _rowIndex(d['riskRating'] as String?);
      final col = _likelihoods.indexOf(d['likelihood'] as String? ?? '');
      if (row != null && col >= 0) grid[row][col]++;
    }
    return grid;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tenantId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: tenantId == null ? null : fs.tenantCollection(tenantId, 'risk_assessments').snapshots(),
      builder: (context, hiraSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: tenantId == null ? null : fs.tenantCollection(tenantId, 'strategic_risks').snapshots(),
          builder: (context, stratSnap) {
            final grid = _bucket([...?hiraSnap.data?.docs, ...?stratSnap.data?.docs]);
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
                            final cellColor = color.withValues(alpha: 0.1 + intensity * 0.6);
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
          },
        );
      },
    );
  }
}
