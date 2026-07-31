import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../finance/providers/finance_providers.dart';
import '../../field_service/providers/field_service_providers.dart';
import '../../projects/providers/project_providers.dart';
import '../../customer_service/services/customer_service_service.dart';
import '../../supply_chain/providers/scm_streams_provider.dart';
import '../../people/providers/employee_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final String value;
  final String module;
  final Color accent;
  final IconData icon;
  final String route;

  const _KpiData({
    required this.label,
    required this.value,
    required this.module,
    required this.accent,
    required this.icon,
    required this.route,
  });
}

class _AlertData {
  final String title;
  final String description;
  final Color severity;
  final String route;

  const _AlertData({
    required this.title,
    required this.description,
    required this.severity,
    required this.route,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ControlTowerScreen
// ─────────────────────────────────────────────────────────────────────────────

/// C-suite Global Control Tower — premium executive dashboard with live clock,
/// real KPI cards (streamed from each pillar's own collection), and real
/// alerts, with drill-down navigation to the source module. See F-512 in
/// docs/fixes/FIX_LIST.md.
class ControlTowerScreen extends ConsumerStatefulWidget {
  const ControlTowerScreen({super.key});

  @override
  ConsumerState<ControlTowerScreen> createState() => _ControlTowerScreenState();
}

class _ControlTowerScreenState extends ConsumerState<ControlTowerScreen>
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

  String _fmtCurrency(double amount) {
    final sign = amount < 0 ? '-' : '';
    final abs = amount.abs();
    if (abs >= 1000000) return '$sign\$${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$sign\$${(abs / 1000).toStringAsFixed(1)}K';
    return '$sign\$${abs.toStringAsFixed(0)}';
  }

  List<_KpiData> _buildKpis() {
    final invoices = ref.watch(invoicesStreamProvider).valueOrNull;
    final workOrders = ref.watch(workOrdersStreamProvider).valueOrNull;
    final projects = ref.watch(projectsProvider).valueOrNull;
    final tickets = ref.watch(ticketsProvider).valueOrNull;
    final inventoryItems = ref.watch(inventoryItemsListStreamProvider).valueOrNull;
    final employees = ref.watch(employeesProvider).valueOrNull;

    final cashPosition = invoices == null
        ? null
        : invoices.where((i) => i.invoiceType == 'AR').fold<double>(0, (sum, i) => sum + (i.amountPaidOrReceived ?? 0)) -
            invoices.where((i) => i.invoiceType == 'AP').fold<double>(0, (sum, i) => sum + (i.amountPaidOrReceived ?? 0));

    final openWorkOrders = workOrders
        ?.where((w) => w.status != 'COMPLETED' && w.status != 'CANCELED')
        .length;

    final activeProjects = projects?.where((p) => p.status == 'Active').length;

    final openCases = tickets
        ?.where((t) => t.status != 'Resolved' && t.status != 'Closed')
        .length;

    final inventoryValue = inventoryItems?.fold<double>(
        0,
        (sum, i) => sum + (i.stockLevel * ((i.standardCost?['amount'] as num?)?.toDouble() ?? 0)));

    final activeHeadcount = employees?.where((e) => e.status == 'Active').length;

    return [
      _KpiData(
        label: 'Cash Position',
        value: cashPosition == null ? '—' : _fmtCurrency(cashPosition),
        module: 'Finance',
        accent: const Color(0xFF22C55E),
        icon: Icons.account_balance_wallet_rounded,
        route: '/finance',
      ),
      _KpiData(
        label: 'Open Work Orders',
        value: openWorkOrders?.toString() ?? '—',
        module: 'Field Service',
        accent: const Color(0xFFF97316),
        icon: Icons.build_circle_rounded,
        route: '/field-service',
      ),
      _KpiData(
        label: 'Active Projects',
        value: activeProjects?.toString() ?? '—',
        module: 'PMO',
        accent: const Color(0xFF3B82F6),
        icon: Icons.folder_special_rounded,
        route: '/projects-ops',
      ),
      _KpiData(
        label: 'Open Cases',
        value: openCases?.toString() ?? '—',
        module: 'Customer Service',
        accent: const Color(0xFFA855F7),
        icon: Icons.support_agent_rounded,
        route: '/customer-service',
      ),
      _KpiData(
        label: 'Inventory Value',
        value: inventoryValue == null ? '—' : _fmtCurrency(inventoryValue),
        module: 'SCM',
        accent: const Color(0xFF14B8A6),
        icon: Icons.inventory_2_rounded,
        route: '/supply-chain',
      ),
      _KpiData(
        label: 'Headcount',
        value: activeHeadcount?.toString() ?? '—',
        module: 'HR',
        accent: const Color(0xFFEC4899),
        icon: Icons.people_rounded,
        route: '/hr',
      ),
    ];
  }

  List<_AlertData> _buildAlerts() {
    final invoices = ref.watch(invoicesStreamProvider).valueOrNull;
    final inventoryItems = ref.watch(inventoryItemsListStreamProvider).valueOrNull;
    final alerts = <_AlertData>[];

    if (invoices != null) {
      final cashPosition = invoices.where((i) => i.invoiceType == 'AR').fold<double>(0, (sum, i) => sum + (i.amountPaidOrReceived ?? 0)) -
          invoices.where((i) => i.invoiceType == 'AP').fold<double>(0, (sum, i) => sum + (i.amountPaidOrReceived ?? 0));
      if (cashPosition < 0) {
        alerts.add(_AlertData(
          title: 'Negative Net Cash Position',
          description:
              'Realized AP payments currently exceed realized AR receipts by ${_fmtCurrency(cashPosition.abs())}. Review outstanding invoices in Finance.',
          severity: const Color(0xFFEF4444),
          route: '/finance',
        ));
      }
    }

    if (inventoryItems != null) {
      final lowStock = inventoryItems.where((i) => i.stockLevel <= i.reorderPoint).toList();
      if (lowStock.isNotEmpty) {
        alerts.add(_AlertData(
          title: 'Inventory Reorder Point Reached',
          description:
              '${lowStock.length} item(s) are at or below their reorder point, including "${lowStock.first.name}". Review in Supply Chain.',
          severity: const Color(0xFFEAB308),
          route: '/supply-chain',
        ));
      }
    }

    return alerts;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final kpis = _buildKpis();
    final alerts = _buildAlerts();

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
              _buildKpiGrid(kpis),
              _buildSectionLabel('Critical Alerts'),
              _buildAlertsSliver(alerts),
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
              color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
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
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
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
  SliverPadding _buildKpiGrid(List<_KpiData> kpis) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _KpiCard(data: kpis[index]),
          childCount: kpis.length,
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
  Widget _buildAlertsSliver(List<_AlertData> alerts) {
    if (alerts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            'No critical alerts.',
            style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _AlertTile(data: alerts[index]),
          childCount: alerts.length,
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
      child: GestureDetector(
        onTap: () => context.go(widget.data.route),
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
                    accent.withValues(alpha: _hovered ? 0.18 : 0.08),
                    const Color(0xFF0D1321),
                  ],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: _hovered ? 0.6 : 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: _glowAnim.value * (_hovered ? 0.4 : 0.2)),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(widget.data.icon, color: accent, size: 18),
                        ),
                        const Spacer(),
                        Text(
                          widget.data.module,
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
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
                                color: accent.withValues(alpha: 0.6),
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
        child: InkWell(
          onTap: () => context.go(data.route),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: data.severity.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: data.severity.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.severity.withValues(alpha: 0.12),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.severity.withValues(alpha: 0.15),
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
                  color: data.severity.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
