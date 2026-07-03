import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';

class CompetencyEmployeeCard extends StatelessWidget {
  final MapEntry<String, List<Map<String, dynamic>>> entry;

  const CompetencyEmployeeCard({
    super.key,
    required this.entry,
  });

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Valid':
        return XMTheme.success;
      case 'Expiring Soon':
        return XMTheme.warning;
      case 'Expired':
        return XMTheme.error;
      case 'Revoked':
        return XMTheme.riskExtreme;
      default:
        return XMTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allValid = entry.value.every(
      (c) => c['status'] == 'Valid',
    );
    final hasExpired = entry.value.any(
      (c) => c['status'] == 'Expired',
    );
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (allValid
                          ? XMTheme.success
                          : hasExpired
                          ? XMTheme.error
                          : XMTheme.warning)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allValid
                      ? Icons.verified
                      : hasExpired
                      ? Icons.cancel
                      : Icons.warning,
                  size: 20,
                  color:
                      allValid
                          ? XMTheme.success
                          : hasExpired
                          ? XMTheme.error
                          : XMTheme.warning,
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${entry.value.length} certifications',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GStatusTag(
                label: allValid
                      ? 'COMPLIANT'
                      : hasExpired
                      ? 'NON-COMPLIANT'
                      : 'ACTION NEEDED',
                color: (allValid
                          ? XMTheme.success
                          : hasExpired
                          ? XMTheme.error
                          : XMTheme.warning),
              ),
            ],
          ),
          GSpacing.vMd,
          ...entry.value.map<Widget>((cert) {
            final status = cert['status'] ?? 'Valid';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      borderRadius: BorderRadius.circular(
                        2,
                      ),
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          cert['certification'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            if (cert['issuer'] != null &&
                                cert['issuer']
                                    .toString()
                                    .isNotEmpty)
                              Text(
                                '${cert['issuer']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            if (cert['expiryDate'] !=
                                null) ...[
                              Text(
                                ' • Exp: ${_formatDate(cert['expiryDate'])}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  GStatusTag(
                    label: status,
                    color: _statusColor(status),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
