import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final String value;
  final String module;
  final Color accent;
  final IconData icon;

  const _KpiData({
    required this.label,
    required this.value,
    required this.module,
    required this.accent,
    required this.icon,
  });
}

class _AlertData {
  final String title;
  final String description;
  final Color severity;

  const _AlertData({
    required this.title,
    required this.description,
    required this.severity,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ControlTowerScreen
// ─────────────────────────────────────────────────────────────────────────────

/// C-suite Global Control Tower — premium executive dashboard with live clock,
/// KPI cards, and critical alerts.
class ControlTowerScreen extends StatefulWidget {
  const ControlTowerScreen({super.key});

  @override
  State<ControlTowerScreen> createState() => _ControlTowerScreenState();
}

class _ControlTowerScreenState extends State<ControlTowerScreen>
    with TickerProviderStateMixin {
  // ── Clock ──────────────────────────────────────────────────────────────────
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  // ── Card entrance animations ───────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── Theme ──────────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF060B18);
  static const Color _surface = Color(0xFF0D1321);
  static const Color _surfaceAlt = Color(0xFF111827);
  static const Color _textPrimary = Color(0xFFEEF2FF);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _border = Color(0xFF1E293B);

  // ── Static Data ────────────────────────────────────────────────────────────
  static const List<_KpiData> _kpis = [
    _KpiData(
      label: 'Cash Position',
      value: '\$12.4M',
      module: 'Finance',
      accent: Color(0xFF22C55E),
      icon: Icons.account_balance_wallet_rounded,
    ),
    _KpiData(
      label: 'Open Work Orders',
      value: '47',
      module: 'Field Service',
      accent: Color(0xFFF97316),
      icon: Icons.build_circle_rounded,
    ),
    _KpiData(
      label: 'Active Projects',
      value: '23',
      module: 'PMO',
      accent: Color(0xFF3B82F6),
      icon: Icons.folder_special_rounded,
    ),
    _KpiData(
      label: 'Open Cases',
      value: '156',
      module: 'Customer Service',
      accent: Color(0xFFA855F7),
      icon: Icons.support_agent_rounded,
    ),
    _KpiData(
      label: 'Inventory Value',
      value: '\$8.2M',
      module: 'SCM',
      accent: Color(0xFF14B8A6),
      icon: Icons.inventory_2_rounded,
    ),
    _KpiData(
      label: 'Headcount',
      value: '1,847',
      module: 'HR',
      accent: Color(0xFFEC4899),
      icon: Icons.people_rounded,
    ),
  ];

  static const List<_AlertData> _alerts = [
    _AlertData(
      title: 'Low Cash Runway Detected',
      description:
          'Projected cash reserves fall below the 30-day threshold in Finance module. Immediate CFO review recommended.',
      severity: Color(0xFFEF4444),
    ),
    _AlertData(
      title: 'SLA Breach Risk — 12 Cases',
      description:
          '12 open customer cases are within 2 hours of their SLA deadline. Customer Service team notified.',
      severity: Color(0xFFF97316),
    ),
    _AlertData(
      title: 'Inventory Reorder Point Reached',
      description:
          'SKU-4421 (Industrial Valves) has reached the minimum reorder threshold. Auto-PO draft created.',
      severity: Color(0xFFEAB308),
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Live clock
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Entrance animation
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              _buildSectionLabel('Key Performance Indicators'),
              _buildKpiGrid(),
              _buildSectionLabel('Critical Alerts'),
              _buildAlerts(),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildHeader() {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_now);
    final timeStr = DateFormat('HH:mm:ss').format(_now);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A103A), Color(0xFF0A1628)],
          ),
          border: Border.all(color: const Color(0xFF2D1B69), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.18),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.5),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.cell_tower_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            // Titles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Global Control Tower',
                    style: TextStyle(
                      color: Color(0xFFEEF2FF),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Executive Intelligence Dashboard',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Date / Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Color(0xFF06B6D4),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildSectionLabel(String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFB24BF3), Color(0xFF06B6D4)],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── KPI Grid ───────────────────────────────────────────────────────────────
  SliverPadding _buildKpiGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _KpiCard(data: _kpis[index]),
          childCount: _kpis.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
        ),
      ),
    );
  }

  // ── Alerts ─────────────────────────────────────────────────────────────────
  SliverPadding _buildAlerts() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _AlertTile(data: _alerts[index]),
          childCount: _alerts.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI Card widget
// ─────────────────────────────────────────────────────────────────────────────
class _KpiCard extends StatefulWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(_glowCtrl);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.data.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withOpacity(_hovered ? 0.18 : 0.08),
                  const Color(0xFF0D1321),
                ],
              ),
              border: Border.all(
                color: accent.withOpacity(_hovered ? 0.6 : 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(_glowAnim.value * (_hovered ? 0.4 : 0.2)),
                  blurRadius: _hovered ? 24 : 14,
                  spreadRadius: _hovered ? 2 : 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon + module
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(widget.data.icon, color: accent, size: 18),
                      ),
                      const Spacer(),
                      Text(
                        widget.data.module,
                        style: TextStyle(
                          color: accent.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  // Value + label
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.value,
                        style: TextStyle(
                          color: const Color(0xFFEEF2FF),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          shadows: [
                            Shadow(
                              color: accent.withOpacity(0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        widget.data.label,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert Tile widget
// ─────────────────────────────────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final _AlertData data;
  const _AlertTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: data.severity.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: data.severity.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: data.severity.withOpacity(0.12),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.severity.withOpacity(0.15),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: data.severity,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        color: data.severity,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.description,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: data.severity.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
