import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Mock Data Models ─────────────────────────────────────────────────────────

class _JournalEntry {
  final String id;
  final String description;
  final String project;
  final double debit;
  final double credit;
  final DateTime date;
  final String status;
  final String milestone;

  const _JournalEntry({
    required this.id,
    required this.description,
    required this.project,
    required this.debit,
    required this.credit,
    required this.date,
    required this.status,
    required this.milestone,
  });
}

// ─── Mock Journal Entries ─────────────────────────────────────────────────────

final _mockEntries = [
  _JournalEntry(
    id: 'JE-2026-041',
    description: 'Revenue recognised on project milestone completion',
    project: 'Riverside Precinct Development',
    debit: 85000.00,
    credit: 85000.00,
    date: DateTime(2026, 6, 30),
    status: 'Posted',
    milestone: 'M3 – Structural Handover',
  ),
  _JournalEntry(
    id: 'JE-2026-042',
    description: 'Deferred revenue reclassification – Phase 2 start',
    project: 'Harbour Tunnel Extension',
    debit: 120000.00,
    credit: 120000.00,
    date: DateTime(2026, 6, 28),
    status: 'Posted',
    milestone: 'M1 – Mobilisation',
  ),
  _JournalEntry(
    id: 'JE-2026-043',
    description: 'Contract modification – scope increase recognition',
    project: 'Solar Farm Grid Connect',
    debit: 45000.00,
    credit: 45000.00,
    date: DateTime(2026, 6, 25),
    status: 'Pending Review',
    milestone: 'M2 – Grid Design Approval',
  ),
  _JournalEntry(
    id: 'JE-2026-044',
    description: 'Performance obligation satisfied – HVAC installation',
    project: 'Alder Heights Commercial Tower',
    debit: 18000.00,
    credit: 18000.00,
    date: DateTime(2026, 6, 20),
    status: 'Posted',
    milestone: 'M4 – MEP Completion',
  ),
  _JournalEntry(
    id: 'JE-2026-045',
    description: 'Variable consideration constraint released – Stage 3',
    project: 'East Precinct Road Upgrade',
    debit: 12000.00,
    credit: 12000.00,
    date: DateTime(2026, 6, 15),
    status: 'Draft',
    milestone: 'M5 – Final Inspection',
  ),
];

// ─── Providers ────────────────────────────────────────────────────────────────

final _ledgerFilterProvider = StateProvider<String>((ref) => 'All');

// ─── Screen ───────────────────────────────────────────────────────────────────

class RevenueRecognitionScreen extends ConsumerWidget {
  const RevenueRecognitionScreen({super.key});

  // Deep blue / emerald palette
  static const _bgDeep = Color(0xFF050D1A);
  static const _navyDark = Color(0xFF0A1628);
  static const _navy = Color(0xFF0D2137);
  static const _navyAccent = Color(0xFF1A3A5C);
  static const _blueGlow = Color(0xFF1E6FD9);
  static const _emerald = Color(0xFF10B981);
  static const _emeraldLight = Color(0xFF34D399);
  static const _amber = Color(0xFFF59E0B);
  static const _rose = Color(0xFFF87171);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_ledgerFilterProvider);

    final filtered =
        filter == 'All'
            ? _mockEntries
            : _mockEntries.where((e) => e.status == filter).toList();

    return Scaffold(
      backgroundColor: _bgDeep,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 80,
            pinned: true,
            backgroundColor: _navyDark,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _blueGlow.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: _blueGlow,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Revenue Recognition',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white70),
                tooltip: 'Export Ledger',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white70,
                ),
                tooltip: 'Filter',
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Summary Cards ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _SummarySection(),
            ),
          ),

          // ── Period Indicator ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: _blueGlow,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Period: Q2 2026  ·  Apr – Jun 2026',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Standard: IFRS 15',
                    style: TextStyle(
                      fontSize: 11,
                      color: _blueGlow.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Ledger Table Header ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _LedgerHeader(filter: filter, ref: ref),
            ),
          ),

          // ── Ledger Rows ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver:
                filtered.isEmpty
                    ? SliverToBoxAdapter(
                      child: _EmptyState(filter: filter),
                    )
                    : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _LedgerRow(
                          entry: filtered[index],
                          isEven: index.isEven,
                        ),
                        childCount: filtered.length,
                      ),
                    ),
          ),

          // ── Totals Row ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverToBoxAdapter(
              child: _TotalsRow(entries: filtered),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Section ──────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Deferred Revenue',
                amount: r'$420,000',
                subtitle: '6 contracts pending',
                icon: Icons.hourglass_top_rounded,
                accentColor: RevenueRecognitionScreen._amber,
                gradientColors: const [
                  Color(0xFF1A2A10),
                  Color(0xFF0F1E0A),
                ],
                borderColor: RevenueRecognitionScreen._amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Recognised Revenue',
                amount: r'$280,000',
                subtitle: '5 milestones satisfied',
                icon: Icons.check_circle_rounded,
                accentColor: RevenueRecognitionScreen._emerald,
                gradientColors: const [
                  Color(0xFF0A2520),
                  Color(0xFF051510),
                ],
                borderColor: RevenueRecognitionScreen._emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RevenueProgressBar(
          recognised: 280000,
          deferred: 420000,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final Color borderColor;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _RevenueProgressBar extends StatelessWidget {
  final double recognised;
  final double deferred;

  const _RevenueProgressBar({
    required this.recognised,
    required this.deferred,
  });

  @override
  Widget build(BuildContext context) {
    final total = recognised + deferred;
    final recognisedFraction = total == 0 ? 0.0 : recognised / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevenueRecognitionScreen._navy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              RevenueRecognitionScreen._navyAccent.withValues(alpha: 0.60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Total Contract Value',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const Spacer(),
              Text(
                '\$${(total / 1000).toStringAsFixed(0)}K',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  color: RevenueRecognitionScreen._amber.withValues(alpha: 0.25),
                ),
                FractionallySizedBox(
                  widthFactor: recognisedFraction,
                  child: Container(
                    height: 10,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          RevenueRecognitionScreen._emerald,
                          RevenueRecognitionScreen._emeraldLight,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(
                color: RevenueRecognitionScreen._emerald,
                label:
                    'Recognised ${(recognisedFraction * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(width: 16),
              _Legend(
                color: RevenueRecognitionScreen._amber.withValues(alpha: 0.70),
                label:
                    'Deferred ${((1 - recognisedFraction) * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}

// ─── Ledger Header ────────────────────────────────────────────────────────────

class _LedgerHeader extends StatelessWidget {
  final String filter;
  final WidgetRef ref;

  const _LedgerHeader({required this.filter, required this.ref});

  static const _statuses = ['All', 'Posted', 'Pending Review', 'Draft'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 16,
              color: RevenueRecognitionScreen._blueGlow,
            ),
            const SizedBox(width: 8),
            const Text(
              'Milestone Journal Entries',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // Status filter chips
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final s = _statuses[i];
                  final selected = s == filter;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(_ledgerFilterProvider.notifier).state = s,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? RevenueRecognitionScreen._blueGlow
                                    .withValues(alpha: 0.25)
                                : RevenueRecognitionScreen._navy,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              selected
                                  ? RevenueRecognitionScreen._blueGlow
                                  : RevenueRecognitionScreen._navyAccent,
                        ),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              selected
                                  ? RevenueRecognitionScreen._blueGlow
                                  : Colors.white54,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: RevenueRecognitionScreen._navyAccent.withValues(alpha: 0.40),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _ColHeader('Description / Project'),
              ),
              Expanded(
                flex: 2,
                child: _ColHeader('Milestone'),
              ),
              _ColHeader('Debit', rightAlign: true),
              const SizedBox(width: 16),
              _ColHeader('Credit', rightAlign: true),
              const SizedBox(width: 16),
              _ColHeader('Date', rightAlign: true),
              const SizedBox(width: 12),
              _ColHeader('Status'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final bool rightAlign;
  const _ColHeader(this.text, {this.rightAlign = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: rightAlign ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Ledger Row ───────────────────────────────────────────────────────────────

class _LedgerRow extends StatelessWidget {
  final _JournalEntry entry;
  final bool isEven;
  const _LedgerRow({required this.entry, required this.isEven});

  Color _statusColor(String status) {
    switch (status) {
      case 'Posted':
        return RevenueRecognitionScreen._emerald;
      case 'Pending Review':
        return RevenueRecognitionScreen._amber;
      case 'Draft':
        return Colors.white38;
      default:
        return Colors.white54;
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} '
      '${_month(dt.month)} '
      '${dt.year}';

  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(entry.status);

    return Container(
      decoration: BoxDecoration(
        color:
            isEven
                ? RevenueRecognitionScreen._navy.withValues(alpha: 0.40)
                : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color:
                RevenueRecognitionScreen._navyAccent.withValues(alpha: 0.30),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description + Project
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.id,
                  style: const TextStyle(
                    fontSize: 9,
                    color: RevenueRecognitionScreen._blueGlow,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.project,
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
              ],
            ),
          ),
          // Milestone
          Expanded(
            flex: 2,
            child: Text(
              entry.milestone,
              style: const TextStyle(fontSize: 10, color: Colors.white60),
            ),
          ),
          // Debit
          SizedBox(
            width: 70,
            child: Text(
              '\$${_fmt(entry.debit)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: RevenueRecognitionScreen._rose.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Credit
          SizedBox(
            width: 70,
            child: Text(
              '\$${_fmt(entry.credit)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: RevenueRecognitionScreen._emerald,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Date
          SizedBox(
            width: 64,
            child: Text(
              _formatDate(entry.date),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ),
          const SizedBox(width: 12),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              entry.status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    }
    return v.toStringAsFixed(0);
  }
}

// ─── Totals Row ───────────────────────────────────────────────────────────────

class _TotalsRow extends StatelessWidget {
  final List<_JournalEntry> entries;
  const _TotalsRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final totalDebit = entries.fold<double>(0, (s, e) => s + e.debit);
    final totalCredit = entries.fold<double>(0, (s, e) => s + e.credit);
    final balanced = (totalDebit - totalCredit).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevenueRecognitionScreen._navyAccent.withValues(alpha: 0.30),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        border: Border.all(
          color: RevenueRecognitionScreen._navyAccent.withValues(alpha: 0.50),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: const SizedBox.shrink()),
          Text(
            'TOTALS',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white54,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              '\$${_fmtFull(totalDebit)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: RevenueRecognitionScreen._rose,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 70,
            child: Text(
              '\$${_fmtFull(totalCredit)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: RevenueRecognitionScreen._emerald,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const SizedBox(width: 64),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:
                  (balanced
                          ? RevenueRecognitionScreen._emerald
                          : RevenueRecognitionScreen._rose)
                      .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  balanced
                      ? Icons.balance_rounded
                      : Icons.warning_amber_rounded,
                  size: 10,
                  color:
                      balanced
                          ? RevenueRecognitionScreen._emerald
                          : RevenueRecognitionScreen._rose,
                ),
                const SizedBox(width: 4),
                Text(
                  balanced ? 'Balanced' : 'Unbalanced',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color:
                        balanced
                            ? RevenueRecognitionScreen._emerald
                            : RevenueRecognitionScreen._rose,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtFull(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'No "$filter" entries found.',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
