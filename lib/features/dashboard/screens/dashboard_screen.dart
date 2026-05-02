import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/skeleton_loader.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (siteId == null) return const Center(child: Text('No site assigned.'));

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('incidents')
          .where('siteId', isEqualTo: siteId)
          .orderBy('createdAt', descending: true).limit(10).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const DashboardSkeleton();
        }
        
        final incidents = (snap.data?.docs ?? []).map((d) => d.data() as Map<String, dynamic>).toList();
        final openCount = incidents.where((i) => i['status'] == 'Open').length;
        final criticalCount = incidents.where((i) => i['severity'] == 'Critical' || i['severity'] == 'Major').length;
        final recent30 = incidents.where((i) {
          try { return DateTime.parse(i['createdAt']).isAfter(DateTime.now().subtract(const Duration(days: 30))); } catch (_) { return false; }
        }).length;
        final riskScore = (recent30 * 15).clamp(0, 100);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Text('Command Center', style: Theme.of(context).textTheme.headlineSmall),
            Text('Real-time intelligence for ${profile?.siteId ?? "your site"}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            // KPI Row 1
            Row(children: [
              Expanded(flex: 2, child: _Bento(gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('LTIFR', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  const Text('0.45', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                  Row(children: [const Icon(Icons.trending_down, color: XMTheme.success, size: 16), const SizedBox(width: 4), Text('2.1% improvement', style: TextStyle(color: XMTheme.success, fontSize: 12))]),
                ]))),
              const SizedBox(width: 12),
              Expanded(child: Column(children: [
                _Bento(gradient: LinearGradient(colors: [XMTheme.primary, XMTheme.primaryDark]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('OPEN', style: TextStyle(color: Color(0xFFBBDEFB), fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('$openCount', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                  ])),
                const SizedBox(height: 12),
                _Bento(color: Theme.of(context).cardColor,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CRITICAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: XMTheme.error)),
                    const SizedBox(height: 6),
                    Text('$criticalCount', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                  ])),
              ])),
            ]),
            const SizedBox(height: 12),
            // KPI Row 2
            Row(children: [
              _KpiSmall(icon: Icons.verified, value: '94%', label: 'Compliance', color: XMTheme.success),
              const SizedBox(width: 12),
              _KpiSmall(icon: Icons.shield, value: '$riskScore/100', label: 'Risk Score', color: riskScore > 50 ? XMTheme.error : XMTheme.success),
              const SizedBox(width: 12),
              _KpiSmall(icon: Icons.engineering, value: '8', label: 'Pending Maint.', color: XMTheme.info),
            ]),
            const SizedBox(height: 24),
            // Risk Radar
            _SectionCard(title: 'Enterprise Risk Radar', icon: Icons.gpp_maybe, iconColor: XMTheme.secondary, children: [
              _RiskRow(text: 'Facade degradation on South wing', site: 'Site A', sev: 'High', color: XMTheme.warning),
              _RiskRow(text: 'Cooling system redundancy failure', site: 'Site B', sev: 'Critical', color: XMTheme.error),
              _RiskRow(text: 'Fire safety regulation changes', site: 'Site C', sev: 'Medium', color: XMTheme.info),
            ]),
            const SizedBox(height: 16),
            // Action Center
            _SectionCard(title: 'Action Center', icon: Icons.checklist, iconColor: XMTheme.primary, children: [
              _ActionRow(title: 'Sign off on SOP: Working at Heights', type: 'Document', urgent: true),
              _ActionRow(title: 'Complete daily site inspection', type: 'Task', urgent: false),
              _ActionRow(title: 'Review Incident Report #INC-2026-042', type: 'Review', urgent: true),
            ]),
            const SizedBox(height: 16),
            // Recent Incidents
            _SectionCard(title: 'Recent Incidents', icon: Icons.report, iconColor: XMTheme.error, children: [
              if (incidents.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No recent incidents')))
              else ...incidents.take(5).map((inc) => _IncRow(data: inc)),
            ]),
            const SizedBox(height: 32),
          ]),
        );
      },
    );
  }
}

class _Bento extends StatelessWidget {
  final Widget child; final LinearGradient? gradient; final Color? color;
  const _Bento({required this.child, this.gradient, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: gradient, color: color, borderRadius: BorderRadius.circular(XMTheme.radiusLg), border: gradient == null ? Border.all(color: Theme.of(context).dividerColor) : null),
    child: child,
  );
}

class _KpiSmall extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _KpiSmall({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(XMTheme.radiusLg), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20), const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  ));
}

class _SectionCard extends StatelessWidget {
  final String title; final IconData icon; final Color iconColor; final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.iconColor, required this.children});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, color: iconColor, size: 20), const SizedBox(width: 8), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis))]),
    const SizedBox(height: 12), ...children,
  ])));
}

class _RiskRow extends StatelessWidget {
  final String text, site, sev; final Color color;
  const _RiskRow({required this.text, required this.site, required this.sev, required this.color});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(XMTheme.radiusMd), border: Border.all(color: Theme.of(context).dividerColor)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(site, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
        child: Text(sev, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
    ]),
  );
}

class _ActionRow extends StatelessWidget {
  final String title, type; final bool urgent;
  const _ActionRow({required this.title, required this.type, required this.urgent});
  @override
  Widget build(BuildContext context) {
    final c = urgent ? XMTheme.error : XMTheme.primary;
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(XMTheme.radiusMd)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(type, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
          child: Text(urgent ? 'Urgent' : 'Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c))),
      ]),
    );
  }
}

class _IncRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _IncRow({required this.data});
  @override
  Widget build(BuildContext context) {
    final isOpen = data['status'] == 'Open';
    final c = isOpen ? XMTheme.error : XMTheme.success;
    return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(XMTheme.radiusMd)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${data['type'] ?? ''} • ${data['severity'] ?? ''}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
          child: Text(data['status'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c))),
      ]),
    );
  }
}
