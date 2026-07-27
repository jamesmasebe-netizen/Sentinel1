import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Mock Data Models ─────────────────────────────────────────────────────────

class _KeyResult {
  final String title;
  final double progress; // 0.0 – 1.0
  final String metric;
  final String target;

  const _KeyResult({
    required this.title,
    required this.progress,
    required this.metric,
    required this.target,
  });
}

class _Objective {
  final String title;
  final String category;
  final IconData icon;
  final List<_KeyResult> keyResults;

  const _Objective({
    required this.title,
    required this.category,
    required this.icon,
    required this.keyResults,
  });

  double get overallProgress =>
      keyResults.isEmpty
          ? 0.0
          : keyResults.map((kr) => kr.progress).reduce((a, b) => a + b) /
              keyResults.length;
}

// ─── Mock OKR Data ────────────────────────────────────────────────────────────

const _mockObjectives = [
  _Objective(
    title: 'Achieve Operational Excellence',
    category: 'Operations',
    icon: Icons.rocket_launch_rounded,
    keyResults: [
      _KeyResult(
        title: 'Reduce incident response time by 30%',
        progress: 0.72,
        metric: '21.4 min avg',
        target: '21 min',
      ),
      _KeyResult(
        title: 'Complete 100% of SLA-bound tickets on time',
        progress: 0.88,
        metric: '88 / 100',
        target: '100%',
      ),
      _KeyResult(
        title: 'Automate 5 repetitive workflows',
        progress: 0.60,
        metric: '3 of 5 done',
        target: '5 workflows',
      ),
    ],
  ),
  _Objective(
    title: 'Grow Revenue & Client Portfolio',
    category: 'Commercial',
    icon: Icons.trending_up_rounded,
    keyResults: [
      _KeyResult(
        title: 'Onboard 10 new enterprise clients',
        progress: 0.50,
        metric: '5 clients',
        target: '10 clients',
      ),
      _KeyResult(
        title: 'Increase ARR by 25%',
        progress: 0.38,
        metric: '+9.5%',
        target: '+25%',
      ),
      _KeyResult(
        title: 'Achieve NPS score ≥ 60',
        progress: 0.90,
        metric: 'NPS 54',
        target: 'NPS 60',
      ),
    ],
  ),
  _Objective(
    title: 'Strengthen People & Culture',
    category: 'HR & People',
    icon: Icons.groups_rounded,
    keyResults: [
      _KeyResult(
        title: 'Complete 360° reviews for all managers',
        progress: 1.0,
        metric: '12 / 12',
        target: '12 reviews',
      ),
      _KeyResult(
        title: 'Achieve ≥ 80% employee satisfaction score',
        progress: 0.78,
        metric: '78%',
        target: '80%',
      ),
      _KeyResult(
        title: 'Deliver 40 hrs of L&D per employee',
        progress: 0.55,
        metric: '22 hrs avg',
        target: '40 hrs',
      ),
    ],
  ),
];

// ─── Providers ────────────────────────────────────────────────────────────────

final _selectedCycleProvider = StateProvider<String>(
  (ref) => 'Q2 2026',
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class OkrDashboardScreen extends ConsumerWidget {
  const OkrDashboardScreen({super.key});

  // Brand purple/indigo palette
  static const _gradientStart = Color(0xFF4F46E5); // Indigo-600
  static const _gradientEnd = Color(0xFF7C3AED);   // Violet-600
  static const _gradientMid = Color(0xFF6366F1);   // Indigo-500
  static const _accentAmber = Color(0xFFFBBF24);
  static const _accentEmerald = Color(0xFF34D399);
  static const _accentRose = Color(0xFFF87171);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycle = ref.watch(_selectedCycleProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          // ── Gradient SliverAppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildHeaderBanner(cycle, cs),
            ),
            actions: [
              _CycleSelector(currentCycle: cycle),
              const SizedBox(width: 8),
            ],
          ),

          // ── Summary Chips Row ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: _SummaryRow(objectives: _mockObjectives),
            ),
          ),

          // ── Section Label ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    size: 18,
                    color: _gradientMid,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Objectives & Key Results',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_mockObjectives.length} objectives',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── OKR Cards ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ObjectiveCard(
                  objective: _mockObjectives[index],
                  index: index,
                ),
                childCount: _mockObjectives.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(String cycle, ColorScheme cs) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1B4B), // Indigo-950
            Color(0xFF312E81), // Indigo-900
            Color(0xFF4C1D95), // Violet-900
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gradientEnd.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gradientStart.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _accentAmber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: _accentAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$cycle Performance Review Cycle',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accentAmber,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'OKR Dashboard',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: _gradientMid,
                        child: Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alex Johnson  ·  Senior Operations Manager',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cycle Selector ───────────────────────────────────────────────────────────

class _CycleSelector extends ConsumerWidget {
  final String currentCycle;
  const _CycleSelector({required this.currentCycle});

  static const _cycles = ['Q1 2026', 'Q2 2026', 'Q3 2026', 'Q4 2026'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      initialValue: currentCycle,
      onSelected:
          (val) =>
              ref.read(_selectedCycleProvider.notifier).state = val,
      itemBuilder:
          (context) =>
              _cycles
                  .map(
                    (c) => PopupMenuItem(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentCycle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<_Objective> objectives;
  const _SummaryRow({required this.objectives});

  @override
  Widget build(BuildContext context) {
    final totalKRs = objectives.fold<int>(
      0,
      (sum, o) => sum + o.keyResults.length,
    );
    final completedKRs = objectives.fold<int>(
      0,
      (sum, o) => sum + o.keyResults.where((kr) => kr.progress >= 1.0).length,
    );
    final avgProgress =
        objectives.isEmpty
            ? 0.0
            : objectives.map((o) => o.overallProgress).reduce((a, b) => a + b) /
                objectives.length;
    final onTrack = objectives.where((o) => o.overallProgress >= 0.6).length;

    return Row(
      children: [
        _SummaryChip(
          label: 'Avg. Progress',
          value: '${(avgProgress * 100).toStringAsFixed(0)}%',
          icon: Icons.donut_large_rounded,
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(width: 10),
        _SummaryChip(
          label: 'On Track',
          value: '$onTrack / ${objectives.length}',
          icon: Icons.check_circle_outline_rounded,
          color: OkrDashboardScreen._accentEmerald,
        ),
        const SizedBox(width: 10),
        _SummaryChip(
          label: 'KRs Done',
          value: '$completedKRs / $totalKRs',
          icon: Icons.task_alt_rounded,
          color: OkrDashboardScreen._accentAmber,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Objective Card ───────────────────────────────────────────────────────────

class _ObjectiveCard extends StatefulWidget {
  final _Objective objective;
  final int index;
  const _ObjectiveCard({required this.objective, required this.index});

  @override
  State<_ObjectiveCard> createState() => _ObjectiveCardState();
}

class _ObjectiveCardState extends State<_ObjectiveCard> {
  bool _expanded = true;

  static const _cardColors = [
    [Color(0xFF312E81), Color(0xFF1E1B4B)], // Indigo deep
    [Color(0xFF4C1D95), Color(0xFF2E1065)], // Violet deep
    [Color(0xFF1E3A5F), Color(0xFF0F2442)], // Blue deep
  ];

  Color _progressColor(double progress) {
    if (progress >= 1.0) return OkrDashboardScreen._accentEmerald;
    if (progress >= 0.6) return const Color(0xFF818CF8); // Indigo-400
    if (progress >= 0.3) return OkrDashboardScreen._accentAmber;
    return OkrDashboardScreen._accentRose;
  }

  @override
  Widget build(BuildContext context) {
    final obj = widget.objective;
    final idx = widget.index % _cardColors.length;
    final gradColors = _cardColors[idx];
    final pct = (obj.overallProgress * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradColors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(obj.icon, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            obj.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            obj.category,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Overall progress badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _progressColor(obj.overallProgress),
                          ),
                        ),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white38,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Thin overall progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: obj.overallProgress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _progressColor(obj.overallProgress),
                  ),
                ),
              ),
            ),

            // ── Key Results ───────────────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _KeyResultsList(
                keyResults: obj.keyResults,
                progressColor: _progressColor,
              ),
              crossFadeState:
                  _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Key Results List ─────────────────────────────────────────────────────────

class _KeyResultsList extends StatelessWidget {
  final List<_KeyResult> keyResults;
  final Color Function(double) progressColor;

  const _KeyResultsList({
    required this.keyResults,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        children: [
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 12),
          ...keyResults.map((kr) => _KeyResultTile(
                keyResult: kr,
                progressColor: progressColor(kr.progress),
              )),
        ],
      ),
    );
  }
}

class _KeyResultTile extends StatelessWidget {
  final _KeyResult keyResult;
  final Color progressColor;

  const _KeyResultTile({
    required this.keyResult,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (keyResult.progress * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radio_button_checked_rounded,
                size: 12,
                color: progressColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  keyResult.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: keyResult.progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                'Current: ${keyResult.metric}',
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
              const Spacer(),
              Text(
                'Target: ${keyResult.target}',
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
